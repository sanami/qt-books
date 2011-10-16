require File.dirname(__FILE__) + '/config.rb'

require 'app.rb'

app = App.new
#app.run :gui
#app.run :console
app.run
