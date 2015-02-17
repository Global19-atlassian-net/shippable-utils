#!/usr/bin/env ruby
# Author: Michael Goff <Michael.Goff@Quantum.com>
# Licence: MIT
# Copyright (c) 2015, Quantum Corp.
#
# Requires the octokit and mime-types gems

require 'octokit'
require 'optparse'
require 'find'
require 'ostruct'

access_token = ENV['GITHUB_TOKEN']

options = OpenStruct.new(
  :help => false,
  :draft => false,
  :prerelease => false,
  :ignoreSemver => false,
  :body => ''
)

# Parse options
opts = OptionParser.new
opts.banner = "Usage:\n  #{$0} [<options>] <repo_name> <branch> <asset_path>"
opts.separator ''
opts.separator 'Description:
  Checks the branch name and if it is a semantic version,
  create a new github release in the specified repo and uploads
  assets from the specified path.'
opts.separator ''
opts.separator 'Options:'
opts.on('-h', '--help', 'Print out this help text') do
  options.help = true
end
opts.on('--pre', 'Sets this release to be a prerelease. Default is false.') do
  options.prerelease = true
end
opts.on('--draft', 'Sets this release to be a draft. Default is false.') do
  options.draft = true
end
opts.on('--description DESCRIPTION', 'Sets the description (body) of the release. Default is empty') do |b|
  options.body = b
end
opts.on('--ignore-semver', 'Proceed even if the branch is not a semver.') do
  options.ignoreSemver = true
end
opts.separator ''
opts.separator 'Arguments:
  repo_name - the name of the repo in the form user/repo. e.g. trovalds/linux
  branch - the name of the branch. e.g. master or 1.0.3-alpha.4+build.6
  asset_path - a path to the binary assets to be uploaded'
opts.separator ''
opts.separator 'Environment:
  GITHUB_TOKEN - github oauth token'
opts.separator ''
opts.separator 'Examples:
  github-release trovalds/linux 4.90.23 ./builds'

begin
  opts.parse!
rescue OptionParser::InvalidOption => e
  STDERR.puts e
  STDERR.puts opts
  exit 1
end

if options.help
  puts opts
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


if access_token.nil?
  STDERR.puts "Missing GITHUB_TOKEN environment variable"
  puts opts
  exit 1
end

unless File.exists?(asset_path)
  STDERR.puts "Could not find file or folder: #{asset_path}"
  exit 1
end

unless options.ignoreSemver or /^(\d+)\.(\d+)\.(\d+)(-([A-Za-z0-9\-\.]+))?(\+([A-Za-z0-9\-\.]+))?$/.match(branch)
  puts "Skipping github release from branch #{branch}."
  exit 0
end

octokit = Octokit::Client.new(:access_token => access_token)

# create the draft releast if not already created.
begin
  release = octokit.releases(repo_name).find {|r| r.tag_name == branch }
rescue Octokit::NotFound => e
  STDERR.puts "Could not find repo: #{repo_name}"
  exit 1
end

if release.nil?
  puts "creating"
  release = octokit.create_release(repo_name, branch, {
    :draft => options.draft,
    :prerelease => options.prerelease,
    :name => branch,
    :body => options.body
  })
  puts release.inspect
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
