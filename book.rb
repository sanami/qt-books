##
# Информация о книге, запись в таблице
class Book < ActiveRecord::Base
	##
	# Создать таблицу
	def self.create_table
		ActiveRecord::Schema.define do
			create_table('books') do |t|
				t.string   :file_name, :limit => 1000     # Название файла/архива, без пути на диске/архиве
				t.string   :file_path, :limit => 1000 # Полный путь файла/архива в котором находится документ
				t.string   :title_path, :limit => 1000     # Полный путь файла в архиве
				t.string   :title, :limit => 1000     # Название документа, без пути на диске/архиве
				t.datetime :last_modified # Дата документа
				t.datetime :added_to_storage # Дата добавления в базу
				t.integer  :size        # Размер документа
				t.integer  :crc         # CRC32
			end
		end
	rescue
		# Если уже существует
	end

	##
	# Корректные данные
	def good?
		bad = file_path.empty? || title.empty? || size == 0
	  !bad
	end
end
