# HasReindexableAssociations [![Build Status](https://travis-ci.org/efigence/has_reindexable_associations.png?branch=master)](https://travis-ci.org/efigence/has_reindexable_associations) [![Coverage Status](https://coveralls.io/repos/github/efigence/has_reindexable_associations/badge.png?branch=master)](https://coveralls.io/github/efigence/has_reindexable_associations?branch=master) [![Code Climate](https://codeclimate.com/github/efigence/has_reindexable_associations/badges/gpa.svg)](https://codeclimate.com/github/efigence/has_reindexable_associations)
Keep specified associations in sync with ease using async reindexing ([searchkick](https://github.com/ankane/searchkick) gem is required).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'has_reindexable_associations'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install has_reindexable_associations

## Usage

```ruby
MyClass < ActiveRecord::Base
  include HasReindexableAssociations

  belongs_to :some_association
  has_many :some_associations

  has_reindexable_associations :some_association, :some_associations
end
```

### Handle imports

```ruby
# set `reindexable_associations_skip` class attribute to `true` before any seeds or imports to postpone the reindexing of associations
MyClass.reindexable_associations_skip = true

# import data
MyClass.import(...)

# reindex data
MyClass.reindex

# revert the configuration option
MyClass.reindexable_associations_skip = false

# reindex associations after import (repeat for each imported model, eg. MyClass, that has `has_reindexable_associations` configured)
MyClass.reindexable_associations.each { |association| MyClass.send(association).model.reindex }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/efigence/has_reindexable_associations. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
