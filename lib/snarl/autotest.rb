$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'snp'

# Usage:
# On $HOME/.autotest.
#     require 'snarl/autotest'
#     Autotest::Snarl.host = '192.168.0.1'
module Autotest::Snarl

   @snarl_host = '127.0.0.1'
   @snarl_port = 9887

   class << self
     attr_accessor :snarl_host, :snarl_port
   end

   def self.host
     ENV['SNARL_HOST'] || Autotest::Snarl.snarl_host
   end
   def self.host=(host)
     Autotest::Snarl.snarl_host = host
   end
   def self.port
     ENV['SNARL_PORT'] || Autotest::Snarl.snarl_port
   end
   def self.port=(port)
     Autotest::Snarl.snarl_port = port.to_i
   end

  # Windows Snarl shortcut's "working folder" (left click property)
  # %HOME%\Application Data\full phat\snarl\styles
  def self.hostdir
    "./"
  end
  def self.icon_ok
    # %HOME%\Application Data\full phat\snarl\styles\ok.png works fine
    "ok.png"
  end
  def self.icon_fail
    "fail.png"
  end
  def self.icon_pending
    "pending.png"
  end
  def self.app
    "Autotest::Snarl"
  end

  def self.iconset
    {
      :green    => File.join(hostdir, icon_ok),
      :red      => File.join(hostdir, icon_fail),
      :yellow   => File.join(hostdir, icon_pending), # TODO:
      :info     => nil
    }
  end

  def self.classes
    {
      'green'   => 'test ok',
      'red'     => 'test fail',
      'yellow'  => 'test pending',
      'info'    => 'system message'
    }
  end

  def self.snarl(title, text, status = :info, timeout = nil)
    Snarl::SNP.open(host, port){|c|
      c.iconset(iconset)
      c.register(app)
      c.add_classes(classes)
      c.notification(
                     :title => title,
                     :text => text,
                     :class => status.to_s,
                     :timeout => (timeout||10),
                     :icon => status)
    }
  end

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
    snarl("autotest", "autotest was started", :info, 5) if $DEBUG
  end

  Autotest.add_hook :interrupt do |at|
    snarl("autotest", "autotest was reset", :info, 5) if $DEBUG
  end

  Autotest.add_hook :quit do |at|
    snarl("autotest", "autotest is exiting", :info, 5) if $DEBUG
  end

  Autotest.add_hook :all do |at|_hook
    snarl("autotest", "Tests have fully passed", :green)
  end

end
