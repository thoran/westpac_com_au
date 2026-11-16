# westpac_com_au.gemspec

require_relative './lib/WestpacComAu/VERSION'

class Gem::Specification
  def dependencies=(gems)
    gems.each{|gem| add_dependency(*gem)}
  end

  def development_dependencies=(gems)
    gems.each{|gem| add_development_dependency(*gem)}
  end
end

Gem::Specification.new do |spec|
  spec.name = 'westpac_com_au'
  spec.version = WestpacComAu::VERSION

  spec.summary = "Interact with Westpac Online Banking via Selenium WebDriver."
  spec.description = "Log into Westpac Online Banking (banking.westpac.com.au) and export an account's transactions as a CSV file."

  spec.author = 'thoran'
  spec.email = 'code@thoran.com'
  spec.homepage = 'https://github.com/thoran/westpac_com_au'
  spec.license = 'MIT'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/thoran/westpac_com_au/issues',
    'changelog_uri' => 'https://github.com/thoran/westpac_com_au/blob/master/CHANGELOG',
    'source_code_uri' => 'https://github.com/thoran/westpac_com_au',
    'documentation_uri' => 'https://github.com/thoran/westpac_com_au/blob/master/README.md',
  }

  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.3'

  spec.files = [
    'westpac_com_au.gemspec',
    Dir['lib/**/*.rb'],
    Dir['test/**/*.rb'],
    'CHANGELOG',
    'Gemfile',
    'LICENSE',
    'Rakefile',
    'README.md',
  ].flatten

  spec.dependencies = [
    ['selenium-webdriver', '>= 4.0'],
    ['webaccount', '~> 0.10']
  ]

  spec.development_dependencies = %w{
    minitest
    minitest-spec-context
    rake
  }
end
