#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'scraperwiki'
require 'scraped'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def date_from(str)
  return if str.to_s.empty?
  return Date.parse(str).to_s rescue nil
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('.//h2[a[@id="HKMembers"]]/following-sibling::div[@class="ms-rtestate-read ms-rte-wpbox"]//div[@class="link-item"]/a/@href').each do |m|
    scrape_person(m.text)
  end
end

def scrape_person(url)
  noko = noko_for(url)

  box = noko.css('.page_content_nav')

  title = box.css('h1').text.tidy.match(/(.*)\s+\((.*?)\)/)

  data = {
    id:         box.css('img.ms-rteImage-2/@src').text.split('/').last.sub(/\..*?$/, '').downcase,
    name:       title.captures.first.sub('Hon ', ''),
    area:       title.captures.last,
    image:      box.css('img.ms-rteImage-2/@src').text,
    email:      box.css('h2 a[href*="mailto"]/@href').text.sub('mailto:', ''),
    phone:      box.css('h2').text[/Contact Tel: ([\d[[:space:]]]+)/, 1].tidy,
    birth_date: date_from(noko.xpath('.//strong[contains(.,"Born")]//following-sibling::text()').text),
    term:       2011,
    source:     url,
  }
  data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite(%i(id term), data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://www.tynwald.org.im/memoff/member/Pages/default.aspx')
