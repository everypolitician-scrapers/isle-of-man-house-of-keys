#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

require_rel 'lib'

class String
  def to_date
    return if to_s.empty?
    return Date.parse(self).to_s rescue nil
  end
end

class MembersPage < TynwaldPage
  field :member_urls do
    box.xpath('.//div[@class="link-item"]/a/@href').map(&:text)
  end

  private

  def box
    noko.xpath('.//h2[a[@id="HKMembers"]]/following-sibling::div[@class="ms-rtestate-read ms-rte-wpbox"]')
  end
end

class MemberPage < TynwaldPage
  field :id do
    image.split('/').last.sub(/\..*?$/, '').downcase
  end

  field :name do
    title.captures.first.sub('Hon ', '').sub('MHK', '').tidy
  end

  field :area do
    title.captures.last
  end

  field :image do
    (noko.at_css('img.ms-rteImage-2/@src') || noko.at_css('img.ms-rtePosition-2/@src')).text
  end

  field :email do
    noko.css('h2 a[href*="mailto"]/@href').text.sub('mailto:', '')
  end

  field :phone do
    noko.css('h2').text.tidy[/Tel: ([\d[[:space:]]()]+)/, 1].tidy
  end

  field :birth_date do
    noko.xpath('.//strong[contains(.,"Born")]//following-sibling::text()').text.to_date
  end

  field :facebook do
    noko.css('a[href*=facebook]/@href').text
  end

  field :twitter do
    noko.css('a[href*=twitter]/@href').map(&:text).reject { |t| t.include? 'TynwaldInfo' }.join(';')
  end

  field :source do
    url
  end

  private

  def title
    noko.css('h1').text.tidy.match(/(.*)\s+\((.*?)\)/)
  end
end

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
start = 'http://www.tynwald.org.im/memoff/member/Pages/default.aspx'
data = scrape(start => MembersPage).member_urls.map do |url|
  scrape(url => MemberPage).to_h.merge(term: 2016)
end
# puts data.map { |r| r.reject { |_k, v| v.to_s.empty? }.sort_by { |k, _v| k }.to_h }
ScraperWiki.save_sqlite(%i(id term), data)
