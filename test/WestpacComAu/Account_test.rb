# test/WestpacComAu/Account_test.rb

# Notes:
# 1. No browser and no Westpac: only what doesn't depend on the site is tested. Every account which might reach for its browser is given a stand-in, so as none is started.

require_relative '../helper'

require 'date'

describe WestpacComAu::Account do
  def stand_in_element(displayed: true)
    element = Object.new
    element.define_singleton_method(:displayed?){displayed}
    element.define_singleton_method(:click){@clicked = true}
    element.define_singleton_method(:clicked?){!!@clicked}
    element.define_singleton_method(:clear){(@keys ||= []) << :clear}
    element.define_singleton_method(:send_keys){|keys| (@keys ||= []) << keys}
    element.define_singleton_method(:keys){@keys || []}
    element
  end

  # Finds the elements given for each selector type and value, and none for any other.
  def stand_in_driver(elements: {})
    driver = Object.new
    driver.define_singleton_method(:find_elements){|type, value| elements.fetch([type, value], [])}
    driver.define_singleton_method(:get){|url| (@urls ||= []) << url}
    driver.define_singleton_method(:urls){@urls || []}
    driver
  end

  def account_with_driver(driver, **args)
    account = WestpacComAu::Account.new(**args)
    account.instance_variable_set(:@driver, driver)
    account.instance_variable_set(:@logged_in, true)
    account.define_singleton_method(:default_find_timeout){0.1}
    account
  end

  describe "#username and #password" do
    it "are those given" do
      account = WestpacComAu::Account.new(username: 'customer', password: 'secret')
      _(account.username).must_equal('customer')
      _(account.password).must_equal('secret')
    end

    it "can be set after construction" do
      account = WestpacComAu::Account.new
      account.username, account.password = 'customer', 'secret'
      _(account.username).must_equal('customer')
      _(account.password).must_equal('secret')
    end
  end

  describe "#login" do
    it "names the one missing, before starting the browser" do
      account = WestpacComAu::Account.new(username: 'customer')
      _(_{account.login}.must_raise(ArgumentError).message).must_equal('password is missing.')
      _(account.instance_variable_get(:@driver)).must_be_nil
    end

    it "names both where both are missing" do
      _(_{WestpacComAu::Account.new.login}.must_raise(ArgumentError).message).must_equal('username, password are missing.')
    end

    it "takes either given to login itself as given" do
      _(_{WestpacComAu::Account.new.login(username: 'customer')}.must_raise(ArgumentError).message).must_equal('password is missing.')
    end
  end

  describe "#download_transactions" do
    def account_recording_steps
      account = account_with_driver(stand_in_driver)
      steps = []
      account.define_singleton_method(:get_transactions_page){steps << :get_transactions_page}
      account.define_singleton_method(:enter_dates){|from_date:, to_date:| steps << [:enter_dates, from_date, to_date]}
      account.define_singleton_method(:select_bank_account){|account_number| steps << [:select_bank_account, account_number]}
      account.define_singleton_method(:click){|selector| steps << [:click, selector]}
      account.define_singleton_method(:export_csv){steps << :export_csv; '/downloads/transactions.csv'}
      [account, steps]
    end

    it "sets the dates, the account and CSV, and is the file exported" do
      account, steps = account_recording_steps
      _(account.download_transactions(account_number: '123456', from_date: '2026-10-01', to_date: '2026-10-31')).must_equal('/downloads/transactions.csv')
      _(steps).must_equal([:get_transactions_page, [:enter_dates, '2026-10-01', '2026-10-31'], [:select_bank_account, '123456'], [:click, {id: 'File_type_1'}], :export_csv])
    end

    it "is the last year where neither a period nor a date is given" do
      account, steps = account_recording_steps
      account.download_transactions(account_number: '123456')
      _(steps[1]).must_equal([:enter_dates, Date.today.prev_year, Date.today])
    end

    it "requires an account number, before going to the transactions page" do
      account, steps = account_recording_steps
      _(_{account.download_transactions}.must_raise(ArgumentError).message).must_equal('missing keyword: :account_number')
      _(steps).must_be_empty
    end
  end

  describe "the selectors" do
    it "are Westpac's where none is given" do
      account = WestpacComAu::Account.new
      _(account.login_page_url).must_equal('https://banking.westpac.com.au/wbc/banking/handler?TAM_OP=login&segment=personal&logout=false')
      _(account.login_page_username_field_selector).must_equal({id: 'fakeusername'})
      _(account.login_page_password_field_selector).must_equal({id: 'password'})
      _(account.login_page_submit_button_selector).must_equal({id: 'signin'})
      _(account.logout_button_selector).must_equal({xpath: '//a[normalize-space()="Sign Out"]'})
      _(account.logged_out_selector).must_equal({css: 'form#logout, form#login'})
    end

    it "are those given to new, or set afterwards, over Westpac's" do
      account = WestpacComAu::Account.new(logout_button_selector: {id: 'signout'})
      account.logged_out_selector = {css: 'form#logout'}
      _(account.logout_button_selector).must_equal({id: 'signout'})
      _(account.logged_out_selector).must_equal({css: 'form#logout'})
      _(account.login_page_username_field_selector).must_equal({id: 'fakeusername'})
    end
  end

  describe "the cookie notice" do
    it "is declined, with Accept essential only, where it's showing" do
      button = stand_in_element
      account = account_with_driver(stand_in_driver(elements: {[:id, 'didomi-notice-disagree-button'] => [button]}))
      account.send(:decline_cookies)
      _(button.clicked?).must_equal(true)
    end

    it "is left where it's there but not showing" do
      button = stand_in_element(displayed: false)
      account = account_with_driver(stand_in_driver(elements: {[:id, 'didomi-notice-disagree-button'] => [button]}))
      _(account.send(:decline_cookies)).must_be_nil
      _(button.clicked?).must_equal(false)
    end

    it "is passed over where there's none" do
      account = account_with_driver(stand_in_driver)
      _(account.send(:decline_cookies)).must_be_nil
    end

    it "is declined on getting the login page" do
      button = stand_in_element
      driver = stand_in_driver(elements: {[:id, 'didomi-notice-disagree-button'] => [button]})
      account = account_with_driver(driver)
      account.send(:get_login_page)
      _(driver.urls).must_equal([WestpacComAu::Account::PAGE_SELECTORS[:login_page_url]])
      _(button.clicked?).must_equal(true)
    end
  end

  describe "#dates" do
    def dates(**args)
      WestpacComAu::Account.new.send(:dates, **{period: nil, from_date: nil, to_date: nil}.merge(args))
    end

    it "is the last year for :all" do
      _(dates(period: :all)).must_equal([Date.today.prev_year, Date.today])
    end

    it "is last month for :last_month" do
      today = Date.today
      _(dates(period: :last_month)).must_equal([Date.new(today.prev_month.year, today.prev_month.month, 1), Date.new(today.year, today.month, 1) - 1])
    end

    it "is the dates given, defaulting either to a year ago or today" do
      _(dates(from_date: '2026-01-01', to_date: '2026-02-01')).must_equal(['2026-01-01', '2026-02-01'])
      _(dates(from_date: '2026-01-01')).must_equal(['2026-01-01', Date.today])
      _(dates(to_date: '2026-02-01')).must_equal([Date.today.prev_year, '2026-02-01'])
      _(dates).must_equal([Date.today.prev_year, Date.today])
    end

    it "refuses a period it doesn't know" do
      _{dates(period: :fortnight)}.must_raise(ArgumentError)
    end
  end

  describe "#formatted_date" do
    it "is day/month/year, from a Date or a String" do
      account = WestpacComAu::Account.new
      _(account.send(:formatted_date, Date.new(2026, 3, 4))).must_equal('04/03/2026')
      _(account.send(:formatted_date, '2026-03-04')).must_equal('04/03/2026')
    end
  end

  describe "#enter_dates" do
    def stand_in_date_field(value)
      field = Object.new
      field.instance_variable_set(:@value, value)
      field.define_singleton_method(:attribute){|name| @value if name == 'value'}
      field.define_singleton_method(:value=){|value| @value = value}
      field
    end

    # An account whose set_value() sets the field, or, where the page throws the value away, doesn't.
    def account_with_date_fields(from_field, to_field, taking: true)
      account = account_with_driver(stand_in_driver)
      account.define_singleton_method(:find){|selector| selector == {id: 'DateRange_StartDate'} ? from_field : to_field}
      account.define_singleton_method(:set_value){|field, value| field.value = value if taking}
      account
    end

    it "sets the from and to fields" do
      from_field, to_field = stand_in_date_field('16/11/2026'), stand_in_date_field('16/11/2026')
      account = account_with_date_fields(from_field, to_field)
      account.send(:enter_dates, from_date: Date.new(2026, 10, 1), to_date: Date.new(2026, 10, 31))
      _([from_field, to_field].map{|field| field.attribute('value')}).must_equal(['01/10/2026', '31/10/2026'])
    end

    it "says so where the dates didn't take, rather than exporting another range" do
      account = account_with_date_fields(stand_in_date_field('16/11/2026'), stand_in_date_field('16/11/2026'), taking: false)
      error = _{account.send(:enter_dates, from_date: Date.new(2026, 10, 1), to_date: Date.new(2026, 10, 31))}.must_raise(RuntimeError)
      _(error.message).must_include('01/10/2026 to 31/10/2026')
    end
  end

  describe "#export_csv" do
    it "is the download which finishes after Export is clicked" do
      account = account_with_driver(stand_in_driver)
      clicked = []
      account.define_singleton_method(:click){|selector| clicked << selector}
      account.define_singleton_method(:wait_for_download){|since:| since.is_a?(Time) && '/downloads/transactions.csv'}
      _(account.send(:export_csv)).must_equal('/downloads/transactions.csv')
      _(clicked).must_equal([{css: 'button.export-link'}])
    end
  end
end
