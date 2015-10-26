#!/usr/bin/env ruby

# Add the lib directory to $LOAD_PATH (aka $:), unless it's already there
$:.unshift(File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib")) unless
    $:.include?(File.join(File.dirname(__FILE__), "..", "lib")) ||
    $:.include?(File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib")))
# credit to http://stackoverflow.com/questions/837123/adding-a-directory-to-load-path-ruby,
# answer from http://stackoverflow.com/users/56190/luke-antins -- modified to add the join


require 'bulk_update/options'
require 'bulk_update/logger'
require 'bulk_update/github'

options = BulkUpdateOptions.parse(ARGV)

logger = BulkUpdateLogger.new(options)

ghwrapper = BulkUpdateGithub.new(options)

logger.debug("Starting main script invocation")

all_repos = ghwrapper.get_repos(options.user)

if not options.all_repositories then
  repos = all_repos.select { |r| r.name == options.single_repo }
else
  repos = all_repos
end

# load the key from the file if we have one
# the option parser should have done some validation here, requiring the key file be specified if needed
if options.key_file then
  key = File.read(options.key_file, "r")
else
  key = nil
end


case options.operation
when :add
  repos.each do |r|
    ghwrapper.add_key_for_repo(r, key)
  end
when :remove
  repos.each do |r|
    ghwrapper.remove_key_for_repo(r, key)
  end
when :remove_all
  repos.each do |r|
    ghwrapper.remove_all_keys_for_repo(r)
  end
when :list
  puts "Listing keys for all repositories specified:"
  repos.each do |r|
    keys = ghwrapper.get_keys_for_repo(r)
    puts "#{r.full_name}:"
    keys.each do |k|
      puts "  #{k.title}: #{k.read_only ? "Read-only" : "WARNING: allows writing"}"
      puts "    Created on #{k.created_at}"
      if options.verbose or options.debug then
        puts "    Content:"
        puts k.key
      end
    end
  end
end
