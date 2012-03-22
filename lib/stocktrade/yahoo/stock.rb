#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..')))
require 'stocktrade'
require 'mechanize'
require 'pstore'

module StockTrade::Yahoo
  class Stock
    attr_reader :code, :name, :unit
    include StockTrade

    def filename
      File.join(RUNDIR,"stocks.db")
    end

    def initialize code = nil
      get(code) if code
      yield self if block_given?
    end

    def root_url
      "http://stocks.finance.yahoo.co.jp"
    end

    def url code
      "#{root_url}/stocks/detail/?code=#{code}"
    end

    def get code
      @code = code
      begin
        @sotck = cache(code)
      rescue => e
        raise "get error code: #{code}"
      end

      @name = @sotck[:name]
      @unit = @sotck[:unit]
    end

    def cache code
      PStore.new(filename).transaction { |db|
        db[:cache] ||= {}
        if db[:cache].include?(code) and 
            db[:cache][code][:expired_at] > Time.now and
            db[:cache][code][:unit]
          return db[:cache][code]
        end
        stock = load(code)
        stock[:expired_at] = Time.now + 60 * 60 * 24
        db[:cache][code] = stock
        return stock
      }

    end

    def parse page
      title = page.at("title").text.toutf8
      if /(.+)【(\d{4})】/ =~ title
        name = $1
        code = $2
      end
      unit = nil
      #　<dd class="ymuiEditLink mar0"><strong>---</strong>株</dd>
      page.search("div.lineFi").each { |div|
        if /単元株数/ =~ div.text.toutf8
          unit = div.at("dd.ymuiEditLink").text.toutf8.split(',').join.to_i
          unit = 1 if unit == 0
        end
      }
      {:name => name, :code => code, :unit => unit}
    end

    def load code
      @agent ||= Mechanize.new
      @agent.get(url(code))
      parse(@agent.page)
    end

    def to_s
      "#{@code} #{@name}"
    end

  end
end

if $0 == __FILE__
  codes = StockTrade::Yahoo::Ranking.get("売買代金上位",1)
  codes.each { |code|
    stock = StockTrade::Yahoo::Stock.new(code)
    puts stock
  }
end
