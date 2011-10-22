require 'spec_helper'
require 'process_dir.rb'

describe 'process_dir' do

	it "should count folders" do
		all = process_dir(TEST_DIR, :count) do |action, file_path|
			action.should == :count
			pp file_path
		end
		all.should be > 0
	end

	it "should call action for each file" do
		all = []
		process_dir(TEST_DIR, :list) do |action, file_path|
			#pp action, file_path
			pp File.basename file_path
			all << file_path
		end
		all.should_not be_empty
	end

end

