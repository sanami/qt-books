require 'finder_base.rb'
require 'storage.rb'

##
# Находит копии книги из базы
class DuplicateFinder < FinderBase
	def initialize(storage)
		super()
		@storage = storage
	end

private
	##
	# Обработать файл
	def process_file(file_path, file_name_utf8, file_path_utf8)
		puts "DuplicateFinder.process_file(#{file_path_utf8})"
		entries = list_file_entries(file_path, file_name_utf8, file_path_utf8)

		# Только архивы с одним документом
#		if entries.size == 1 && file_type(entries.first[:title]) == :doc # && entries.first[:crc] > 0
#			book = OpenStruct.new(entries.first)
#			#pp book
#
#			duplicates = @storage.find_duplicate book
#			unless duplicates.empty?
#				puts "\tfound duplicate id #{duplicates.first.id}"
#
#				File.delete to_win(book.file_path)
#				#break
#			end
#		else
#			puts "\tskip"
#		end

		entries.each do |e|
			if is_book(e[:title])
				book = OpenStruct.new(e)

				duplicates = @storage.find_duplicate book
				unless duplicates.empty?
					puts "\tfound duplicate id #{duplicates.first.id}"

					File.delete to_win(book.file_path)
					break
				end
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
