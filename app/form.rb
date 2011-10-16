require 'misc.rb'
require 'ui_form.rb'
require 'qrc_resources.rb'
require 'storage.rb'
require 'book_finder.rb'
require 'duplicate_finder.rb'

# Колонки дерева результата поиска
COLUMN_TITLE = 0
COLUMN_SIZE = 1
COLUMN_TIME = 2
COLUMN_CRC = 3
COLUMN_FILE_PATH = 4
COLUMN_TITLE_PATH = 5

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
	slots 'on_action_update_storage_triggered()'
	slots 'on_action_find_duplicates_triggered()'
	slots 'on_action_find_duplicates_in_storage_triggered()'
	slots 'on_action_delete_files_triggered()'
	slots 'on_action_search_from_clipboard_triggered()'
	slots 'on_book_search()'
	slots 'on_search_result_itemDoubleClicked(QTreeWidgetItem *, int)'
	slots 'on_duplicates_result_itemDoubleClicked(QTreeWidgetItem *, int)'
	slots 'on_duplicates_result_currentItemChanged(QTreeWidgetItem *, QTreeWidgetItem *)'
	slots 'on_search_next_page_clicked()'
	slots 'on_search_prev_page_clicked()'

	def initialize
		super
		init_ui

		@state = nil # Текущее состояние
		@storage = Storage.new
		@book_finder = BookFinder.new @storage
	  @dup_finder = DuplicateFinder.new @storage

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
		@ui.search_result.setColumnWidth(COLUMN_FILE_PATH, 500)
		@ui.search_result.setColumnWidth(COLUMN_TITLE_PATH, 500)

		# Дерево результатов поиска
		@ui.duplicates_result.setColumnWidth(COLUMN_TITLE, 300)
		@ui.duplicates_result.setColumnWidth(COLUMN_FILE_PATH, 500)
		@ui.duplicates_result.setColumnWidth(COLUMN_TITLE_PATH, 500)
		@ui.duplicates_result.addAction @ui.action_delete_files

		# Строка поиска
		connect(@ui.search, SIGNAL('clicked()'), SLOT('on_book_search()'))
	  connect(@ui.search_filter, SIGNAL('returnPressed()'), SLOT('on_book_search()'))

#		statusBar.addPermanentWidget(ui.messages, 100);
#		statusBar.addPermanentWidget(ui.newsCount);
		statusBar.addPermanentWidget(@ui.progress)

	  init_actions
	end

	def init_actions
		# ALT+B активизирует окно
		#WORD wVirtualKeyCode = 0x42; //B
		#WORD wModifiers = 0x04;//HOTKEYF_ALT;
		#::SendMessage(winId(), WM_SETHOTKEY, MAKEWORD(wVirtualKeyCode, wModifiers), 0);
		#Win32::SendMessage.call(winId(), 50, 0x4204, 0)
		# winId не работает, вызывает Segmentation fault

		# ESC сворачивает окно
		a = Qt::Action.new(self)
		a.setShortcut(Qt::KeySequence.new(Qt::Key_Escape))
		connect(a, SIGNAL('triggered()'), SLOT('showMinimized()'))
		addAction(a)

		# CTRL+E фокус на строку поиска
		a = Qt::Action.new(self)
		a.setShortcut(Qt::KeySequence.new(Qt::Key_E + Qt::CTRL))
		connect(a, SIGNAL('triggered()'), @ui.search_filter, SLOT('setFocus()'))
		addAction(a)

		# Вставка из буфера
	  addAction(@ui.action_search_from_clipboard)
	end

	##
	# Запрос подтверждения
	def confirm?(message)
		Qt::MessageBox::question(self, "Confirm", message, Qt::MessageBox::Ok, Qt::MessageBox::Cancel) == Qt::MessageBox::Ok
	end

	##
	# Сообщение в строке состояния
	def status(msg)
		statusBar.showMessage msg
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
		status "File loaded: #{File.basename file_name}"
	rescue => ex
		save_error ex
		status "File error: #{File.basename file_name}"
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
			status "File saved: #{File.basename file_name}"
		end
	rescue => ex
		save_error ex
		status "File error: #{File.basename file_name}"
	end

	##
	# Инициализировать прогресс бар
	def init_progress(dir_path)
		# Посчитать кол-во каталогов
		status 'Count folders'
		@ui.progress.setMaximum 10000
		@ui.progress.setValue(0)
		dir_count = FinderBase.count_process_dir(dir_path) do |action, obj|
			if action == :count_dir
				# В obj имя каталога
				#puts to_utf(obj)
				@ui.progress.setValue(@ui.progress.value+1)
			else
			  raise "Unknown action: #{action}"
			end

			$qApp.processEvents
		end

		@ui.progress.setValue(0)
		@ui.progress.setMaximum dir_count
	end

	##
	# Обновить прогресс
	def update_progress
		@ui.progress.setValue(@ui.progress.value+1)
	end

  ##
	# Добавить все книги из каталога в базу
	def on_action_add_folder_to_storage_triggered
		@@last_dir ||= '.'
		dir_path = Qt::FileDialog::getExistingDirectory(self, 'Add folder', @@last_dir, Qt::FileDialog::ShowDirsOnly)
	  if dir_path
		  @@last_dir = dir_path

		  @ui.search_result.clear
		  init_progress(dir_path)

		  # Обработка файлов
		  status 'Add folder'

		  @book_finder.process_dir(dir_path, :list) do |action, obj|
			  if action == :list_dir
				  # obj - имя каталога
				  update_progress
			  elsif action == :add_book
				  # obj - книга
			    show_book(@ui.search_result, obj)
			  else
			    raise "Unknown action: #{action}"
				end

			  $qApp.processEvents
		  end

		  @ui.progress.reset
		  status 'OK'
	  end
	end

	##
	# Найти повторы файлов из базы в выбранном каталоге
	def on_action_find_duplicates_triggered
		@@last_dir2 ||= '.'
		dir_path = Qt::FileDialog::getExistingDirectory(self, 'Find duplicates', @@last_dir2, Qt::FileDialog::ShowDirsOnly)
	  if dir_path
		  @@last_dir2 = dir_path

		  @ui.duplicates_result.clear
		  init_progress(dir_path)

		  # Обработка файлов
		  status 'Find duplicates'

		  @dup_finder.process_dir(dir_path, :list) do |action, obj|
			  if action == :list_dir
				  # obj - имя каталога
				  update_progress
			  elsif action == :duplicate_found
				  # obj - [book, [duplicates]]
			    show_duplicate(@ui.duplicates_result, obj[0], obj[1])
			  else
			    raise "Unknown action: #{action}"
				end

			  $qApp.processEvents
		  end

		  @ui.progress.reset
		  status 'OK'
	  end
	end

	##
	# Найти повторы в базе
	def on_action_find_duplicates_in_storage_triggered
		return unless confirm? 'Find duplicates in storage'

		status 'Find duplicates in storage'
		@ui.duplicates_result.clear

		@dup_finder.find_in_storage do |i, max_count, book, duplicates|
			@ui.progress.setValue i
			@ui.progress.setMaximum max_count

			show_duplicate(@ui.duplicates_result, book, duplicates)

			$qApp.processEvents
		end		
		
		@ui.progress.reset
		status 'OK'
	end

	##
	# Обновить базу
	def on_action_update_storage_triggered
		return unless confirm? 'Update storage'
		status 'Update storage'
		@ui.update_result.clear
		@ui.progress.setMaximum @storage.size

		@book_finder.update_storage do |i, action, book_title|
			@ui.progress.setValue i

			columns = [i.to_s, action.to_s, book_title]
			it = Qt::TreeWidgetItem.new(columns)
			@ui.update_result.addTopLevelItem it

			$qApp.processEvents
		end
		@ui.progress.reset
		status 'OK'
	end

	##
	# Поиск по фразе в строке поиска
	def on_book_search
		status 'Book search'

		str = @ui.search_filter.text
		str.gsub!(/[^\w]/, ' ')
		patterns = str.split(/[\s]+/).select {|word| word.jlength >= @ui.search_min_word.value }
		str = patterns.join ' '
		@ui.search_filter.setText str

		# Результаты
		books = @storage.find(patterns)
		show_search_results books

		status 'OK'
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
		@ui.search_page.setText "#{@storage.current_page}"
		@ui.search_result.clear
		books.each do |book|
			#pp book
			show_book(@ui.search_result, book)
		end
	end

	##
	# Добавить информацию об одной книге в таблицу
	def show_book(tree_widget, book)
	    it = create_tree_item(book)
		file_item = tree_widget.findItems(book.file_path, Qt::MatchExactly, 3)
		if file_item.empty?
			tree_widget.addTopLevelItem it
		else
			# Файлы в архиве под одним элементов
			parent_item = file_item.first
			parent_item_size = parent_item.data(COLUMN_SIZE, SIZE_ROLE).toULongLong

			if book.size > parent_item_size
				tree_widget.addTopLevelItem it
				while parent_item.childCount > 0
					it.addChild(parent_item.takeChild(0))
				end
				parent_index = tree_widget.indexOfTopLevelItem(parent_item)
				tree_widget.takeTopLevelItem(parent_index)
				it.addChild(parent_item)
			else
				parent_item.addChild it
			end
		end
	end

	# Добавить информацию об одной книге в таблицу
	def show_duplicate(tree_widget, book, duplicates = [])
		it = create_tree_item book
		tree_widget.addTopLevelItem it

		duplicates.each do |book_dup|
			dup_it = create_tree_item(book_dup)
			it.addChild dup_it
		end
		it.setExpanded true
	end

	##
	# Создать элемент для дерева
	def create_tree_item(book)
		size = book.size.to_s.align_right(12)
		size.gsub!(/(.{3})/, ' \1')
		columns = [book.title, size, book.last_modified.strftime('%Y-%m-%d %H:%M'), '%X' % book.crc, book.file_path, book.title_path]
		it = Qt::TreeWidgetItem.new(columns)
		#it = BookItem.new(columns)
		it.setTextAlignment(COLUMN_SIZE, Qt::AlignRight)
		it.setTextAlignment(COLUMN_TIME, Qt::AlignCenter)
		it.setData(COLUMN_SIZE, SIZE_ROLE, Qt::Variant.new(book.size))
		it
	end

	##
	# Удалить файлы выбранные в таблице результатов поиска
	def on_action_delete_files_triggered
		until (all = @ui.duplicates_result.selectedItems).empty?
			it = all.first
			file_path = it.text(COLUMN_FILE_PATH)
			begin
				File.delete to_win(file_path)
			rescue => ex
				save_error ex
				break
				#TODO Переход на следующий элемент
			else
				puts "deleted: #{file_path}"
				# Удалить из таблицы
				it.dispose
			end
		end
	end

	##
	# Вставить текст из буфера в строку поиска
	def on_action_search_from_clipboard_triggered
		@ui.search_filter.setText(Qt::Application.clipboard.text)
		@ui.search_filter.setFocus

		# Сразу делать поиск
		on_book_search
	end

  ##
	# Открыть документ или архив
	def on_search_result_itemDoubleClicked(it, column)
		url = Qt::Url.new("file:///" + it.text(COLUMN_FILE_PATH));
		Qt::DesktopServices::openUrl(url);
	end

	##
	# Открыть документ или архив
	def on_duplicates_result_itemDoubleClicked(it, column)
		url = Qt::Url.new("file:///" + it.text(COLUMN_FILE_PATH));
		Qt::DesktopServices::openUrl(url);
	end

	##
	# Список всех вложенных файлов
  def on_duplicates_result_currentItemChanged(current, prev)
	  @ui.file_content.clear
	  if current
	    file_path_utf8 = current.text(COLUMN_FILE_PATH)

	    # Показать содержание файла
		  @storage.file_content(file_path_utf8).each do |book|
			  show_book(@ui.file_content, book)
		  end
		end
  end
end
