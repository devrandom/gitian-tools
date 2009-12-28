require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'net/http'
require 'net/https'

describe Gem::Commands::GitianCommand do
  before :each do
    @command = Gem::Commands::GitianCommand.new
    @command.stub!(:say)
    @url = "http://original/asdf"
    @new_url = "http://new/asdf/"
    @gitian_url = Gem::AbstractGitianCommand::URL
    @command.options[:release] = 'latest'
  end

  it "should set sources if url supplied" do
    @command.should_receive(:get_one_optional_argument).and_return(@new_url)
    @command.should_receive(:get_cert)
    Gem.configuration.should_receive(:[]).with("gitian_source").and_return(nil)
    Gem.configuration.should_receive(:[]=).with("gitian_source", @new_url + "latest/")
    Gem.configuration.should_receive(:[]=).with("saved_srcs", [@url])
    Gem.configuration.should_receive(:[]).with("gem").at_least(:once).and_return("--no-ri")
    Gem.configuration.should_receive(:[]=).with("gem", "--no-ri --trust-policy HighSecurity")
    Gem.configuration.should_receive(:write)
    Gem.should_receive(:sources).at_least(:once).and_return([@url])
    Gem.should_receive(:sources=).with([@new_url + "latest/"])
    @command.execute
  end

  def normal_expects
    @command.should_receive(:get_one_optional_argument).and_return(nil)
    @command.should_receive(:get_cert)
    Gem.configuration.should_receive(:write)
    Gem.configuration.should_receive(:[]).with("gitian_source").and_return(nil)
    Gem.configuration.should_receive(:[]=).with("gitian_source", @gitian_url + "latest/")
    Gem.configuration.should_receive(:[]=).with("saved_srcs", [@url])
    Gem.should_receive(:sources).at_least(:once).and_return([@url])
    Gem.should_receive(:sources=).with([@gitian_url + "latest/"])
  end

  it "should set sources if url not supplied" do
    normal_expects
    Gem.configuration.should_receive(:[]).with("gem").at_least(:once).and_return("--no-ri")
    Gem.configuration.should_receive(:[]=).with("gem", "--no-ri --trust-policy HighSecurity")
    @command.execute
  end

  it "should set gem command line if there wasn't one before" do
    normal_expects
    Gem.configuration.should_receive(:[]).with("gem").at_least(:once).and_return(nil)
    Gem.configuration.should_receive(:[]=).with("gem", "--trust-policy HighSecurity")
    @command.execute
  end

  it "should override trust policy" do
    normal_expects
    Gem.configuration.should_receive(:[]).with("gem").at_least(:once).and_return("--trust-policy NoSecurity")
    Gem.configuration.should_receive(:[]=).with("gem", "--trust-policy HighSecurity")
    @command.execute
  end

  it "should override trust policy anywhere on command line" do
    normal_expects
    Gem.configuration.should_receive(:[]).with("gem").at_least(:once).and_return("--a --trust-policy=NoSecurity --b")
    Gem.configuration.should_receive(:[]=).with("gem", "--a --b --trust-policy HighSecurity")
    @command.execute
  end

  it "should undo" do
    pending
  end

  it "should make an HTTP object with certificates" do
    uri = URI.parse('https://a.com/')
    http = Object.new
    Net::HTTP.should_receive(:new).with(uri.host, uri.port).and_return(http)
    http.should_receive(:use_ssl=).with(true)
    http.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
    http.should_receive(:ca_file=).with('/etc/ssl/certs/ca-certificates.crt')
    @command.make_http(uri)
  end
end

