#!/usr/bin/env ruby
###########################################################
# Political Projections 0.1.3beta by Chase Higgins, Algorithm: 0.2.1beta
###########################################################
# This script will take several indicators fom a text file input and use
	# them to guage the chances of certain political events taking place
# This script is in beta, and is intended for educational purposes only
# Hopefully as the script matures it will begin to be very accurate
	# in it's predictions. 
###########################################################
# TODO:
	# create a more robust indicator parser
	# find a method to automate the gathering of the indicator data,
		# check into intrade, ipredict and RCP APIs for this
	# tweak the weights of the algorithm to reflect past election results, 
		# this will help tune the algorithm's accuracy
	# create vote percentage projection to complement the chance of win %
###########################################################

class Error
	# various errors for the class
	def self.fileReadError(fin)
		puts("[-] Could not open #{fin} for reading, please ensure the file exists and you have permision to read it");
	end;
end; # end of errors class


class Result
	# this is where we will store our results from the projection algorithm
	# allow direct access of our instance variables
	attr_accessor :figure, :event, :intrade, :ipredict, :twitter_hits, :poll_avg, :total_weight, :projection;

	def initialize(results, event, figure) 
		# store the results in an object for later use
		@event = event;
		@figure = figure;
		@intrade = results[:intrade];
		@ipredict = results[:ipredict];
		@twitter_hits = results[:twitter_hits];
		@poll_avg = results[:poll_avg];
		total_weight = 0;
		# now get the total algo weight
    results.each() { |key, val|
			total_weight += val;
		}
		@total_weight = total_weight;
		@projection = 0;
	end; # end of contructor

	def updateProjection(projection)
  	@projection = (projection * 100).round.to_f / 100
	end; # end of updateProjection class
	
end; # end of result class


class PoliticalProjection
	# we will use this class to make predictions about who will win certain political events
	def initialize(indicators)
		@indicators = indicators;
		@results = Array.new;
		# we need a count of the different indicator lines, each of which makes up a contestant in our algorithm
		@num_contestants = @indicators.length; 
		# that takes care of the indicators, now we decide how much weight to give each in the algorithm
		# the indicators get a weight as a percentage of 100, we will define them in a hash. These are of
		# course a work in progress and just my arbirtary weights, feel free to adjust them to your liking
		@algo_weights = {
			:intrade => 30,
			:ipredict => 20, 
			:twitter_hits => 70,
			:poll_avg => 20
		}
		# now that we have that, we will just loop through the indicators array and store the results
		@indicators.each() { |indicator|
			results = {
				:intrade => weighIntrade(indicator),
				:ipredict => weighIpredict(indicator),
				:twitter_hits => weighTwitterHits(indicator),
				:poll_avg => weighPollAverage(indicator)
			}
			# each result should be instantiated as a result object
			@results << Result.new(results, indicator.event, indicator.figure);
		}
		# we should have a list of result objects now
		# next let's count the total weights between the two to make a projection
		weights_total = 0;
		@results.each() { |result|
			# calculate the projection
			weights_total += result.total_weight;
		}
		@results.each() { |result|
			projection = (result.total_weight / weights_total) * 100;
			result.updateProjection(projection);
		}
		# now display the results
		showResults();
	end; # end of constructor
	
	def weighIntrade(indicator)
		# since this is already a percentage figure it is easy to calculate
		weight = (Float(indicator.intrade) * @algo_weights[:intrade]);
		return weight;
	end; # end of weighIntrade method
	
	def weighIpredict(indicator)
		# just like intrade it is already a nice percentage value, so just go with that
		weight = (Float(indicator.ipredict) * @algo_weights[:ipredict]);
		return weight;
	end; # end of weighIpredict method
	
	def weighTwitterHits(indicator)
		# we will add the figures together for all tweets then get the percentage for this candidate
		# after we have a percentage of tweets we will normalize them with our algo weight
		total_hits = 0;
		@indicators.each() { |candidate| 
			total_hits += Integer(candidate.twitter_hits);
		}
		weight = ((Float(indicator.twitter_hits) / total_hits) * 100) * @algo_weights[:twitter_hits];
		return weight;
	end; # end of weighTwitterHits method
	
	def weighPollAverage(indicator) 
		# polling is obviously already a pecentage as well, but wait things are not that simple
    # you see polling should be considered way less important than other factors if the 
    # margin between candidates is only a few points, because of margin of error and general
    # lack of veracity in polling. however if there is a ten point spread, that would make the
    # polling significantly more important and the algorithm should reflect that
    	  

  	weight = (Float(indicator.poll_avg) * @algo_weights[:poll_avg]);
		return weight;
	end; # end of weighPollAverage method
	
	def showResults()
		@results.each() { |result|
	    puts("[+] With the supplied indicators, #{result.figure} would have a #{result.projection}% chance of winning #{result.event}");
  	}
	end; # end of showResults method
end; # end of PoliticalProjection class


class Indicators 
	# store each inidicator entry from the file in it's own object
	# make our class variables directly accessable
	attr_accessor :event, :figure, :intrade, :ipredict, :twitter_hits, :poll_avg;
	def initialize(indicators)
		@event = indicators[:event];
		@figure = indicators[:figure];
		@intrade = indicators[:intrade];
		@ipredict = indicators[:ipredict];
		@twitter_hits = indicators[:twitter];
		@poll_avg = indicators[:poll_avg];
	end; # end of constructor
end; # end of the indicators class


class FileIO
	# here is where we will read and parse our input variables to the algorithm
	def getVariables(fin) 
		# we will parse an input file that should follow this format for the input data(CSV):
		# event_name, figure_name, intrade_prediction, ipredict.co.nz_prediction, 24_hour_twitter_hits, poll_aggregate
		indicators = Array.new;
		#begin
			File.open(fin, 'r') do |fh|
				while (line = fh.gets) do
					indicators << parseInput(line);
				end;
			end;
		#rescue
			# if we could not open the input file raise an exception and end the script
		#	Error::fileReadError(fin);
		#	exit;
		#end; # end of exception handling
		# after we have parsed the indicators, we will return the indicators list
		# to whatever method called the parser
		return indicators;
	end; # end of getVariables method
	
	def parseInput(line) 
		# we need to split the entries per line based on a comma space format, this is required of the input file
		@indicators = Array.new;
		parts = line.split(", ");
		# create an indicators hash
		indicators = {
			:event => parts[0],
			:figure => parts[1], 
			:intrade => parts[2],
			:ipredict => parts[3],
			:twitter => parts[4],
			:poll_avg => parts[5].strip
		}
		# pass the hash to the store indicators function
		indicator_obj  = storeIndicators(indicators);
		return indicator_obj;
	end;
	
	def storeIndicators(indicators)
		# basically we need to instantiate an object to store our indicators
		# then we return it to be appended to the indicators list, which we 
		# will pass to the PoliticalProjections class to use
		return Indicators.new(indicators);
	end; # end of storeIndicators method
end; # end of FileIO class 

# end of classes move on to main function

def main()
	# get the file to read indicators from, it should be ARGV[0], if not start interactive wizard
	begin 
		fin = ARGV[0];
	rescue 
		fin = gets("Please enter indicator input file name: ");
	end; 
	# now we have an in file guaranteed, send it to the parser
	#indicators = FileIO::getVariables(fin);
	f = FileIO.new;
	indicators = f.getVariables(fin);
	# now we have an array containing all the indicators, send them off to the projections class
	PoliticalProjection.new(indicators);
end; # end of main function

if (__FILE__ == $0)
	main;
end;
