require 'finder_base.rb'
require 'storage.rb'

##
# Ищет книги по каталогам/архивам
class BookFinder < FinderBase
	def initialize(storage)
		super()
		@storage = storage
	end

	##
	# Обновить базу
	def update_storage(max_count = -1, &gui_proc)
		@storage.transaction do
			@storage.each_with_index do |book, i|
				break if i == max_count
	
				if File.exists?(to_win(book.file_path))
					# Вычислить CRC32
					if book.crc == 0
						new_crc = @storage.calculate_crc(book.file_path)
						if new_crc != 0
							book.update_attribute(:crc, new_crc)
						end

						gui_proc.call(i, :crc, book.title) if gui_proc
					end
				else
					# Удалить из базы
					book.delete

					gui_proc.call(i, :delete, book.title) if gui_proc
					next
				end
	
			end
		end
	end

private
	##
	# Обработать этот файл?
	def can_process_file?(file_path, file_path_utf8)
		# Пропускать файлы больше 200 mb
		file_size = File.size(file_path)
		# Для файлов больше 2gb ruby 1.8 возвращает <0
		(!@storage.contains?(file_path_utf8)) && (file_size > 0 && file_size < 200*1024*1024)
	rescue
		false
	end

	##
	# Обработать файл
	def process_file(file_path, file_name_utf8, file_path_utf8, &gui_proc)
		puts "BookFinder.process_file(#{file_path_utf8})"
		entries = list_file_entries(file_path, file_name_utf8, file_path_utf8)

	  entries.each do |e|
		  # Только документы
		  next if file_type(e[:title]) != :doc
		  #pp e

		  @storage.add do |book|
			  book.file_name = e[:file_name]
			  book.file_path = e[:file_path]
			  book.title_path = e[:title_path]
			  book.title = e[:title]
			  book.last_modified = e[:last_modified]
			  book.size = e[:size]
			  book.crc = e[:crc] != 0 ? e[:crc] : @storage.calculate_crc(book.file_path) # Вычислить

			  gui_proc.call(:add_book, book) if gui_proc
		  end
	  end
	end

public
  def test
	  puts @storage.size
    update_storage(100) do |i, action, book_title|
	    puts "#{i}, #{action}, #{book_title}"
    end
#		process_dir('C:\_books_new\_bad', :list)
  end
end

if $0 == __FILE__
	obj = BookFinder.new Storage.new
	obj.test
end
