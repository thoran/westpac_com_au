# test/gemspec_test.rb

require_relative './helper'

describe 'westpac_com_au.gemspec' do
  let(:spec){Gem::Specification.load(File.expand_path('../westpac_com_au.gemspec', __dir__))}

  it "is a valid specification" do
    _(spec.validate).must_equal(true)
  end

  it "is named westpac_com_au" do
    _(spec.name).must_equal('westpac_com_au')
  end

  it "does not pin a date" do
    _(spec.date).must_equal(Gem::Specification.new.date)
  end

  it "takes its version from WestpacComAu::VERSION" do
    _(spec.version.to_s).must_equal(WestpacComAu::VERSION)
  end

  it "declares its runtime dependencies" do
    _(spec.runtime_dependencies.map(&:name).sort).must_equal(%w{selenium-webdriver webaccount})
  end

  it "ships the gemspec which names it" do
    _(spec.files).must_include('westpac_com_au.gemspec')
  end

  it "links the homepage and each metadata link to the repository" do
    links = [spec.homepage] + spec.metadata.values
    _(spec.metadata.keys.sort).must_equal(%w{bug_tracker_uri changelog_uri documentation_uri source_code_uri})
    links.each{|link| _(link).must_match(%r{\Ahttps://github\.com/thoran/westpac_com_au(/|\z)})}
  end
end
