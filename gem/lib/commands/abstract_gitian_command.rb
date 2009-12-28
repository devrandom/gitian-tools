require 'rubygems/local_remote_options'

class Gem::AbstractGitianCommand < Gem::Command
  include Gem::LocalRemoteOptions

  URL = "https://gitian.org/rubygems/"

  CERTIFICATES = '/etc/ssl/certs/ca-certificates.crt'

  def make_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      certs = ENV['CERTIFICATES'] || CERTIFICATES
      if File.exists? certs
	http.ca_file = certs
      else
	$stderr.puts "ERROR : Could not find SSL certificates at #{CERTIFICATES}"
	$stderr.puts "Please set the CERTIFICATES environment variable"
	exit(1)
      end
    end
    http
  end
end
