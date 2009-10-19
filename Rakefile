require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "svn-props-to-yaml"
    gem.summary = %Q{Convert svn properties to YAML Front Matter}
    gem.description = %Q{Given a Subversion repository, svn-props-to-yaml creates a new repo that is identical, except that all or some of the properties on each file are move from the properties to YAML prepended to the body of the file. Primarily useful prior to conversions to other repository types such as git.}
    gem.email = "jmorgan@morgancreative.net"
    gem.homepage = "http://github.com/jm81/svn-props-to-yaml"
    gem.authors = ["Jared Morgan"]
    gem.add_dependency('svn-fixture', '= 0.2.0')
    gem.add_development_dependency "spicycode-micronaut"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'micronaut/rake_task'
Micronaut::RakeTask.new(:examples) do |examples|
  examples.pattern = 'examples/**/*_example.rb'
  examples.ruby_opts << '-Ilib -Iexamples'
end

Micronaut::RakeTask.new(:rcov) do |examples|
  examples.pattern = 'examples/**/*_example.rb'
  examples.rcov_opts = '-Ilib -Iexamples'
  examples.rcov = true
end

task :examples => :check_dependencies

task :default => :examples

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "svn-props-to-yaml #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
