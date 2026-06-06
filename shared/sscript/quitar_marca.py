#!/usr/bin/env python3
import os
import sys

try:
    import cv2
    import numpy as np
    from PIL import Image
    OPENCV_AVAILABLE = True
except ImportError:
    OPENCV_AVAILABLE = False
    from PIL import Image, ImageFilter

def remove_watermark(input_path, output_path, method="inpaint"):
    try:
        if method == "inpaint" and OPENCV_AVAILABLE:
            # Usar OpenCV para "Inpainting" (Reconstrucción inteligente de píxeles)
            # 1. Leer la imagen con OpenCV
            img_cv = cv2.imread(input_path)
            if img_cv is None:
                raise ValueError("No se pudo leer la imagen con OpenCV.")
                
            h, w = img_cv.shape[:2]
            
            # 2. Crear una máscara (fondo negro, zona a reparar en blanco)
            mask = np.zeros((h, w), dtype=np.uint8)
            
            # La marca de Gemini suele estar en los últimos 80x80 píxeles de la esquina inferior derecha
            # Dibujamos un rectángulo blanco en la máscara en esa zona
            ancho_marca = 80
            alto_marca = 80
            cv2.rectangle(mask, (w - ancho_marca, h - alto_marca), (w, h), 255, -1)
            
            # 3. Aplicar inpainting (Telea algorithm suele ser muy bueno para logos)
            result_cv = cv2.inpaint(img_cv, mask, inpaintRadius=3, flags=cv2.INPAINT_TELEA)
            
            # Guardar resultado
            cv2.imwrite(output_path, result_cv)
            print(f"✅ Procesado con Inteligencia Artificial (Inpaint): {os.path.basename(input_path)}")
            return

        # Si OpenCV no está disponible o se elige otro método, usar Pillow
        with Image.open(input_path) as img:
            width, height = img.size
            
            if method == "crop":
                crop_box = (0, 0, width, height - 60)
                result_img = img.crop(crop_box)
            
            elif method == "blur":
                result_img = img.copy()
                box = (width - 100, height - 100, width, height)
                region = result_img.crop(box)
                region = region.filter(ImageFilter.GaussianBlur(radius=15))
                result_img.paste(region, box)
                
            elif method == "patch":
                result_img = img.copy()
                patch_width = 100
                patch_height = 100
                source_box = (width - patch_width * 2, height - patch_height, width - patch_width, height)
                patch = result_img.crop(source_box)
                target_box = (width - patch_width, height - patch_height, width, height)
                result_img.paste(patch, target_box)
                
            else:
                if method == "inpaint" and not OPENCV_AVAILABLE:
                    print("⚠️ OpenCV no está instalado. Ejecuta 'pip install opencv-python' primero.")
                    return
                result_img = img
                
            result_img.save(output_path)
            print(f"✅ Procesado: {os.path.basename(input_path)}")
            
    except Exception as e:
        print(f"❌ Error al procesar {os.path.basename(input_path)}: {e}")

def main():
    import sys
    
    # Si se pasa un archivo como argumento (ej. python3 quitar_marca.py foto.png)
    if len(sys.argv) > 1:
        # Se pueden pasar múltiples imágenes: python3 quitar_marca.py img1.png img2.jpg
        archivos_a_procesar = sys.argv[1:]
    else:
        # Si no se pasan argumentos, buscar en la carpeta actual
        print("⚠️ No se especificó una imagen. Procesando todas las imágenes en la carpeta actual...")
        folder_path = "."
        extensiones = ('.png', '.jpg', '.jpeg', '.webp')
        archivos_a_procesar = [f for f in os.listdir(folder_path) if f.lower().endswith(extensiones)]
        
        if not archivos_a_procesar:
            print("❌ No se encontraron imágenes. Uso: python3 quitar_marca.py <nombre_de_imagen.png>")
            return

    # Usar el método más avanzado por defecto
    metodo_elegido = "inpaint" 
    
    for filename in archivos_a_procesar:
        if not os.path.exists(filename):
            print(f"❌ El archivo '{filename}' no existe.")
            continue
            
        # Carpeta donde está el archivo original (por si se pasa una ruta como carpeta/imagen.png)
        directorio_base = os.path.dirname(filename) or "."
        nombre_archivo = os.path.basename(filename)
        
        # Crear la carpeta sin_marca_magia en el mismo lugar que la imagen original
        output_folder = os.path.join(directorio_base, "sin_marca_magia")
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)
            
        output_path = os.path.join(output_folder, nombre_archivo)
        remove_watermark(filename, output_path, method=metodo_elegido)
        
    print(f"✨ ¡Proceso terminado! Las imágenes están en la carpeta 'sin_marca_magia'.")

if __name__ == "__main__":
    main()
