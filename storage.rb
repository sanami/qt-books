require 'misc.rb'
require 'book.rb'

##
# Хранилище информации о книгах
class Storage
	include Enumerable

	attr_reader :current_page

	def initialize
		ActiveRecord::Base.establish_connection(
			:adapter => 'sqlite3',
			:database  => File.expand_path('storage.sqlite3') # Файл базы данных
		)
#		ActiveRecord::Base.logger = Logger.new(STDERR)
#		ActiveRecord::Base.colorize_logging = true
		ActiveRecord::Base.logger = nil
#		ActiveRecord::Base.colorize_logging = true

		Book.create_table
	end

	##
	# Все записи из базы
	def each
		Book.all.each {|b| yield b }
	end

	##
	# Кол-во записей в базы
	def size
		Book.count
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

		@current_page = 1
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

		@current_page = 1
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

public
	def test
		p Book.column_names #названия столбцов
		puts "count #{Book.find(:all).size}"

		# Найти все
		find().each { |b| pp b }
		# Найти русский текст, не работает ignore case
#	  find(['ред']).each { |b| pp b }
	end
end

if $0 == __FILE__
	obj = Storage.new
	obj.test
end
