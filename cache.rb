##
# Информация о файле у которого был вычислен CRC32
class Cache < ActiveRecord::Base
	##
	# Создать таблицу
	def self.create_table
		ActiveRecord::Schema.define do
			create_table('caches') do |t|
				t.string   :file_name, :limit => 1000 # Имя файла
				t.string   :file_path, :limit => 1000 # Полный путь файла
				t.datetime :last_modified    # Дата изменения файла
				t.datetime :added_to_storage # Дата добавления в базу
				t.integer  :size        # Размер документа
				t.integer  :crc         # CRC32
			end
		end
	rescue
		# Если уже существует
	end

	##
	# Добавить поле с именем файла
  def self.add_file_name_column
	  ActiveRecord::Schema.define do
		  add_column :caches, :file_name, :string, :limit => 1000
	  end

	  all.each do |c|
		  c.update_attribute(:file_name, File.basename(c.file_path))
		end
  end

  def self.show_all
	  all.each do |c|
		  pp c
		end
  end
end
