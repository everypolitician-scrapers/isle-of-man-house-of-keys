# frozen_string_literal: true
require_relative 'tynwald_page'

class String
  def to_date
    return if to_s.empty?
    return Date.parse(self).to_s rescue nil
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
