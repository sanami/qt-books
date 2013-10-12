require 'spec_helper'
require 'process_dir.rb'

describe 'process_dir' do

  it "should count folders" do
    #dir = ROOT('1/testcases')
    dir = ROOT('1/testcases_ln')

    all = process_dir(dir, :count) do |action, file_path|
      action.should == :count
      pp file_path
    end
    all.should be > 1
  end

  it "should call action for each file" do
    #dir = ROOT('1/testcases')
    dir = ROOT('1/testcases_ln')

    all = []
    process_dir(dir, :list) do |action, file_path|
      pp action, file_path
      pp File.basename file_path
      all << file_path
    end
    all.count.should be > 5
  end

end

