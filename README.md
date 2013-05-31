Recalls API Server
==============

[![Build Status](https://travis-ci.org/GSA-OCSIT/recalls_api.png)](https://travis-ci.org/GSA-OCSIT/recalls_api)

When you're buying and using products, safety comes first. 

## Access the Data

Use our [Recalls API](http://usasearch.howto.gov/developer/recalls.html) to tap into a list of car, drug, food, and product safety data and recalls.

See the most recent recalls in [JSON](http://api.usa.gov/recalls/recent.json) or [RSS](http://api.usa.gov/recalls/recent.rss).

You can also see how this data is used when [searching for recalls on USA.gov](http://search.usa.gov/search/news?affiliate=usagov&channel=66).

## Contribute to the Code

The server code that runs our [Recalls API](http://usasearch.howto.gov/developer/recalls.html) is here on Github. If you're a Ruby developer, keep reading. Fork this repo to add features (such as additional datasets) or fix bugs.

### Ruby

You'll need [Ruby 2.0](http://www.ruby-lang.org/en/downloads/).

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

### API Versioning

We support API versioning with json format. The current version is v1.

You can specify a a specific JSON version of recalls data like this:

    curl -H 'Accept: application/vnd.usagov.recalls.v1' http://localhost:3000/search.json
    
### Parameters

Seven generic parameters are accepted: (1) query, (2) organization, (3) start_date, (4) end_date, (5) page, (6) per_page, and (7) sort. There are additional parameters that are specific to food, product, and car safety recalls. None are required.

Full documentation on the parameters is in our [Recalls API documentation](http://usasearch.howto.gov/developer/recalls.html#parameters).

## Tests

Tests require a Solr server to be spun up.

    bundle exec rake sunspot:solr:start RAILS_ENV=test

Make sure the tests run:

    bundle exec rake spec

## Code Coverage

We track test coverage of the codebase over time, to help identify areas where we could write better tests and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/rcov/index.html` in your browser.

Click around on the files that have < 100% coverage to see what lines weren't exercised.

## License

This project is covered under the terms of the GNU General Public License, version 2 or later.

## Terms of Use

By accessing this Recalls API server, you agree to our [Terms of Service](http://www.usa.gov/About/developer-resources/terms-of-service.shtml).

Feedback
--------

You can send feedback via [Github Issues](https://github.com/GSA-OCSIT/recalls_api/issues).

-----
