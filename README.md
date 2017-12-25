# Etc

[![Build Status](https://travis-ci.org/ruby/etc.svg?branch=master)](https://travis-ci.org/ruby/etc)

The Etc module provides access to information typically stored in files in the /etc directory on Unix systems.

The information accessible consists of the information found in the `/etc/passwd` and `/etc/group` files, plus information about he system's temporary directory (/tmp) and configuration directory (/etc).

The Etc module provides a more reliable way to access information about the logged in user than environment variables such as +$USER+.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'etc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install etc

## Usage

```ruby
require 'etc'

login = Etc.getlogin
info = Etc.getpwnam(login)
username = info.gecos.split(/,/).first
puts "Hello #{username}, I see your login name is #{login}"
```

Note that the methods provided by this module are not always secure. It should be used for informational purposes, and not for security.

All operations defined in this module are class methods, so that you can include the Etc module into your class.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/etc.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
