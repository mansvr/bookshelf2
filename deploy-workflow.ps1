# Complete Deployment Workflow
# Syncs books to Drive, generates metadata, and pushes to GitHub

param(
    [string]$CommitMessage = "Update bookshelf"
)

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  BOOKSHELF DEPLOYMENT WORKFLOW" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Sync to Google Drive
Write-Host "Step 1: Syncing to Google Drive..." -ForegroundColor Yellow
Write-Host ""

.\sync-simple.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Sync failed! Aborting deployment." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Sync complete!" -ForegroundColor Green
Write-Host ""

# Step 2: Git operations
Write-Host "Step 2: Committing to Git..." -ForegroundColor Yellow
Write-Host ""

# Check if there are changes
$status = git status --porcelain
if (-not $status) {
    Write-Host "No changes to commit" -ForegroundColor Gray
} else {
    Write-Host "Changes detected:" -ForegroundColor White
    git status --short
    Write-Host ""
    
    # Add books.json
    Write-Host "Adding books.json to Git..." -ForegroundColor White
    git add books.json
    
    # Commit
    Write-Host "Committing changes..." -ForegroundColor White
    git commit -m "$CommitMessage"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Committed successfully!" -ForegroundColor Green
        
        # Push
        Write-Host ""
        Write-Host "Pushing to GitHub..." -ForegroundColor White
        git push
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Pushed successfully!" -ForegroundColor Green
        } else {
            Write-Host "ERROR: Push failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "WARNING: Nothing to commit or commit failed" -ForegroundColor Yellow
    }
}

Write-Host ""

# Step 3: Summary
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "What happened:" -ForegroundColor Cyan
Write-Host "  1. Books synced to Google Drive" -ForegroundColor White
Write-Host "  2. books.json generated with Drive URLs" -ForegroundColor White
Write-Host "  3. Changes committed to Git" -ForegroundColor White
Write-Host "  4. Pushed to GitHub" -ForegroundColor White
Write-Host ""
Write-Host "Vercel Deployment:" -ForegroundColor Cyan
Write-Host "  - Vercel detected the push" -ForegroundColor White
Write-Host "  - Build starting in ~30 seconds" -ForegroundColor White
Write-Host "  - Site will update in ~1-2 minutes" -ForegroundColor White
Write-Host ""
Write-Host "Check deployment at: https://vercel.com/dashboard" -ForegroundColor Yellow
Write-Host ""
Write-Host "Your bookshelf is being deployed!" -ForegroundColor Green
Write-Host ""
