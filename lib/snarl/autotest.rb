$LOAD_PATH.unshift("#{File.dirname(__FILE__)}")

require 'snp/autosnp'
# Usage:
# On $HOME/.autotest.
#     require 'snarl/autotest'
#     Autotest::Snarl.host = '192.168.0.1'

module Autotest::Snarl

  extend Snarl::SNP::AutoSNP

  Autotest.add_hook :run do  |at|
    snarl("Run", "Run", :info)
  end

  Autotest.add_hook :red do |at|
    failed_tests = at.files_to_test.inject(0){ |s,a| k,v = a;  s + v.size}
    snarl("Tests Failed", "#{failed_tests} tests failed", :red)
  end

  Autotest.add_hook :green do |at|
    # TODO: "All tests passed (and pending 3)"
    snarl("Tests Passed", "All tests passed", :green)
  end

  Autotest.add_hook :run do |at|
    snarl("autotest", "autotest was started", :info) if $DEBUG
  end

  Autotest.add_hook :interrupt do |at|
    snarl("autotest", "autotest was reset", :info) if $DEBUG
  end

  Autotest.add_hook :quit do |at|
    snarl("autotest", "autotest is exiting", :info) if $DEBUG
  end

  Autotest.add_hook :all do |at|_hook
    snarl("autotest", "Tests have fully passed", :green)
  end
end
