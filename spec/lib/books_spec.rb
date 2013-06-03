require 'spec_helper'
require 'books.rb'

describe Books do
  subject { Books.new }

  it "should load" do
    pp subject.status_message
  end

  it "should find_in_folder" do
    all = []
    folder = '/home/sa/Books/ruby'
    rx_pattern = /best/i
    subject.find_in_folder(all, folder, rx_pattern)
    pp all
  end

  it "should fix_books" do
    folder = '/home/sa/Books/ruby'
    subject.fix_books(folder)

  end

end

