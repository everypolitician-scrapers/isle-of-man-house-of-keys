# frozen_string_literal: true
require 'scraped'

class TynwaldPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls
end
