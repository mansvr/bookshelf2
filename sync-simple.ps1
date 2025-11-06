# Simple Sync Script for Calibre to Google Drive
# This is a simplified version to test the sync

param(
    [string]$CalibrePath = "D:\BIBLIO_\calibre",
    [string]$RcloneRemote = "bookshel-drive",
    [string]$DrivePath = "Bookshelf"
)

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "[BOOKS] Syncing Bookshelf to Google Drive" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Set script directory and add Ruby to PATH
Set-Location $PSScriptRoot
$rubyPaths = @(
    "C:\Ruby33-x64\bin",
    "C:\Ruby32-x64\bin",
    "C:\Ruby31-x64\bin"
)
foreach ($path in $rubyPaths) {
    if (Test-Path $path) {
        $env:PATH = "$path;$env:PATH"
        break
    }
}

# Check Ruby
if (-not (Get-Command ruby -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Ruby not found!" -ForegroundColor Red
    Write-Host "Please install Ruby or set the correct path" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Ruby found" -ForegroundColor Green

# Check Rclone
$rclone = ".\rclone.exe"
if (-not (Test-Path $rclone)) {
    $rclone = "rclone"
    if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] Rclone not found!" -ForegroundColor Red
        exit 1
    }
}
Write-Host "[OK] Rclone found" -ForegroundColor Green

# Check Calibre library
if (-not (Test-Path "$CalibrePath\metadata.db")) {
    Write-Host "[ERROR] Calibre library not found at: $CalibrePath" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Calibre library found" -ForegroundColor Green

# Check Rclone remote
$remoteTest = & $rclone lsd "${RcloneRemote}:" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Rclone remote '$RcloneRemote' not configured!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Rclone remote configured" -ForegroundColor Green
Write-Host ""

# Step 1: Generate metadata
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Step 1: Generating metadata from Calibre" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

ruby generate-metadata.rb "$CalibrePath"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to generate metadata!" -ForegroundColor Red
    exit 1
}

# Load metadata
$metadata = Get-Content "books.json" | ConvertFrom-Json
Write-Host "[OK] Loaded $($metadata.Count) books from metadata" -ForegroundColor Green
Write-Host ""

# Step 2: Upload to Google Drive
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Step 2: Uploading to Google Drive" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Create temporary directories
$tempDir = "temp_sync"
$coversDir = "$tempDir\covers"
$booksDir = "$tempDir\books"

if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $coversDir -Force | Out-Null
New-Item -ItemType Directory -Path $booksDir -Force | Out-Null

Write-Host "Preparing covers..." -ForegroundColor Yellow
$count = 0
foreach ($book in $metadata) {
    $count++
    $coverPath = $book._local_cover
    if (Test-Path $coverPath) {
        $ext = [System.IO.Path]::GetExtension($coverPath)
        Copy-Item $coverPath "$coversDir\$($book.id)$ext"
        Write-Host "[$count/$($metadata.Count)] $($book.title) - OK" -ForegroundColor White
    } else {
        Write-Host "[$count/$($metadata.Count)] $($book.title) - WARN: Cover not found at $coverPath" -ForegroundColor Yellow
    }
}
Write-Host "[OK] Covers prepared!" -ForegroundColor Green
Write-Host ""

Write-Host "Preparing books..." -ForegroundColor Yellow
$count = 0
foreach ($book in $metadata) {
    $count++
    $bookPath = $book._local_file
    if ($bookPath -and (Test-Path $bookPath)) {
        $ext = [System.IO.Path]::GetExtension($bookPath)
        Copy-Item $bookPath "$booksDir\$($book.id)$ext"
        $sizeMB = [math]::Round((Get-Item $bookPath).Length / 1MB, 1)
        Write-Host "[$count/$($metadata.Count)] $($book.title) - OK ($sizeMB MB)" -ForegroundColor White
    } else {
        Write-Host "[$count/$($metadata.Count)] $($book.title) - WARN: File not found at $bookPath" -ForegroundColor Yellow
    }
}
Write-Host "[OK] Books prepared!" -ForegroundColor Green
Write-Host ""

# Upload to Drive
Write-Host "Uploading covers to Google Drive..." -ForegroundColor Yellow
& $rclone sync $coversDir "${RcloneRemote}:${DrivePath}/covers/" --progress --transfers 8
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Covers uploaded!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to upload covers!" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "Uploading books to Google Drive..." -ForegroundColor Yellow
& $rclone sync $booksDir "${RcloneRemote}:${DrivePath}/books/" --progress --transfers 4
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Books uploaded!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to upload books!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Cleanup temp
Remove-Item $tempDir -Recurse -Force
Write-Host "[OK] Cleanup complete!" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Sync Complete!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "  Books synced: $($metadata.Count)" -ForegroundColor White
Write-Host "  Check your Google Drive at: https://drive.google.com" -ForegroundColor White
Write-Host ""
Write-Host "[NEXT] Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Verify files in Google Drive" -ForegroundColor White
Write-Host "  2. Update book URLs in books.json" -ForegroundColor White
Write-Host "  3. Deploy to Vercel" -ForegroundColor White
Write-Host ""

