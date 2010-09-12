##
# Информация о книге, запись в таблице
class Book < ActiveRecord::Base
	##
	# Создать таблицу
	def self.create_table
		ActiveRecord::Schema.define do
			create_table :books do |t|
				t.string   :file_path, :limit => 1000 # Путь файла/архива в котором находится документ
				t.string   :title, :limit => 1000     # Название документа, без пути на диске/архиве
				t.datetime :last_modified # Дата документа
#				t.datetime :added_to_storage # Дата добавления в базу
				t.integer  :size        # Размер документа
				t.integer  :crc         # CRC32
				t.integer  :quick_hash  # Быстрый CRC
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
