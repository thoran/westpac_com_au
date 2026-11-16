# WestpacComAu/Transactions.rb
# WestpacComAu::Transactions

require_relative './Account'

module WestpacComAu
  module Transactions
    class << self
      # web_account_options go to WestpacComAu::Account.new as they are, as browser:, profile_directory:, download_directory: and the like. Returns the name of the CSV file downloaded.
      def download_csv_file(account_number:, username: nil, password: nil, period: nil, from_date: nil, to_date: nil, web_account_options: {})
        westpac_account = WestpacComAu::Account.new(username: username, password: password, **web_account_options)
        westpac_account.download_transactions(account_number: account_number, period: period, from_date: from_date, to_date: to_date)
      ensure
        westpac_account&.shutdown
      end
    end # class << self
  end
end
