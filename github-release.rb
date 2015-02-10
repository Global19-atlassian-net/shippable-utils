#!/usr/bin/env ruby
# Author: Michael Goff <Michael.Goff@Quantum.com>
# Licence: MIT
# Copyright (c) 2015, Quantum Corp.
#
# Requires the octokit and mime-types gems

require 'octokit'
require 'optparse'
require 'find'

access_token = ENV['GITHUB_TOKEN']

# Should show help?
help = false

# Parse options
opts = OptionParser.new
opts.banner = "Usage:\n  #{$0} [<options>] <repo_name> <branch> <asset_path>"
opts.separator ""
opts.separator "options:"
opts.on('-h', '--help', 'Print out this help text') do
  help = true
end

begin
  opts.parse!
rescue OptionParser::InvalidOption => e
  STDERR.puts e
  STDERR.puts opts
  exit 1
end

repo_name, branch, asset_path = ARGV

if ARGV.length != 3
  STDERR.puts "repo_name is required" unless repo_name
  STDERR.puts "branch is required" unless branch
  STDERR.puts "asset_path is required" unless asset_path
  STDERR.puts opts
  exit 1
end

if help
  puts opts
  exit 1
end

if access_token.nil?
  STDERR.puts "Missing GITHUB_TOKEN environment variable"
  puts opts
  exit 1
end

unless File.exists?(asset_path)
  STDERR.puts "Could not find file or folder: #{asset_path}"
  exit 1
end

unless /^(\d+)\.(\d+)\.(\d+)(-([A-Za-z0-9\-\.]+))?(\+([A-Za-z0-9\-\.]+))?$/.match(branch)
  puts "Skipping github release from branch #{branch}."
  exit 0
end

octokit = Octokit::Client.new(:access_token => access_token)

# create the draft releast if not already created.
release = octokit.releases(repo_name).find {|r| r.tag_name == branch }
if release.nil?
  release = octokit.create_release(repo_name, branch, :draft => true, :name => branch, :body => "Release Draft")
end

files = []
if File.file?(asset_path)
  files.push(asset_path)
elsif File.directory?(asset_path)
  Find.find(asset_path) do |path|
    files.push(path) if File.file?(path)
  end
else
  STDERR.puts "Unknown file type for: #{asset_path}"
  exit 1
end

existing_files = release.assets.collect(&:name)

files.each do |file|
  filename = File.basename(file)

  if existing_files.include?(filename)
    STDERR.puts "Already uploaded file: #{filename}"
  else
    puts "Uploading #{file}"
    octokit.upload_asset(release.url, file, :name => filename)
  end
end
