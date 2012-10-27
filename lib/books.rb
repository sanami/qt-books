#require 'yaml'
require 'process_dir.rb'

# Books storage
class Books
  attr_reader :files

  def initialize(db_file = '', db_file_old = '')
    @books = []
    @books_old = []

    # Load
    load(db_file)
    if File.exist? db_file_old
      @books_old = YAML.load_file db_file_old
    end
  end

  def clear
    @books.clear
  end

  def status_message
    "Books: #{@books.count}, Old books: #{@books_old.count}"
  end

  def find(patterns, in_new = true, live_folders = [], &gui_proc)
    all = []
    rx_pattern = /#{patterns.join('.+')}/i
    puts "Books.find #{rx_pattern}"

    (in_new ? @books : @books_old).each do |book|
      #pp book
      if book['title'] =~ rx_pattern
        all << book
      end
    end

    # Find on disk
    live_folders.each do |folder|
      find_in_folder(all, folder, rx_pattern, &gui_proc)
    end

    puts "\t#{all.size}"
    all
  end

  # Search in folder
  def find_in_folder(all, dir_path, rx_pattern, &gui_proc)
    process_dir(dir_path, :list) do |action, file_path|
      case action
        when :list
          #pp file_path
          gui_proc.call(:list, file_path)

        when :action
          file_name = File.basename(file_path)
          if file_name =~ rx_pattern
            book = {}
            book['title'] = file_name
            book['size'] = File.size(file_path)
            book['file_path'] = file_path

            all << book
          end
      end
    end
  end

  def add_books(dir_path, &gui_proc)
    process_dir(dir_path, :list) do |action, file_path|
      case action
        when :list
          #pp file_path
          gui_proc.call(:list, file_path)

        when :action
          book = {}
          book['title'] = File.basename(file_path)
          book['size'] = File.size(file_path)
          book['file_path'] = file_path

          @books << book
      end
    end

  end

  def load(file_name)
    if File.exist? file_name
      @books = YAML.load_file file_name
    end
  end

  def save(file_name)
    File.open( file_name, 'w' ) do |f|
      YAML.dump(@books, f)
    end
  end

end
