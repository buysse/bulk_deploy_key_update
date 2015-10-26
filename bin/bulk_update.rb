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
