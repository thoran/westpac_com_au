# test/WestpacComAu/Transactions_test.rb

# Notes:
# 1. WestpacComAu::Account.new is swapped for a stand-in for the length of each example and put back afterwards, so as no browser is started.

require_relative '../../lib/westpac_com_au'

require 'minitest/autorun'
require 'minitest-spec-context'

describe WestpacComAu::Transactions do
  def with_stand_in_account(download: ->{'/downloads/transactions.csv'})
    account = Object.new
    account.define_singleton_method(:download_transactions){|account_number:, **dates| (@asked ||= []) << [account_number, dates]; download.call}
    account.define_singleton_method(:asked){@asked}
    account.define_singleton_method(:shutdown){@shut_down = true}
    account.define_singleton_method(:shut_down?){!!@shut_down}
    arguments = []
    original = WestpacComAu::Account.method(:new)
    WestpacComAu::Account.define_singleton_method(:new){|**args| arguments << args; account}
    yield account, arguments
  ensure
    WestpacComAu::Account.define_singleton_method(:new, original)
  end

  describe ".download_csv_file" do
    it "is the file downloaded, for the account and period given, the credentials and web_account_options going to the account, which is shut down" do
      with_stand_in_account do |account, arguments|
        _(WestpacComAu::Transactions.download_csv_file(account_number: '123456', username: 'customer', password: 'secret', period: :last_month, web_account_options: {download_directory: '/downloads'})).must_equal('/downloads/transactions.csv')
        _(account.asked).must_equal([['123456', {period: :last_month, from_date: nil, to_date: nil}]])
        _(arguments).must_equal([{username: 'customer', password: 'secret', download_directory: '/downloads'}])
        _(account.shut_down?).must_equal(true)
      end
    end

    it "shuts the account down even where the download fails" do
      with_stand_in_account(download: ->{raise Selenium::WebDriver::Error::TimeoutError}) do |account, _arguments|
        _{WestpacComAu::Transactions.download_csv_file(account_number: '123456')}.must_raise(Selenium::WebDriver::Error::TimeoutError)
        _(account.shut_down?).must_equal(true)
      end
    end

    it "refuses a keyword it doesn't know, rather than passing it on" do
      _{WestpacComAu::Transactions.download_csv_file(account_number: '123456', download_directory: '/downloads')}.must_raise(ArgumentError)
    end
  end
end
