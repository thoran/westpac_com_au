# test/helper.rb

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest-spec-context'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'westpac_com_au'
