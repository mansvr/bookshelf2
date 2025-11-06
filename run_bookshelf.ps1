# Run the 3D Bookshelf locally
# Usage: .\run_bookshelf.ps1

$CalibreLibrary = "D:\BIBLIO_\calibre"

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   3D BOOKSHELF - LOCAL SERVER" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Check if Calibre library exists
if (-not (Test-Path $CalibreLibrary)) {
    Write-Host "ERROR: Calibre library not found at:" -ForegroundColor Red
    Write-Host "  $CalibreLibrary" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please edit this script and set the correct path." -ForegroundColor Yellow
    exit 1
}

# Check if Ruby is installed
try {
    $rubyVersion = ruby --version 2>$null
    Write-Host "✓ Ruby: $rubyVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Ruby not found! Please install Ruby first." -ForegroundColor Red
    exit 1
}

# Install gems if needed
if (-not (Test-Path "Gemfile.lock")) {
    Write-Host ""
    Write-Host "Installing Ruby gems..." -ForegroundColor Yellow
    bundle install
}

# Start the server
Write-Host ""
Write-Host "Starting server..." -ForegroundColor Cyan
Write-Host "Open your browser to: http://localhost:4567" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

ruby app.rb $CalibreLibrary

