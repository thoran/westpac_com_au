# WestpacComAu.rb
# WestpacComAu

# 20140801
# 0.0.14

require 'Array/extract_optionsX'
require 'Date/self.last_year'
require 'Date/self.parse'
require 'Month.rbd/Month'
require 'selenium-webdriver'
require 'Selenium/WebDriver/SearchContext/ElementTests'

module WestpacComAu
  class Account

    attr_accessor :customer_id
    attr_accessor :password

    def initialize(*args)
      options = args.extract_options!
      @customer_id = options[:customer_id] || options['customer_id']
      @password = options[:password] || options['password']
      user_agent_alias = options[:user_agent_alias] || options['user_agent_alias'] || :chrome
      @driver = Selenium::WebDriver.for(user_agent_alias)
      @driver.manage.timeouts.implicit_wait = 5
      @driver_wait = Selenium::WebDriver::Wait.new(timeout: 180)
    end

    def login(customer_id = nil, password = nil)
      @logged_in = false
      customer_id ||= self.customer_id
      password ||= self.password
      attempts = 0
      loop do
        begin
          @driver.get('https://online.westpac.com.au/esis/Login/SrvPage?referrer=http%3A%2F%2Fwww.westpac.com.au%2FHomepageAlternative%2F')
          enter_customer_id
          enter_password
          sign_in
          break
        rescue Timeout::Error, Selenium::WebDriver::Error::UnknownError, Selenium::WebDriver::Error::NoSuchElementError => e
          attempts += 1
          if attempts >= 3
            @driver.quit
            puts "Giving up after 3 attempts to #{__method__} because #{e}."
            exit
          end
        end
      end
      @logged_in = @driver_wait.until do
        @driver.element_present?(:id, 'overview-dashboard') ||
        @driver.element_present?(:id, 'Overview.Accounts.List')
      end
    end

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
      submit_button.click
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

    def logout
      case
      when @driver.element_present?(:xpath, '//a[.="Sign Out"]') # The link provided on the dashboard page and most everywhere else.
        @driver.find_element(:xpath, '//a[.="Sign Out"]').click
      when @driver.element_present?(:xpath, '//a[.="Sign out"]') # The link provided on the "Multiple sessions" page.
        @driver.element_present?(:xpath, '//a[.="Sign out"]').click
      else # Failing the above, there's always just getting the link.
        @driver.get('https://banking.westpac.com.au/wbc/banking/handler?TAM_OP=logout')
      end
    end

    def shutdown
      logout
      @driver.quit
    end

    # boolean methods

    def logged_in?
      @logged_in
    end

    private

    # logging in

    def enter_customer_id
      customer_id_field.send_keys(customer_id)
    end

    def customer_id_field
      @driver.find_element(:id, 'username_temp')
    end

    def enter_password
      password.each_char{|char| password_button(char).click}
    end

    def password_button(char)
      @driver.find_element(:id, "keypad_0_kp#{char.upcase}")
    end

    def sign_in
      submit_button.click
    end

    def submit_button
      case
      when @driver.element_present?(:id, 'btn-submit')
        @driver.find_element(:id, 'btn-submit')
      when @driver.element_present?(:css, 'button')
        @driver.find_element(:css, 'button')
      end
    end

    # transactions-related

    def get_transactions_page
      if logged_in?
        @driver.get('https://banking.westpac.com.au/secure/banking/reportsandexports/home')
        @driver_wait.until{@driver.elements_present?(:css, '.action-stack .action-stack-item a')}
        @driver.find_elements(:css, '.action-stack .action-stack-item a').first.click
        sleep 5
        @driver_wait.until{@driver.element_present?(:css, 'h1')}
        return @driver.find_element(:css, 'h1').text == 'Transactions export'
      else
        login
        sleep 10
        get_transactions_page
      end
    end

    def from_date_field
      @driver.find_element(:xpath, '//div[@class="date-range-selector"]/div[@class="fiserv-date-picker from"]/label/input')
    end

    def to_date_field
      @driver.find_element(:xpath, '//div[@class="date-range-selector"]/div[@class="fiserv-date-picker to"]/label/input')
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

    def bank_account_dropdown_list
      @driver.find_element(:css, '.export-accountlist')
    end

    def select_bank_account(account_number)
      webdriver_select_list = Selenium::WebDriver::Support::Select.new(bank_account_dropdown_list)
      if option = webdriver_select_list.options.detect{|option| option.attribute(:text) =~ /#{account_number}/}
        option.click
      else
        raise "Can't find supplied account number from the dropdown list."
      end
    end

    def formatted_date(date)
      date = Date.parse(date) if date.is_a?(String)
      date.strftime("%d/%m/%Y")
    end

  end
end
