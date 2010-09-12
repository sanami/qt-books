require 'misc.rb'
require 'book.rb'

##
# Хранилище информации о книгах
class Storage
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
	# Найти запись
	def find(patterns = [], page = 1, per_page = 100)
		conditions = nil
		unless patterns.empty?
			patterns = patterns.map { |word| "%#{word}%" }
			# Искать по названию документа или архива
			#TODO Исключить каталог
			query1 = (["(title LIKE ?)"] * patterns.size).join(" AND ")
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

	def find_show_page(next_page = true)
		books = []
		if @current_page
			next_page ? @current_page += 1 : @current_page -= 1
			books = Book.paginate :page => @current_page, :per_page => @current_per_page, :conditions => @current_conditions
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
