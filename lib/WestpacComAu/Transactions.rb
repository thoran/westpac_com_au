require 'Array/all_but_first'
require 'Date/last_year'
require 'fileutils'
require 'time'
require 'WestpacComAu/Account'

module WestpacComAu
  class Transactions
    class << self

      def csv_filename
        date_today = Date.today
        year = date_today.year
        month_number = '%02d' % date_today.month
        day_number = '%02d' % date_today.day
        File.expand_path("~/Downloads/Data_export_#{day_number}#{month_number}#{year}.csv")
      end

      def download_csv_file(account_number:, from_date:, password:, username:)
        FileUtils.rm(csv_filename) if File.exist?(csv_filename)
        westpac_account = WestpacComAu::Account.new(password: password, username: username)
        westpac_account.download_transactions(account_number: account_number, from_date: from_date, to_date: Date.today)
        westpac_account.shutdown
      end

    end # class << self
  end
end
