# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "iq_fckeditor/version"

Gem::Specification.new do |s|
  s.name        = "iq_fckeditor"
  s.version     = IqFckeditor::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Till Schulte-Coerne"]
  s.email       = ["till.schulte-coerne@innoq.com"]
  s.homepage    = "http://github.com/tilsc/iq_fckeditor"
  s.summary     = "IqFckeditor"
  s.description = s.summary
  s.extra_rdoc_files = ['README.md', 'LICENSE']

  s.add_development_dependency "bundler"
  s.add_dependency "actionpack"

  s.files = %w(LICENSE README.md Rakefile iq_fckeditor.gemspec) + Dir.glob("{app,lib,tasks,test}/**/*")
  s.test_files = Dir.glob("{test}/**/*")
  s.executables = Dir.glob("{bin}/**/*")
  s.require_paths = ["lib"]
end
