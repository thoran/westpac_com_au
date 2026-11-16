# westpac_com_au

## Description

Log into Westpac Online Banking (banking.westpac.com.au) and export an account's transactions as a CSV file.

It drives a browser via Selenium WebDriver and WebAccount.

## Installation

Add this line to your application's Gemfile:
```ruby
gem 'westpac_com_au'
```
And then execute:
```shell
$ bundle
```
Or install it yourself as:
```shell
$ gem install westpac_com_au
```

## Usage

### Downloading transactions
```ruby
  require 'westpac_com_au'

  westpac_account = WestpacComAu::Account.new(username: customer_id, password: password)
  westpac_account.login
  westpac_account.download_transactions(account_number: '123456')
  # => "/Users/me/Downloads/Data_export_16112026.csv"
  westpac_account.shutdown # Logs out if still logged in, then quits the browser.
```
The account number is typed into the export page's account field, and the account Westpac suggests for it is taken. The transactions are exported as CSV.

Without a period or dates, they're those of the last year. Otherwise:
```ruby
  westpac_account.download_transactions(account_number: '123456', period: :last_month)
  westpac_account.download_transactions(account_number: '123456', period: :all) # The last year.
  westpac_account.download_transactions(account_number: '123456', from_date: '2026-01-01', to_date: '2026-06-30')
```
Dates are Dates, or Strings `Date.parse` can read. Where only one of `from_date` and `to_date` is given, the other is a year ago or today.

`download_transactions` waits for the download to finish, and returns the newest CSV file to have appeared in the download directory since Export was clicked.

Or in one step, logging in, downloading, and shutting down even where the download fails:
```ruby
  WestpacComAu::Transactions.download_csv_file(account_number: '123456', username: customer_id, password: password, period: :last_month)
```
It takes `period:`, `from_date:` and `to_date:` as `download_transactions` does. `web_account_options:` are passed to `WestpacComAu::Account.new`:
```ruby
  WestpacComAu::Transactions.download_csv_file(account_number: '123456', username: customer_id, password: password, web_account_options: {download_directory: '~/path/to/statements'})
```

### Credentials

The username is the customer ID. It and the password are given, or set afterwards:
```ruby
  westpac_account.username, westpac_account.password = customer_id, password
```
Where either is missing, `login` raises ArgumentError before starting the browser, naming every one missing.

### The browser

The browser is WebAccount's: Chrome, unless `browser: :firefox` is given. Given a `profile_directory`, it's started with that profile, kept between runs; without one, each run has a new, temporary profile.
```ruby
  WestpacComAu::Account.new(profile_directory: '~/path/to/profile')
```
It downloads into `download_directory`, `~/Downloads` unless given, without asking where. `headless:`, `window_size:` and `user_agent:` are passed to WebAccount too, and `driver_options:` replaces the browser's options altogether.

Where Westpac's cookie notice is showing, Accept essential only is clicked. Where Westpac asks for a one-time code after signing in, `login` waits up to 30 seconds for it to be entered in the browser.

## Westpac's site

Each version worked against Westpac's site of its time. Only the latest is meant to work now.

| Westpac's site | Seen | WestpacComAu |
|---|---|---|
| Keypad password, select list of accounts, export reached from the reports page | 20140628 | 0.0.0–0.0.14 |
| Export link moved, submit button lost its id | by 20150208 | 0.1.0 |
| Account chosen in a text field | by 20160403 | 0.2.0 |
| Username field, keypad buttons and submit button renamed | by 20160820 | 0.3.0–0.4.0 |
| Keypad replaced by a password field; account field changed | about 2018, met 20190908 | 0.5.0–0.5.3 |
| Login at banking.westpac.com.au, a signed-out page | by 2023 | 0.6.0 |
| A cookie notice | 2026 | 0.6.0 |

## Limitations

The selectors were taken from the live site, and a change to it will break them.

Each key of `WestpacComAu::Account::PAGE_SELECTORS` is also a keyword of `new`, and has a setter, either of which wins over Westpac's, so as a selector which has changed can be given without waiting for a new version:
```ruby
  WestpacComAu::Account.new(logout_button_selector: {xpath: '//a[normalize-space()="Sign out"]'})
  westpac_account.logged_out_selector = {css: 'form#logout'}
```

The tests cover only what doesn't depend on Westpac's site.

## Contributing

1. Fork it: https://github.com/thoran/westpac_com_au/fork
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new pull request
