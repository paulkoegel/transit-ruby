#!/usr/bin/env rake
require 'bundler'
Bundler.setup

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

task :irb do
  sh 'irb -I lib -r transit -I dev -r irb_tools'
end

def project_name
  "transit-ruby"
end

def gemspec_filename
  @gemspec_filename = "#{project_name}.gemspec"
end

def build_version
  @build_version ||= begin
                       r = `build/revision`.chomp.to_i
                       "0.8.#{r}"
                     end
end

def gem_filename
  @gem_filename ||= "#{project_name}-#{build_version}.gem"
end

def gem_path
  @gem_path ||= "pkg/#{gem_filename}"
end

task :foo => [:ensure_committed]

desc "Build #{gem_filename}.gem into the pkg directory"
task :build do
  begin
    gemspec_content = File.read(gemspec_filename)
    File.open(gemspec_filename, 'w+') do |f|
      f.write gemspec_content.sub("0.1.dev", build_version)
    end
    sh "gem build #{gemspec_filename}"
    sh "mkdir -p pkg"
    sh "mv #{gem_filename} #{gem_path}"
  ensure
    File.open(gemspec_filename, 'w+') do |f|
      f.write gemspec_content
    end
  end
end

desc "Build and install #{gem_filename}"
task :install => [:build] do
  sh "gem install #{gem_path}"
end

task :ensure_committed do
  raise "Can not release with uncommitted changes." unless `git status` =~ /clean/
end

desc "Create tag v#{build_version} and build and push #{gem_filename} to Rubygems"
task :release => [:ensure_committed, :build] do
  sh "git tag v#{build_version}"
  # gem push "#{target_path}"
end

desc "Uninstall #{project_name}"
task :uninstall do
  sh "gem uninstall #{project_name}"
end

desc "Clean up generated files"
task :clobber do
  sh "rm -rf ./tmp ./pkg ./.yardoc doc"
end
