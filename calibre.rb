require 'sqlite3'
begin
  require 'mini_magick'
  HAS_IMAGEMAGICK = true
rescue LoadError
  HAS_IMAGEMAGICK = false
  puts "Warning: ImageMagick not available. Book colors and aspect ratios will use defaults."
end

class CalibreBook
  def self.connect(path_to_calibre_db)
    @@calibre_path = path_to_calibre_db
    @@db = SQLite3::Database.new "#{@@calibre_path}/metadata.db"
    ## Find pagecount custom column
    @@pagecount_column = nil
    begin
      @@pagecount_column = @@db.execute("select id from custom_columns where label = 'pagecount'").first.first
    rescue
    end
  end

  def self.has_pages?
    return !@@pagecount_column.nil?
  end

  def self.all_books()
    @@db.execute("select id from books")
        .flatten.map{|book_id| CalibreBook.new(book_id)}
        .sort_by{|book| [book.author_sort, book.series, book.series_index]}
  end

  def self.some_books(limit=10)
    @@db.execute("select id from books limit #{limit}")
        .flatten.map{|book_id| CalibreBook.new(book_id)}
        .sort_by{|book| [book.author_sort, book.series, book.series_index]}
  end

  def self.search_author(query)
    @@db.execute("select books.id FROM books JOIN books_authors_link ON books.id == books_authors_link.book JOIN authors ON books_authors_link.author == authors.id WHERE authors.name LIKE '#{query}'")
        .flatten.map{|book_id| CalibreBook.new(book_id)}
        .sort_by{|book| [book.series, book.series_index]}
  end

  def self.search_series(query)
    @@db.execute("select books.id FROM books JOIN books_series_link ON books.id == books_series_link.book JOIN series ON books_series_link.series == series.id WHERE series.name LIKE '#{query}'")
        .flatten.map{|book_id| CalibreBook.new(book_id)}
        .sort_by{|book| [book.series, book.series_index]}
  end

  def initialize(book_id)
    @id = book_id
  end

  def id
    return @id
  end

  def title
    @title ||= @@db.execute("select title from books where id = #{@id}").first.first
  end

  def author #getting first author, there might be more
    @author ||= @@db.execute("SELECT name FROM authors JOIN books_authors_link ON authors.id=books_authors_link.author WHERE books_authors_link.book=#{@id}").first.first
  end

  def author_sort
    @author_sort ||= @@db.execute("SELECT author_sort FROM books where id=#{@id}").first.first
  end

  def series
    return @series unless @series.nil?
    query = @@db.execute("SELECT name FROM series JOIN books_series_link ON series.id=books_series_link.series WHERE books_series_link.book=#{@id}")
    if query.size > 0
       @series = query.first.first
    else
       @series = ""
    end
    return @series
  end

  def series_index
    return @series_index unless @series_index.nil?
    query = @@db.execute("select series_index from books where id = #{@id}")
    if query.size>0
      @series_index = query.first.first
    else
      @series_index = 0
    end
    return @series_index
  end

  def series_index_display
    i = self.series_index
    if i.to_i.to_f == i.to_f
      return i.to_i.to_s
    else
      return i.to_s
    end
  end

  def description
    return @description unless @description.nil?
    begin
      @description = @@db.execute("select text from comments where book = #{@id}").first.first
    rescue
      @description = ""
    end
    return @description
  end

  def book_path
    @book_path ||= @@db.execute("select path from books where id = #{@id}").first.first
  end

  def cover
    return @cover unless @cover.nil?
    cover_bool = @@db.execute("select has_cover from books where id = #{@id}").first.first
    if cover_bool
      @cover = "#{@@calibre_path}/#{book_path}/cover.jpg"
      return @cover
    else
      return nil
    end
  end

  def cover_color
    return @cover_color unless @cover_color.nil?
    return @cover_color = "#8B4513" unless HAS_IMAGEMAGICK  # Default brown color
    begin
      # Extract dominant color by sampling the left edge (spine area) of the cover
      # Take a thin vertical strip from the left edge and get its average color
      result = MiniMagick::Tool::Convert.new do |convert|
        convert << self.cover
        convert.gravity "West"  # Focus on left edge (spine)
        convert.crop "5x100%+0+0"  # Take 5px wide strip from left edge
        convert.scale "1x1!"  # Scale to 1 pixel (averages all colors)
        convert << "txt:-"  # Output as text format
      end
      
      # Parse the output to extract RGB values
      # Format: "0,0: (R,G,B) #HEXCOLOR ..."
      if result =~ /\((\d+),(\d+),(\d+)/
        r, g, b = $1.to_i, $2.to_i, $3.to_i
        @cover_color = "#%02x%02x%02x" % [r, g, b]
      else
        @cover_color = "#8B4513"
      end
    rescue => e
      puts "Color extraction failed for #{self.title}: #{e.message}"
      @cover_color = "#8B4513"  # Fallback to brown
    end
    return @cover_color
  end

  def cover_contrast
    return @cover_contrast unless @cover_contrast.nil?
    return @cover_contrast = "#eee" unless HAS_IMAGEMAGICK  # Default light text
    color_string = self.cover_color
    red = color_string[1..2].to_i(16)
    green = color_string[3..4].to_i(16)
    blue = color_string[5..6].to_i(16)
    brightness = (red + green + blue)/3.0
    if brightness > 128
      @cover_contrast = "#111"
    else
      @cover_contrast = "#eee"
    end
    return @cover_contrast
  end

  def aspect_ratio
    return 0.67 unless HAS_IMAGEMAGICK  # Default typical book aspect ratio
    begin
      img = MiniMagick::Image.open(self.cover)
      return img.width.to_f / img.height.to_f
    rescue => e
      return 0.67  # Fallback to default
    end
  end

  def file_path
    return @file_path unless @file_path.nil?
    book_files = @@db.execute("select name, format from data where book=#{@id}")
    book_files.each do |book_file|
      if book_file.last=="EPUB"
        @file_path = "#{@@calibre_path}/#{book_path}/#{book_file.first}.epub"
        return @file_path
      end
    end
    file_ext = book_files.first.last.downcase
    @file_path = "#{@@calibre_path}/#{book_path}/#{book_files.first.first}.#{file_ext}"
    return @file_path
  end

  def page_count
    return 300 if @@pagecount_column.nil?
    result = @@db.execute("select value from custom_column_#{@@pagecount_column} where book=#{@id}")
    @page_count ||= result.empty? ? 300 : result.first.first
  end

  def nonlinear_thickness
    @thickness ||= [0.85*(self.page_count**0.6),8].max
  end
end


##  Usage
#CalibreBook.connect("/Users/matt/Documents/books/Calibre Star Trek")
#CalibreBook.some_books.sort_by{|b| [b.series,b.series_index]}.each do |b|
#  puts b.title
#  puts b.author
#  puts "#{b.series} #{b.series_index}"
#  puts "#{b.page_count} Pages"
##  puts b.file_path
##  puts b.cover
#  puts ""
#end
      
