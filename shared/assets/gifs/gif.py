import os
from PIL import Image
from pathlib import Path

def extraer_p4x(nombre_gif, salto=5):
    # Definir la ruta de salida de forma dinámica (~/Descargas/gif1)
    home = str(Path.home())
    output_dir = os.path.join(home, "Descargas", "gif1")
    
    # Crear la carpeta si no existe
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"📁 Carpeta creada: {output_dir}")

    try:
        with Image.open(nombre_gif) as im:
            saved_count = 0
            total_frames = im.n_frames
            
            print(f"🚀 Procesando {nombre_gif} ({total_frames} frames)...")
            
            for i in range(total_frames):
                im.seek(i)
                # Aplicamos tu lógica de 1 fotograma cada 5
                if i % salto == 0:
                    frame_path = os.path.join(output_dir, f"frame_{saved_count:03d}.png")
                    # Convertimos a RGBA por si tiene transparencias el GIF
                    im.convert("RGBA").save(frame_path)
                    saved_count += 1
            
            print(f"✅ ¡Listo! {saved_count} fotogramas guardados en: {output_dir}")
            
    except FileNotFoundError:
        print(f"❌ Error: No encontré el archivo {nombre_gif} en esta carpeta.")

# Ejecución con tus datos específicos
extraer_p4x("22222332.gif", salto=5)
