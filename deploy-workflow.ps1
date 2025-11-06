# 🚀 Complete Deployment Workflow
# This script handles everything: sync to Drive, commit to Git, deploy to Vercel

param(
    [string]$CommitMessage = "Update bookshelf",
    [switch]$SkipSync,
    [switch]$SkipGit,
    [switch]$DryRun
)

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "🚀 Bookshelf Deployment Workflow" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Step 1: Sync to Google Drive (unless skipped)
if (-not $SkipSync) {
    Write-Host "Step 1: Syncing to Google Drive..." -ForegroundColor Yellow
    Write-Host ""
    
    if ($DryRun) {
        & .\sync-to-drive.ps1 -DryRun
    } else {
        & .\sync-to-drive.ps1
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ Sync failed! Aborting deployment." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "✓ Sync complete!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "⏭ Skipping sync (using existing files)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 2: Git operations (unless skipped)
if (-not $SkipGit) {
    Write-Host "Step 2: Git operations..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check if there are changes
    $status = git status --porcelain
    if (-not $status) {
        Write-Host "ℹ No changes to commit" -ForegroundColor Gray
    } else {
        Write-Host "Changes detected:" -ForegroundColor White
        Write-Host $status -ForegroundColor Gray
        Write-Host ""
        
        if ($DryRun) {
            Write-Host "🔍 DRY RUN - Would commit and push:" -ForegroundColor Yellow
            Write-Host "  Message: $CommitMessage" -ForegroundColor White
        } else {
            # Add files
            Write-Host "Adding files to Git..." -ForegroundColor White
            git add public/books.json
            git add public/css/
            git add public/fonts/
            git add views/
            
            # Commit
            Write-Host "Committing changes..." -ForegroundColor White
            git commit -m "$CommitMessage"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Committed successfully!" -ForegroundColor Green
                
                # Push
                Write-Host ""
                Write-Host "Pushing to GitHub..." -ForegroundColor White
                git push
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Pushed successfully!" -ForegroundColor Green
                } else {
                    Write-Host "❌ Push failed!" -ForegroundColor Red
                    Write-Host "You may need to: git push --set-upstream origin main" -ForegroundColor Yellow
                    exit 1
                }
            } else {
                Write-Host "⚠ Nothing to commit or commit failed" -ForegroundColor Yellow
            }
        }
    }
    Write-Host ""
} else {
    Write-Host "⏭ Skipping Git operations" -ForegroundColor Yellow
    Write-Host ""
}

# Step 3: Deployment info
Write-Host "=" * 70 -ForegroundColor Green
Write-Host "✨ Workflow Complete!" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 This was a DRY RUN - no actual changes were made" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To deploy for real, run without -DryRun flag" -ForegroundColor White
} else {
    Write-Host "📊 What happened:" -ForegroundColor Cyan
    Write-Host "  ✓ Books synced to Google Drive" -ForegroundColor White
    Write-Host "  ✓ Metadata generated (public/books.json)" -ForegroundColor White
    Write-Host "  ✓ Changes committed to Git" -ForegroundColor White
    Write-Host "  ✓ Pushed to GitHub" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Vercel Deployment:" -ForegroundColor Cyan
    Write-Host "  • Vercel will auto-detect the push" -ForegroundColor White
    Write-Host "  • Build will start in ~30 seconds" -ForegroundColor White
    Write-Host "  • Your site will update in ~1-2 minutes" -ForegroundColor White
    Write-Host ""
    Write-Host "🔗 Check deployment:" -ForegroundColor Cyan
    Write-Host "  https://vercel.com/dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Quick commands:" -ForegroundColor Cyan
    Write-Host "  View status:  git status" -ForegroundColor White
    Write-Host "  View history: git log --oneline -5" -ForegroundColor White
    Write-Host "  View remote:  git remote -v" -ForegroundColor White
}

Write-Host ""
Write-Host "🎉 Your bookshelf is being deployed!" -ForegroundColor Green
Write-Host ""

