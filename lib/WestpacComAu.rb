# WestpacComAu.rb
# WestpacComAu

# 20140628
# 0.0.0

# https://online.westpac.com.au/esis/Login/SrvPage?referrer=http%3A%2F%2Fwww.westpac.com.au%2FHomepageAlternative%2F
# username_temp
# keypad_0_kp1..keypad_0_kp9
# keypad_0_kpA..keypad_0_kpM
# keypad_0_kpN..keypad_0_kpZ
# btn-submit

require 'Array/extract_optionsX'
require 'selenium-webdriver'

module WestpacComAu
  class Account

    attr_accessor :customer_id
    attr_accessor :password

    def initialize(*args)
      options = args.extract_options!
      user_agent_alias = options[:user_agent_alias] || options['user_agent_alias'] || :chrome
      @customer_id = options[:customer_id] || options['customer_id']
      @password = options[:password] || options['password']
      @http_client = Selenium::WebDriver.for(user_agent_alias)
      @http_client.manage.timeouts.implicit_wait = 5
    end

    def login(customer_id = nil, password = nil)
      customer_id ||= self.customer_id
      password ||= self.password
      attempts = 0
      loop do
        begin
          @http_client.get('https://online.westpac.com.au/esis/Login/SrvPage?referrer=http%3A%2F%2Fwww.westpac.com.au%2FHomepageAlternative%2F')
          enter_customer_id
          enter_password
          sign_in
          break
        rescue Timeout::Error, Selenium::WebDriver::Error::UnknownError, Selenium::WebDriver::Error::NoSuchElementError => e
          attempts += 1
          if attempts >= 3
            @http_client.quit
            puts "Giving up after 3 attempts to #{__method__} because #{e}."
            exit
          end
        end
      end
    end

    private

    def enter_customer_id
      customer_id_field.send_keys(customer_id)
    end

    def customer_id_field
      @http_client.find_element(:id, 'username_temp')
    end

    def enter_password
      password.each_char{|char| password_button(char).click}
    end

    def password_button(char)
      @http_client.find_element(:id, "keypad_0_kp#{char.upcase}")
    end

    def sign_in
      submit_button.click
    end

    def submit_button
      @http_client.find_element(:id, 'btn-submit')
    end

  end
end
