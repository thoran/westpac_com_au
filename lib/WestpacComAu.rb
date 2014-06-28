# WestpacComAu.rb
# WestpacComAu

# 20140628
# 0.0.1

require 'Array/extract_optionsX'
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
      @driver_wait = Selenium::WebDriver::Wait.new(timeout: 30)
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
      @logged_in = @driver_wait.until{@driver.element_present?(:id, 'overview-dashboard')}
    end

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

    def logged_in?
      @logged_in
    end

    private

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
      @driver.find_element(:id, 'btn-submit')
    end

  end
end
