#!/usr/bin/env ruby
# Generate metadata.json from Calibre library for web deployment

require 'json'
require_relative 'calibre.rb'

# Configuration
CALIBRE_PATH = ARGV[0] || "D:\\BIBLIO_\\calibre"
OUTPUT_FILE = "public/books.json"
DRIVE_BASE_URL = "https://drive.google.com"

puts "=" * 60
puts "📚 Generating Book Metadata for Web Deployment"
puts "=" * 60
puts ""

# Connect to Calibre
puts "Connecting to Calibre library..."
CalibreBook.connect(CALIBRE_PATH)
puts "✓ Connected!"
puts ""

# Get all books
puts "Reading books from Calibre..."
books = CalibreBook.all_books
puts "✓ Found #{books.length} books"
puts ""

# Generate metadata
metadata = []
books.each_with_index do |book, index|
  puts "[#{index + 1}/#{books.length}] Processing: #{book.title}"
  
  begin
    metadata << {
      id: book.id,
      title: book.title,
      author: book.author,
      author_sort: book.author_sort,
      description: book.description || "",
      cover_url: "#{DRIVE_BASE_URL}/thumbnail?id=COVER_#{book.id}&sz=w400", # Placeholder
      book_url: "#{DRIVE_BASE_URL}/uc?export=download&id=BOOK_#{book.id}",   # Placeholder
      cover_color: book.cover_color,
      cover_contrast: book.cover_contrast,
      page_count: book.page_count,
      aspect_ratio: book.aspect_ratio,
      nonlinear_thickness: book.nonlinear_thickness,
      series: book.series,
      series_index: book.series_index,
      # Store local paths for sync script to use
      _local_cover: book.cover,
      _local_file: book.file_path
    }
  rescue => e
    puts "  ⚠ Error processing book: #{e.message}"
    next
  end
end

# Create public directory if it doesn't exist
require 'fileutils'
FileUtils.mkdir_p('public')

# Write metadata
puts ""
puts "Writing metadata to #{OUTPUT_FILE}..."
File.write(OUTPUT_FILE, JSON.pretty_generate(metadata))
puts "✓ Metadata written!"
puts ""

# Also create a version with file IDs that will be updated by sync script
File.write("#{OUTPUT_FILE}.template", JSON.pretty_generate(metadata))
puts "✓ Template created for sync script"
puts ""

# Summary
puts "=" * 60
puts "📊 Summary"
puts "=" * 60
puts "Books processed: #{metadata.length}"
puts "Output file: #{OUTPUT_FILE}"
puts "File size: #{File.size(OUTPUT_FILE) / 1024} KB"
puts ""
puts "🎯 Next Steps:"
puts "1. Run sync-to-drive.ps1 to upload files"
puts "2. Sync script will update Drive file IDs"
puts "3. Commit public/books.json to Git"
puts "4. Push to Vercel"
puts ""
puts "✨ Done!"

