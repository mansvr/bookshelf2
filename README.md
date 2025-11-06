# 📚 3D Bookshelf

A beautiful 3D virtual bookshelf that displays your Calibre ebook library on the web.

![Bookshelf Demo](demo.gif)

## ✨ Features

- **3D Book Display**: Books rendered in 3D with realistic spine colors and thickness
- **Interactive**: Click books to flip and see details (title, author, description, page count)
- **Responsive**: Adapts to any screen size
- **Dark/Light Mode**: Built-in theme switcher
- **Dynamic Data**: Books pulled from your Calibre library
- **Cloud Hosted**: Covers and books hosted on Google Drive
- **Auto Deploy**: One command to sync and deploy updates

## 🚀 Quick Start

### Local Development (Ruby Backend)

1. **Install Prerequisites**:
   - Ruby 3.0+
   - ImageMagick (for cover color extraction)
   - Calibre (with your book library)

2. **Install Dependencies**:
   ```bash
   bundle install
   ```

3. **Run the Server**:
   ```bash
   ruby app.rb "D:\Path\To\Your\Calibre\Library"
   ```

4. **Visit**: http://localhost:4567

### Deploy to Vercel (Static Site)

The bookshelf is deployed as a static site on Vercel, with book covers and files hosted on Google Drive.

## 📦 Deployment Workflow

### First-Time Setup

1. **Install Rclone**:
   - Download from: https://rclone.org/downloads/
   - Place `rclone.exe` in the project directory

2. **Configure Google Drive**:
   ```powershell
   .\rclone.exe config
   ```
   - Name your remote (e.g., `bookshelf-drive`)
   - Choose Google Drive
   - Follow OAuth flow to authorize

3. **Create Drive Folders**:
   - `Bookshelf/books/` - For PDF/EPUB files
   - `Bookshelf/covers/` - For cover images

4. **Update Scripts**:
   - Edit `sync-simple.ps1` and set `$RcloneRemote` to your remote name
   - Edit `sync-simple.ps1` and set `$CalibreLibrary` to your Calibre path

### Regular Updates

**One command to update everything**:

```powershell
.\deploy-workflow.ps1
```

This script automatically:
1. Syncs book covers and files to Google Drive
2. Generates `books.json` with metadata and Drive URLs
3. Commits changes to Git
4. Pushes to GitHub
5. Triggers Vercel deployment

## 📁 File Structure

```
bookshelf2/
├── app.rb                  # Ruby Sinatra backend (local dev)
├── calibre.rb              # Calibre database reader
├── logos.rb                # Series logo handler
├── Gemfile                 # Ruby dependencies
├── views/
│   └── index.erb          # ERB template for local dev
├── public/
│   ├── css/               # Stylesheets
│   └── fonts/             # Custom fonts
├── index.html             # Static HTML for Vercel
├── books.json             # Generated book metadata (with Drive URLs)
├── vercel.json            # Vercel configuration
├── sync-simple.ps1        # Sync Calibre → Google Drive
├── generate-metadata.rb   # Generate books.json
└── deploy-workflow.ps1    # One-command deployment
```

## 🎨 Customization

### Theme Colors

Edit `public/css/style.css`:

```css
body[data-theme="dark"] {
    --bg-color: #1a1a1a;
    --text-color: #ffffff;
}

body[data-theme="light"] {
    --bg-color: #f5f5f5;
    --text-color: #000000;
}
```

### Book Display

Edit `public/css/style.css` to change:
- Book size (`.book` width/height)
- Spacing (`.container` gap)
- Animations (`.book:hover` transforms)

## 🛠️ How It Works

### Local Development Flow

1. **Calibre** stores your books and metadata in `metadata.db`
2. **Ruby backend** (`app.rb`) reads the database
3. **calibre.rb** extracts book details (title, author, cover color, page count)
4. **ImageMagick** analyzes cover images for spine colors
5. **ERB template** renders the 3D bookshelf

### Production Deployment Flow

1. **sync-simple.ps1** copies covers and books from Calibre to Google Drive
2. **generate-metadata.rb** reads Calibre metadata and creates `books.json` with Drive URLs
3. **index.html** (static) fetches `books.json` and renders the bookshelf
4. **Vercel** serves the static site
5. **Google Drive** hosts the book files and covers

## 🔧 Troubleshooting

### Books not showing?

- Check browser console (F12) for errors
- Verify `books.json` exists and is valid JSON
- Ensure Google Drive files are publicly accessible

### Local Ruby server not starting?

- Check Ruby is installed: `ruby --version`
- Install gems: `bundle install`
- Check ImageMagick: `magick --version`

### Covers not loading?

- Verify Google Drive URLs in `books.json`
- Check Drive folder permissions (should be public or shared)
- Run `update-drive-urls.ps1` to regenerate Drive URLs

## 📝 Credits

- Original concept: [mawise/bookshelf](https://github.com/mawise/bookshelf)
- CSS 3D transforms for book rendering
- Calibre for book management
- Google Drive for cloud storage
- Vercel for hosting

## 📄 License

MIT License - See LICENSE file for details

---

**Enjoy your virtual bookshelf!** 📚✨

