
require 'optparse'
require 'optparse/time'

# simple dictionary syntax
require 'ostruct'

# TODO: or validation of public key provided
require 'sshkey'

class BulkUpdateOptions

  def self.parse(args)

    options = OpenStruct.new
    options.debug = false
    options.verbose = false
    options.api_host = false
    options.all_repositories = true
    options.key_is_readonly = true
    options.operation = nil
    options.is_error = false
    options.error_messages = []
    options.token = nil

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: bulk_update.rb [options]"

      opts.on("-v", "--[no-]verbose", "Run with verbose logging") do |v|
        options.verbose = v
      end

      opts.on("--[no-]debug", "Run with debug logging") do |d|
        options.debug = d
      end

      opts.on("-h", "--api-host HOSTNAME", "FQDN for Github Enterprise instance.", "(only useful for GitHub Enterprise instances)", "Defaults to using github.com endpoint") do |h|
        options.api_host = h
      end

      opts.on("-C", "--credentials TOKEN", "GitHub OAuth token allowing access to the repositories", "You can obtain this on your settings page under Personal Tokens") do |creds|
        options.token = creds
      end


      opts.on("-u", "--user USER_OR_ORGANIZATION", "Github user or organization to act on") do |u|
        options.user = u
      end

      opts.on("-f", "--key-file KEY_FILE", "SSH public key file to add or remove") do |f|
        options.key_file = f
        if not (File.exists?(f) and File.readable?(f)) then
          options.is_error = true
          options.error_messages << "Specified key-file #{f} doesn't exist or is not readable."
        end
      end

      opts.on("-r", "--repo REPO_NAME", "Single repository name to act on.  If not specified, will act on all repositories owned by the user.") do |r|
        options.all_repositories = false
        options.single_repo = r
      end

      opts.on("-A", "--add", "Adds the specified deploy key to GitHub") do
        if not options.operation.nil? then
          options.is_error = true
          options.error_messages << "Only one operation can be specified (add, remove, or list)"
        else
          options.operation = :add
        end
      end

      opts.on("-r", "--remove", "Removes the specified deploy key from GitHub") do
        if not options.operation.nil? then
          options.is_error = true
          options.error_messages << "Only one operation can be specified (add, remove, or list)"
        else
          options.operation = :remove
        end
      end

      opts.on("-l", "--list", "Lists the deploy keys on Github") do
        if not options.operation.nil? then
          options.is_error = true
          options.error_messages << "Only one operation can be specified (add, remove, or list)"
        else
          options.operation = :list
        end
      end

      opts.on("-X", "--remove-all", "DANGER: Removes all deploy keys from GitHub") do
        if not options.operation.nil? then
          options.is_error = true
          options.error_messages << "Only one operation can be specified (add, remove, or list)"
        else
          options.operation = :remove_all
        end
      end

    end
    parser.parse!(args)

    # check for mandatory options
    ['token', 'user', 'operation'].each do |k|
      if options.send(k).nil? then
        options.is_error = true
        options.error_messages << "Authentication token, the user/org to act on, and operation (add, remove, list, remove-all) must be specified."
      end
    end

    # validate the operation
    case options.operation
    when :add, :remove
      if options.key_file.nil? then
        options.is_error = true
        options.error_messages << "When adding or removing keys, must specify a key file (--key-file)."
      end
    when :remove_all, :list
      if not options.key_file.nil? then
        options.is_error = true
        options.error_messages << "When listing or removing all keys, must NOT specify a key file."
      end
    end

    # validate the github URL
    # TODO

    if options.is_error then
      puts "Error(s) encountered while parsing options: "
      options.error_messages.each do |msg|
        puts " * #{msg}"
      end

      raise "Error parsing options"
    end

    return options
  end

end
