Recalls API Server
==============

## Purpose

The Recalls API Server provides access to searchable food, car, and product safety data and recalls. This data comes from three federal government sources: (1) food safety data from [FoodSafety.gov](http://www.foodsafety.gov); (2) car safety data from the [National Highway Traffic Safety Administration](http://www.nhtsa.gov/); and (3) product safety data from the [Consumer Product Safety Commission](http://www.cpsc.gov). 

You can see how this data is used when [searching for recalls on USA.gov](http://search.usa.gov/search/news?affiliate=usagov&channel=66).

## Ruby

You will need Ruby 1.9.3.

## Gems

We use bundler to manage gems.
You can install bundler and other required gems like this:

    gem install bundler
    bundle install

## Solr

We're using Solr for fulltext search.

You can start/stop/reindex Solr like this:

    bundle exec rake sunspot:solr:start
    bundle exec rake sunspot:solr:stop
    bundle exec rake sunspot:solr:run
    bundle exec rake sunspot:solr:reindex

# Database

The database.yml file assumes you have a local database server up and running (preferably MySQL >= 5.1.65), accessible from user 'root' with no password.

Create and setup your development and test databases:

    bundle exec rake db:setup
    bundle exec rake db:setup RAILS_ENV=test

# Seed data

Populate recall data for your development database:

    bundle exec rake usagov:recalls:import_cdc_data
    bundle exec rake usagov:recalls:import_cpsc_data
    bundle exec rake usagov:recalls:import_nhtsa_data

You need to run these tasks daily to receive the latest recalls data.

# Running it

Fire up a server and try it all out:

    bundle exec rails s

<http://127.0.0.1:3000/search.json?query=stroller>

For additional parameters, see <https://github.com/GSA-OCSIT/recalls_api/wiki/GET-search>

For most recent recall in JSON, <http://127.0.0.1:3000/recent.json>

For most recent recall in RSS, <http://127.0.0.1:3000/recent.rss>

You can use browser extensions to view json data.

For Chrome: <https://chrome.google.com/webstore/search/json?hl=en-US>

For Firefox: <https://addons.mozilla.org/en-US/firefox/search/?q=json>

# API Versioning

We support API versioning with json format. The current version is v1.

You can specify a a specific JSON version of recalls data like this:

    curl -H 'Accept: application/vnd.usagov.recalls.v1' http://localhost:3000/search.json

# Tests

These require a Solr server to be spun up.

    bundle exec rake sunspot:solr:start RAILS_ENV=test

Make sure the tests run:

    bundle exec rake spec

# Code Coverage

We track test coverage of the codebase over time, to help identify areas where we could write better tests and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/rcov/index.html` in your favorite browser.

You can click around on the files that have < 100% coverage to see what lines weren't exercised.

#LICENSE

This project is covered under the terms of the GNU General Public License, version 2 or later.
