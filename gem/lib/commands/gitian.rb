require 'net/http'
require 'net/https'
require 'digest/sha1'
require 'rubygems/security'

class Gem::Commands::GitianCommand < Gem::AbstractGitianCommand
  def description
    'Use a Gitian distribution as the primary gem source and enable gem security'
  end

  def arguments
    "[URL]	URL of Gitian distribution, (see -g for default)"
  end

  def usage
    "#{program_name} [URL]"
  end

  def initialize
    super 'gitian', description

    defaults.merge!(
      :insecure => false,
      :release => 'latest',
      :gitian => false,
      :re_get_cert => false
    )

    add_option('-r', '--release REL', 'Specify a release (default is "latest")') do |value, options|
      options[:release] = value
    end

    add_option('-g', '--use-gitian', "Switch to #{URL}") do |value, options|
      options[:gitian] = true
    end

    add_option('', '--re-get-cert', 'Get the signing certificate again') do |value, options|
      options[:re_get_cert] = true
    end

    add_option('', '--insecure', 'Do not require signatures on gems') do |value, options|
      options[:insecure] = true
    end
  end

  def execute
    gitian(options[:insecure], options[:release])
    show_status
  end

  def gitian(insecure, release)
    gem_opts = Gem.configuration["gem"] || ""
    gem_opts.gsub!(/\s*--trust-policy[ =]\S+/, "")
    policy = "HighSecurity"
    policy = "MediumSecurity" if insecure
    gem_opts = gem_opts + " --trust-policy #{policy}"
    Gem.configuration["gem"] = gem_opts.strip
    oldurl = Gem.configuration["gitian_source"]

    url = get_one_optional_argument
    if url.nil?
      if options[:gitian] || oldurl.nil?
	url = URL
      else
	url = URI.parse(oldurl).merge("..").to_s
      end
    end

    url += "/" if url[-1,1] != "/"
    url = url + release
    url += "/" if url[-1,1] != "/"

    sources = Gem.sources
    sources.reject! { |s| s == url || s == oldurl }
    sources.unshift url
    Gem.sources = sources

    uri = URI.parse(url)
    if uri.relative?
      $stderr.puts "URL must be absolute - i.e. start with http://, https://, file:///"
      $stderr.puts ""
      show_help()
      exit(1)
    end

    Gem.configuration["gitian_source"] = url

    get_cert(uri, options[:re_get_cert])

    Gem.configuration.write

    if options[:insecure]
      say "Insecure mode."
    else
      say "High security enabled.  You will get an 'unsigned gem' error if you try to install a gem from a normal, non-signing gem repository."
    end
  end

  def show_status
  end

  def get_cert(uri, do_force)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
      http.use_ssl = true
    end
    http.start do
      cert_uri = uri.merge("../gem-public_cert.pem")
      http.request_get(cert_uri.path) do |res|
	case res
	when Net::HTTPSuccess
	  # OK
	else
	  $stderr.puts "Could not get certificate at #{cert_uri}"
	  res.error!
	end
	cert = OpenSSL::X509::Certificate.new(res.body)
	path = Gem::Security::Policy.trusted_cert_path(cert)
	return if (!do_force && File.exists?(path))
	Gem::Security.add_trusted_cert(cert)
	digest = Digest::SHA1.hexdigest(cert.to_der)
	digest = digest.upcase.gsub(/../, '\0:').chop
	subject = cert.subject.to_s
	subject.sub!("/CN=", '')
	subject.sub!("/DC=", '@')
	subject.gsub!("/DC=", '.')
	puts "Please verify fingerprint for <#{subject}> is\n #{digest}"
      end
    end
  end

end
