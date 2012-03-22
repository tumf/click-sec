#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift(File.join(File.dirname(__FILE__),'..','..'))
require 'stocktrade'
require "rexml/document"
require 'mechanize'
require 'logger'
require "keystorage"
require 'kconv'
require 'json'

module StockTrade::ClickSec
  class Base

    include StockTrade
    include StockTrade::ClickSec

    def initialize
      @agent = Mechanize.new
      @agent.user_agent_alias = 'Windows Mozilla'
      @agent.log = Logger.new(File.join(LOGDIR,"access.log"))
      @agent.log.level = Logger::INFO
      @agent.max_history = 1
      yield self if block_given?
    end

    def url file
      "https://kabu.click-sec.com/%s/%s" % [@sec,file]
    end

    def page_by_code code
      @agent ||= Mechanize.new
      @agent.get(url_by_code(code))
    end

    def page_param page
      html = page.body.toutf8 if page.is_a? Mechanize::Page
      html = page.to_s.toutf8 if page.is_a? Nokogiri::HTML::Document
      html ||= page

      s = html.scan(/\/subwindow\/indexDatetime\.do\?marketCode=(\d+)&securityCode=(\d+)/)
      { 
        :securityCode => s[0][1],
        :meigaraCode => html.scan(/<input type="hidden" name="meigaraCode" value="(\d+)" id="meigaraCode">/)[0][0],
        :marketCode => s[0][0]
      }
    end

    def url_by_code code
      url "kabu/meigaraInfo.do?securityCode=%d" % [code]
    end

    def order_url
      url "wpi/kabu/orderCommit.do"
    end

    def login
      @agent ||= Mechanize.new
      @agent.get("https://sec-sso.click-sec.com/loginweb/sso-redirect") { |page|
        unless login?
          page.form_with(:name => 'loginForm') { |form|
            form.field_with(:name => 'j_username').value = ACCOUNT
            form.field_with(:name => 'j_password').value = Keystorage.get("clicksec",ACCOUNT)
            form.click_button
          }
          @sec = @agent.page.uri.to_s.scan(/\/(sec\d+-\d+)\//)[0][0]
        end
      }
      raise "LOGIN FAILED"  unless login?
    end

    def login?
      return false unless @agent.page and @sec
      # /#{USERNAME}/ =~ @agent.page.body.toutf8
      true
    end

    def logout
      @agent ||= Mechanize.new
      @agent.get("https://sec-sso.click-sec.com/loginweb/sso-logout") if login?
    end


  end
end
