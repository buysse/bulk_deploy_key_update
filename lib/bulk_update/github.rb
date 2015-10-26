require 'octokit'
require 'bulk_update/logger'
require 'sshkey'

class BulkUpdateGithub

  def new(options)
    @logger = BulkUpdateLogger.new(options)

    if not options.api_host.nil? then
      Octokit.configure do |c|
        c.api_endpoint = "https://#{options.api_host}/api/v3"
        logger.verbose "Configured Github Enterprise endpoint using host: #{options.api_host}."
      end
    end

    @github = Octokit::Client.new(:access_token => options.token)
    @logger.verbose("Logged in to github as user #{github.user.login} using token.")
    @logger.debug("Octokit client state:", @github)
    end

    def get_repos(user)
      # get the user (to determine if org or user)
      repos = []
      u = @github.user(user)
      @logger.verbose("Found user #{user} on Github")
      @logger.debug("Octokit user #{user}:", u)

      # get the list of repositories
      if u.type === "Organization" then
        @logger.verbose("Loaded #{user} as an organization")
        repos = @github.organization_repositories(user)
      else
        @logger.verbose("Loaded #{user} as a normal user")
        repos = @github.repositories(user)
      end
      @logger.debug("Repositories loaded:", repos)
      # return as array
      return repos
    end

    def get_keys_for_repo(repo)
      repo_obj = get_repo_object(repo)
      # list the keys
      keys = @gh.list_deploy_keys(repo_obj.full_name)
      @logger.debug("Loaded keys from repo #{repo_obj.full_name}", keys)
      # return as array
      return keys
    end

    def add_key_for_repo(repo, key)
      # load the key
      if not self.is_valid_pubkey?(key) then
        @logger.error("The provided key is not a valid SSH public key (String):", key)
        raise "Error loading public key"
      end
      # check the repo for validity and get the object
      repo_obj = get_repo_object(repo)
      current_keys = @gh.list_deploy_keys(repo_obj.full_name)
      # check if the key is there
      key_added = false
      current_keys.each do |k|
        if compare_keys(key, k.key) then
          @logger.verbose("Found existing key #{k.title} that matches on #{repo_obj.full_name}, not adding")
          key_added = true
          if not k.read_only === @options.key_is_readonly then
            @logger.warning("Key #{k.title} already exists in #{repo.full_name}, but read_only status does not match options passed to script")
            @logger.warning("Continuing, but you may want to remove and re-add (update not implemented)")
          end
        end
      end
      # append the key if not there
      if not key_added then
        @logger.verbose("Attempting to add key #{key} to #{repo.full_name}")
        @github.add_deploy_key(repo_obj.full_name, 'Added by bulk_update.rb script', key, :read_only => true)
      end
      true # if no exceptions were raised
    end

    def remove_key_for_repo(repo, key)
      # check the repo for validity
      repo_obj = get_repo_object(repo)
      current_keys = @github.list_deploy_keys(repo_obj.full_name)
      # check if the key is there
      found_key = nil
      current_keys.each do |k|
        if compare_keys(key, k.key) then
          @logger.verbose("in remove_key, found existing key #{k.title} that matches on #{repo_obj.full_name}")
          found_key = k
        end
      end
      # remove the key if there
      if not found_key.nil? then
        @logger.debug("Removing key #{found_key.title}from repo #{repo.full_name}", found_key)
        @github.remove_deploy_key(repo_obj.full_name, found_key.id)
      else
        @logger.debug("Key wasn't found in #{repo.full_name}", key)
      end
      # return the result
      true # no exceptions raised, we good.
    end

    def remove_all_keys_for_repo(repo)
      # check the repo for validity
      repo_obj = get_repo_object(repo)
      @logger.verbose("Removing all keys on repo #{repo_obj.full_name}")
      # enumerate the keys on the repo
      current_keys = @github.list_deploy_keys(repo_obj.full_name)
      @logger.debug("Removing all keys found on #{repo_obj.full_name}:", current_keys)
      # remove each key
      current_keys.each do |k|
        @logger.debug("Removing key #{k.title} from #{repo_obj.full_name}")
        @github.remove_deploy_key(repo_obj.full_name, k.id)
      end
      true # no exceptions
    end

    #### INTERNAL HELPER FUNCTIONS

    def self.is_valid_pubkey?(pubkey)
      return SSHKey.valid_ssh_public_key?(pubkey)
    end

    # takes just strings containing a SSH public key and compares the fingerprints
    # could be used like compare_keys(File.read(...), k2)
    def self.compare_keys(key1, key2)
      f1 = SSHKey.sha1_fingerprint(key1)
      f2 = SSHKey.sha1_fingerprint(key2)
      return f1 === f2
    end

    # expect a repo object from above, or an integer id, or a
    # user/name combo.  Any are acceptable.
    def self.get_repo_object(repo)
      repo_obj = nil
      case repo.class
      when Fixnum
        repo_obj = @github.repository(:id => repo)
      when String
        u,r = repo.split('/')
        repo_obj = @github.repository(:user => u, :name => r)
      when Sawyer::Resource
        repo_obj = repo
      end
      if repo_obj.nil? then
        @logger.error("Failed to locate repository!", repo)
        raise "Error: unable to find repository for #{repo}"
      end
      @logger.debug("Found repo #{repo_obj.full_name}", repo_obj)
      return repo_obj
    end
  end
