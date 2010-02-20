require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'

NAME = "linked-data-api"
VER = "0.1"

RDOC_OPTS = ['--quiet', '--title', 'Linked Data API Reference', '--main', 'README']

PKG_FILES = %w( README Rakefile CHANGES ) + 
  Dir.glob("{bin,doc,tests,examples,lib}/**/*")

CLEAN.include ['*.gem', 'pkg']  
SPEC =
  Gem::Specification.new do |s|
    s.name = NAME
    s.version = VER
    s.platform = Gem::Platform::RUBY
    s.required_ruby_version = ">= 1.8.5"    
    s.has_rdoc = true
    s.extra_rdoc_files = ["README", "CHANGES"]
    s.rdoc_options = RDOC_OPTS
    s.summary = "Linked Data API"
    s.description = s.summary
    s.author = "Leigh Dodds"
    s.email = 'leigh.dodds@talis.com'
    #s.homepage = 'http://linked-data-a.rubyforge.net'
    #s.rubyforge_project = 'pho'
    s.files = PKG_FILES
    s.require_path = "lib" 
    s.bindir = "bin"
    #s.executables = ["run_api"]
    s.test_file = "tests/ts_linked_data_api.rb"
    s.add_dependency("httpclient", ">= 2.1.3.1")
    s.add_dependency("json", ">= 1.1.3")
    s.add_dependency("mocha", ">= 0.9.5")
    s.add_dependency("mime-types", ">= 1.16")
  end
      
Rake::GemPackageTask.new(SPEC) do |pkg|
    pkg.need_tar = true
end

Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = 'doc/rdoc'
    rdoc.options += RDOC_OPTS
    rdoc.rdoc_files.include("README", "CHANGES", "lib/**/*.rb")
    rdoc.main = "README"
    
end

Rake::TestTask.new do |test|
  test.test_files = FileList['tests/tc_*.rb']
end

desc "Install from a locally built copy of the gem"
task :install do
  sh %{rake package}
  sh %{sudo gem install pkg/#{NAME}-#{VER}}
end

desc "Uninstall the gem"
task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{NAME}}
end
