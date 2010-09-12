require 'rubygems'
require 'facets/dictionary'
require 'facets/string'
require 'ostruct'
require 'active_record'
require 'will_paginate'

# Без этого не работает
WillPaginate.enable_activerecord

# Search for required files
required_files = ['qmisc.rb', 'settings.rb']

dir_name = '_shared/'
depth = 0
until File.exists? dir_name
	dir_name = '../' + dir_name
	depth += 1
	throw "#{dir_name} no found" if depth > 10
end

required_files.each do |file_name|
	require dir_name + file_name
end
