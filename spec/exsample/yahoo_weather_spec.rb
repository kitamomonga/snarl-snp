# -*- coding:utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'snarl/snp'
require 'rubygems'
require 'webmock'

html = File.open(File.join(File.dirname(__FILE__), 'data', 'weather_yahoo_co_jp.html')){|f| f.read}
WebMock.stub_request(:get, 'http://weather.yahoo.co.jp/weather/jp/1b/1400.html').to_return(:body => html)

require 'open-uri'
#p open('http://weather.yahoo.co.jp/weather/jp/1b/1400.html').read
describe "Show weathercast of Sapporo, Japan" do
  it "do" do
    lambda{
      argv = ARGV.dup
      ARGV.clear # spec -fs -v yahoo_weather_spec.rb #=> ARGV[0] == '-fs'
      ARGV[0] = Snarl::SNP::Config.host
      load File.expand_path(File.dirname(__FILE__) + '../../../exsample/yahoo_weather.rb')
      ARGV.concat(argv)
    }.should_not raise_error
  end
end
