#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..')))
require 'stocktrade'
require 'mechanize'

module StockTrade::Yahoo
  class Ranking
    def initialize
      yield self if block_given?
    end

    def root_url
      "http://stocks.finance.yahoo.co.jp/"
    end

    def get object,to
      codes = []
      @agent ||= Mechanize.new
      @agent.get(root_url) { |page|
        @agent.page.link_with(:text => "株式ランキング").click

        page = @agent.page
        unless object == "値上がり率"
          page = @agent.page.link_with(:text => object).click
        end

        (2..to+1).each { |n|
          raise "PAGE Not Found" unless page
          page.links_with(:text => /\d{4}/).each { |link|
            codes << link.text
          }
          link = page.link_with(:text => n.to_s)
          break unless link
          page = link.click
        }
      }
      codes.uniq
    end

    def self.get object,to
      new.get(object,to)
    end

  end
end

if $0 == __FILE__
  p StockTrade::Yahoo::Ranking.get("売買代金上位",3)
  StockTrade::Yahoo::Ranking.new { |ranking|
    p ranking.get "売買代金上位",3
  }
  exit 0
end
