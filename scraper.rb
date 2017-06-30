# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# require 'scraperwiki'
# require 'mechanize'
#
# agent = Mechanize.new
#
# # Read in a page
# page = agent.get("http://foo.com")
#
# # Find somehing on the page using css selectors
# p page.at('div.content')
#
# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
#!/usr/bin/env ruby

require 'scraperwiki'

# Saving data:
# unique_keys = [ 'id' ]
# data = { 'id'=>12, 'name'=>'violet', 'age'=> 7 }
# ScraperWiki.save_sqlite(unique_keys, data)

require 'nokogiri'
require 'json'
require 'rubygems'
require 'mechanize'
require 'csv'

# SPECIFY YOUR VARIBLES HERE:
url = 'http://planning.basildon.gov.uk/online-applications/search.do?action=advanced' #link to the advanced search page on the local authority website
url_beginning = "http://planning.basildon.gov.uk" #the first bit of the url (ending with "gov.uk")
council = "Basildon" #specify the council name
startDate = "01/06/2017" #specify decision date start
endDate = "10/06/2017" #specify decision date end
# ALSO, CHECK OPTIONS IN 3 PLACES OF THIS CODE MARKED WITH *****
# and make a copy of the HTML code regarding selections
# available under the application type and development type fields

# PART 1
# THIS IS TO FETCH ALL APPLICATIONS IN THE TIME PERIOD SPECIFIED ABOVE
# ALONG WITH THEIR REFERENCE NUMBER, ALTERNATIVE REFERENCE NUMBER,
# RECEIVED DATE, VALIDATED DATE, ADDRESS, PROPOSAL, DECISION
# OUTCOME AND DECISION DATE. THEN, TO PUSH THE DATA
# TO THE SQLITE TABLE
# TWO FIELDS: APPLICATION TYPE AND DEVELOPMENT TYPE ARE ADDED
# IN PARTS 2 AND 3 OF THIS CODE. CONCIL NAMES AND URLS OF EACH
# INDIVIDUAL APPLICATION ARE ALSO ADDED IN THIS CODE.

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url)

# this is to print the page to see what html names are used for
# the form and fields
#pp page

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# this is to set the values of two fields of the form
search_form['date(applicationDecisionStart)'] = startDate
search_form['date(applicationDecisionEnd)'] = endDate

# this is to submit the form
page = agent.submit(search_form)

# this is to create an empty array to store the links (results)
links_array = []

# the following loop is to find all links on the page which include
# the "applicationDetails" wording and store them in the links_array
# then, to move to the "next" page and do the same,
# until there is no "next"

loop do
	page.links.each do |link|
		if link.href.include?"applicationDetails"
		links_array.push(link.href)
		end
	end

	if link = page.link_with(:text => "Next")
	page = link.click
	else break
	end
end

# this is to convert the links to strings,
# then, to suplement urls with the missing text:
# "http://planning.xxxxxxxx.gov.uk"

links_array.map! do |item|
	item.to_s
	item = "#{url_beginning}#{item}"
end

# *****
# this is to define empty arrays where we will store all the details
# on individual applications
reference_array = []
altreference_array = []
received_array = []
validated_array = []
address_array = []
proposal_array = []
outcome_array = []
decided_array = []

# the following .each method is to scrap the data on the aplications'
# reference number, alternative reference number, 
# receival date, application validation date
# address of the development, proposed development, decision
# oucome (granted or refused), decision date and council. 
# Then, to store the scraped data in the relevant arrays

links_array.each do |application|

# this is to instantiate a new mechanize object
    agent = Mechanize.new

# this is to fetch the webpage and parse HTML using Nokogiri
    sub_page = ScraperWiki::scrape(application)
    parse_sub_page = Nokogiri::HTML(sub_page)

# *****
# this is to parse the data, remove spaces and push the data
# to the relevant arrays. The code also removes comas from
# the proposal descriptions. Please check and amend the td
# positions in brackets: []

	reference = parse_sub_page.css('#simpleDetailsTable').css('td')[0].text
	reference_tidied = reference.strip
	reference_array.push(reference_tidied)

	altreference = parse_sub_page.css('#simpleDetailsTable').css('td')[1].text
	altreference_tidied = altreference.strip
	altreference_array.push(altreference_tidied)

	received = parse_sub_page.css('#simpleDetailsTable').css('td')[2].text
	received_tidied = received.strip
	received_array.push(received_tidied)

	validated = parse_sub_page.css('#simpleDetailsTable').css('td')[3].text
	validated_tidied = validated.strip
	validated_array.push(validated_tidied)

	address = parse_sub_page.css('#simpleDetailsTable').css('td')[4].text
	address_tidied = address.strip
	address_array.push(address_tidied)

	proposal = parse_sub_page.css('#simpleDetailsTable').css('td')[5].text
	proposal_tidied = proposal.strip
	proposal_array.push(proposal_tidied)
	proposal_array.each do |proposal|
		proposal.gsub(",","")
	end

	outcome = parse_sub_page.css('#simpleDetailsTable').css('td')[7].text
	outcome_tidied = outcome.strip
	outcome_array.push(outcome_tidied)

	decided = parse_sub_page.css('#simpleDetailsTable').css('td')[8].text
	decided_tidied = decided.strip
	decided_array.push(decided_tidied)

end

# this is to add one more array: council name
counting = links_array.count
council_array = Array.new(counting,council)

# *****
# this is to transpose the data in the arrays in order to
# change the layout of data

table = [reference_array, altreference_array, received_array, validated_array, address_array, proposal_array, outcome_array, decided_array, links_array, council_array].transpose
pp table

# this is the loop to save the data in the SQlite table

# i = 0

# while i < counting

# data = { "reference"=>reference_array[i], "altreference" =>altreference_array[i], "received"=>received_array[i], "validated"=>validated_array[i], "address"=>address_array[i], "proposal"=>proposal_array[i], "outcome"=>outcome_array[i], "decided"=>decided_array[i], "links"=>links_array[i], "council"=>council_array[i] }
# unique_keys = [ "reference" ]
# ScraperWiki::save_sqlite(unique_keys, data, table_name = "basildon",verbose=2)

# i = i + 1
# end

# PART 2
# THE CODE BELOW FINDS THE PLANNING APPLICATION LINKS AND
# THE RELEVANT TYPES OF APPLICATION AND PUSHES THE DATA
# TO THE SQLITE TABLE

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url)

# this is to print the page to see what html names are used for
# the form and fields
#pp page

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# this is to check how many options there are on the form
# under the 'application type' field
types = search_form.field_with(:name => 'searchCriteria.caseType').options
counter = types.count

# this is to create empty arrays to store the links (results)
links_array = []
apptype_array = []

# this is the "i" definition for the while loop
i = 1

# this is where the while loop starts. It will run until it
# will fetch all options avaialble under the application
# type field

while i < counter

	# this is to set the values of three fields of the form
	search_form['date(applicationDecisionStart)'] = startDate
	search_form['date(applicationDecisionEnd)'] = endDate
	search_form.field_with(:name => 'searchCriteria.caseType').options[i].select

	# this is to submit the form
	page = agent.submit(search_form)

	# the following loop is to find all links on the page which include
	# the "applicationDetails" wording and store them in the links_array
	# then, to move to the "next" page and do the same,
	# until there is no "next". The code also adds application
	# type label for each link

	loop do
		page.links.each do |link|
			if link.href.include?"applicationDetails"
			links_array.push(link.href)
			counting_array = []
			counting_array.push(link.href)
			counting = counting_array.count
			appnames_array = []
			appnames_array = Array.new(counting,i)
			apptype_array.push(appnames_array)
			end
		end

		if link = page.link_with(:text => "Next")
		page = link.click
		else break
		end
	end

	i = i + 1

end

apptype_array.map! do |app|
    app.to_s
end

# this is to convert the links to strings,
# then, to suplement urls with the missing text:
# "http://planning.xxxxxxxx.gov.uk"

links_array.map! do |item|
	item.to_s
	item = "#{url_beginning}#{item}"
end

ref_array = []

links_array.each do |link|
ref = link[-13..-1]
ref_array.push(ref)
end

# pp ref_array

# this is to transpose the data in the arrays in order to
# change the layout
table2 = [ref_array, apptype_array].transpose
pp table2

# i = 0
# counter = ref_array.count

# while i < counter

# data2 = { "ref"=>ref_array[i], "apptype"=>apptype_array[i] }
# unique_keys2 = [ "ref" ]
# ScraperWiki::save_sqlite(unique_keys2, data2, table_name = "basildonapp",verbose=2)

# i = i + 1
# end

# PART 3
# THE CODE BELOW FINDS THE PLANNING APPLICATION LINKS AND
# THE RELEVANT TYPES OF DEVELOPMENT AND PUSHES THE DATA
# TO THE SQLITE TABLE

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url)

# this is to print the page to see what html names are used for
# the form and fields
#pp page

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# this is to check how many options there are on the form
# under the 'application type' field
types = search_form.field_with(:name => 'searchCriteria.developmentType').options
counter = types.count

# this is to create empty arrays to store the links (results)
links_array = []
devtype_array = []

# this is the "i" definition for the while loop
i = 1

# this is where the while loop starts. It will run until it
# will fetch all options avaialble under the development
# type field

while i < counter

	# this is to set the values of three fields of the form
	search_form['date(applicationDecisionStart)'] = startDate
	search_form['date(applicationDecisionEnd)'] = endDate
	search_form.field_with(:name => 'searchCriteria.developmentType').options[i].select

	# this is to submit the form
	page = agent.submit(search_form)

	# the following loop is to find all links on the page which include
	# the "applicationDetails" wording and store them in the links_array
	# then, to move to the "next" page and do the same,
	# until there is no "next". The code also adds development
	# type label for each link

	loop do
		page.links.each do |link|
			if link.href.include?"applicationDetails"
			links_array.push(link.href)
			counting_array = []
			counting_array.push(link.href)
			counting = counting_array.count
			devnames_array = []
			devnames_array = Array.new(counting,i)
			devtype_array.push(devnames_array)
			end
		end

		if link = page.link_with(:text => "Next")
		page = link.click
		else break
		end
	end

	i = i + 1

end

devtype_array.map! do |dev|
    dev.to_s
end

# this is to convert the links to strings,
# then, to suplement urls with the missing text:
# "http://planning.xxxxxx.gov.uk"

links_array.map! do |item|
	item.to_s
	item = "#{url_beginning}#{item}"
end

refer_array = []

links_array.each do |link|
refer = link[-13..-1]
refer_array.push(refer)
end

# pp refer_array

# this is to transpose the data in the arrays in order to
# change the layout
table3 = [refer_array, apptype_array].transpose
pp table3

# i = 0
# counter = refer_array.count

# while i < counter

# data3 = { "refer"=>refer_array[i], "devtype"=>devtype_array[i] }
# unique_keys3 = [ "refer" ]
# ScraperWiki::save_sqlite(unique_keys3, data3, table_name = "basildondev",verbose=2)

# i = i + 1
# end
