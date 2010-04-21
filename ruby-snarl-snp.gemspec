# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby-snarl-snp}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["kitamomonga"]
  s.date = %q{2010-04-22}
  s.description = %q{Snarl Network Protocol Client. Snarl is the notification program for Windows. You can send notification messages to Snarl with SNP over LAN.}
  s.email = %q{ezookojo@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc",
     "README.rdoc.ja"
  ]
  s.files = [
    "HOWTO.rdoc.ja",
     "MIT-LICENSE",
     "README.rdoc",
     "README.rdoc.ja",
     "Rakefile",
     "VERSION",
     "exsample/ping.rb",
     "exsample/snarl_winamp.rb",
     "exsample/yahoo_weather.rb",
     "lib/snarl/autotest.rb",
     "lib/snarl/snp.rb",
     "lib/snarl/snp/action.rb",
     "lib/snarl/snp/config.rb",
     "lib/snarl/snp/error.rb",
     "lib/snarl/snp/request.rb",
     "lib/snarl/snp/response.rb",
     "lib/snarl/snp/snp.rb",
     "ruby-snarl-snp.gemspec",
     "spec/exsample/data/weather_yahoo_co_jp.html",
     "spec/exsample/yahoo_weather_spec.rb",
     "spec/snp/action_spec.rb",
     "spec/snp/config_spec.rb",
     "spec/snp/request_spec.rb",
     "spec/snp/response_sprc.rb",
     "spec/snp/snp_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/kitamomonga/ruby-snarl-snp}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Snarl Network Protocol Client. You can notify Snarl over LAN.}
  s.test_files = [
    "spec/exsample/yahoo_weather_spec.rb",
     "spec/exsample/snarl_winamp_spec.rb",
     "spec/spec_helper.rb",
     "spec/snp/config_spec.rb",
     "spec/snp/response_sprc.rb",
     "spec/snp/request_spec.rb",
     "spec/snp/snp_spec.rb",
     "spec/snp/action_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<webmock>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<webmock>, [">= 0"])
  end
end
