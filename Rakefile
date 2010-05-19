require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "snarl-snp"
    gem.summary = %Q{Snarl Network Protocol Client. You can notify to Snarl on LAN.}
    gem.description = %Q{Snarl Network Protocol Client. Snarl is the notification program for Windows. You can send notification messages to Snarl with SNP on LAN.}
    gem.email = "ezookojo@gmail.com"
    gem.homepage = "http://github.com/kitamomonga/snarl-snp"
    gem.authors = ["kitamomonga"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "snarl-snp #{version}"
  rdoc.rdoc_files.include('README.rdoc*')
  rdoc.rdoc_files.include('GUIDE.rdoc*')
  rdoc.rdoc_files.include('YAML.rdoc*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('doc-ja/**/*rdoc.ja')
end
