require 'misc.rb'
require 'find'
require 'zip/zip'
require '../_gems/unrar/rubyrar.so'

##
# Поиск файлов по всем каталогам
class FinderBase
	##
	# Подсчитать кол-во обрабатываемых каталогов
	def self.count_process_dir(dir_path, &gui_proc)
		puts "FinderBase.count_process_dir(#{dir_path})"
		dir_count = 0
		Find.find(File.expand_path(to_win(dir_path))) do |file_path| # file_path в кодировке Windows
			if FileTest.directory? file_path
				dir_count += 1
				gui_proc.call(:count_dir, file_path) if gui_proc
			end
		end
	  dir_count
	end

	##
	# Пройтись по каталогу, dir_path в utf8
	def process_dir(dir_path, action, &gui_proc)
		puts "FinderBase.process_dir(#{dir_path})"
		dir_count = 0
		Find.find(File.expand_path(to_win(dir_path))) do |file_path| 
			# file_path в кодировке Windows
			case action
				when :count
					# Считать кол-во каталогов
					if FileTest.directory? file_path
						dir_count += 1
						gui_proc.call(:count_dir, file_path) if gui_proc
					end
				when :list
					if FileTest.directory? file_path
						# Прогресс
						gui_proc.call(:list_dir, file_path) if gui_proc
					else
						file_path_utf8 = to_utf(file_path, 'cp1251')
						file_name_utf8 = File.basename(file_path_utf8)
						process_file(file_path, file_name_utf8, file_path_utf8, &gui_proc) if can_process_file?(file_path, file_path_utf8)
					end
			end
		end

		# Возвращаемое значение
		case action
			when :count
			  dir_count
			else
		    nil
		end
	end

protected
	##
	# Обработать этот файл? переопределять
	def can_process_file?(file_path, file_path_utf8)
		true
	end

	##
	# Обработать файл, переопределять
	# Вызывать gui_proc.call(:action, object) if gui_proc
	def process_file(file_path, file_name_utf8, file_path_utf8, &gui_proc)
		puts "FinderBase.process_file(#{file_path_utf8})"

		entries = list_file_entries(file_path, file_name_utf8, file_path_utf8)
		pp entries
	end

	##
	# Вернуть данные файла, или списка файлов из архива
	def list_file_entries(file_path, file_name_utf8, file_path_utf8)
		#puts "FinderBase.list_file_entries(#{file_path_utf8})"

		entries = []
		case file_type(file_path)
			when :rar
				entries += list_rar(file_path, file_name_utf8, file_path_utf8)
			when :zip
				entries += list_zip(file_path, file_name_utf8, file_path_utf8)
			else
				entries << {:file_name => file_name_utf8, :file_path => file_path_utf8,
				            :title_path => file_path_utf8, :title => file_name_utf8,
				            :last_modified => File.mtime(file_path), :size => File.size(file_path),
				            :crc => 0 }
		end

		entries
	rescue => ex
		save_error ex
		#TODO Отображать ошибки в GUI
		[]
	end

private
	##
	# Определить тип файла по расширению
	def file_type(file_name)
#		@@doc_ext ||= %w[ pdf doc rtf txt djv djvu chm htm html ].map { |ext| ".#{ext}" }
		@@doc_ext ||= %w[ pdf djv djvu chm ].map { |ext| ".#{ext}" }
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
	# Определить тип файла по расширению
	def is_book(file_name)
		@@book_ext ||= %w[ pdf djv djvu chm ].map { |ext| ".#{ext}" }

		case File.extname(file_name).downcase
			when *@@book_ext
				true
			else
				false
		end
	end

	##
	# Вернуть список файлов в архиве RAR
	def list_rar(rar_file_path, rar_file_name_utf8, rar_file_path_utf8)
		result = []
		RubyRar.list(rar_file_path) do |entry|
			next if entry[RAR_IsDir]

			entry_name_utf8 = Iconv.conv('utf-8', 'UCS-2-INTERNAL', entry[RAR_FileNameW])
			result << {:file_name => rar_file_name_utf8, :file_path => rar_file_path_utf8,
			           :title_path => entry_name_utf8, :title => File.basename(entry_name_utf8),
			           :last_modified => entry[RAR_FileTime], :size => entry[RAR_UnpSize],
			           :crc => entry[RAR_FileCRC] }
		end
		result
	#TODO rescue
	#	[]
	end

	##
	# Вернуть список файлов в архиве ZIP
	def list_zip(zip_file_path, zip_file_name_utf8, zip_file_path_utf8)
		zf = Zip::ZipFile.new(zip_file_path)
		result = []
		zf.each do |entry|
			next if entry.directory?

			entry_name_utf8 = entry.name
			begin
				#enc = entry.name_encoding.gsub(/\//, '')
				entry_name_utf8 = Iconv.conv('utf-8', 'ibm866', entry_name_utf8)
			#TODO rescue
			end

			result << {:file_name => zip_file_name_utf8, :file_path => zip_file_path_utf8,
			           :title_path => entry_name_utf8, :title => File.basename(entry_name_utf8),
			           :last_modified => entry.mtime, :size => entry.size,
			           :crc => entry.crc }
		end
		result
	#TODO rescue
	#	[]
	end

public
  def test
#  	process_dir('./1/test', :count)
#  	puts "********************* #{count_dir} folders"
#  	process_dir('./1/test', :list)
  end
end

if $0 == __FILE__
#	$console_codec = 'ibm866'
	obj = FinderBase.new
	obj.test
end
