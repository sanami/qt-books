require 'active_record'
require 'zlib'
require 'book.rb'
require 'cache.rb'

##
# Хранилище информации о книгах
class Storage
	include Enumerable

	attr_reader :current_page

	def initialize
		ActiveRecord::Base.establish_connection(
			:adapter => 'sqlite3',
			:database  => ROOT('db/storage.sqlite3') # Файл базы данных
		)
# 		ActiveRecord::Base.logger = Logger.new(STDERR)

		Book.create_table
		Cache.create_table
		#Cache.add_file_name_column
		#Cache.show_all

		puts "Book.count #{Book.count}, Cache.count #{Cache.count}"
	end

	##
	# Массовая обработка базы данных
	def transaction 
		Book.transaction { yield }
	end

	##
	# Все записи из базы
	def each
		Book.find_each {|b| yield b }
	end

	##
	# Кол-во записей в базы
	def size
		Book.count
	end

	##
	# Конвертировать в YAML
	def to_yaml(file_db)
		all = []
		Book.find_each do |book|
			all << book.attributes
		end

		File.open( file_db, 'w' ) do |out|
			YAML.dump( all, out )
		end
	end

	##
	# Книги с одинаковым CRC32, после искать по размеру
	def find_same_crc
		books = Book.all :group => 'crc', :having => 'count(crc) > 1'
		books
	end

	##
	# Список документов из этого же файла
	def file_content(file_path_utf8)
		Book.find_all_by_file_path file_path_utf8
	end

	##
	# Найти записи с разбитием на страницы
	def find(patterns = [], page = 1, per_page = 100)
		conditions = nil
		unless patterns.empty?
			patterns = patterns.map { |word| "%#{word}%" }
			# Искать по названию документа или архива
			#TODO Исключить каталог
			query1 = (["(title_path LIKE ?)"] * patterns.size).join(" AND ")
			query2 = (["(file_path LIKE ?)"] * patterns.size).join(" AND ")
			conditions = [ "(#{query1}) OR (#{query2})"  ]
			conditions = conditions + patterns + patterns
			#pp conditions
		end
		#books = Book.find(:all, :conditions => conditions)
		books = Book.paginate :page => page, :per_page => per_page, :conditions => conditions

		@current_page = page
		@current_per_page = per_page
		@current_conditions = conditions

		books
	end

	##
	# Найти похожие записи
	def find_duplicate(original_book, page = 1, per_page = 100)
		conditions = nil
		if original_book.crc == 0
			# Искать по размеру и имени файла
			#TODO index.html
			conditions = ["size = ? and title = ?", original_book.size, original_book.title]
		else
			# Искать по размеру и CRC32
			conditions = ["size = ? and crc <> 0 and crc = ?", original_book.size, original_book.crc]
		end
		books = Book.paginate :page => page, :per_page => per_page, :conditions => conditions

		@current_page = page
		@current_per_page = per_page
		@current_conditions = conditions

		books
	end

	##
	# Следующая/предыдущая страница текущего запроса
	def find_show_page(next_page = true)
		books = []
		if @current_page
			next_page ? @current_page += 1 : @current_page -= 1
			if @current_page > 0
				books = Book.paginate :page => @current_page, :per_page => @current_per_page, :conditions => @current_conditions
			end
		end

		books
	end

	##
	# Запись уже добавлена
	def added?(file_path)
		Book.exists?(:file_path => file_path)
	end
	alias contains? added?

	##
	# Добавить запись
	def add
		book = Book.new
		yield book
		book.added_to_storage = DateTime.now
		book.save if book.good?
	end

	##
	# Вычислить CRC32 указанного файла, путь в UTF-8
	def calculate_crc(file_path_utf8)
		file_name_utf8 = File.basename(file_path_utf8)
		file_path = to_win(file_path_utf8)
		file_size = File.size(file_path) 
		file_mtime = File.mtime(file_path)
#		conditions = ["file_path = ? and size = ? and last_modified = ?",
#		              file_path_utf8, file_size, file_mtime]
		conditions = ["file_name = ? and size = ? and last_modified = ?",
		              file_name_utf8, file_size, file_mtime]
		cache = Cache.first(:conditions => conditions)
		# Вернуть из кэша
		return cache.crc if (cache)

		crc = Zlib.crc32( open(file_path, 'rb') {|f| f.read } )
		puts('CRC32=%x %s' % [crc, file_path_utf8])

		# Добавить в кэш
		if crc != 0
			cache = Cache.create(:file_name => file_name_utf8, :file_path => file_path_utf8,
			                     :last_modified => file_mtime, :size => file_size, :crc => crc,
			                     :added_to_storage => DateTime.now)
		end

		crc
	rescue => ex
		save_error ex
		0
	end

public
	def test
#		p Book.column_names # Названия столбцов

		# Найти все
#		find().each { |b| pp b }
		# Найти русский текст, не работает ignore case
#	  find(['ред']).each { |b| pp b }

#		p Cache.column_names # Названия столбцов
#		p calculate_crc('./1/test/Основы программирования на C++ [Липпман].djvu')

#		books = Book.paginate :page => 1, :per_page => 5,
#			:group => 'size', :having => 'count(size) > 1'

#		books = Book.find_by_sql 'select * from books group by size having count(size) > 1'
#		pp books.size
		#pp books.first.attributes

	end
end

if $0 == __FILE__
	obj = Storage.new
	obj.test
end
