require 'finder_base.rb'
require 'storage.rb'

##
# Находит копии книги из базы
class DuplicateFinder < FinderBase
	def initialize(storage)
		super()
		@storage = storage
	end

	##
	# Найти повторы в базе
	def find_in_storage(max_count = -1, &gui_proc)
		books = @storage.find_same_crc
		max_count = books.size
		books.each_with_index do |book, i|
			break if i == max_count
			
			dups = @storage.find_duplicate(book).reject {|obj| obj == book }
			gui_proc.call(i, max_count, book, dups) if gui_proc && !dups.empty?
		end
		#TODO дубликат может находится в архиве с другими файлами


#		@storage.each_with_index do |book, i|
#			break if i == max_count
#
#			dups = @storage.find_duplicate(book).reject {|obj| obj == book }
#			#TODO найдёт также для каждого из dups
#
#			unless dups.empty?
#				gui_proc.call(i, book, dups) if gui_proc
#			end
#
#		end
	end

private
	##
	# Обработать этот файл?
	def can_process_file?(file_path, file_path_utf8)
		# Пропускать файлы больше 200 mb
		file_size = File.size(file_path) 
		# Для файлов больше 2gb ruby 1.8 возвращает <0
		(file_size > 0 && file_size < 200*1024*1024)
	rescue
		false
	end

	##
	# Обработать файл
	def process_file(file_path, file_name_utf8, file_path_utf8, &gui_proc)
		puts "DuplicateFinder.process_file(#{file_path_utf8})"
		entries = list_file_entries(file_path, file_name_utf8, file_path_utf8)

		# Только файл или архив с одним документом
		return if entries.size != 1

		# Только книги: pdf djv djvu chm
		book = OpenStruct.new(entries.first)
		return unless is_book(book.title)

		entries.each do |e|
			book = OpenStruct.new(e)

			# Вычислить CRC
			if book.crc == 0
				book.crc = @storage.calculate_crc book.file_path
			end

			duplicates = @storage.find_duplicate book
			unless duplicates.empty?
				puts "\tfound duplicate id #{duplicates.first.id}"

				gui_proc.call(:duplicate_found, [book, duplicates]) if gui_proc
#				File.delete to_win(book.file_path)
				break
			end
		end
	end

public
  def test
#  	process_dir('./1/test/', :list)
  	process_dir('D:\2\_books', :list)
  end
end

if $0 == __FILE__
	$console_codec = 'ibm866'
	obj = DuplicateFinder.new Storage.new
	obj.test
end
