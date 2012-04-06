require 'yaml'
require 'process_dir.rb'

##
# Хранилище информации о файлах
class Books
  attr_reader :files        # { file_path => file_info, .. }
  attr_writer :is_changed
  attr_reader :db_file
  attr_reader :db_file_old

  def initialize(db_file, db_file_old)
    @books = []
    @books_old = []
    @db_file = db_file
    @db_file_old = db_file_old
    @is_changed = false
    load
  end

  def find(patterns, in_new = true)
    all = []
    rx_pattern = /#{patterns.join('.+')}/i
    puts "Books.find #{rx_pattern}"

    (in_new ? @books : @books_old).each do |book|
      #pp book
      if book['title'] =~ rx_pattern
        all << book
      end
    end

    puts "\t#{all.size}"
    all
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

  def load
    @is_changed = false
    if File.exist? @db_file
      @books = YAML.load_file @db_file
    end
    if  File.exist? @db_file_old
      @books_old = YAML.load_file @db_file_old
    end
    puts "Books.loaded: #{@books_old.count}"
  rescue
    @books_old = []
  end

  def save
    if @is_changed
    File.open( @db_file, 'w' ) do |out|
      YAML.dump( @books, out )
    end

    File.open( @db_file_old, 'w' ) do |out|
        YAML.dump( @books_old, out )
      end
      puts "Books.saved: #{@books_old.count}"
    end
  end

end
