require 'yaml'

##
# Хранилище информации о файлах
class Books
	attr_reader :files        # { file_path => file_info, .. }
	attr_writer :is_changed
	attr_reader :db_file

	def initialize(db_file)
		@books = {}
		@db_file = db_file
		@is_changed = false
		load
	end

	def find(patterns)
		all = []
		rx_pattern = /#{patterns.join('.*')}/i
		puts "Books.find #{rx_pattern}"
		@books.each do |book|
			#pp book
			if book['title'] =~ rx_pattern
				all << book
			end
		end
		puts "\t#{all.size}"

		all
	end

	def load
		@is_changed = false
		@books = YAML.load_file @db_file
		puts "Books.loaded: #{@books.count}"
	rescue
		@books = {}
	end

	def save
		if @is_changed
			File.open( @db_file, 'w' ) do |out|
				YAML.dump( @books, out )
			end
			puts "Books.saved: #{@books.count}"
		end
	end

end
