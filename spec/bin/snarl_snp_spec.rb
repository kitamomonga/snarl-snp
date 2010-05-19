# -*- coding:utf-8 -*-
require 'tempfile'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

if defined?(TEST_SNARL_SNP_BIN_SPEC) then
  class SNPBin
    remove_const :"BINCMD_OPTION"
  end
else
  TEST_SNARL_SNP_BIN_SPEC=true
end
load File.expand_path(File.dirname(__FILE__) + '/../../bin/snarl_snp')

describe "SNPBin" do

  before :all do
    @argv_bak = ARGV.dup
  end
  after :all do
    ARGV.replace(@argv_bak)
  end

  describe "initialize" do
    before do
      @snpbin = SNPBin.new
    end
    it "initialize data" do
      @snpbin.argv_option.should eql({})
      @snpbin.config.should eql({})
    end
  end

  describe "parse_argv" do
    SNPBin::BINCMD_OPTION.each do |optname, opthash|
      before do
        ARGV.clear
        @snpbin = SNPBin.new
      end
      # opthash[:opt] == ['-a app', '--app=app']
      arg = opthash[:opt][0].split(/\s+|=/) # ['-a', 'app']
      value = if arg[1] then "'#{arg[1]}'" else true end # ''app''
      instance_eval(<<EOS)
      it "when ARGV[1] = '#{opthash[:opt][0]}', set {'#{optname}' => #{value}} to @argv_option" do
        ARGV.replace([__FILE__] + arg)
        @snpbin.parse_argv
        @snpbin.argv_option.should eql({'#{optname}' => #{value}})
      end
EOS
    end
  end

  describe "merge_yaml_from_argvopt" do
    before do
      @yamlfile = Tempfile.new('snarlsnpbinsnarlsnpspecrb')
      File.open(@yamlfile.path, 'w'){|f| f.write("data : yaml!")}
      @snpbin = SNPBin.new
      @snpbin.argv_option.update({'yaml' => @yamlfile.path})
    end
    after do
      @yamlfile.close
    end

    it "do nothing when @argv_option has no 'yaml' key" do
      @snpbin.argv_option.delete('yaml')
      lambda{@snpbin.merge_yaml_from_argvopt}.should_not change(@snpbin, :config)
    end

    it "picks and deletes {'yaml' => yamlpath} from @argv_option and update @config by yamlpath-yaml" do
      # FIXME: rewrite with change matcher
      @snpbin.config.should be_empty
      @snpbin.merge_yaml_from_argvopt
      @snpbin.config.should eql({'data' => 'yaml!'})
      @snpbin.argv_option.should_not have_key('yaml')
    end
  end

  describe "#merge_all_argvopt_to_config" do
    before do
      @snpbin = SNPBin.new
      @data = {'key' => 'value'}
    end
    it "copys @argv_option to @config" do
      @snpbin.instance_variable_set(:@argv_option, @data)
      @snpbin.merge_all_argvopt_to_config
      @snpbin.config.should eql(@data)
    end
  end

  # tests for SNPBin#exec_snplib and #run are in ../snp/real_connection_spec.rb

end
