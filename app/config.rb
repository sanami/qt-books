require 'rubygems'
require 'ostruct'
require 'pp'
require 'pathname'

require 'bundler'
Bundler.require

ROOT_PATH = Pathname.new File.expand_path('../../', __FILE__)

def ROOT(file)
	ROOT_PATH + file
end

# Ensure existing folders
['db', 'config', 'log', 'tmp'].each do |path|
	FileUtils.mkpath ROOT(path)
end

# Required folders
['app', 'app/db', 'lib'].each do |folder|
	$: << ROOT(folder)
end
#pp $:

# Search for shared folder
path = Pathname.new(File.dirname(__FILE__))
name = 'shared'

depth = 0
dir = path + name
until dir.directory?
	depth += 1
	raise "#{name} no found" if depth > 10

	path = path.parent
	dir = path + name
end

#pp dir

# Required files
['misc.rb', 'qt/misc.rb', 'settings.rb'].each do |file_name|
# ['misc.rb', 'settings.rb'].each do |file_name|
	require dir + file_name
end



#$console_codec = 'ibm866' # Для работы из командной строки
#$debug = true # Нет диалога закрытия
#Qt.debug_level = Qt::DebugLevel::Minimal
