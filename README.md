Recalls API
==============

**Note:** The endpoint for our [Recalls API](http://search.digitalgov.gov/developer/recalls.html) will be deprecated on January 31, 2015. The source code will remain on here on Github, if you'd like to clone or fork it.

### Ruby

This code is currently tested against [Ruby 2.1](http://www.ruby-lang.org/en/downloads/).

### Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

### Solr

We're using [Solr](http://lucene.apache.org/solr/) for fulltext search. You can start/stop/reindex Solr like this:

    bundle exec rake sunspot:solr:start
    bundle exec rake sunspot:solr:stop
    bundle exec rake sunspot:solr:run
    bundle exec rake sunspot:solr:reindex

### Database

`database.yml` assumes you have a local database server up and running (preferably [MySQL](http://www.mysql.com/) >= 5.1.65), accessible from user 'root' with no password.

Create and setup your development and test databases:

    bundle exec rake db:setup
    bundle exec rake db:setup RAILS_ENV=test

### Seed data

Populate recall data for your development database:

    bundle exec rake usagov:recalls:import_cdc_data
    bundle exec rake usagov:recalls:import_cpsc_data
    bundle exec rake usagov:recalls:import_nhtsa_data

You need to run these tasks daily to receive the latest recalls data.

### Running it

Fire up a server and try it all out:

    bundle exec rails s

<http://127.0.0.1:3000/search.json?query=stroller>

### Parameters

Seven generic parameters are accepted: (1) query, (2) organization, (3) start_date, (4) end_date, (5) page, (6) per_page, and (7) sort. There are additional parameters that are specific to food, product, and car safety recalls. None are required.

Full documentation on the parameters is in our [Recalls API documentation](http://search.digitalgov.gov/developer/recalls.html#parameters).

## Tests

Tests require a Solr server to be spun up.

    bundle exec rake sunspot:solr:start RAILS_ENV=test

Make sure the tests run:

    bundle exec rake spec

## Code Coverage

Track test coverage of the codebase over time to help identify areas where better tests could be written and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/rcov/index.html` in your browser.

Click around on the files that have < 100% coverage to see what lines weren't exercised.
