Recalls API
==============

**Note:** The endpoint for our Recalls API was deprecated on March 27, 2015. The source code will remain here on Github, if you'd like to clone or fork it.

## Ruby

This code is currently tested against [Ruby 2.1](http://www.ruby-lang.org/en/downloads/).

## Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

## Solr

We're using [Solr](http://lucene.apache.org/solr/) for fulltext search. You can start/stop/reindex Solr like this:

    bundle exec rake sunspot:solr:start
    bundle exec rake sunspot:solr:stop
    bundle exec rake sunspot:solr:run
    bundle exec rake sunspot:solr:reindex

## Database

`database.yml` assumes you have a local database server up and running (preferably [MySQL](http://www.mysql.com/) >= 5.1.65), accessible from user 'root' with no password.

Create and setup your development and test databases:

    bundle exec rake db:setup
    bundle exec rake db:setup RAILS_ENV=test

## Seed data

Populate recall data for your development database:

    bundle exec rake usagov:recalls:import_cdc_data
    bundle exec rake usagov:recalls:import_cpsc_data
    bundle exec rake usagov:recalls:import_nhtsa_data

You need to run these tasks daily to receive the latest recalls data.

## Running it

Fire up a server and try it all out:

    bundle exec rails s

<http://127.0.0.1:3000/search.json?query=stroller>

## Parameters

Seven generic parameters are accepted.

1. query
1. organization
1. start_date
1. end_date
1. page
1. per_page
1. sort

There are additional parameters that are specific to food, product, and car safety recalls. None are required.

### query

Attempts to extract as much "signal" as possible from the input text. Handles word variants, so a search on "choke" will find a recall categorized as a "choking" hazard.

### organization

Specifies which agency issued the recall. Possible values are `CPSC`, `FDA`, `NHTSA`, or `USDA`.

Example (one agency): <http://127.0.0.1:3000/recalls/search.json?organization=nhtsa>

Example (multiple agencies): <http://127.0.0.1:3000/recalls/search.json?organization=fda+usda>

### start_date

Specifies the start date of the recall.

Example: <http://127.0.0.1:3000/recalls/search.json?start_date=2012-01-01>

### end_date

Specifies the end date of the recall.

Example: <http://127.0.0.1:3000/recalls/search.json?end_date=2012-12-31>

### page

Specifies the pagination of search results. Possible values are `1` to `20`.

Example: <http://127.0.0.1:3000/recalls/search.json?page=3>

### per_page

Specifies the number of search results for each page. Possible values are `1` to `50`.

Example: <http://127.0.0.1:3000/recalls/search.json?per_page=10>

### sort

Results are sorted by relevance by default. Possible values are `rel` or `date`. Use 'sort=date' to sort results by date with the most recent listed first.

Example: <http://127.0.0.1:3000/recalls/search.json?sort=date>

### food_type 
Only for drug and food safety recalls. Possible values are `food` or `drug`.

Example: <http://127.0.0.1:3000/recalls/search.json?food_type=drug>

### upc

Only for CPSC recalls. Specifies the UPC code when available. Not all products have UPC codes.

Example: <http://127.0.0.1:3000/recalls/search.json?upc=042666601627>

### make, model, year, and code (only for NHTSA recalls)

* `make` specifies the make of the vehicle or equipment. Example: <http://127.0.0.1:3000/recalls/search?make=winnebago>
* `model` specifies the model of the vehicle or equipment. Example: <http://127.0.0.1:3000/recalls/search?model=ellipse>
* `year` specifies the year of the vehicle or equipment. Example: <http://127.0.0.1:3000/recalls/search?year=2010>
* `code` specifies the NHTSA code. Possible values are `E`, `V` [for vehicles], `I`, `T`, `C`, or `X`. Example: <http://127.0.0.1:3000/recalls/search?code=v>

<a name="data-sources"></a>

## Data Sources

Data are normalized across (1) drug and food safety recalls from the [FDA](http://www.fda.gov), [UDSA FSIS](http://www.fsis.usda.gov/wps/portal/fsis/home), and [FoodSafety.gov](http://www.FoodSafety.gov); (2) car safety recalls from the [NHTSA](http://www.nhtsa.gov); and (3) product safety recalls from the [CPSC](http://www.cpsc.gov).

We encourage you to use the five original data sources directly or via [Recalls.gov](http://www.recalls.gov).

1. [FDA recalls, market withdrawals, and safety alerts](http://www.fda.gov/Safety/Recalls/default.htm)
2. [USDA FSIS recalls and public health alerts](http://www.fsis.usda.gov/wps/portal/fsis/topics/recalls-and-public-health-alerts)
3. [FoodSafety.gov recalls and alerts](http://www.foodsafety.gov/recalls)
4. [NHTSA recalls and defects](http://www.nhtsa.gov/Vehicle+Safety/Recalls+&+Defects)
5. [CPSC recalls](http://www.cpsc.gov/Recalls/)

<a name="what-it-returns"></a>

## What it Returns

Below are three sample JSON responses for food, product, and car safety recalls.

### Food Recalls

	{
		success: {
			total: 82,
			results: [
				{
					organization: "USDA",
					recall_number: "1df0a5440b",
					recall_date: "2011-05-14",
					recall_url: "http://www.fsis.usda.gov/News_&_Events/Recall_037_2011_Release/index.asp",
					description: "Rose & Shore Meat Co., a Vernon, Calif., establishment, is recalling approximately 15,900 pounds of ready-to-eat deli meat products that may be contaminated with Listeria monocytogenes.",
					summary: "California Firm Recalls Deli Meat Products for Possible Listeria Contamination"
				},
				{
					organization: "FDA",
					recall_number: "51d9096a25",
					recall_date: "2010-06-21",
					recall_url: "http://www.fda.gov/Safety/Recalls/ucm216371.htm",
					description: "Portland Shellfish Company, Inc. is expanding this voluntarily recall to include the Meat Without Feet private label food service (2 Lb bags), pack of ready to eat frozen lobster claw and knuckle meat. Lot 13310, as recent tests show the product has the potential to be contaminated with Listeria monocytogenes, an organism which can cause serious and sometimes fatal infections in young children, frail or elderly people, and others with weakened immune systems",
					summary: "Portland Shellfish Company Expands Recall to Include Meat Without Feet Label, Lobster Claw and Knuckle Meat, because of Possible Health Risk"
				}
		    ]
	}}

### Product Recalls

	{"success":{
	    "total":2,
	    "results":[
	        {
	            "organization":"CPSC",
	            "recall_number":"12080",
	            "recall_date":"2012-01-05",
	            "recall_url":"http://www.cpsc.gov/cpscpub/prerel/prhtml12/12080.html",
	            "manufacturers":["Target"],
	            "product_types":["Lights & Accessories"],
	            "descriptions":["Target 6-pc. LED Flashlight Sets"],
	            "upcs":["490021010049"],
	            "hazards":["Fire & Fire-Related Burn"],
	            "countries":["China"]
	        },
	        {
	            "organization":"CPSC",
	            "recall_number":"12710",
	            "recall_date":"2012-01-05",
	            "recall_url":"http://www.cpsc.gov/cpscpub/prerel/prhtml12/12710.html",
	            "manufacturers":["Sterno"],
	            "product_types":["Candles & Candle Holders"],
	            "descriptions":["Sterno Bulk Pack 5 Hour Tea Lights"],
	            "upcs":null,
	            "hazards":["Fire & Fire-Related Burn"],
	            "countries":["Thailand"]
	        }
	    ]
	}}

### Car Recalls

	{"success":{
	    "total":2,
	    "results":[
	        {
	            "organization":"NHTSA",
	            "recall_number":"12V579000",
	            "recall_date":"2012-12-18",
	            "recall_url":"http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=12V579000&summary=true&PrintVersion=YES",
	            "records":[
	                {
	                    "component_description":"VISIBILITY/WIPER",
	                    "make":"SPARTAN",
	                    "manufacturer":"Spartan Chassis, Inc.",
	                    "manufacturing_begin_date":"2012-10-01",
	                    "manufacturing_end_date":"2012-10-31",
	                    "model":"GLADIATOR",
	                    "recalled_component_id":"000051813001317776000001349",
	                    "year":2012
	                },
	                {
	                    "component_description":"VISIBILITY/WIPER",
	                    "make":"SPARTAN",
	                    "manufacturer":"Spartan Chassis, Inc.",
	                    "manufacturing_begin_date":"2012-10-01",
	                    "manufacturing_end_date":"2012-10-31",
	                    "model":"METROSTAR",
	                    "recalled_component_id":"000051813001317777000001349",
	                    "year":2012
	                }
	            ],
	            "manufacturer_campaign_number":"12016",
	            "component_description":"VISIBILITY/WIPER",
	            "manufacturer":"Spartan Chassis, Inc.",
	            "code":"V",
	            "potential_units_affected":"36",
	            "initiator":"MFR",
	            "report_date":"20121210",
	            "defect_summary":"Spartan Motors Chassis is recalling certain model year 2012-2013 Gladiator, Metro Star, Metro Star-X, and Force emergency rescue chassis cabs built between October 1, 2012, through October 31, 2012.  The wiper motor shaft and the wiper arm shaft have diff",
	            "consequence_summary":"If the windshield wipers become inoperative, the driver could have reduced visibility, which may increase the risk of a crash.  ",
	            "corrective_summary":"The remedy for this recall campaign is still under development.  The manufacturer has not yet provided a notification schedule.  Owners may contact Spartan at 1-800-543-5008.",
	            "notes":"Spartan's recall campaign number is 12016.Owners may also contact the National Highway Traffic Safety Administration Vehicle Safety Hotline at 1-888-327-4236 (TTY 1-800-424-9153), or go to www.safercar.gov.",
	            "recall_subject":"Windshield Wipers may become Inoperative"
	        },
	        {
	            "organization":"NHTSA",
	            "recall_number":"12V571000",
	            "recall_date":"2012-12-18",
	            "recall_url":"http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=12V571000&summary=true&PrintVersion=YES",
	            "records":[
	                {
	                    "component_description":"FUEL SYSTEM, GASOLINE:DELIVERY:FUEL PUMP",
	                    "make":"JAGUAR",
	                    "manufacturer":"JAGUAR CARS LTD",
	                    "manufacturing_begin_date":"2012-10-03",
	                    "manufacturing_end_date":"2012-10-12",
	                    "model":"XF",
	                    "recalled_component_id":"000051654001723816000000152",
	                    "year":2013
	                },
	                {
	                    "component_description":"ELECTRICAL SYSTEM",
	                    "make":"JAGUAR",
	                    "manufacturer":"JAGUAR CARS LTD",
	                    "manufacturing_begin_date":"2012-10-03",
	                    "manufacturing_end_date":"2012-10-12",
	                    "model":"XF",
	                    "recalled_component_id":"000051654001723816000000200",
	                    "year":2013
	                }
	            ],
	            "manufacturer_campaign_number":"J028",
	            "component_description":"ELECTRICAL SYSTEM",
	            "manufacturer":"Jaguar Land Rover North America, LLC",
	            "code":"V",
	            "potential_units_affected":"13",
	            "initiator":"MFR",
	            "report_date":"20121207",
	            "defect_summary":"Jaguar Land Rover is recalling certain model year 2013 XF vehicles manufactured October 3, 2012, through October 12, 2012 and equipped with a gasoline engine.",
	            "consequence_summary":"An engine stall without warning while driving may lead to a loss of motive power, a loss of power-assisted braking and a loss of power-assisted steering.",
	            "corrective_summary":"Jaguar Land Rover will notify owners, and dealers will install an additional wiring harness to the in-tank fuel pump, free of charge.",
	            "notes":"Jaguar's campaign recall number is J028.Owners may also contact the National Highway Traffic Safety Administration Vehicle Safety Hotline at 1-888-327-4236 (TTY 1-800-424-9153), or go to www.safercar.gov.",
	            "recall_subject":"Fuel Starvation may cause Vehicle Stall"
	        }
	    ]
	}}

## Tests

Tests require a Solr server to be spun up.

    bundle exec rake sunspot:solr:start RAILS_ENV=test

Make sure the tests run:

    bundle exec rake spec

## Code Coverage

Track test coverage of the codebase over time to help identify areas where better tests could be written and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/rcov/index.html` in your browser.

Click around on the files that have < 100% coverage to see what lines weren't exercised.
