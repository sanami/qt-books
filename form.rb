require 'misc.rb'
require 'ui_form.rb'
require 'qrc_resources.rb'
require 'storage.rb'
require 'finder.rb'

# Колонки дерева рузультата поиска
COLUMN_TITLE = 0
COLUMN_SIZE = 1
COLUMN_TIME = 2
COLUMN_FILE = 3

SIZE_ROLE = Qt::UserRole + 1

#class BookItem < Qt::TreeWidgetItem
#	def <(other)
#		puts 'aaaaaaaaaaaa'
#		column = treeWidget().sortColumn()
#		case column
#			when COLUMN_SIZE
#		    data(COLUMN_SIZE, SIZE_ROLE).toULongLong < other.data(COLUMN_SIZE, SIZE_ROLE).toULongLong
#		  else
#			  super
#		end
#	end
#end

##
# Главное окно приложения
class Form < Qt::MainWindow
	slots 'on_action_quit_triggered()'
	slots 'on_action_new_triggered()'
	slots 'on_action_open_triggered()'
	slots 'on_action_save_triggered()'
	slots 'on_action_save_as_triggered()'
	slots 'on_action_add_folder_to_storage_triggered()'
	slots 'on_book_search()'
	slots 'on_search_result_itemDoubleClicked(QTreeWidgetItem *, int)'
	slots 'on_search_next_page_clicked()'
	slots 'on_search_prev_page_clicked()'

	def initialize
		super
		init_ui

		@storage = Storage.new
		@finder = Finder.new @storage

		# Загрузить настройки
		#load_settings

		#if @settings.current_file and File.exists? @settings.current_file
		#	open_file @settings.current_file
		#end
	end

protected
	##
	# Не должен быть private
	def closeEvent(e)
		unless $debug
			if Qt::MessageBox::question(self, "Confirm Exit", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) != Qt::MessageBox::Ok
				e.ignore
				return
			end
		end

		# Сохранить настройки
#		save_settings
		super
	end

private
	##
	# Инициализация GUI
	def init_ui
		@ui = Ui::MainWindow.new
		@ui.setupUi(self)
		optimize_layouts self

		resize(1000, 600)
		move(0, 0)
		setWindowIcon(Qt::Icon.new(':/resources/app.ico'))
		setWindowTitle 'Books'

		# Дерево результатов поиска
		@ui.search_result.setColumnWidth(COLUMN_TITLE, 300)

		# Строка поиска
		connect(@ui.search, SIGNAL('clicked()'), SLOT('on_book_search()'))
	  connect(@ui.search_filter, SIGNAL('returnPressed()'), SLOT('on_book_search()'))
	end

	##
	#TODO автозагрузка состояния контролов окна
	def load_widget(parent)


	end

	##
	# Загрузка и применение настроек
	def load_settings
		@settings = Settings.new 'settings.yaml'

		if @settings.current_parser
			@ui.tabWidget_parsers.setCurrentIndex @settings.current_parser
		end

		if @settings.list_of_rx_choices.empty?
			# Значения по умолчанию
			@settings.list_of_rx_choices = ['^(\d+)\s*[\)\.](.+)', '^([a-z])\s*[\)\.](.+)']
		end

		unless @settings.list_of_rx_choices.empty?
			@ui.comboBox_rx_choices.addItems @settings.list_of_rx_choices
		end

		if @settings.current_rx_choice
			@ui.comboBox_rx_choices.setCurrentIndex @settings.current_rx_choice
		end

		if @settings.current_glossary_type
			@ui.comboBox_glossary_type.setCurrentIndex @settings.current_glossary_type
		end
		if @settings.current_glossary_delimiter
			@ui.comboBox_glossary_delimiter.setCurrentIndex @settings.current_glossary_delimiter
		end

		if @settings.shuffleanswers
			@ui.comboBox_shuffleanswers.setCurrentIndex @settings.shuffleanswers
		end

		if @settings.answernumbering
			@ui.comboBox_answernumbering.setCurrentIndex @settings.answernumbering
		end

		if @settings.splitter
			@ui.splitter.restoreState Qt::ByteArray.new(@settings.splitter)
		end
		if @settings.splitter_2
			@ui.splitter_2.restoreState Qt::ByteArray.new(@settings.splitter_2)
		end

		if @settings.form_geometry
			self.restoreGeometry Qt::ByteArray.new(@settings.form_geometry)
		end
	end

	##
	# Сохранение настроек
	def save_settings
		@settings.current_parser = @ui.tabWidget_parsers.currentIndex

		# Список шаблонов
		@settings.list_of_rx_choices = []
		0.upto(@ui.comboBox_rx_choices.count-1) { |i| @settings.list_of_rx_choices << @ui.comboBox_rx_choices.itemText(i) }
		@settings.current_rx_choice = @ui.comboBox_rx_choices.currentIndex

		@settings.current_glossary_type = @ui.comboBox_glossary_type.currentIndex
		@settings.current_glossary_delimiter = @ui.comboBox_glossary_delimiter.currentIndex

		@settings.shuffleanswers = @ui.comboBox_shuffleanswers.currentIndex
		@settings.answernumbering = @ui.comboBox_answernumbering.currentIndex

#		@settings.splitter = @ui.splitter.saveState.toBase64.to_s
		@settings.splitter = @ui.splitter.saveState.to_s
		@settings.splitter_2 = @ui.splitter_2.saveState.to_s

		@settings.form_geometry = self.saveGeometry.to_s

		@settings.save
	end

	##
	# Загрузить файл
	def open_file(file_name)
		@settings.current_file = file_name

		@ui.src.clear
		if zip_archive? file_name
			@mode = :archive
			@ui.src.setEnabled false
		else
			@mode = :text
			open(file_name) do |f|
				@ui.src.setPlainText to_utf(f.read)
				@ui.src.setEnabled true
			end
		end
		on_action_convert_triggered

		setWindowTitle "#{file_name} - Moodle"
		@settings.save
		statusBar.showMessage "File loaded: #{File.basename file_name}"
	rescue => ex
		save_error ex
		statusBar.showMessage "File error: #{File.basename file_name}"
	end

	##
	# Выйти из программы
	def on_action_quit_triggered
		$qApp.quit
	end

	##
	# Диалог загрузки файла
	def on_action_load_triggered
		dir_name = File.dirname(@settings.current_file || '.')
		file_name = Qt::FileDialog::getOpenFileName(nil, 'Open', dir_name, '*.*')
		if file_name
			open_file file_name
		end
	end

	##
	# Диалог сохранения файла
	def on_action_save_triggered
		return unless @settings.current_file

		# Имя по умолчанию
		file_name = "#{File.dirname(@settings.current_file)}/#{File.basename(@settings.current_file)}.xml"

		# Диалог выбора файла
		file_name = Qt::FileDialog::getSaveFileName(nil, 'Save XML', file_name, "XML (*.xml)")
		if file_name
			# Записать содержимое окна результата
			open(file_name, 'wb') { |f| f.write @ui.dst.to_plain_text }
			statusBar.showMessage "File saved: #{File.basename file_name}"
		end
	rescue => ex
		save_error ex
		statusBar.showMessage "File error: #{File.basename file_name}"
	end

  ##
	# Добавить все книги из каталога в базу
	def on_action_add_folder_to_storage_triggered
		@@last_dir ||= '.'
		dir = Qt::FileDialog::getExistingDirectory(self, 'Open Directory', @@last_dir, Qt::FileDialog::ShowDirsOnly)
	  if dir
		  @@last_dir = dir

		  # Посчитать кол-во каталогов
		  @ui.search_progress.setValue(0)
		  @finder.reset_dir_counter
		  @finder.process_dir(to_win(dir), :count) do |dir_name, max_count|
			  @ui.search_progress.setMaximum max_count
			  @ui.search_progress.setValue(@ui.search_progress.value+1)
			  $qApp.processEvents
				#puts to_utf(dir_name)
		  end

		  puts "*"*77

		  # Настоящая обработка файлов
		  @ui.search_progress.setValue(0)
		  @finder.process_dir(to_win(dir), :list) do |dir_name, max_count|
			  @ui.search_progress.setMaximum max_count
			  @ui.search_progress.setValue(@ui.search_progress.value+1)
			  $qApp.processEvents
			  #puts to_utf(dir_name)
		  end

	  end
	end

	##
	# Поиск по фразе в строке поиска
	def on_book_search
		str = @ui.search_filter.text
		str.gsub!(/[^\w]/, ' ')
		patterns = str.split(/[\s]+/).select {|word| word.jlength >= @ui.search_min_word.value }
		str = patterns.join ' '
		@ui.search_filter.setText str

		# Результаты
		books = @storage.find(patterns)
		show_search_results books
	end

	##
	# Следующая страница результатов поиска
	def on_search_next_page_clicked
		books = @storage.find_show_page true
	  show_search_results books
	end

	##
	# Предыдущая страница результатов поиска
	def on_search_prev_page_clicked
		books = @storage.find_show_page false
		show_search_results books
	end

	##
	# Показать результаты поиска
	def show_search_results(books)
		@ui.search_result.clear
		books.each do |book|
			size = book.size.to_s.align_right(12)
			size.gsub!(/(.{3})/, ' \1')
			columns = [book.title, size, book.last_modified.strftime('%Y-%m-%d %H:%M'), book.file_path]
			it = Qt::TreeWidgetItem.new(columns)
			#it = BookItem.new(columns)
			it.setTextAlignment(COLUMN_SIZE, Qt::AlignRight)
			it.setTextAlignment(COLUMN_TIME, Qt::AlignCenter)
			it.setData(COLUMN_SIZE, SIZE_ROLE, Qt::Variant.new(book.size))

			file_item = @ui.search_result.findItems(book.file_path, Qt::MatchExactly, 3)
			if file_item.empty?
				@ui.search_result.addTopLevelItem it
			else
				# Файлы в архиве под одним элементов
				parent_item = file_item.first
				parent_item_size = parent_item.data(COLUMN_SIZE, SIZE_ROLE).toULongLong
				
				if book.size > parent_item_size
					@ui.search_result.addTopLevelItem it
					while parent_item.childCount > 0
						it.addChild(parent_item.takeChild(0))
					end
					parent_index = @ui.search_result.indexOfTopLevelItem(parent_item)
					@ui.search_result.takeTopLevelItem(parent_index)
					it.addChild(parent_item)
				else
					parent_item.addChild it
				end
			end
		end
	end

  ##
	# Открыть документ или архив
	def on_search_result_itemDoubleClicked(it, column)
		url = Qt::Url.new("file:///" + it.text(COLUMN_FILE));
		Qt::DesktopServices::openUrl(url);
	end

end
