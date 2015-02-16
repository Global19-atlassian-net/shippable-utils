#!/usr/bin/env ruby
# Author: Michael Goff <Michael.Goff@Quantum.com>
# Licence: MIT
# Copyright (c) 2015, Quantum Corp.
#
# Requires the octokit and mime-types gems

require 'octokit'
require 'optparse'
require 'ostruct'
require 'net/http'
require 'open-uri'

access_token = ENV['GITHUB_TOKEN']

options = OpenStruct.new(
  :help => false,
  :destination => nil,
  :release => nil
)

# Parse options
opts = OptionParser.new
opts.banner = "Usage:\n  #{$0} [<options>] <repo_name> <destination>"
opts.separator ''
opts.separator 'Description:
  Download the first release asset from a given (or lastest) release.'
opts.separator ''
opts.separator 'Options:'
opts.on('-h', '--help', 'Print out this help text') do
  options.help = true
end
opts.on('--release', 'Sets the release to fetch the url from. Default is to select the latest release.') do
  options.prerelease = true
end
opts.separator ''
opts.separator 'Arguments:
  repo_name - the name of the repo in the form user/repo. e.g. trovalds/linux
  destination - the filename to save the asset as'
opts.separator ''
opts.separator 'Environment:
  GITHUB_TOKEN - github oauth token'
opts.separator ''
opts.separator 'Examples:
  #{$0} --release 4.90.23 trovalds/linux'

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

repo_name, destination = ARGV

if ARGV.length != 2
  STDERR.puts "repo_name is required" unless repo_name
  STDERR.puts "destination is required" unless destination
  STDERR.puts opts
  exit 1
end

if access_token.nil?
  STDERR.puts "Missing GITHUB_TOKEN environment variable"
  puts opts
  exit 1
end

# Fetch releases
octokit = Octokit::Client.new(:access_token => access_token)
begin
  releases = octokit.releases(repo_name)
rescue Octokit::NotFound => e
  STDERR.puts "Could not find repo: #{repo_name}"
  exit 1
end

# Select the specific release
release = nil
if options.release
  release = releases.find {|r| r.name == options.release}
  if release.nil?
    STDERR.puts "Could not find release: #{options.release}"
    exit 1
  end
else
  release = releases.sort_by(&:created_at).last

  if release.nil?
    STDERR.puts "No releases found"
    exit 1
  end
end

# Download the first asset
if release.assets.first.nil?
  STDERR.puts "Release had no assets: #{release.name}"  
end

uri = URI(release.assets.first.url)

open(uri, 'Accept' => 'application/octet-stream', :http_basic_authentication => ['quantum-build', access_token]) do |input|
  open destination, 'w' do |output|
    until input.eof?
      output.write input.read(100*1024)
    end
  end
end

# Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
#   req = Net::HTTP::Get.new(uri)
#   req.basic_auth 'quantum-build', access_token
#   req['Accept'] = 'application/octet-stream'
# 
#   http.request(req) do |response|
#     puts response.inspect
# 
#     open destination, 'w' do |io|
#       response.read_body do |chunk|
#         io.write chunk
#       end
#     end
#   end
# end