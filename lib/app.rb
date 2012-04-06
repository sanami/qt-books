require 'optparse'
require 'books.rb'

class App

  def initialize
    parse_cmd_line

    @settings = Settings.new(ROOT('config/settings.yaml'))
    @books = Books.new(ROOT('db/storage.yaml'), ROOT('db/storage_old.yaml'))
  end

  ##
  # Старт
  def run(run_mode = nil)
    case run_mode || @options.run_mode
      when :gui
        run_gui
      when :console
        run_console
      else
        puts @cmd_line_opts
    end

    @settings.save
  end

private

  ##
  # Настройки из командной строки
  def parse_cmd_line
    @options = OpenStruct.new
    @cmd_line_opts = OptionParser.new do |opts|
      opts.banner = "Usage: #$0 [options]"

      opts.on('-c', '--codec [ ibm866, utf-8 ]', 'console output codec') do |str|
        $console_codec = str.downcase
      end

      opts.on('-m', '--mode [ console, gui ]', 'run mode: console, gui') do |str|
        @options.run_mode = str.downcase.to_sym
      end

      #opts.on('-p', '--path ../ ', 'work folder') do |str|
      #	@options.pics_path = str
      #end

      opts.on_tail('-h', '--help', 'display this help and exit') do
        puts opts
        exit
      end
    end

    @cmd_line_opts.parse!
  end

  ##
  # Консольный режим
  def run_console
  end

  ##
  # GUI режим
  def run_gui()
    require 'form.rb'

    app = Qt::Application.new(ARGV)
    Qt::init_codec
    form = Form.new @settings, @books
    form.show
    app.exec
    puts "app.exec done"
  end

end
