$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|

  require 'snarl/snp'
  require 'logger'
  require 'tempfile'
  require 'yaml'
  yaml_host = nil
  yaml_port = nil
  begin
    config = YAML.load_file(File.join(File.dirname(__FILE__), 'snp.config'))
    yaml_host = config['host'] if config['host']
    yaml_port = config['port'] if config['port']
  rescue Errno::ENOENT
  end
  SNARL_HOST = ENV['SNARL_HOST'] || yaml_host || '127.0.0.1'
  SNARL_PORT = (ENV['SNARL_PORT'] || yaml_port || 9887).to_i
end
