<#
.SYNOPSIS
    Optimize all PlantWeb images using ImageMagick

.DESCRIPTION
    This script optimizes all images in Source/Images folder:
    - Resizes large images to max 1920x1920 (preserving aspect ratio)
    - Compresses with 85% JPEG quality
    - Removes EXIF metadata
    - Converts PNG to JPG where appropriate
    - Creates backups before processing

.PARAMETER MaxWidth
    Maximum width in pixels (default: 1920)

.PARAMETER MaxHeight
    Maximum height in pixels (default: 1920)

.PARAMETER JpegQuality
    JPEG quality percentage (1-100, default: 85)

.PARAMETER BackupFirst
    Create backup of Images folder before processing (recommended)

.PARAMETER SkipBackup
    Skip backup creation (not recommended)

.EXAMPLE
    .\optimize-plantweb-images.ps1

.EXAMPLE
    .\optimize-plantweb-images.ps1 -MaxWidth 1600 -JpegQuality 90
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$MaxWidth = 1920,

    [Parameter(Mandatory=$false)]
    [int]$MaxHeight = 1920,

    [Parameter(Mandatory=$false)]
    [int]$JpegQuality = 85,

    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup
)

# Configuration
$sourceFolder = Join-Path $PSScriptRoot "Source\Images"
$backupFolder = Join-Path $PSScriptRoot "Images_Backup_$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Supported image extensions
$imageExtensions = @(".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tiff", ".tif", ".JPG", ".JPEG", ".PNG", ".BMP", ".GIF", ".TIFF", ".TIF")

# Statistics
$script:totalFiles = 0
$script:processedFiles = 0
$script:skippedFiles = 0
$script:totalOriginalSize = 0
$script:totalOptimizedSize = 0
$script:errors = @()

# Color output functions
function Write-Success { param([string]$Message) Write-Host $Message -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param([string]$Message) Write-Host $Message -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host $Message -ForegroundColor Red }

# Check if ImageMagick is installed
function Test-ImageMagick {
    try {
        $result = & magick --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $version = ($result | Select-Object -First 1) -replace "Version: ImageMagick ", ""
            Write-Success "✓ ImageMagick found: $version"
            return $true
        }
    } catch {
        Write-ErrorMsg "✗ ImageMagick not found!"
        Write-Host ""
        Write-Host "Please install ImageMagick:" -ForegroundColor Yellow
        Write-Host "  1. Download from: https://imagemagick.org/script/download.php#windows" -ForegroundColor White
        Write-Host "  2. Or use: winget install ImageMagick.ImageMagick" -ForegroundColor White
        Write-Host "  3. Make sure to add ImageMagick to your PATH during installation" -ForegroundColor White
        Write-Host ""
        return $false
    }
}

# Function to optimize a single image IN-PLACE
function Optimize-ImageInPlace {
    param(
        [string]$ImagePath
    )

    try {
        $file = Get-Item $ImagePath
        $originalSize = $file.Length
        $tempOutput = Join-Path $file.Directory.FullName "temp_optimizing_$($file.Name).tmp"

        # Determine output format
        $outputPath = if ($file.Extension -ieq ".png" -or $file.Extension -ieq ".bmp" -or $file.Extension -ieq ".gif" -or $file.Extension -ieq ".tiff" -or $file.Extension -ieq ".tif") {
            # Convert to JPG
            $file.FullName -replace '\.[^.]+$', '.jpg'
        } else {
            $file.FullName
        }

        # Build ImageMagick command - optimize in place
        $magickArgs = @(
            $ImagePath,
            "-auto-orient",                               # Fix orientation from EXIF
            "-strip",                                     # Remove metadata
            "-resize", "${MaxWidth}x${MaxHeight}>",       # Resize only if larger
            "-quality", $JpegQuality,                     # Set JPEG quality
            "-sampling-factor", "4:2:0",                  # Standard JPEG subsampling
            $tempOutput
        )

        # Execute ImageMagick
        $output = & magick @magickArgs 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "ImageMagick failed: $output"
        }

        # If format changed, delete original
        if ($outputPath -ne $file.FullName) {
            Remove-Item $file.FullName -Force
        }

        # Replace original with optimized version
        Move-Item $tempOutput $outputPath -Force

        # Get optimized size
        $optimizedSize = (Get-Item $outputPath).Length

        # Update statistics
        $script:totalOriginalSize += $originalSize
        $script:totalOptimizedSize += $optimizedSize
        $script:processedFiles++

        # Calculate savings
        $savings = if ($originalSize -gt 0) {
            [math]::Round((($originalSize - $optimizedSize) / $originalSize) * 100, 1)
        } else {
            0
        }

        $originalKB = [math]::Round($originalSize / 1KB, 0)
        $optimizedKB = [math]::Round($optimizedSize / 1KB, 0)

        # Only show significant changes or conversions
        if ($savings -gt 5 -or $outputPath -ne $file.FullName) {
            Write-Host "  ✓ " -NoNewline -ForegroundColor Green
            Write-Host "$($file.Name) " -NoNewline
            Write-Host "$originalKB KB → $optimizedKB KB " -NoNewline
            Write-Host "(-$savings%)" -ForegroundColor Cyan
        } else {
            $script:skippedFiles++
            Write-Host "  - " -NoNewline -ForegroundColor Gray
            Write-Host "$($file.Name) (already optimized)" -ForegroundColor Gray
        }

        return $true

    } catch {
        $script:errors += @{Path = $ImagePath; Error = $_.Exception.Message}
        Write-Host "  ✗ Failed: $((Get-Item $ImagePath).Name) - $($_.Exception.Message)" -ForegroundColor Red
        
        # Clean up temp file if it exists
        $tempFile = Join-Path (Split-Path $ImagePath) "temp_optimizing_*.tmp"
        Get-Item $tempFile -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        
        return $false
    }
}

# Main execution
Write-Info "=================================================="
Write-Info "  PlantWeb Image Optimizer"
Write-Info "  Powered by ImageMagick"
Write-Info "=================================================="
Write-Host ""

# Check ImageMagick
if (-not (Test-ImageMagick)) {
    exit 1
}
Write-Host ""

# Validate source folder
if (-not (Test-Path $sourceFolder)) {
    Write-ErrorMsg "Error: Source folder not found: $sourceFolder"
    exit 1
}

Write-Info "Configuration:"
Write-Host "  Source Folder:    $sourceFolder" -ForegroundColor White
Write-Host "  Max Dimensions:   ${MaxWidth}×${MaxHeight} px" -ForegroundColor White
Write-Host "  JPEG Quality:     $JpegQuality%" -ForegroundColor White
Write-Host "  Backup:           $(if ($SkipBackup) { 'Disabled' } else { 'Enabled' })" -ForegroundColor $(if ($SkipBackup) { 'Yellow' } else { 'Green' })
Write-Host ""

# Create backup if requested
if (-not $SkipBackup) {
    Write-Info "Creating backup..."
    Write-Host "  This may take a few minutes..." -ForegroundColor Gray
    try {
        Copy-Item -Path $sourceFolder -Destination $backupFolder -Recurse -Force
        Write-Success "✓ Backup created: $backupFolder"
        Write-Host "  You can delete this later if optimization is successful" -ForegroundColor Gray
    } catch {
        Write-ErrorMsg "✗ Failed to create backup: $($_.Exception.Message)"
        $response = Read-Host "Continue without backup? (Y/N)"
        if ($response -ne "Y" -and $response -ne "y") {
            Write-Info "Operation cancelled."
            exit 0
        }
    }
    Write-Host ""
}

# Find all image files
Write-Info "Scanning for images..."
$imageFiles = Get-ChildItem -Path $sourceFolder -File | Where-Object { $imageExtensions -contains $_.Extension }

$script:totalFiles = $imageFiles.Count

if ($script:totalFiles -eq 0) {
    Write-Warning "No image files found in the source folder."
    exit 0
}

Write-Success "Found $($script:totalFiles) image(s) to process"
Write-Host ""

# Analyze current state
Write-Info "Analyzing current images..."
$largeImages = $imageFiles | Where-Object { $_.Length -gt 500KB }
$totalSizeMB = [math]::Round(($imageFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
$avgSizeKB = [math]::Round(($imageFiles | Measure-Object -Property Length -Average).Average / 1KB, 0)

Write-Host "  Total Size:       $totalSizeMB MB" -ForegroundColor White
Write-Host "  Average Size:     $avgSizeKB KB" -ForegroundColor White
Write-Host "  Images > 500KB:   $($largeImages.Count)" -ForegroundColor White
Write-Host ""

$response = Read-Host "Ready to optimize $($script:totalFiles) images. Continue? (Y/N)"
if ($response -ne "Y" -and $response -ne "y") {
    Write-Info "Operation cancelled."
    exit 0
}
Write-Host ""

# Process images
Write-Info "Optimizing images (this will take a while)..."
Write-Host ""

$counter = 0
$startTime = Get-Date

foreach ($file in $imageFiles) {
    $counter++
    
    # Progress indicator every 50 files
    if ($counter % 50 -eq 0) {
        $elapsed = (Get-Date) - $startTime
        $avgTimePerFile = $elapsed.TotalSeconds / $counter
        $remaining = ($script:totalFiles - $counter) * $avgTimePerFile
        Write-Host ""
        Write-Info "Progress: $counter/$($script:totalFiles) - Est. remaining: $([math]::Round($remaining/60, 1)) min"
        Write-Host ""
    }

    Write-Host "[$counter/$($script:totalFiles)] " -NoNewline -ForegroundColor Cyan
    Optimize-ImageInPlace -ImagePath $file.FullName | Out-Null
}

# Summary
Write-Host ""
Write-Info "=================================================="
Write-Info "  Optimization Complete!"
Write-Info "=================================================="
Write-Host ""

$actualProcessed = $script:processedFiles - $script:skippedFiles

Write-Host "Total Images:     $($script:totalFiles)" -ForegroundColor White
Write-Host "Optimized:        " -NoNewline
Write-Host "$actualProcessed files" -ForegroundColor Green
Write-Host "Already Optimal:  " -NoNewline
Write-Host "$($script:skippedFiles) files" -ForegroundColor Gray
Write-Host "Failed:           " -NoNewline
Write-Host "$($script:errors.Count) files" -ForegroundColor $(if ($script:errors.Count -gt 0) { "Red" } else { "Gray" })

Write-Host ""
$originalMB = [math]::Round($script:totalOriginalSize / 1MB, 2)
$optimizedMB = [math]::Round($script:totalOptimizedSize / 1MB, 2)
$totalSavings = if ($script:totalOriginalSize -gt 0) {
    [math]::Round((($script:totalOriginalSize - $script:totalOptimizedSize) / $script:totalOriginalSize) * 100, 1)
} else {
    0
}

Write-Host "Original Size:    $originalMB MB" -ForegroundColor White
Write-Host "Optimized Size:   $optimizedMB MB" -ForegroundColor White
Write-Host "Total Savings:    " -NoNewline
Write-Host "$totalSavings%" -ForegroundColor Cyan

if (-not $SkipBackup) {
    Write-Host ""
    Write-Success "Backup Location: $backupFolder"
    Write-Host "  Keep this backup until you verify the optimized images" -ForegroundColor Yellow
}

if ($script:errors.Count -gt 0) {
    Write-Host ""
    Write-Warning "Errors encountered:"
    foreach ($err in $script:errors) {
        Write-Host "  • " -NoNewline -ForegroundColor Red
        Write-Host "$(Split-Path -Leaf $err.Path): " -NoNewline
        Write-Host $err.Error -ForegroundColor Gray
    }
}

Write-Host ""
$elapsed = (Get-Date) - $startTime
Write-Info "Total Time: $([math]::Round($elapsed.TotalMinutes, 1)) minutes"

Write-Host ""
Write-Info "Next steps:"
Write-Host "1. Test build locally: cd Source; sphinx-build -b html . ../Build" -ForegroundColor White
Write-Host "2. Review the website to ensure images look good" -ForegroundColor White
Write-Host "3. If satisfied, commit and push: git add .; git commit -m 'Optimize images'; git push" -ForegroundColor White
if (-not $SkipBackup) {
    Write-Host "4. Delete backup folder after confirming: Remove-Item '$backupFolder' -Recurse" -ForegroundColor White
}
