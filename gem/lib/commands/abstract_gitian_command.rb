require 'rubygems/local_remote_options'

class Gem::AbstractGitianCommand < Gem::Command
  include Gem::LocalRemoteOptions

  URL = "https://gitian.org/rubygems/"
end
