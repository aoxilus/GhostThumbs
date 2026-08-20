# 👻 GhostThumbs 🥑

🌐 **[Leer en Español](README.es.md)**

**See thumbnails for cloud-only files — without downloading them.**

GhostThumbs solves the **#1 complaint** about cloud storage on Windows: *"Why can't I see thumbnails for my cloud-only files?"*

When you use Dropbox Smart Sync, OneDrive Files On-Demand, or Google Drive Streaming, Windows keeps your files in the cloud to save disk space. But it also **refuses to show thumbnail previews** for those files — leaving you with rows of generic blank icons instead of actual image previews.

GhostThumbs fixes this by temporarily downloading each image just long enough to cache its thumbnail, then immediately freeing the space. You get visual previews of every file, while keeping your disk clean.

## ✨ Features

- 🔍 **Auto-detects** Dropbox, OneDrive, Google Drive, and iCloud folders
- 👻 **Caches thumbnails** without permanently downloading files  
- 📁 **Recursive scanning** — process entire folder trees
- ⚡ **Fast** — processes hundreds of images in seconds
- 🔄 **Scheduled mode** — auto-run on login to keep thumbnails fresh
- 🖱️ **Double-click launcher** — no terminal knowledge needed
- 💻 **Zero dependencies** — pure PowerShell, works on any Windows 10/11 PC

## 🚀 Quick Start

### Option 1: Double-click (easiest)
1. Download this repo
2. Double-click **`GhostThumbs.bat`**
3. It auto-finds your cloud folders and caches all thumbnails

### Option 2: PowerShell (more control)
```powershell
# Auto-detect and process all cloud folders
.\GhostThumbs.ps1

# Process a specific folder
.\GhostThumbs.ps1 -FolderPath "C:\Users\you\Dropbox\Photos"

# Process a folder and all subfolders
.\GhostThumbs.ps1 -FolderPath "C:\Users\you\OneDrive" -Recurse

# Run silently (for scheduled tasks)
.\GhostThumbs.ps1 -AutoDetect -Recurse -Silent
```

### Option 3: Auto-run on login
1. Double-click **`install-scheduled.bat`** (run as Administrator)
2. GhostThumbs will run 2 minutes after every login
3. To remove: `schtasks /delete /tn "GhostThumbs" /f`

## 🧠 How It Works

1. **Scans** your cloud storage folders for image files marked as "cloud-only" (Offline + Sparse file attributes)
2. **Reads** each file, which forces the cloud provider (Dropbox/OneDrive/etc.) to temporarily download it
3. **Generates** a thumbnail using the Windows Shell COM interface and .NET System.Drawing
4. **Stores** the thumbnail in Windows' built-in `thumbcache` database
5. **Frees** the file so the cloud provider can remove the local copy and reclaim disk space

The thumbnails persist in Windows' cache even after the files go back to cloud-only status, so you see previews without wasting storage.

## ❓ FAQ

**Q: Does this permanently download my files?**  
A: No. Files are downloaded temporarily (a few seconds per file) and then freed. Your disk space usage goes back to normal.

**Q: Which cloud providers are supported?**  
A: Dropbox Smart Sync, OneDrive Files On-Demand, Google Drive Streaming, iCloud Drive, and any provider that uses the Windows Cloud Files API.

**Q: Do thumbnails survive a reboot?**  
A: Yes! They're stored in Windows' thumbnail cache database. They only disappear if you manually clear the thumbnail cache (Disk Cleanup → Thumbnails).

**Q: What image formats are supported?**  
A: JPG, JPEG, PNG, GIF, BMP, WebP, TIFF, ICO, HEIC, HEIF, AVIF, JFIF, SVG, and RAW formats (CR2, NEF, ARW).

**Q: Is it safe?**  
A: Yes. GhostThumbs only reads files — it never modifies, moves, or deletes anything. The source code is fully open and readable.

## 📋 Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+ (included with Windows)
- At least one cloud storage app with "Files On-Demand" or "Smart Sync" enabled

## 📄 License

CC BY-NC-SA 4.0 — see [LICENSE](LICENSE).

## 🤝 Contributing

Found a bug? Have an idea? Open an issue or submit a PR!

---

*Made with 🥑 by [aoxilus](https://github.com/aoxilus)*
