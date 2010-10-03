$:.unshift File.expand_path('../../lib', __FILE__)
$:.unshift File.expand_path('..', __FILE__)

require 'rubygems'
require 'ruby-debug'
require 'test/unit'
require 'mocha'
require 'test_declarative'
require 'pathname'
require 'fileutils'
require 'deliminator'

module Mocks
  class Buffer < Array
    def initialize
      super
      self << nil
    end
  end

  class Window
    attr_accessor :buffer, :cursor

    def initialize
      @buffer = Buffer.new
      @cursor = [1, 0]
    end
  end
end
