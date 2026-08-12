# 👻 GhostThumbs

🌐 **[Read in English](README.md)**

**Vea miniaturas de archivos guardados solo en la nube — sin descargarlos.**

GhostThumbs resuelve la **queja n.º 1** sobre el almacenamiento en la nube en Windows: *«¿Por qué no puedo ver miniaturas de mis archivos almacenados solo en la nube?»*

Cuando usas Dropbox Smart Sync, OneDrive Files On-Demand o Google Drive Streaming, Windows mantiene tus archivos en la nube para ahorrar espacio en disco. Sin embargo, también **se niega a mostrar vistas previas de miniaturas** de esos archivos, dejándote con filas de iconos en blanco genéricos en lugar de vistas previas de imágenes reales.

GhostThumbs soluciona esto descargando temporalmente cada imagen el tiempo suficiente para guardar su miniatura en la caché y liberando inmediatamente el espacio. Obtienes vistas previas visuales de cada archivo mientras mantienes tu disco limpio.

## ✨ Características

- 🔍 **Detección automática** de carpetas de Dropbox, OneDrive, Google Drive e iCloud
- 👻 **Guarda miniaturas en caché** sin descargar archivos de forma permanente  
- 📁 **Escaneo recursivo** — procesa árboles de carpetas completos
- ⚡ **Rápido** — procesa cientos de imágenes en segundos
- 🔄 **Modo programado** — ejecución automática al iniciar sesión para mantener las miniaturas actualizadas
- 🖱️ **Lanzador de doble clic** — no se requieren conocimientos de terminal
- 💻 **Sin dependencias** — PowerShell puro, funciona en cualquier PC con Windows 10/11

## 🚀 Inicio rápido

### Opción 1: Doble clic (la más fácil)
1. Descarga este repositorio
2. Haz doble clic en **`GhostThumbs.bat`**
3. Encontrará automáticamente tus carpetas en la nube y guardará en caché todas las miniaturas

### Opción 2: PowerShell (más control)
```powershell
# Detectar automáticamente y procesar todas las carpetas en la nube
.\GhostThumbs.ps1

# Procesar una carpeta específica
.\GhostThumbs.ps1 -FolderPath "C:\Users\you\Dropbox\Photos"

# Procesar una carpeta y todas sus subcarpetas
.\GhostThumbs.ps1 -FolderPath "C:\Users\you\OneDrive" -Recurse

# Ejecutar de forma silenciosa (para tareas programadas)
.\GhostThumbs.ps1 -AutoDetect -Recurse -Silent
```

### Opción 3: Ejecución automática al iniciar sesión
1. Haz doble clic en **`install-scheduled.bat`** (ejecutar como Administrador)
2. GhostThumbs se ejecutará 2 minutos después de cada inicio de sesión
3. Para eliminarlo: `schtasks /delete /tn "GhostThumbs" /f`

## 🧠 Cómo funciona

1. **Escanea** tus carpetas de almacenamiento en la nube en busca de archivos de imagen marcados como "solo en la nube" (atributos de archivo Offline + Sparse)
2. **Lee** cada archivo, lo que obliga al proveedor de la nube (Dropbox/OneDrive/etc.) a descargarlo temporalmente
3. **Genera** una miniatura utilizando la interfaz COM de Windows Shell y .NET System.Drawing
4. **Almacena** la miniatura en la base de datos `thumbcache` integrada de Windows
5. **Libera** el archivo para que el proveedor de la nube pueda eliminar la copia local y recuperar espacio en disco

Las miniaturas permanecen en la caché de Windows incluso después de que los archivos vuelvan al estado de "solo en la nube", por lo que verás vistas previas sin desperdiciar almacenamiento.

## ❓ Preguntas frecuentes (FAQ)

**P: ¿Esto descarga mis archivos de forma permanente?**  
R: No. Los archivos se descargan temporalmente (unos pocos segundos por archivo) y luego se liberan. El uso de espacio en disco vuelve a la normalidad.

**P: ¿Qué proveedores de la nube son compatibles?**  
R: Dropbox Smart Sync, OneDrive Files On-Demand, Google Drive Streaming, iCloud Drive y cualquier proveedor que utilice la API de Windows Cloud Files.

**P: ¿Las miniaturas se mantienen tras reiniciar?**  
R: ¡Sí! Se almacenan en la base de datos de caché de miniaturas de Windows. Solo desaparecen si limpias manualmente la caché de miniaturas (Liberador de espacio en disco → Miniaturas).

**P: ¿Qué formatos de imagen son compatibles?**  
R: JPG, JPEG, PNG, GIF, BMP, WebP, TIFF, ICO, HEIC, HEIF, AVIF, JFIF, SVG y formatos RAW (CR2, NEF, ARW).

**P: ¿Es seguro?**  
R: Sí. GhostThumbs solo lee archivos — nunca modifica, mueve ni elimina nada. El código fuente es totalmente abierto y legible.

## 📋 Requisitos

- Windows 10 o Windows 11
- PowerShell 5.1+ (incluido con Windows)
- Al menos una aplicación de almacenamiento en la nube con "Archivos a petición" (Files On-Demand) o "Smart Sync" activado

## 📄 Licencia

Licencia MIT — consulta [LICENSE](LICENSE) para más detalles.

## 🤝 Contribuciones

¿Encontraste un error? ¿Tienes una idea? ¡Abre un problema (issue) o envía un PR!

---

*Creado por la frustración con Microsoft por no resolver esto por sí mismos. 👻*
