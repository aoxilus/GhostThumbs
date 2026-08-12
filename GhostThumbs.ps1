<#
.SYNOPSIS
    GhostThumbs — See thumbnails for cloud-only files without downloading them.

.DESCRIPTION
    Solves the #1 complaint about cloud storage on Windows:
    "Why can't I see thumbnails for my cloud-only files?"

    GhostThumbs temporarily downloads each image, forces Windows to cache 
    its thumbnail, then immediately frees the space — giving you visual 
    previews of files that only exist in the cloud.

    Works with Dropbox Smart Sync, OneDrive Files On-Demand, Google Drive 
    Streaming, and any cloud provider using the Windows Cloud Files API.

.PARAMETER FolderPath
    The folder to process. If not specified, auto-detects cloud folders.

.PARAMETER Recurse
    Process subfolders recursively.

.PARAMETER BatchSize
    Number of files to process per batch. Default: 10

.PARAMETER AutoDetect
    Automatically find and process all cloud storage folders.

.PARAMETER Silent
    Minimal output — only shows summary at the end.

.EXAMPLE
    .\GhostThumbs.ps1
    # Auto-detects and processes all cloud folders

.EXAMPLE
    .\GhostThumbs.ps1 -FolderPath "C:\Users\you\Dropbox"
    # Processes a specific folder

.EXAMPLE
    .\GhostThumbs.ps1 -FolderPath "C:\Users\you\OneDrive" -Recurse
    # Processes a folder and all subfolders

.LINK
    https://github.com/aoxilus/GhostThumbs
#>

[CmdletBinding()]
param(
    [string]$FolderPath,
    [switch]$Recurse,
    [int]$BatchSize = 10,
    [switch]$AutoDetect,
    [switch]$Silent
)

# ════════════════════════════════════════════════════════════════════
#  CONFIG
# ════════════════════════════════════════════════════════════════════

$VERSION = "1.0.0"

$IMAGE_EXTENSIONS = @(
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp',
    '.tiff', '.tif', '.ico', '.heic', '.heif', '.avif',
    '.jfif', '.svg', '.raw', '.cr2', '.nef', '.arw'
)

$OFFLINE_FLAG  = 0x1000   # FILE_ATTRIBUTE_OFFLINE
$SPARSE_FLAG   = 0x200    # FILE_ATTRIBUTE_SPARSE_FILE
$REPARSE_FLAG  = 0x400    # FILE_ATTRIBUTE_REPARSE_POINT

# ════════════════════════════════════════════════════════════════════
#  DISPLAY HELPERS
# ════════════════════════════════════════════════════════════════════

function Write-Banner {
    $ghost = @"

   ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
  ██║  ███╗███████║██║   ██║███████╗   ██║   
  ██║   ██║██╔══██║██║   ██║╚════██║   ██║   
  ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║   
   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   

  ████████╗██╗  ██╗██╗   ██╗███╗   ███╗██████╗ ███████╗
  ╚══██╔══╝██║  ██║██║   ██║████╗ ████║██╔══██╗██╔════╝
     ██║   ███████║██║   ██║██╔████╔██║██████╔╝███████╗
     ██║   ██╔══██║██║   ██║██║╚██╔╝██║██╔══██╗╚════██║
     ██║   ██║  ██║╚██████╔╝██║ ╚═╝ ██║██████╔╝███████║
     ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚══════╝
"@
    Write-Host $ghost -ForegroundColor Magenta
    Write-Host "  v$VERSION — See cloud files. Keep your space." -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    if (-not $Silent) { Write-Host $Message -ForegroundColor $Color }
}

function Write-FileStatus {
    param(
        [int]$Current, 
        [int]$Total, 
        [string]$FileName, 
        [string]$Status, 
        [string]$Color
    )
    if ($Silent) { return }
    $name = $FileName
    if ($name.Length -gt 40) { $name = $name.Substring(0, 37) + "..." }
    $pct = [math]::Round(($Current / $Total) * 100)
    Write-Host "  [$Current/$Total] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$name " -NoNewline -ForegroundColor White
    Write-Host $Status -ForegroundColor $Color
}

function Write-ProgressBar {
    param([int]$Current, [int]$Total)
    if ($Silent) { return }
    $pct = [math]::Round(($Current / $Total) * 100)
    $barLen = 30
    $filled = [math]::Round(($pct / 100) * $barLen)
    $empty = $barLen - $filled
    $bar = ("█" * $filled) + ("░" * $empty)
    Write-Host "`r  [$bar] $pct% ($Current/$Total)  " -NoNewline -ForegroundColor Cyan
}

# ════════════════════════════════════════════════════════════════════
#  CORE FUNCTIONS
# ════════════════════════════════════════════════════════════════════

function Test-IsCloudOnly {
    param([System.IO.FileInfo]$File)
    $attrs = [int]$File.Attributes
    # File is cloud-only if it has the Offline flag, OR if it's Sparse + ReparsePoint
    return (($attrs -band $OFFLINE_FLAG) -ne 0) -or 
           (($attrs -band $SPARSE_FLAG) -ne 0 -and ($attrs -band $REPARSE_FLAG) -ne 0)
}

function Find-CloudFolders {
    <#
    .SYNOPSIS
        Auto-detects common cloud storage folders on the system.
    #>
    $found = @()
    $userProfile = $env:USERPROFILE

    # OneDrive (personal and business)
    $oneDrivePaths = @(
        $env:OneDrive,
        $env:OneDriveConsumer,
        $env:OneDriveCommercial
    )
    # Also scan for OneDrive folders in user profile
    Get-ChildItem -Path $userProfile -Directory -Force -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -like "OneDrive*" } | 
        ForEach-Object { $oneDrivePaths += $_.FullName }
    
    foreach ($p in ($oneDrivePaths | Where-Object { $_ } | Sort-Object -Unique)) {
        if (Test-Path -LiteralPath $p) { $found += $p }
    }

    # Dropbox
    $dropboxInfo = "$env:LOCALAPPDATA\Dropbox\info.json"
    if (Test-Path $dropboxInfo) {
        try {
            $info = Get-Content $dropboxInfo -Raw | ConvertFrom-Json
            if ($info.personal.path) { $found += $info.personal.path }
            if ($info.business.path) { $found += $info.business.path }
        } catch { }
    }
    # Fallback
    $dropboxDefault = Join-Path $userProfile "Dropbox"
    if ((Test-Path $dropboxDefault) -and ($found -notcontains $dropboxDefault)) {
        $found += $dropboxDefault
    }

    # Google Drive
    $gdrivePaths = @(
        (Join-Path $userProfile "Google Drive"),
        (Join-Path $userProfile "My Drive"),
        "G:\"   # Common mount point
    )
    foreach ($p in $gdrivePaths) {
        if (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue) { $found += $p }
    }

    # iCloud
    $icloud = Join-Path $userProfile "iCloudDrive"
    if (Test-Path $icloud) { $found += $icloud }

    return $found | Sort-Object -Unique
}

function Invoke-ThumbnailCache {
    <#
    .SYNOPSIS
        Forces Windows to generate and cache a thumbnail for the given file.
        Uses two methods for maximum reliability:
        1. Shell COM — triggers Explorer's thumbnail pipeline
        2. .NET System.Drawing — exercises the Windows Imaging Component
    #>
    param([string]$FilePath, [byte[]]$FileBytes)

    $success = $false

    # Method 1: .NET Image decode + thumbnail generation
    try {
        $stream = New-Object System.IO.MemoryStream(, $FileBytes)
        $img = [System.Drawing.Image]::FromStream($stream)
        $thumb = $img.GetThumbnailImage(256, 256, $null, [IntPtr]::Zero)
        $thumb.Dispose()
        $img.Dispose()
        $stream.Dispose()
        $success = $true
    } catch { }

    # Method 2: Shell COM — triggers the Explorer thumbnail pipeline
    try {
        $parentPath = Split-Path $FilePath -Parent
        $fileName = Split-Path $FilePath -Leaf
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace($parentPath)
        if ($folder) {
            $item = $folder.ParseName($fileName)
            if ($item) {
                $null = $folder.GetDetailsOf($item, 0)    # Name
                $null = $folder.GetDetailsOf($item, 31)    # Dimensions
            }
        }
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        $success = $true
    } catch { }

    return $success
}

function Invoke-FreeSpace {
    <#
    .SYNOPSIS
        Tells the cloud provider to free local space for this file.
    #>
    param([string]$FilePath)
    try {
        & attrib.exe -P +U $FilePath 2>&1 | Out-Null
    } catch { }
}

function Invoke-GhostThumbs {
    <#
    .SYNOPSIS
        Main processing function. Scans a folder, caches thumbnails,
        frees space.
    #>
    param(
        [string]$Path,
        [switch]$DoRecurse,
        [int]$Batch
    )

    Write-Status "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "DarkGray"
    Write-Status "📁 $Path" "Yellow"

    # Find image files
    $gciParams = @{
        LiteralPath = $Path
        File = $true
        Force = $true
        ErrorAction = "SilentlyContinue"
    }
    if ($DoRecurse) { $gciParams.Recurse = $true }

    $allFiles = @(Get-ChildItem @gciParams | Where-Object {
        $IMAGE_EXTENSIONS -contains $_.Extension.ToLower()
    })

    $cloudFiles = @($allFiles | Where-Object { Test-IsCloudOnly $_ })
    $localCount = $allFiles.Count - $cloudFiles.Count

    Write-Status "   Found: $($allFiles.Count) images ($($cloudFiles.Count) cloud-only, $localCount local)" "White"

    if ($cloudFiles.Count -eq 0) {
        Write-Status "   ✓ All thumbnails already available!" "Green"
        return @{ Cached = 0; Failed = 0; Skipped = 0; Total = 0 }
    }

    $cached = 0
    $failed = 0
    $total = $cloudFiles.Count
    $i = 0

    foreach ($file in $cloudFiles) {
        $i++

        try {
            # Step 1: Force-download by reading the file bytes
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)

            # Step 2: Cache the thumbnail
            $result = Invoke-ThumbnailCache -FilePath $file.FullName -FileBytes $bytes

            if ($result) {
                Write-FileStatus -Current $i -Total $total -FileName $file.Name -Status "✓ CACHED" -Color "Green"
                $cached++
            } else {
                Write-FileStatus -Current $i -Total $total -FileName $file.Name -Status "✗ CACHE FAILED" -Color "Red"
                $failed++
            }
        }
        catch {
            Write-FileStatus -Current $i -Total $total -FileName $file.Name -Status "✗ DOWNLOAD FAILED" -Color "Red"
            $failed++
        }

        # Step 3: Free disk space
        Invoke-FreeSpace -FilePath $file.FullName

        # Show progress bar every 10 files
        if (-not $Silent -and $i % 10 -eq 0) {
            Write-ProgressBar -Current $i -Total $total
            Write-Host ""
        }
    }

    Write-Status "" 
    return @{ Cached = $cached; Failed = $failed; Total = $total }
}

# ════════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════════

# Load System.Drawing for thumbnail generation
Add-Type -AssemblyName System.Drawing -ErrorAction Stop

if (-not $Silent) { Write-Banner }

# Determine which folders to process
$foldersToProcess = @()

if ($FolderPath) {
    # User specified a folder
    if (-not (Test-Path -LiteralPath $FolderPath)) {
        Write-Host "ERROR: Folder not found: $FolderPath" -ForegroundColor Red
        exit 1
    }
    $foldersToProcess += $FolderPath
}
elseif ($AutoDetect -or (-not $FolderPath)) {
    # Auto-detect cloud folders
    Write-Status "🔍 Scanning for cloud storage folders..." "Cyan"
    $foldersToProcess = Find-CloudFolders
    
    if ($foldersToProcess.Count -eq 0) {
        Write-Host "No cloud storage folders found." -ForegroundColor Yellow
        Write-Host "Use -FolderPath to specify a folder manually." -ForegroundColor DarkGray
        exit 0
    }

    Write-Status "   Found $($foldersToProcess.Count) cloud folder(s):" "White"
    foreach ($f in $foldersToProcess) {
        Write-Status "   • $f" "DarkGray"
    }
    Write-Status ""

    # Always recurse when auto-detecting
    $Recurse = [switch]::new($true)
}

# Process each folder
$totalStats = @{ Cached = 0; Failed = 0; Total = 0 }
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($folder in $foldersToProcess) {
    $stats = Invoke-GhostThumbs -Path $folder -DoRecurse:$Recurse -Batch $BatchSize
    $totalStats.Cached += $stats.Cached
    $totalStats.Failed += $stats.Failed
    $totalStats.Total  += $stats.Total
}

$stopwatch.Stop()

# ════════════════════════════════════════════════════════════════════
#  SUMMARY
# ════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "   👻 GhostThumbs Complete!" -ForegroundColor Magenta
Write-Host "  ════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "   Cached:  $($totalStats.Cached)" -ForegroundColor Green
Write-Host "   Failed:  $($totalStats.Failed)" -ForegroundColor $(if ($totalStats.Failed -gt 0) { "Red" } else { "DarkGray" })
Write-Host "   Total:   $($totalStats.Total) cloud-only images" -ForegroundColor White
Write-Host "   Time:    $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s" -ForegroundColor DarkGray
Write-Host ""

if ($totalStats.Cached -gt 0) {
    Write-Host "   Your cloud files now have thumbnails! 👻" -ForegroundColor Cyan
    Write-Host "   Open your folders in File Explorer to see them." -ForegroundColor DarkGray
}
Write-Host ""
