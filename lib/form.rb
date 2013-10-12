Qt::require ROOT('resources/form.ui'), ROOT('tmp')
Qt::require ROOT('resources/resources.qrc'), ROOT('tmp')

# Колонки дерева результата поиска
COLUMN_SIZE = 0
COLUMN_TITLE = 1
COLUMN_FILE_PATH = 2
COLUMN_TIME = 3
COLUMN_CRC = 4
COLUMN_TITLE_PATH = 5

SIZE_ROLE = Qt::UserRole + 1

# Главное окно приложения
class Form < Qt::MainWindow
  slots 'on_action_quit_triggered()'
  slots 'on_action_new_triggered()'
  slots 'on_action_open_triggered()'
  slots 'on_action_save_as_triggered()'
  slots 'on_action_add_folder_to_storage_triggered()'
  slots 'on_action_fix_names_triggered()'

  slots 'on_action_delete_files_triggered()'
  slots 'on_action_search_from_clipboard_triggered()'
  slots 'on_book_search()'
  slots 'on_search_result_itemDoubleClicked(QTreeWidgetItem *, int)'

  slots 'on_search_filter_activate()'


  def initialize(settings, storage)
    super()
    init_ui

    @storage = storage

    # Загрузить настройки
    @settings = settings
    load_settings

    status 'Ready'
  end

protected
  # Не должен быть private
  def closeEvent(e)
    unless $debug
      if Qt::MessageBox::question(self, "Confirm Exit", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) != Qt::MessageBox::Ok
        e.ignore
        return
      end
    end

    # Сохранить настройки
    save_settings
    super
    puts "closeEvent"
    $qApp.quit
  end

  # Autofocus search field
  def changeEvent(e)
    if e.type == Qt::Event::ActivationChange
      #pp "#changeEvent #{isActiveWindow}"
      if isActiveWindow
        on_search_filter_activate
      end
    end
    super
  end

private
  # Инициализация GUI
  def init_ui
    @ui = Ui::MainWindow.new
    @ui.setupUi(self)
    #Qt::optimize_layouts self

    resize(1000, 600)
    move(0, 0)
    setWindowIcon(Qt::Icon.new(':/resources/app.ico'))
    setWindowTitle 'Books'

    # Дерево результатов поиска
    @ui.search_result.setColumnWidth(COLUMN_SIZE, 150)
    @ui.search_result.setColumnWidth(COLUMN_TITLE, 500)
    @ui.search_result.setColumnWidth(COLUMN_FILE_PATH, 500)
    @ui.search_result.setColumnWidth(COLUMN_TITLE_PATH, 500)

    @ui.search_result_old.setColumnWidth(COLUMN_SIZE, 150)
    @ui.search_result_old.setColumnWidth(COLUMN_TITLE, 500)
    @ui.search_result_old.setColumnWidth(COLUMN_FILE_PATH, 500)

    # Строка поиска
    connect(@ui.search, SIGNAL('clicked()'), SLOT('on_book_search()'))
    connect(@ui.search_filter, SIGNAL('returnPressed()'), SLOT('on_book_search()'))

#		statusBar.addPermanentWidget(ui.messages, 100);
#		statusBar.addPermanentWidget(ui.newsCount);
    statusBar.addPermanentWidget(@ui.progress)

    # ESC сворачивает окно
    a = Qt::Action.new(self)
    a.setShortcut(Qt::KeySequence.new(Qt::Key_Escape))
    connect(a, SIGNAL('triggered()'), SLOT('showMinimized()'))
    addAction(a)

    # CTRL+E фокус на строку поиска
    a = Qt::Action.new(self)
    a.setShortcut(Qt::KeySequence.new(Qt::Key_E + Qt::CTRL))
    connect(a, SIGNAL('triggered()'), SLOT('on_search_filter_activate()'))
    addAction(a)

    # Вставка из буфера
    addAction(@ui.action_search_from_clipboard)
  end

  # Запрос подтверждения
  def confirm?(message)
    Qt::MessageBox::question(self, "Confirm", message, Qt::MessageBox::Ok, Qt::MessageBox::Cancel) == Qt::MessageBox::Ok
  end

  # Storage status
  def status(msg)
    statusBar.showMessage "#{msg}. #{@storage.status_message}"
  end

  # Загрузка и применение настроек
  def load_settings
    if @settings.form_geometry
      self.restoreGeometry Qt::ByteArray.new(@settings.form_geometry.to_s)
    end

    @ui.live_folders.setPlainText @settings.live_folders
  end

  # Сохранение настроек
  def save_settings
    @settings.form_geometry = self.saveGeometry.to_s

    @settings.live_folders = @ui.live_folders.toPlainText
  end

  # Выйти из программы
  def on_action_quit_triggered
    $qApp.quit
  end

  # Reset storage
  def on_action_new_triggered
    @storage.clear
    status 'Cleared'
  end

  # Add saved db to storage
  def on_action_open_triggered
    @settings.storage_dir ||= '.'
    file_name = Qt::FileDialog::getOpenFileName(self, "Open File", @settings.storage_dir)
    if file_name
      @settings.storage_dir = File.dirname file_name
      @storage.load(file_name)

      status 'Loaded'
    end
  end

  # Save storage to db file
  def on_action_save_as_triggered
    @settings.storage_dir ||= '.'
    file_name = Qt::FileDialog::getSaveFileName(self, "Save File", @settings.storage_dir)
    if file_name
      @settings.storage_dir = File.dirname file_name
      @storage.save(file_name)

      status 'Saved'
    end
  end

  # Add files from folder to storage
  def on_action_add_folder_to_storage_triggered
    @settings.scan_dir ||= '.'

    dir_path = Qt::FileDialog::getExistingDirectory(self, "Open Dir", @settings.scan_dir)
    if dir_path
      init_progress dir_path
      @settings.scan_dir = dir_path

      @storage.add_books(dir_path) do |action, file_path|
        #pp file_path
        update_progress
        $qApp.processEvents
      end

      status 'Loaded'
    end
  end

  # Fix file names
  def on_action_fix_names_triggered
    @settings.scan_dir ||= '.'

    dir_path = Qt::FileDialog::getExistingDirectory(self, "Open Dir", @settings.scan_dir)
    if dir_path
      init_progress dir_path

      @storage.fix_books(dir_path) do |action, file_path|
        #pp file_path
        update_progress
        $qApp.processEvents
      end

      status 'Done'
    end
  end

  # Вставить текст из буфера в строку поиска
  def on_action_search_from_clipboard_triggered
    @ui.search_filter.setText(Qt::Application.clipboard.text)
    @ui.search_filter.setFocus

    # Сразу делать поиск
    on_book_search
  end

  # Открыть документ или архив
  def on_search_result_itemDoubleClicked(it, column)
    url = Qt::Url.fromLocalFile(it.text(COLUMN_FILE_PATH))
    Qt::DesktopServices::openUrl(url)
  end

  # Инициализировать прогресс бар
  def init_progress(dir_path_list, fast = false)
    if fast
      status ''
      @ui.progress.setMaximum 1000
      @ui.progress.setValue(0)
    else
      dir_path_list = [dir_path_list] unless dir_path_list.is_a?(Enumerable)

      # Посчитать кол-во каталогов
      status 'Counting folders...'
      @ui.progress.setMaximum 1000
      @ui.progress.setValue(0)

      dir_count = 0
      dir_path_list.each do |dir_path|
        dir_count += process_dir(dir_path, :count) do |action, obj|
          @ui.progress.setValue(@ui.progress.value+1)

          $qApp.processEvents
        end
      end

      @ui.progress.setValue(0)
      @ui.progress.setMaximum dir_count
      status "Total folders: #{dir_count}"
    end
  end

  # Обновить прогресс
  def update_progress
    @ui.progress.setValue(@ui.progress.value+1)
  end

  # Поиск по фразе в строке поиска
  def on_book_search
    status 'Book search'

    search_str = @ui.search_filter.text
    search_str.gsub!('_', ' ') # part of \w
    search_str.gsub!(/[^\w]/, ' ')
    patterns = search_str.split(/[\s]+/).select {|word| word.length >= @ui.search_min_word.value }
    search_str = patterns.join ' '
    @ui.search_filter.setText search_str
    @ui.search_filter.selectAll

    live_folders = @ui.live_folders.toPlainText.split "\n"
    #pp live_folders
    # Update subfolders count
    init_progress(live_folders, true)

    unless patterns.empty?
      # Результаты
      books = @storage.find(patterns, true, live_folders) do |action, file_path|
        #pp file_path
        update_progress
        $qApp.processEvents
      end

      @ui.search_result.clear
      books.each do |book|
        #pp book
        show_book(@ui.search_result, book)
        $qApp.processEvents
      end

      books = @storage.find(patterns, false)

      @ui.search_result_old.clear
      books.each do |book|
        #pp book
        show_book(@ui.search_result_old, book)
        $qApp.processEvents
      end
    end

    if @ui.search_result.topLevelItemCount == 0
      Qt::TreeWidgetItem.new(@ui.search_result, ['not found', search_str])
    end
    status "Done: #{search_str}"
  end

  # Добавить информацию об одной книге в таблицу
  def show_book(tree_widget, book)
    it = create_tree_item(book)
    file_item = tree_widget.findItems(book['file_path'], Qt::MatchExactly, 2)
    if file_item.empty?
      tree_widget.addTopLevelItem it
    else
      # Файлы в архиве под одним элементов
      parent_item = file_item.first
      #pp parent_item.data(COLUMN_SIZE, SIZE_ROLE)
      parent_item_size = parent_item.data(COLUMN_SIZE, SIZE_ROLE).toInt

      if book['size'] > parent_item_size
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

  # Создать элемент для дерева
  def create_tree_item(book)
    size = book['size'].to_s.rjust(9)
    size.gsub!(/(.{3})/, ' \1')
    #columns = [ book['title'], size, book['last_modified'].strftime('%Y-%m-%d %H:%M'), '%X' % book['crc'], book['file_path'], book['title_path'] ]
    columns = [ size, book['title'], book['file_path'] ]
    it = Qt::TreeWidgetItem.new(columns)
    #it = BookItem.new(columns)
    it.setTextAlignment(COLUMN_SIZE, Qt::AlignRight)
    it.setTextAlignment(COLUMN_TIME, Qt::AlignCenter)
    it.setData(COLUMN_SIZE, SIZE_ROLE, Qt::Variant.new(book['size']))
    it
  end

  # Set focus and select text for replace by copy/paste
  def on_search_filter_activate
    @ui.search_filter.setFocus
    @ui.search_filter.selectAll
  end

end
