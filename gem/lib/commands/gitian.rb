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
      :undo => false,
      :release => nil,
      :gitian => false,
      :re_get_cert => false,
      :status => false
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

    add_option('-u', '--undo', 'Disable gitian (so that you can install from an insecure repository)') do |value, options|
      options[:undo] = true
    end
    add_option('-s', '--status', 'Show status') do |value, options|
      options[:status] = true
    end
  end

  def execute
    if options[:undo]
      undo()
    elsif options[:status]
    else
      gitian(options[:gitian], options[:release])
    end
    show_status
  end

  def undo
    unless Gem.configuration["saved_srcs"]
      puts "There is no saved configuration"
      return
    end

    gem_opts = Gem.configuration["gem"] || ""
    gem_opts.gsub!(/\s*--trust-policy[ =]\S+/, "")
    Gem.configuration["gem"] = gem_opts.strip
    Gem.sources = Gem.configuration["saved_srcs"]
    Gem.configuration["saved_srcs"] = nil

    Gem.configuration.write
  end

  def gitian(use_gitian, release)
    gem_opts = Gem.configuration["gem"] || ""
    gem_opts.gsub!(/\s*--trust-policy[ =]\S+/, "")
    policy = "HighSecurity"
    gem_opts = gem_opts + " --trust-policy #{policy}"
    Gem.configuration["gem"] = gem_opts.strip
    oldurl = Gem.configuration["gitian_source"]

    url = get_one_optional_argument
    if url
      release ||= 'latest'
    else
      if use_gitian || oldurl.nil?
	url = URL
	release ||= 'latest'
      else
	# if using old URL, strip last component only if release given
	url = oldurl
	url = URI.parse(url).merge("..").to_s if release
      end
    end

    url += "/" if url[-1,1] != "/"
    url = url + release + "/" if release

    sources = Gem.sources
    sources.reject! { |s| s == url || s == oldurl }
    if !sources.empty?
      Gem.configuration["saved_srcs"] = sources
    end
    sources = [ url ]
    Gem.sources = sources
    Gem.configuration["gitian_source"] = url

    uri = URI.parse(url)
    if uri.relative?
      $stderr.puts "URL must be absolute - i.e. start with http://, https://, file:///"
      $stderr.puts ""
      show_help()
      exit(1)
    end

    get_cert(uri, options[:re_get_cert])

    Gem.configuration.write

    say "High security policy enabled.  You will get an 'unsigned gem' error if you try to install a gem from a normal, non-signing gem repository.  Use 'gem gitian --undo' if you want to install an unsigned gem."
  end

  def show_status
    say "Sources in ~/.gemrc:"
    Gem.sources.each do |source|
      say "- #{source}"
    end
    say "Gem defaults: #{Gem.configuration["gem"]}" if Gem.configuration["gem"] && Gem.configuration["gem"] != ""
  end

  def get_cert(uri, do_force)
    http = make_http(uri)
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
