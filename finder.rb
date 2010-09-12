require 'misc.rb'
require 'zip/zip'
require '../_gems/unrar/rubyrar.so'
require 'storage.rb'

##
# Ищет книги по каталогам/архивам
class Finder
	def initialize(storage)
		@storage = storage
	  @count_dir = 0
	end

	def reset_dir_counter
		@count_dir = 0
	end

	##
	# Пройтись по каталогу, dir_name в cp1251
	def process_dir(dir_name, action, &gui_proc)
		#puts "Finder.process_dir(#{to_utf(dir_name)})"
		Dir.chdir dir_name
		Dir.foreach('.') do |file_name| 
			next if file_name == '.' || file_name == '..'

			case action
				when :count
					# Считать кол-во каталогов
					if FileTest.directory? file_name
						@count_dir += 1
						gui_proc.call(file_name, 10000) if gui_proc
						process_dir(file_name, action, &gui_proc)
					end
				when :list
					if FileTest.directory? file_name
						gui_proc.call(file_name, @count_dir) if gui_proc
						process_dir(file_name, action, &gui_proc)
					else
						# Пути в кодировке Windows
						file_name_utf8 = to_utf(file_name, 'cp1251')
						file_path_utf8 = to_utf(File.expand_path(file_name), 'cp1251')
						process_file(file_name, file_name_utf8, file_path_utf8) unless @storage.contains?(file_path_utf8)
					end
			end
		end
		Dir.chdir '..'
	end

private
	##
	# Обработать файл
	def process_file(file_name, file_name_utf8, file_path_utf8)
		puts "Finder.process_file(#{file_path_utf8})"

		entries = []
		case file_type(file_name)
			when :rar
				entries += list_rar(file_name, file_path_utf8)
			when :zip
				entries += list_zip(file_name, file_path_utf8)
			when :doc
				entries << {:file_path => file_path_utf8, :title => file_name_utf8,
										:last_modified => File.mtime(file_name), :size => File.size(file_name),
										:crc => 0, :quick_hash => 0  }
			else
				#puts "\tskip"
		end

	  entries.each do |e|
		  next if file_type(e[:title]) != :doc
		  #pp e

		  @storage.add do |book|
			  book.file_path = e[:file_path]
			  book.title = e[:title]
			  book.last_modified = e[:last_modified]
			  book.size = e[:size]
			  book.crc = e[:crc]
			  book.quick_hash = e[:quick_hash]
		  end
	  end

	rescue => ex
		save_error ex
	end

	##
	# Определить тип файла по расширению
	def file_type(file_name)
		@@doc_ext ||= %w[ pdf doc rtf txt djv djvu chm htm html ].map { |ext| ".#{ext}" }
		@@rar_ext ||= %w[ rar ].map { |ext| ".#{ext}" }
		@@zip_ext ||= %w[ zip ].map { |ext| ".#{ext}" }

		case File.extname(file_name).downcase
			when *@@rar_ext
				:rar
			when *@@zip_ext
				:zip
			when *@@doc_ext
		    :doc
			else
				:unknown
		end
	end

	##
  # Вернуть список файлов в архиве RAR
	def list_rar(rar_file_name, rar_file_path_utf8)
		result = []
		RubyRar.list(rar_file_name) do |entry|
			next if entry[RAR_IsDir]

			entry_name_utf8 = Iconv.conv('utf-8', 'UCS-2-INTERNAL', entry[RAR_FileNameW])
			result << {:file_path => rar_file_path_utf8, :title => File.basename(entry_name_utf8),
			           :last_modified => entry[RAR_FileTime], :size => entry[RAR_UnpSize],
			           :crc => entry[RAR_FileCRC], :quick_hash => 0  }
		end
		result
#	rescue
#		[]
	end

  ##
  # Вернуть список файлов в архиве ZIP
	def list_zip(zip_file_name, zip_file_path_utf8)
		zf = Zip::ZipFile.new(zip_file_name)
		result = []
		zf.each do |entry|
			next if entry.directory?

			entry_name_utf8 = File.basename(entry.name)
			begin
				#enc = entry.name_encoding.gsub(/\//, '')
				entry_name_utf8 = Iconv.conv('utf-8', 'ibm866', entry_name_utf8)
			#TODO rescue
			end

			result << {:file_path => zip_file_path_utf8, :title => entry_name_utf8,
								 :last_modified => entry.mtime, :size => entry.size,
								 :crc => entry.crc, :quick_hash => 0  }
		end
		result
#	rescue
#		[]
	end

public
  def test
#		process_dir('./1/test/')
		process_dir('C:\_books_new\_bad')
#	  process_dir 'C:\_books\_code'
  end
end

if $0 == __FILE__
	s = Storage.new
	obj = Finder.new s
	obj.test
	s.test
end
