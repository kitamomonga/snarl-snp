$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|

  require 'snarl/snp'
  require 'logger'
  require 'tempfile'
  require 'yaml'
  begin
    config = YAML.load_file(File.join(File.dirname(__FILE__), 'snp.config'))
  rescue Errno::ENOENT
    config = {}
  end
  config.each_pair do |mes, value|
    Snarl::SNP::Config.__send__("#{mes}=", value)
  end
end
