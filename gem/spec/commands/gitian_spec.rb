require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gem::Commands::GitianCommand do
  before :each do
    @command = Gem::Commands::GitianCommand.new
    @command.stub!(:say)
    @url = "http://original/asdf"
    @new_url = "http://new/asdf"
    @gitian_url = Gem::AbstractGitianCommand::URL
  end

  it "should set sources if url supplied" do
    @command.should_receive(:get_one_optional_argument).and_return(@new_url)
    Gem.configuration.should_receive(:[]).with("gem").and_return("--no-ri")
    Gem.configuration.should_receive(:[]=).with("gem", "--no-ri --trust-policy HighSecurity")
    Gem.configuration.should_receive(:write)
    Gem.should_receive(:sources).and_return([@url])
    Gem.should_receive(:sources=).with([@new_url, @url])
    @command.execute
  end

  it "should set sources if url not supplied" do
    Gem.configuration.should_receive(:[]).with("gem").and_return("--no-ri")
    Gem.configuration.should_receive(:[]=).with("gem", "--no-ri --trust-policy HighSecurity")
    Gem.configuration.should_receive(:write)
    Gem.should_receive(:sources).and_return([@url])
    Gem.should_receive(:sources=).with([@gitian_url, @url])
    @command.execute
  end

  it "should set gem command line if there wasn't one before" do
    Gem.configuration.should_receive(:[]).with("gem").and_return(nil)
    Gem.configuration.should_receive(:[]=).with("gem", "--trust-policy HighSecurity")
    Gem.configuration.should_receive(:write)
    Gem.should_receive(:sources).and_return([@url])
    Gem.should_receive(:sources=).with([@gitian_url, @url])
    @command.execute
  end

  it "should override trust policy" do
    Gem.configuration.should_receive(:[]).with("gem").and_return("--trust-policy NoSecurity")
    Gem.configuration.should_receive(:[]=).with("gem", "--trust-policy HighSecurity")
    Gem.configuration.should_receive(:write)
    Gem.should_receive(:sources).and_return([@url])
    Gem.should_receive(:sources=).with([@gitian_url, @url])
    @command.execute
  end

  it "should override trust policy anywhere on command line" do
    Gem.configuration.should_receive(:[]).with("gem").and_return("--a --trust-policy=NoSecurity --b")
    Gem.configuration.should_receive(:[]=).with("gem", "--a --b --trust-policy HighSecurity")
    Gem.configuration.should_receive(:write)
    Gem.should_receive(:sources).and_return([@url])
    Gem.should_receive(:sources=).with([@gitian_url, @url])
    @command.execute
  end

  it "should allow insecurity" do
    Gem.configuration.should_receive(:[]).with("gem").and_return(nil)
    Gem.configuration.should_receive(:[]=).with("gem", "--trust-policy MediumSecurity")
    Gem.configuration.should_receive(:write)
    Gem.should_receive(:sources).and_return([@url])
    Gem.should_receive(:sources=).with([@gitian_url, @url])
    @command.gitian(true)
  end
end

