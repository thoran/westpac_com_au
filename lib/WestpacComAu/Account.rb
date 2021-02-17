# WestpacComAu.rb
# WestpacComAu

# 20210217
# 0.5.3

# Changes since 0.4:
# 1. Only now getting around to removing password keypad entry after Westpac changed it to an input field about a year ago.
# 0/1
# 2. /require 'Month.rb/Month'/require 'Month'/
# 1/2
# 3. /require 'Selenium/WebDriver/SearchContext/ElementTests'/require 'Selenium/WebDriver/SearchContext/ElementPresentQ/element_presentQ'
# 2/3
# 4. Commented the @logged_in block back in.

require 'Array/extract_optionsX'
require 'Date/self.last_year'
require 'Date/self.parse'
require 'Month'
require 'selenium-webdriver'
require 'Selenium/WebDriver/SearchContext/ElementPresentQ/element_presentQ'
require 'WebAccount'

module WestpacComAu
  class Account < WebAccount

    PAGE_IDS = {
      login_page_url: 'https://online.westpac.com.au/esis/Login/SrvPage?referrer=http%3A%2F%2Fwww.westpac.com.au%2FHomepageAlternative%2F',
      login_page_username_field_id: 'fakeusername',
      login_page_password_field_id: 'password',
      login_page_submit_button_id: 'signin',
      # logout_button_id: '',
      # logged_out_xpath: ''
    }

    def initialize(username: nil, password: nil)
      super(
        username: username, password: password,
        login_page_url: PAGE_IDS[:login_page_url],
        login_page_username_field_id: PAGE_IDS[:login_page_username_field_id], login_page_password_field_id: PAGE_IDS[:login_page_password_field_id],
        login_page_submit_button_id: PAGE_IDS[:login_page_submit_button_id],
        logout_button_id: PAGE_IDS[:logout_button_id],
        logged_out_xpath: PAGE_IDS[:logged_out_xpath],
      )
    end

    # begin overrides of WebAccount...

    def login(username: nil, password: nil)
      @logged_in = false
      username ||= self.username
      password ||= self.password
      attempts = 0
      loop do
        begin
          get_login_page
          enter_username(username)
          enter_password(password)
          login_page_submit_button.click
          break
        rescue Timeout::Error, Selenium::WebDriver::Error::UnknownError, Selenium::WebDriver::Error::NoSuchElementError => e
          attempts += 1
          if attempts >= 3
            driver.quit
            puts "Giving up after 3 attempts to #{__method__} because #{e}."
            exit
          end
        end
      end
      # The code block below was commented out because it was causing the whole thing to bomb for some reason,
      # so I had set @logged_in to true, but it seems to be working OK now.
      @logged_in = driver_wait.until do
        # If I can do away with one of these elements, then I can use the inherited login().
        driver.element_present?(:id, 'overview-dashboard') ||
        driver.element_present?(:id, 'Overview.Accounts.List')
      end
      # @logged_in = true
    end

    # If I can do away with one of these elements, then I can use the inherited logout().
    def logout
      case
      when driver.element_present?(:xpath, '//a[.="Sign Out"]') # The link provided on the dashboard page and most everywhere else.
        driver.find_element(:xpath, '//a[.="Sign Out"]').click
      when driver.element_present?(:xpath, '//a[.="Sign out"]') # The link provided on the "Multiple sessions" page.
        driver.element_present?(:xpath, '//a[.="Sign out"]').click
      else # Failing the above, there's always just getting the link.
        driver.get('https://banking.westpac.com.au/wbc/banking/handler?TAM_OP=logout')
      end
    end

    # end overrides of WebAccount

    def download_transactions(*args)
      options = args.extract_options!
      if options[:period]
        case options[:period]
        when :all
          download_all_transactions(options)
        when :last_month
          download_last_months_transactions(options)
        end
      else
        download_custom_period_transactions(options)
      end
    end

    def download_custom_period_transactions(options)
      get_transactions_page
      options[:from_date] = options[:from_date] || Date.last_year
      options[:to_date] = options[:to_date] || Date.today
      enter_dates(options)
      select_bank_account(options[:account_number])
      download_submit_button.click
      sleep 10
    end

    def download_last_months_transactions(options)
      options.merge!(from_date: Month.last.start_date, to_date: Month.last.finish_date)
      download_custom_period_transactions(options)
    end

    def download_all_transactions(options)
      options.merge!(from_date: Date.last_year, to_date: Date.today)
      download_custom_period_transactions(options)
    end

    private

    # transactions-related

    def download_submit_button
      driver.find_element(:css, '.export-link')
    end

    def get_transactions_page
      if logged_in?
        driver.get('https://banking.westpac.com.au/secure/banking/reportsandexports/exportparameters/2/')
        return driver.find_element(:css, 'h1').text == 'Transactions export'
      else
        login
        sleep 10
        get_transactions_page
      end
    end

    def from_date_field
      driver.find_element(:xpath, '//div[@class="date-range-selector"]/div[@class="fiserv-date-picker from"]/label/input')
    end

    def to_date_field
      driver.find_element(:xpath, '//div[@class="date-range-selector"]/div[@class="fiserv-date-picker to"]/label/input')
    end

    # The order is to-from because the from date picker occludes the whole of the to input field.
    def enter_dates(options)
      enter_to_date(options[:to_date])
      enter_from_date(options[:from_date])
    end

    def enter_from_date(from_date)
      from_date_field.clear
      from_date_field.send_keys(formatted_date(from_date))
    end

    def enter_to_date(to_date)
      to_date_field.clear
      to_date_field.send_keys(formatted_date(to_date))
    end

    def bank_account_field
      driver.find_element(:xpath, '//input[@id="Accounts_1"]')
    end

    def select_bank_account(account_number)
      bank_account_field.send_keys(account_number)
      sleep 1
      bank_account_field.send_keys(Selenium::WebDriver::Keys[:return])
    end

    def formatted_date(date)
      date = Date.parse(date) if date.is_a?(String)
      date.strftime("%d/%m/%Y")
    end

  end
end

if __FILE__ == $0
  westpac_account = WestpacComAu::Account.new(username: ARGV[0], password: ARGV[1])
  westpac_account.login
  westpac_account.download_transactions
  westpac_account.shutdown
end
