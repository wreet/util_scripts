#!/usr/bin/env ruby
###############################################################################
# PredictWise Site Parser v0.0.1b by Chase Higgins
###############################################################################
# PredictWise Site Parser is a tool to mimic what a PredictWise API might look
# like. It acts as a wrapper that can request a contract on the site, and parse
# the HTML page to get the prediction information. PredictWise has said they 
# are looking into creating an API in the near future, but that is too long
# to wait to start leveraging their data, now that InTrade is gone.
###############################################################################

require 'open-uri';

class PredictWise
	def self.getPredictions(contract)
		# getPredictions is the most obviously important method, and can act as 
		# an all-in-one retrieval tool for a contact
		# first we need page
		p = getPage(contract);
		# now parse them
		events = parseContract(p);
		return events;	
	end; # end getPredictions method

	def self.getPage(contract)
		# get the HTML that makes up the contract page
		p = open('http://www.predictwise.com/' + contract);
		html = p.read;
		# predictwise sort of makes our task a little easier here, since the actual
		# contract is in an iframe, which we can pull to reduce the amount of data
		# we need to parse to get the predictions
		p = html.match(/<iframe class='predictw_table_iframe' src='([\w\d:\/.-]+)/);
		p = p[0];
		parts = p.split("src='");
		url = parts[1];
		# now we can use that URL to get our predictions table
		p = open(url);
		# now we have the actual table of the contract, we can send it back and 
		# get ready to parse the data from it that we would like to have
		return p.read;
	end; # end getPage method

	def self.parseContract(contract)
		# parse the contract table that is provided in the argument
		# now we should be able to get each row
		matches = contract.scan(/<tr class='(even|odd)'>(.*)<\/tr>/);
		# matches is now an array of every prediction in the table, in iterable form
		events = [];
		matches.each { |m| 
			events << getPredictionFromRow(m);
		};
		return events;
	end; # end parseContract method

	def self.getPredictionFromRow(row)
		# take the matched row object and return a hash entry for the condition and
		# the associated probability of its occurence 
		data = row[1]; # this is where the matched string is
		data = data.scan(/<td[^>]+>([\w\d\s.]+)/);	
		# data[0] is event, data[1] is predictwise prediction, the one we want
		h = {
			:event => data[0][0],
			:probability => data[1][0].strip
		};
		return h;
	end; # end getPredictionFromRow method
end; # end PredictWise class
