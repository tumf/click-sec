#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..')))
require 'stocktrade'
require 'stocktrade/clicksec/base'

module StockTrade::ClickSec
  class Board < Base

    include StockTrade
    include StockTrade::ClickSec

    def initialize
      super
      @boards = {}
    end

    def self.get code
      o = new
      o.get code
    end

    def get code
      @agent ||= Mechanize.new
      login unless login?
      page = page_by_code code
      @boards[code] = 
        {:price => parse_price(page), :unit => parse_unit(page), :board => parse_board(page), :action => parse_action(page) }
      @boards[code].merge!(parse_volume(page))
    end

    def price code
      @boards[code] ||= get(code)
      @boards[code][:price]
    end

    def unit code
      @boards[code] ||= get(code)
      @boards[code][:unit]
    end

    def action code
      @boards[code] ||= get(code)
      @boards[code][:action]
    end

    def board code
      @boards[code] ||= get(code)
      @boards[code][:board]
    end

    def asks code
      @boards[code] ||= get(code)
      @boards[code][:board].collect { |v|
        [v[:price], v[:ask]] if v[:ask] > 0
      }.compact
    end

    def bids code
      @boards[code] ||= get(code)
      @boards[code][:board].collect { |v|
        [v[:price], v[:bid]] if v[:bid] > 0
      }.compact
    end

    def vwap code
      @boards[code] ||= get(code)
      return nil unless @boards[code][:turnover]
      @boards[code][:turnover] / @boards[code][:volume].to_f
    end

    def avg_price code
      unless asks(code).size == bids(code).size
        return nil
      end

      sum = 0.0
      size = 0
      asks(code).each { |ask|
        sum += ask[0] * ask[1]
        size += ask[1]
      }
      bids(code).each { |bid|
        sum += bid[0] * bid[1]
        size += bid[1]
      }
      sum / size
    end

    def ask_price code
      ask = asks(code).min { |a,b| a[0] <=> b[0] }
      return nil unless ask
      ask[0]
    end

    def ask_max_volume_price code
      ask = asks(code).max { |a,b| a[1] <=> b[1] }
      return nil unless ask
      ask[0]
    end
    def bid_max_volume_price code
      bid = bids(code).max { |a,b| a[1] <=> b[1] }
      return nil unless bid
      bid[0]
    end

    def bid_price code
      bid = bids(code).max { |a,b| a[0] <=> b[0] }
      return nil unless bid
      bid[0]
    end

    def parse_board page
      keh = []
      # area
      begin
        (1..16).each { |n|
          price = page.at("#board_price_#{n}").inner_text.split(",").join.to_i
          ask = page.at("#ask_volume_#{n}").inner_text.split(",").join.to_i
          bid = page.at("#bid_volume_#{n}").inner_text.split(",").join.to_i
          keh << {:price => price , :ask => ask, :bid => bid }
        }
      rescue
      end
      keh
    end

    def parse_price page
      v = page.at('table#genzaine_front td.genzai span.value')
      v.inner_text.split(",").join.to_i if v
    end

    def parse_unit page
      # if /株数単位：([\d,]+)株/ =~ page.body.toutf8
      if /var baibaiTani = ([\d,]+);/ =~ page.body.toutf8
        return $1.split(',').join.to_i
      end
    end

    def parse_action page
      if /信用規制\[新規\]/ =~ page.body.toutf8
        return {:buy => false, :sell => false} 
      end

      if /span class="shinyou_kbn_seido">制度信用（買）</ =~ page.body.toutf8
        return {:buy => true, :sell => false}
      end
      if /span class="shinyou_kbn_seido">制度信用（買・売）</ =~ page.body.toutf8
        return {:buy => true, :sell => true}
      end

      return {:buy => false, :sell => false}
    end

    def parse_volume page
      vol = nil; turnover = nil
      page.search("tr").each { |tr|
        if /出来高\n\t\t([\d,]+)株/ =~ tr.inner_text.toutf8
          vol = $1.split(/,/).join.to_i 
        end
        if /売買代金\n\t\t([\d,]+)円/ =~ tr.inner_text.toutf8
          turnover = $1.split(/,/).join.to_i 
        end
      }
      { :volume => vol, :turnover => turnover}
    end
  end
end
if $0 == __FILE__
  StockTrade::ClickSec::Board.new { |board|
    board.logout
  }
  exit
end
