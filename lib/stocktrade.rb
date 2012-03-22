#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "bundler/setup"

module StockTrade
  LOGDIR=File.join(File.dirname(__FILE__),'..','log')
  RUNDIR=File.join(File.dirname(__FILE__),'..','run')
  module ClickSec
    ACCOUNT = ENV['STOCKTRADE_ACCOUNT']
    USERNAME = ENV['STOCKTRADE_USERNAME']
  end

  class Alert < Exception;end

end

if RUBY_VERSION < '1.9.0'
  class Array
    def choice
      at(rand(size))
    end
    def pickup n=1
      result = []
      return self if size <= n
      while(result.size < n)
        result << choice
        result.uniq!
      end
      result
    end
  end
end

class Integer
  def to_currency
    self.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end
end

class String
  def is_code?
    /\d{4}/ =~ self
  end
end

module StockTrade

  def log text
    puts "%s %s" % [Time.now.iso8601,text]
  end

  def diff_rate(value,base)
    return nil unless value and base
    (value-base)/base.to_f
  end

end


