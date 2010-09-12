require 'misc.rb'
require 'optparse'
require 'form.rb'

$debug = true  # Нет диалога закрытия
Qt.debug_level = Qt::DebugLevel::Minimal

##
# Настройки из коммандной строки
def parse_cmd_line
	options = OpenStruct.new
	options.run_mode = :test

	opts = OptionParser.new do |opts|
		opts.banner = "Usage: #$0 [options]"

		opts.on('-c', '--codec [ ibm866, utf-8 ]', 'console output codec') do |str|
			$console_codec = str.downcase
		end

		opts.on_tail('-h', '--help', 'display this help and exit') do
			puts opts
			exit
		end
	end

	opts.parse! ARGV
	options
end

# Старт
begin
	options = parse_cmd_line

	$app = Qt::Application.new(ARGV)
	init_codec
	form = Form.new
	form.show
	$app.exec

rescue => ex
	save_error ex
end
