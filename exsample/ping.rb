#!/usr/bin/env ruby
require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '/../lib/'))
require 'snarl/snp'

host = ENV['SNARL_HOST'] || ARGV[0] || '127.0.0.1'

Snarl::SNP.ping(host)
