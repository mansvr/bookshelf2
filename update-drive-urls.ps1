# Update books.json with Real Google Drive File IDs
# This script fetches file IDs from Google Drive and updates the metadata

param(
    [string]$RcloneRemote = "bookshel-drive",
    [string]$DrivePath = "Bookshelf"
)

$rclone = ".\rclone.exe"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Updating books.json with Google Drive URLs" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Load current metadata
Write-Host "Loading metadata..." -ForegroundColor Yellow
$metadata = Get-Content "books.json" | ConvertFrom-Json
Write-Host "[OK] Loaded $($metadata.Count) books" -ForegroundColor Green
Write-Host ""

# Get file IDs from Google Drive
Write-Host "Fetching file information from Google Drive..." -ForegroundColor Yellow
Write-Host ""

# Get covers with IDs
Write-Host "Getting cover file IDs..." -ForegroundColor Yellow
$coversJson = & $rclone lsjson "${RcloneRemote}:${DrivePath}/covers/" --files-only
$coversList = $coversJson | ConvertFrom-Json
$coversMap = @{}
foreach ($file in $coversList) {
    # Extract book ID from filename (e.g., "10.jpg" -> "10")
    $bookId = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $coversMap[$bookId] = $file.ID
    Write-Host "  Cover $bookId -> $($file.ID)" -ForegroundColor Gray
}
Write-Host "[OK] Found $($coversMap.Count) covers" -ForegroundColor Green
Write-Host ""

# Get books with IDs
Write-Host "Getting book file IDs..." -ForegroundColor Yellow
$booksJson = & $rclone lsjson "${RcloneRemote}:${DrivePath}/books/" --files-only
$booksList = $booksJson | ConvertFrom-Json
$booksMap = @{}
foreach ($file in $booksList) {
    # Extract book ID from filename (e.g., "10.pdf" -> "10")
    $bookId = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $booksMap[$bookId] = $file.ID
    Write-Host "  Book $bookId -> $($file.ID)" -ForegroundColor Gray
}
Write-Host "[OK] Found $($booksMap.Count) books" -ForegroundColor Green
Write-Host ""

# Update metadata with real Drive URLs
Write-Host "Updating metadata with Drive URLs..." -ForegroundColor Yellow
$updated = 0
foreach ($book in $metadata) {
    $bookId = $book.id.ToString()
    
    # Update cover URL
    if ($coversMap.ContainsKey($bookId)) {
        $coverId = $coversMap[$bookId]
        $book.cover_url = "https://drive.google.com/thumbnail?id=$coverId&sz=w400"
        Write-Host "  [$bookId] $($book.title) - Cover updated" -ForegroundColor White
        $updated++
    }
    
    # Update book URL
    if ($booksMap.ContainsKey($bookId)) {
        $bookFileId = $booksMap[$bookId]
        $book.book_url = "https://drive.google.com/uc?export=download&id=$bookFileId"
    }
}
Write-Host "[OK] Updated $updated books with Drive URLs" -ForegroundColor Green
Write-Host ""

# Save updated metadata
Write-Host "Saving updated metadata..." -ForegroundColor Yellow
$metadata | ConvertTo-Json -Depth 10 | Set-Content "books.json" -Encoding UTF8
Write-Host "[OK] Saved to books.json" -ForegroundColor Green
Write-Host ""

# Show sample
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Sample Book Entry:" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
$sample = $metadata[0]
Write-Host "ID: $($sample.id)" -ForegroundColor White
Write-Host "Title: $($sample.title)" -ForegroundColor White
Write-Host "Cover URL: $($sample.cover_url)" -ForegroundColor Yellow
Write-Host "Book URL: $($sample.book_url)" -ForegroundColor Yellow
Write-Host ""

Write-Host "======================================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Books.json Updated!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "[NEXT] Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test a URL by opening it in your browser" -ForegroundColor White
Write-Host "  2. Make the Google Drive folder public (see below)" -ForegroundColor White
Write-Host "  3. Push to GitHub and deploy to Vercel" -ForegroundColor White
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host "IMPORTANT: Make Google Drive Files Public" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "To make your files accessible to the web app:" -ForegroundColor White
Write-Host "  1. Go to: https://drive.google.com" -ForegroundColor Cyan
Write-Host "  2. Find the 'Bookshelf' folder" -ForegroundColor White
Write-Host "  3. Right-click -> Share -> Change to 'Anyone with the link'" -ForegroundColor White
Write-Host "  4. Set permission to 'Viewer'" -ForegroundColor White
Write-Host "  5. Click 'Done'" -ForegroundColor White
Write-Host ""
Write-Host "This allows the web app to load your book covers and files!" -ForegroundColor Gray
Write-Host ""

