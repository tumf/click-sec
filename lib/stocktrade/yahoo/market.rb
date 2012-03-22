#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..')))
require 'stocktrade'
require 'stocktrade/market'

require 'mechanize'
require 'chronic'

=begin
StockTrade::Yahoo::Market::open?
=end
module StockTrade::Yahoo
  class Market

    def initialize
      yield self if block_given?
    end
    # 取引可能か？
    def self.active?
      return false unless open?
      StockTrade::Market.active?
    end

    def self.wait
      while !active?
        return if $STOP
        sleep 60
      end
    end

    def self.get url
      Mechanize.new { |agent|
        agent.get(url) { |page|
          return page.body
        }
      }
      raise "Page Not Found."
    end

    def self.open?
      if Time.now <= Chronic::parse("today 8:50") or
          Time.now >= Chronic::parse("today 15:10")
        return false
      end

      return / -- 日本の証券市場はあと(.*)で終了します。/ =~ get("http://finance.yahoo.co.jp/") ? true :false
    end

  end
end


if $0 == __FILE__
  p StockTrade::Yahoo::Market.open?
  p StockTrade::Yahoo::Market.active?
end
