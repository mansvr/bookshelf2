require 'sinatra'
require_relative 'calibre.rb'
require_relative 'logos.rb'

## setup
bookdir = ARGV[0]
raise "Please specify a Calibre library directory as a parameter when running this server" if bookdir.nil?
CalibreBook.connect(bookdir)
books = CalibreBook.some_books(15)

## endpoints

get '/' do
  @books = CalibreBook.some_books(25)
  erb :index
end

# JSON API endpoint for React frontend
get '/books.json' do
  content_type :json
  books = CalibreBook.some_books(50)
  books.map do |book|
    {
      id: book.id,
      title: book.title,
      author: book.author,
      description: book.description,
      cover_color: book.cover_color,
      cover_contrast: book.cover_contrast,
      aspect_ratio: book.aspect_ratio,
      nonlinear_thickness: book.nonlinear_thickness,
      page_count: book.page_count,
      file_path: book.file_path,
      cover: book.cover,
      series: book.series,
      series_index: book.series_index
    }
  end.to_json
end

get '/author/:query' do
  @books = CalibreBook.search_author params['query']
  erb :index
end

get '/series/:query' do
  @books = CalibreBook.search_series params['query']
  erb :index
end

get '/download/*' do
  filepath = params['splat'].first
  filepath.gsub!("/../","/") # try to avoid exposing the whole filesystem, probably not good enough
  puts "DEBUG getting #{filepath}"
  # Check if filepath starts with bookdir (handle Windows paths)
  normalized_filepath = filepath.gsub("\\", "/")
  normalized_bookdir = bookdir.gsub("\\", "/")
  if normalized_filepath.start_with?(normalized_bookdir)
    send_file filepath
  else
    raise Sinatra::NotFound
  end
end
