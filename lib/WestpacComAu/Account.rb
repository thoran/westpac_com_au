# WestpacComAu/Account.rb
# WestpacComAu::Account

# Notes:
# 1. Westpac shows a cookie notice, drawn by Didomi, on the login page and at times on later pages. Where it's showing, Accept essential only is clicked before going on.
# 2. The Sign Out link has no id, so it's found by its text. It's what login waits for, as it's on every page after logging in.
# 3. Signing out lands on a page saying so, with its form#logout, which at times goes on to the login page, with its form#login; either is taken as logged out. Both pages have an element with the id signin, so that id doesn't tell them apart.
# 4. Where a one-time code is asked for after signing in, login waits default_wait_timeout seconds for it to be entered by hand.
# 5. A username or password not given stops login before the browser is started, naming every one missing.
# 6. The newest finished CSV file to appear in download_directory once Export is clicked is taken to be the export.

require 'date'
require 'webaccount'

module WestpacComAu
  class Account < WebAccount
    PAGE_SELECTORS = {
      login_page_url: 'https://banking.westpac.com.au/wbc/banking/handler?TAM_OP=login&segment=personal&logout=false',
      login_page_username_field_selector: {id: 'fakeusername'},
      login_page_password_field_selector: {id: 'password'},
      login_page_submit_button_selector: {id: 'signin'},
      logout_button_selector: {xpath: '//a[normalize-space()="Sign Out"]'},
      logged_out_selector: {css: 'form#logout, form#login'}
    }

    COOKIE_NOTICE_BUTTON_SELECTOR = {id: 'didomi-notice-disagree-button'}

    TRANSACTIONS_PAGE_URL = 'https://banking.westpac.com.au/secure/banking/reportsandexports/exportparameters/2/'

    TRANSACTIONS_SELECTORS = {
      from_date_field: {id: 'DateRange_StartDate'},
      to_date_field: {id: 'DateRange_EndDate'},
      account_field: {id: 'Accounts_1'},
      csv_radio_button: {id: 'File_type_1'},
      export_button: {css: 'button.export-link'}
    }

    # period is :all, the last year, or :last_month. Without it, from_date and to_date, which default to a year ago and today. Returns the name of the CSV file downloaded.
    def download_transactions(account_number:, period: nil, from_date: nil, to_date: nil)
      from_date, to_date = dates(period: period, from_date: from_date, to_date: to_date)
      get_transactions_page
      enter_dates(from_date: from_date, to_date: to_date)
      select_bank_account(account_number)
      click(TRANSACTIONS_SELECTORS[:csv_radio_button])
      export_csv
    end

    private

    # cookie notice

    # Didomi draws its notice once the page has loaded, so it's waited for briefly. Where the choice is remembered, as in a profile kept between runs, there's none.
    def cookie_notice_button
      find_wait.until{driver.find_elements(*COOKIE_NOTICE_BUTTON_SELECTOR.first).detect(&:displayed?)}
    rescue Selenium::WebDriver::Error::TimeoutError
      nil
    end

    def decline_cookies
      cookie_notice_button&.click
    end

    # logging in

    def get_login_page
      super
      decline_cookies
    end

    # dates

    def last_month_start_date
      Date.today.prev_month - (Date.today.prev_month.day - 1)
    end

    def last_month_finish_date
      Date.today - Date.today.day
    end

    def dates(period:, from_date:, to_date:)
      case period
      when :all then [Date.today.prev_year, Date.today]
      when :last_month then [last_month_start_date, last_month_finish_date]
      when nil then [from_date || Date.today.prev_year, to_date || Date.today]
      else raise ArgumentError, "Unknown period #{period.inspect}: it's :all or :last_month."
      end
    end

    def formatted_date(date)
      date = Date.parse(date) if date.is_a?(String)
      date.strftime('%d/%m/%Y')
    end

    # transactions

    def get_transactions_page
      login unless logged_in?
      driver.get(TRANSACTIONS_PAGE_URL)
      wait_for(TRANSACTIONS_SELECTORS[:from_date_field])
      decline_cookies
    end

    # Set by WebAccount's set_value, typed dates being thrown away by the date picker; and stops where the values didn't take, rather than exporting another range.
    def enter_dates(from_date:, to_date:)
      from_date_field, to_date_field = find(TRANSACTIONS_SELECTORS[:from_date_field]), find(TRANSACTIONS_SELECTORS[:to_date_field])
      set_value(from_date_field, formatted_date(from_date))
      set_value(to_date_field, formatted_date(to_date))
      unless [from_date_field, to_date_field].map{|field| field.attribute('value')} == [formatted_date(from_date), formatted_date(to_date)]
        raise "The dates #{formatted_date(from_date)} to #{formatted_date(to_date)} didn't take."
      end
    end

    # The account field suggests accounts as the number is typed, and Enter takes the suggestion.
    def select_bank_account(account_number)
      account_field = find(TRANSACTIONS_SELECTORS[:account_field])
      account_field.send_keys(account_number)
      sleep 1
      account_field.send_keys(Selenium::WebDriver::Keys[:return])
    end

    def export_csv
      clicked_at = Time.now
      click(TRANSACTIONS_SELECTORS[:export_button])
      wait_for_download(since: clicked_at)
    end
  end
end
