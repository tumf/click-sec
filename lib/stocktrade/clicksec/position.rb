# -*- coding: utf-8 -*-
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..')))
require 'stocktrade'
require 'stocktrade/clicksec/base'
require 'stocktrade/yahoo/stock'

module StockTrade::ClickSec

  class Position < Base
    include StockTrade
    include StockTrade::ClickSec

    def opens_url
      url "kabu/tatePositionList.do?currentPageNumber=-1"
    end

    def opens_page
      login unless login?
      @agent.get(opens_url)
      @agent.page
    end

    def num_of_key page,key
      page.search("tr").each { |tr|
        if /positionKey: '#{key}'/ =~ tr.to_s
          if /rowspan="(\d+)"/ =~ tr.to_s
            i = 5
          else
            i = 1
          end
          # p key
          return tr.search("td")[i].inner_text.scan(/[\d,]+/)[0].split(/,/).join.to_i
          # break
        end
      }
      nil
    end

    def tate_of_key page,key,dir
      page.search("tr").each { |tr|
        if /positionKey: '#{key}'/ =~ tr.to_s
          if /rowspan="(\d+)"/ =~ tr.to_s
            i = 5
          else
            i = 1
          end
          dir = :buy if dir == nil and /買建/ =~ tr.inner_text
          dir = :sel if dir == nil and /売建/ =~ tr.inner_text
          	  
          return {
            :dir => dir,
            :num => tr.search("td")[i].inner_text.scan(/[\d,]+/)[0].split(/,/).join.to_i,
            :open_price => tr.search("td")[i+1].inner_text.scan(/[\d,]+/)[0].split(/,/).join.to_i,
            :price => tr.search("td")[i+1].inner_text.scan(/[\d,]+/)[1].split(/,/).join.to_i
          }
          # break
        end
      }
      nil
    end
    
    
    def opens
      login unless login?
      res = {}
      keys = []
      page = opens_page
      page.search("tr").each { |tr|
        a = tr.at("a")
        if a
          code = a.inner_text.toutf8.scan(/\d{4}/)[0]
          if code
            tr.search("input[@type=hidden]").each { |el|
              res[code] ||= {}
              key = el.attr("value")
              keys << key
              res[code][:keys] ||= {}
              res[code][:keys][key] = tate_of_key(page,key,res[code][:dir])
              res[code][:price] = res[code][:keys][key][:price]
            }
          end
        end
      }

      res.each { |code,pos|
        num = 0;sum = 0;dir = nil
        pos[:keys].each { |key,line|
          num += line[:num]
          sum += line[:num] * line[:open_price]
          dir = line[:dir] if line[:dir] #!!
        }
        res[code][:dir] = dir
        res[code][:num] = num
        res[code][:sum] = sum
        res[code][:profit] = res[code][:price] * num - sum
        if dir == :sel
          res[code][:profit] = -res[code][:profit]
        end
        res[code][:profit_rate] = res[code][:profit] / sum.to_f
        res[code][:open_price] = sum / num.to_f
      }

      res
    end

    def close code
      login unless login?
      pos = opens[code]
      raise Alert.new("No position of #{code}") unless pos

      close_url = (url "tb/kabu/order.do")
      req = order_request_default
      page = page_by_code(code)
      req.merge! page_param(page)
      i = 0
      num = 0
      req["jyuchuuSuuryo"] = pos[:num]
      req["limitPrice"] =  ""
      req["marketOrder"] = "true" # 成行

      if pos[:dir] == :sel
        req["torihikiKbn"] = "22" # 返済
        req["baibaiKbn"] = "2" # 売り
      else
        req["torihikiKbn"] = "22" # 返済
        req["baibaiKbn"] = "1" # 買い
      end

      req["pinCode"] = Keystorage.get("clicksec-pin",ACCOUNT)
      # req["omitConfirm"] = 1
      # p req
      @agent.post(close_url,req)
      puts @agent.page.body.toutf8
    end

    def capacity
      login unless login?
      @agent.get(url("kabu/powerAmountUserSheet.do")) { |page|
        page.search(".blue tr").each { |tr|
          if /信用新規建余力/ =~ tr.to_s.toutf8
            return  tr.at("td.txa_r").inner_text.scan(/[-\d,]+/)[0].split(",").join.to_i
          end
        }
      }
      false
    end

    def trade dir,code,num = nil,price = nil
      num = Yahoo::Stock.new(code).unit unless num

      login unless login?
      page = page_by_code(code)
      req = order_request(page_param(page),dir,price,num)
      @agent.post(order_url,req)
      doc = REXML::Document.new(@agent.page.body.toutf8)
      doc.elements.each("/orderResponse/responseStatus") { |e|
        return true if /OK/ =~ e.text
        puts e.text
      }
      doc.elements.each("/orderResponse/messageList/message") { |e|
        raise e.text
      }
    end
    
    def buy code,num = nil,price = nil
      trade :buy,code,num,price
    end

    def sell code,num = nil,price =nil
      trade :sel,code,num,price
    end

    def order_request_default
      {
        "agreeInsiderOrder" => "false",
        # 有効期限: 当日
        "invalidDate" => "1",
        # 口座区分: 特定
        "kouzaKbn" => "2",
        # PIN
        "pinCode" => Keystorage.get("clicksec-pin",ACCOUNT),
        # 執行区分: 01 なし
        "shikkouKbn" => "01",
        # 信用区分: 1 制度信用
        "shinyouKbn" =>	"1",
        # 以下不詳:
        "syohinKbn" => "10",
        "torihikiKbn" => "21",
      }
    end

    def order_request req,dir,price,num
      req.merge! order_request_default
      if dir == :buy
        req[:baibaiKbn] = "2"
      elsif dir == :sel
        req[:baibaiKbn] = "1"
      end

      if price
        req[:limitPrice] = price
        req["marketOrder"] = "false"
      else
        #　成行？
        req["marketOrder"] = "true"
        req[:limitPrice] = ""
      end

      req[:jyuchuuSuuryo] = num
      req
    end
  end
end

if $0 == __FILE__

  StockTrade::ClickSec::Position.new { |pos|
    pos.opens.each { |code,pos|
      name = StockTrade::Yahoo::Stock.new(code).name
      puts "%s %s %s@%0.2f %s(%0.2f%%)" % [code,name,pos[:num].to_currency,pos[:open_price],
                                           pos[:profit].to_currency,pos[:profit_rate]*100]
    }
  }

end
