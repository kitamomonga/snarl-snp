#!ruby -Ku
require 'rubygems'
require 'open-uri'
require 'nokogiri'
$LOAD_PATH.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '/../lib/'))
require 'snarl/snp'

@uri = 'http://weather.yahoo.co.jp/weather/jp/1b/1400.html'
@host = ENV['SNARL_HOST'] || ARGV[0] || (if ARGV[0] == '-H' then ARGV[1] else nil end)

def encode_win(s)
  if s.respond_to?(:encode) then
    s.dup.encode(::Encoding::SHIFT_JIS)
  else
    require 'kconv'
    s.tosjis
  end
end

uri = URI.parse(@uri)
html = open(uri, 'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 1.1.4322)').read
doc = Nokogiri::HTML.parse(html, nil, 'EUC-JP')

place = doc.at('div#cat-pass p').inner_text.split(/>/).last.gsub(/\s+/){''}
table = doc.at('table.yjw_table tr')
weather = table.at('img')

title = encode_win("Yahoo! Weather\n#{place}")
text = encode_win(table.at('table').inner_text.gsub(/\s+/){''})
icon = weather['src']

Snarl::SNP.open(@host) do |snp|
  snp.register('Ruby-Snarl')
  snp.notification(title, text, icon, 20)
end
