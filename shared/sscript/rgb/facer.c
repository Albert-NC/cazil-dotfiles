// SPDX-License-Identifier: GPL-2.0-or-later
/*
 *  Acer Nitro AN515-58 RGB Keyboard Backlight Driver (v5.0 - Final)
 *  All professional improvements applied.
 */

#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/acpi.h>
#include <linux/atomic.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/dmi.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/platform_device.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/version.h>
#include <linux/wmi.h>
#include <linux/workqueue.h>

MODULE_AUTHOR("Antigravity");
MODULE_DESCRIPTION("Acer Nitro AN515-58 RGB Backlight Driver");
MODULE_LICENSE("GPL");
MODULE_VERSION("5.0");

/* Compatibility macros */
#ifndef RTLNX_VER_MIN
#define RTLNX_VER_MIN(a, b, c) (LINUX_VERSION_CODE >= KERNEL_VERSION(a, b, c))
#endif

#define WMID_GUID4 "7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56"
#define ACER_WMID_SET_GAMINGKBBL_METHODID 20
#define ACER_WMID_SET_GAMING_LED_METHODID 2
#define ACER_WMID_GET_GAMING_SYS_INFO_METHODID 5
#define ACER_WMID_SET_GAMING_STATIC_LED_METHODID 6

#define GAMING_KBBL_CHR "acer-gkbbl"
#define GAMING_KBBL_CONFIG_LEN 16
#define GAMING_KBBL_STATIC_CONFIG_LEN 4
#define DRIVER_NAME "acer-nitro-rgb"
#define NUM_ZONES 4

/* ioctl interface */
#define NITRO_RGB_IOC_MAGIC 'N'
#define NITRO_RGB_GET_STATIC                                                   \
  _IOR(NITRO_RGB_IOC_MAGIC, 1, struct nitro_zone_color[NUM_ZONES])
#define NITRO_RGB_GET_DYNAMIC                                                  \
  _IOR(NITRO_RGB_IOC_MAGIC, 2, u8[GAMING_KBBL_CONFIG_LEN])
#define NITRO_RGB_SET_ALL_ZONES                                                \
  _IOW(NITRO_RGB_IOC_MAGIC, 3, struct nitro_zone_color[NUM_ZONES])

struct nitro_zone_color {
  u8 zone;
  u8 r, g, b;
} __packed;

struct nitro_rgb_state {
  struct device *dev;
  struct class *cls;
  struct mutex lock;
  atomic_t open_count;

  /* Cache: dynamic */
  u8 applied_dynamic_config[GAMING_KBBL_CONFIG_LEN];
  bool has_dynamic_applied;

  /* Cache: static (per-zone) */
  struct nitro_zone_color applied_static[NUM_ZONES];
  bool has_static_applied;

  /* Pending state (consumed by workqueue) */
  u8 pending_dynamic_config[GAMING_KBBL_CONFIG_LEN];
  struct nitro_zone_color pending_static[NUM_ZONES];
  bool pending_is_dynamic;
  bool work_pending;

  struct work_struct rgb_work;
  struct cdev cdev_dynamic;
  struct cdev cdev_static;
  dev_t devt;
};

struct led_zone_set_param {
  u8 zone;
  u8 red, green, blue;
} __packed;

/* WMI call helpers */

static acpi_status nitro_wmi_send_array(u32 method_id, void *buf, size_t len) {
  struct acpi_buffer input = {(acpi_size)len, buf};
  return wmi_evaluate_method(WMID_GUID4, 0, method_id, &input, NULL);
}

/* Workqueue Handler */

static void nitro_rgb_work_handler(struct work_struct *work) {
  struct nitro_rgb_state *state =
      container_of(work, struct nitro_rgb_state, rgb_work);
  acpi_status status;

  mutex_lock(&state->lock);

  if (state->pending_is_dynamic) {
    status = nitro_wmi_send_array(ACER_WMID_SET_GAMINGKBBL_METHODID,
                                  state->pending_dynamic_config,
                                  GAMING_KBBL_CONFIG_LEN);
    if (ACPI_SUCCESS(status)) {
      memcpy(state->applied_dynamic_config, state->pending_dynamic_config,
             GAMING_KBBL_CONFIG_LEN);
      state->has_dynamic_applied = true;
    }
  } else {
    int i;
    for (i = 0; i < NUM_ZONES; i++) {
      struct led_zone_set_param params = {
          .zone = state->pending_static[i].zone,
          .red = state->pending_static[i].r,
          .green = state->pending_static[i].g,
          .blue = state->pending_static[i].b,
      };
      status = nitro_wmi_send_array(ACER_WMID_SET_GAMING_STATIC_LED_METHODID,
                                    &params, sizeof(params));
      if (ACPI_SUCCESS(status))
        state->applied_static[i] = state->pending_static[i];
    }
    state->has_static_applied = true;
  }

  state->work_pending = false;
  mutex_unlock(&state->lock);
}

/* Sysfs */

static ssize_t last_static_color_show(struct device *dev,
                                      struct device_attribute *attr,
                                      char *buf) {
  struct nitro_rgb_state *state = dev_get_drvdata(dev);
  int len = 0, i;
  if (!state->has_static_applied)
    return sysfs_emit(buf, "not set\n");
  for (i = 0; i < NUM_ZONES; i++)
    len +=
        sysfs_emit_at(buf, len, "Z%u: R=%u G=%u B=%u\n",
                      state->applied_static[i].zone, state->applied_static[i].r,
                      state->applied_static[i].g, state->applied_static[i].b);
  return len;
}
static DEVICE_ATTR_RO(last_static_color);

static ssize_t last_dynamic_config_show(struct device *dev,
                                        struct device_attribute *attr,
                                        char *buf) {
  struct nitro_rgb_state *state = dev_get_drvdata(dev);
  int i, len = 0;
  if (!state->has_dynamic_applied)
    return sysfs_emit(buf, "not set\n");
  for (i = 0; i < GAMING_KBBL_CONFIG_LEN; i++)
    len += sysfs_emit_at(buf, len, "%02x ", state->applied_dynamic_config[i]);
  len += sysfs_emit_at(buf, len, "\n");
  return len;
}
static DEVICE_ATTR_RO(last_dynamic_config);

static struct attribute *nitro_rgb_attrs[] = {
    &dev_attr_last_static_color.attr,
    &dev_attr_last_dynamic_config.attr,
    NULL,
};
ATTRIBUTE_GROUPS(nitro_rgb);

/* Character Device Handlers */

static int nitro_rgb_open(struct inode *inode, struct file *file) {
  struct nitro_rgb_state *state;

  if (iminor(inode) == 0)
    state = container_of(inode->i_cdev, struct nitro_rgb_state, cdev_dynamic);
  else
    state = container_of(inode->i_cdev, struct nitro_rgb_state, cdev_static);

  /* Only allow one user at a time per device */
  if (atomic_inc_return(&state->open_count) > 1) {
    atomic_dec(&state->open_count);
    return -EBUSY;
  }

  file->private_data = state;
  return 0;
}

static int nitro_rgb_release(struct inode *inode, struct file *file) {
  struct nitro_rgb_state *state = file->private_data;
  atomic_dec(&state->open_count);
  return 0;
}

static ssize_t nitro_rgb_write(struct file *file, const char __user *buf,
                               size_t count, loff_t *offset) {
  struct nitro_rgb_state *state = file->private_data;
  int minor = iminor(file_inode(file));
  unsigned long copy_err;

  if (minor == 0) { /* Dynamic */
    u8 tmp[GAMING_KBBL_CONFIG_LEN];
    if (count != GAMING_KBBL_CONFIG_LEN)
      return -EINVAL;
    copy_err = copy_from_user(tmp, buf, GAMING_KBBL_CONFIG_LEN);
    if (copy_err)
      return -EFAULT;

    mutex_lock(&state->lock);
    if (state->has_dynamic_applied && memcmp(state->applied_dynamic_config, tmp,
                                             GAMING_KBBL_CONFIG_LEN) == 0) {
      mutex_unlock(&state->lock);
      return count; /* Cached — no-op */
    }
    memcpy(state->pending_dynamic_config, tmp, GAMING_KBBL_CONFIG_LEN);
    state->pending_is_dynamic = true;

  } else { /* Static — single zone */
    struct nitro_zone_color zone;
    if (count != sizeof(struct nitro_zone_color))
      return -EINVAL;
    copy_err = copy_from_user(&zone, buf, sizeof(zone));
    if (copy_err)
      return -EFAULT;
    if (zone.zone >= NUM_ZONES)
      return -EINVAL;

    mutex_lock(&state->lock);
    if (state->has_static_applied &&
        memcmp(&state->applied_static[zone.zone], &zone, sizeof(zone)) == 0) {
      mutex_unlock(&state->lock);
      return count; /* Cached — no-op */
    }
    state->pending_static[zone.zone] = zone;
    state->pending_is_dynamic = false;
  }

  state->work_pending = true;
  schedule_work(&state->rgb_work);
  mutex_unlock(&state->lock);
  return count;
}

static ssize_t nitro_rgb_read(struct file *file, char __user *buf, size_t count,
                              loff_t *offset) {
  struct nitro_rgb_state *state = file->private_data;
  int minor = iminor(file_inode(file));
  ssize_t ret;

  mutex_lock(&state->lock);

  if (minor == 0) {
    if (count < GAMING_KBBL_CONFIG_LEN) {
      ret = -EINVAL;
      goto out;
    }
    if (!state->has_dynamic_applied) {
      ret = -ENODATA;
      goto out;
    }
    if (copy_to_user(buf, state->applied_dynamic_config,
                     GAMING_KBBL_CONFIG_LEN)) {
      ret = -EFAULT;
      goto out;
    }
    ret = GAMING_KBBL_CONFIG_LEN;
  } else {
    size_t sz = sizeof(struct nitro_zone_color) * NUM_ZONES;
    if (count < sz) {
      ret = -EINVAL;
      goto out;
    }
    if (!state->has_static_applied) {
      ret = -ENODATA;
      goto out;
    }
    if (copy_to_user(buf, state->applied_static, sz)) {
      ret = -EFAULT;
      goto out;
    }
    ret = sz;
  }

out:
  mutex_unlock(&state->lock);
  return ret;
}

static long nitro_rgb_ioctl(struct file *file, unsigned int cmd,
                            unsigned long arg) {
  struct nitro_rgb_state *state = file->private_data;
  struct nitro_zone_color zones[NUM_ZONES];
  int i;

  switch (cmd) {
  case NITRO_RGB_GET_STATIC:
    mutex_lock(&state->lock);
    if (!state->has_static_applied) {
      mutex_unlock(&state->lock);
      return -ENODATA;
    }
    if (copy_to_user((void __user *)arg, state->applied_static,
                     sizeof(struct nitro_zone_color) * NUM_ZONES)) {
      mutex_unlock(&state->lock);
      return -EFAULT;
    }
    mutex_unlock(&state->lock);
    return 0;

  case NITRO_RGB_GET_DYNAMIC:
    mutex_lock(&state->lock);
    if (!state->has_dynamic_applied) {
      mutex_unlock(&state->lock);
      return -ENODATA;
    }
    if (copy_to_user((void __user *)arg, state->applied_dynamic_config,
                     GAMING_KBBL_CONFIG_LEN)) {
      mutex_unlock(&state->lock);
      return -EFAULT;
    }
    mutex_unlock(&state->lock);
    return 0;

  case NITRO_RGB_SET_ALL_ZONES:
    if (copy_from_user(zones, (void __user *)arg,
                       sizeof(struct nitro_zone_color) * NUM_ZONES))
      return -EFAULT;
    for (i = 0; i < NUM_ZONES; i++)
      if (zones[i].zone >= NUM_ZONES)
        return -EINVAL;
    mutex_lock(&state->lock);
    memcpy(state->pending_static, zones, sizeof(zones));
    state->pending_is_dynamic = false;
    state->work_pending = true;
    schedule_work(&state->rgb_work);
    mutex_unlock(&state->lock);
    return 0;

  default:
    return -ENOTTY;
  }
}

static const struct file_operations nitro_rgb_fops = {
    .owner = THIS_MODULE,
    .open = nitro_rgb_open,
    .release = nitro_rgb_release,
    .write = nitro_rgb_write,
    .read = nitro_rgb_read,
    .unlocked_ioctl = nitro_rgb_ioctl,
};

/* Power Management */

static int nitro_rgb_resume(struct device *dev) {
  struct nitro_rgb_state *state = dev_get_drvdata(dev);
  u64 *val = kzalloc(sizeof(u64), GFP_KERNEL);
  struct acpi_buffer input;

  if (!val)
    return -ENOMEM;
  *val = 8L | (15UL << 40);
  input.length = sizeof(u64);
  input.pointer = val;
  wmi_evaluate_method(WMID_GUID4, 0, ACER_WMID_SET_GAMING_LED_METHODID, &input,
                      NULL);
  kfree(val);

  dev_info(dev, "Restoring RGB state after resume...\n");

  mutex_lock(&state->lock);
  /* Restore last known good mode */
  if (state->has_dynamic_applied) {
    memcpy(state->pending_dynamic_config, state->applied_dynamic_config,
           GAMING_KBBL_CONFIG_LEN);
    state->pending_is_dynamic = true;
    state->work_pending = true;
    schedule_work(&state->rgb_work);
  } else if (state->has_static_applied) {
    memcpy(state->pending_static, state->applied_static,
           sizeof(state->applied_static));
    state->pending_is_dynamic = false;
    state->work_pending = true;
    schedule_work(&state->rgb_work);
  }
  mutex_unlock(&state->lock);

  return 0;
}

static const struct dev_pm_ops nitro_rgb_pm_ops = {
    .resume = nitro_rgb_resume,
};

/* DMI Matching */
static const struct dmi_system_id nitro_dmi_table[] __initconst = {
    {
        .ident = "Acer Nitro AN515-58",
        .matches =
            {
                DMI_MATCH(DMI_SYS_VENDOR, "Acer"),
                DMI_MATCH(DMI_PRODUCT_NAME, "Nitro AN515-58"),
            },
    },
    {}};
MODULE_DEVICE_TABLE(dmi, nitro_dmi_table);

/* Managed Cleanup */

static void nitro_unregister_chrdev(void *data) {
  struct nitro_rgb_state *state = data;
  cancel_work_sync(&state->rgb_work);
  device_destroy(state->cls, MKDEV(MAJOR(state->devt), 1));
  device_destroy(state->cls, MKDEV(MAJOR(state->devt), 0));
  cdev_del(&state->cdev_static);
  cdev_del(&state->cdev_dynamic);
  unregister_chrdev_region(state->devt, 2);
}

static void nitro_destroy_class(void *data) {
  class_destroy((struct class *)data);
}

static int nitro_rgb_uevent(
#if RTLNX_VER_MIN(6, 2, 0)
    const
#endif
    struct device *dev,
    struct kobj_uevent_env *env) {
  add_uevent_var(env, "DEVMODE=%#o", 0666);
  return 0;
}

/* Probe */

static int nitro_rgb_probe(struct platform_device *pdev) {
  struct nitro_rgb_state *state;
  struct class *cls;
  int err;

  state = devm_kzalloc(&pdev->dev, sizeof(*state), GFP_KERNEL);
  if (!state)
    return -ENOMEM;

  state->dev = &pdev->dev;
  mutex_init(&state->lock);
  atomic_set(&state->open_count, 0);
  INIT_WORK(&state->rgb_work, nitro_rgb_work_handler);
  platform_set_drvdata(pdev, state);

  err = alloc_chrdev_region(&state->devt, 0, 2, GAMING_KBBL_CHR);
  if (err < 0)
    return err;

#if RTLNX_VER_MIN(6, 4, 0)
  cls = class_create(GAMING_KBBL_CHR);
#else
  cls = class_create(THIS_MODULE, GAMING_KBBL_CHR);
#endif
  if (IS_ERR(cls)) {
    unregister_chrdev_region(state->devt, 2);
    return PTR_ERR(cls);
  }
  cls->dev_uevent = nitro_rgb_uevent;
  state->cls = cls;

  err = devm_add_action_or_reset(&pdev->dev, nitro_destroy_class, cls);
  if (err)
    return err;

  cdev_init(&state->cdev_dynamic, &nitro_rgb_fops);
  state->cdev_dynamic.owner = THIS_MODULE;
  err = cdev_add(&state->cdev_dynamic, MKDEV(MAJOR(state->devt), 0), 1);
  if (err)
    goto err_out;
  device_create(cls, &pdev->dev, MKDEV(MAJOR(state->devt), 0), NULL,
                "acer-gkbbl");

  cdev_init(&state->cdev_static, &nitro_rgb_fops);
  state->cdev_static.owner = THIS_MODULE;
  err = cdev_add(&state->cdev_static, MKDEV(MAJOR(state->devt), 1), 1);
  if (err)
    goto err_out;
  device_create(cls, &pdev->dev, MKDEV(MAJOR(state->devt), 1), NULL,
                "acer-gkbbl-static");

  err = devm_add_action_or_reset(&pdev->dev, nitro_unregister_chrdev, state);
  if (err)
    return err;

  /* Hardware init */
  {
    struct acpi_buffer sysinfo_out = {ACPI_ALLOCATE_BUFFER, NULL};
    /* Use kzalloc (not stack) for WMI buffer — consistent with resume() */
    u64 *led_val = kzalloc(sizeof(u64), GFP_KERNEL);
    struct acpi_buffer led_in;

    if (!led_val)
      return -ENOMEM;

    wmi_evaluate_method(WMID_GUID4, 0, ACER_WMID_GET_GAMING_SYS_INFO_METHODID,
                        NULL, &sysinfo_out);
    kfree(sysinfo_out.pointer);

    *led_val = 8L | (15UL << 40);
    led_in.length = sizeof(u64);
    led_in.pointer = led_val;
    wmi_evaluate_method(WMID_GUID4, 0, ACER_WMID_SET_GAMING_LED_METHODID,
                        &led_in, NULL);
    kfree(led_val);
  }

  dev_info(&pdev->dev, "Nitro RGB v5.0 Loaded\n");
  return 0;

err_out:
  unregister_chrdev_region(state->devt, 2);
  return err;
}

static struct platform_driver nitro_rgb_driver = {
    .probe = nitro_rgb_probe,
    .driver =
        {
            .name = DRIVER_NAME,
            .pm = &nitro_rgb_pm_ops,
            .dev_groups = nitro_rgb_groups,
        },
};

static struct platform_device *nitro_rgb_device;

static int __init nitro_init(void) {
  if (!dmi_check_system(nitro_dmi_table)) {
    pr_warn("Hardware not supported (DMI mismatch)\n");
    return -ENODEV;
  }
  if (!wmi_has_guid(WMID_GUID4))
    return -ENODEV;

  if (platform_driver_register(&nitro_rgb_driver))
    return -EIO;

  nitro_rgb_device = platform_device_register_simple(DRIVER_NAME, -1, NULL, 0);
  if (IS_ERR(nitro_rgb_device)) {
    platform_driver_unregister(&nitro_rgb_driver);
    return PTR_ERR(nitro_rgb_device);
  }
  return 0;
}

static void __exit nitro_exit(void) {
  platform_device_unregister(nitro_rgb_device);
  platform_driver_unregister(&nitro_rgb_driver);
}

module_init(nitro_init);
module_exit(nitro_exit);
