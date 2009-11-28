class Gem::Commands::GitianCommand < Gem::AbstractGitianCommand
  def description
    'Use a Gitian distribution as the primary gem source and enable gem security'
  end

  def arguments
    "[URL]	URL of Gitian distribution, (default #{URL})"
  end

  def usage
    "#{program_name} [URL]"
  end

  def initialize
    super 'gitian', description

    defaults.merge!(:insecure => false, :release => 'latest')

    add_option('-r', '--release', 'Specify a release (default to latest)') do |value, options|
      options[:release] = value
    end

    add_option('', '--insecure', 'Do not require signatures on gems (defeats the design goal of Gitian!)') do |value, options|
      options[:insecure] = true
    end
  end

  def execute
    say "Thanks for using Gitian!"
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

    url = get_one_optional_argument || URL
    url = url + release
    url += "/" if url[-1,1] != "/"

    sources = Gem.sources
    sources.reject! { |s| s == url || s == oldurl }
    sources.unshift url
    Gem.sources = sources

    Gem.configuration["gitian_source"] = url

    Gem.configuration.write
    say "High security enabled.  You will get an 'unsigned gem' error if you try to install a gem from a normal, non-signing gem repository."
  end

  def show_status
  end
end
