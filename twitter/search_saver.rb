#!/usr/bin/env ruby
################################################################################
# Twitter GET Search Hit Counter v0.1.6b by Chase Higgins
################################################################################
# This script will make a GET request to the twitter search feature and will 
# parse the returned JSON response from twitter. We will then store the results 
# in a SQLite3 DB, we will be storing the tweet id, user id, user name, tweet
# contents, date, and tweet URL in the database. The script is designed to catch
# as many tweets as possible on a subject to get an idea of how popular it is 
# over time, so when using this script expect the local database to grow in size
# rapidly, especially for a popular subject, e.g. I would probably not start a 
# search track for Justin Bieber if you are worried about SQLite taking up huge
# chunks of your disk XD
################################################################################
# TODO:
	# build a popularity graph feature with HTML/CSS or something
	# change to batch insert, especially for when high volume subjects are 
		# logged
	# implement page traversal for especially high volume subjects. Right now we 
		# can only store 100 tweets a minute for a given subject. Plenty enough
		# for most cases, but with some tweaking we can get up to 1500 a minute
		# and that will very rarely ever be exceeded
	# implement last id from command line so that databases can be appended to
	# first round of tweets is always 100 since there is no date limiter, change
		# this so that it only pulls tweets that occurred after the script was 
		# started
	# implement sleep time override as optional cli argument
	# implement cli argument checking and usage assistance, we don't want the 
		# script crashing when unexpected arguments come up, we want it to offer
		# assistance to the user
  # there is an event causing the script to crash sometimes, it looks like it 
    # may be a text escaping issue, only has happened for subj "mitt%20romney"
################################################################################

require 'sqlite3';
require 'rubygems';
require 'json';
require 'open-uri';

# define some of the script constants 
SUBJECT = ARGV[0];
DB = ARGV[1];
SEARCH_URL = "http://search.twitter.com/search.json";
PARAMS = "?q=#{SUBJECT}&result_type=recent&include_entities=true&rpp=100";
# The defined params are as follows: obviously q is the subject, result_type is
# set to recent so that promoted and "popular" tweets do not mess up our result
# set, include_entities is true to allow us to gather extra meta data for the 
# result set, and rpp is the results per page, set to be the max value of 100
Tweet = Struct.new(:id, :user_id, :user_name, :content, :date);
# the Tweet data structure will be the intermediary between the database and 
# JSON response, whenever the script instantiates a tweet this object is used
if (ARGV[2])
	# if max polls is set from cli, then use it
	MAX_POLLS = ARGV[2].to_i;
else 
	# otherwise a 24 hour polling period is the default
	MAX_POLLS = 1440;
end;
# max polls is an easy way to say how long to run the script. Since the script 
# makes a request every 60 seconds, you can limit the run time of the script in 
# minutes by using this constant. e.g. if you wanted to run the script to collect
# tweets for an hour on a given subject, set it to 60. 0 is interpreted as run
# the script until it is manually exited


class SearchPoll
	# the SearchPoll class will query twitter search feature for a given subject,
	# then it will every 60 seconds poll twitter to get new tweets that match the
	# search subject. 
	def searchRequest()
		# we will poll twitter's search feature and ask them to return a result 
		# set, we will then send it off to be parsed by the parseResponse method
		url = "#{SEARCH_URL}#{PARAMS}";
		#url = URI.parse("#{SEARCH_URL}#{PARAMS}");
		if (@last_id != nil)
			# if there is a last_id to go off of then add it to the url params
			url << "&since_id=#{@last_id}";
		end;
		# now with our url string we can make a request to twitter
		puts "[+] Using request: " << url;
    begin
		  @resp = open(url).read;
    rescue
      # if it fails to open it, we will attempt to run this function again
      sleep(5);
      searchRequest;
    end;
		# resp now contains a file handle to be read to retrieve the response
		# and we now have a nice instance variable containing the JSON response
	end; # end of searchRequest method

	def parseResponse()
		# we will parse the response to create a native ruby data structure to 
		# hold the results, which can then be inserted into the database for 
		# future use
		tweet_list = Array.new;
		tweets = JSON.parse(@resp);
		count = 0;
		tweets['results'].each() { |tweet| 
			# we need to create a Tweet struct to save the data from the response
			t = Tweet.new(
				tweet['id'], 
				tweet['from_user_id'],
				tweet['from_user'], 
				tweet['text'].gsub("'", ""), 
				tweet['created_at']
			);
			# now append it to the tweet list
			tweet_list << t;
			# and increment the counter
			count += 1;
		}
		# log how many tweets we collected for the run
		puts "[+] Collected #{count} tweets";
		# we will now store the tweets list as an instance var called @tweets
		@tweets = tweet_list;
		# for the next poll we do not want duplicate tweets, so we take the most
		# recent result(0) and use it's ID to fill the last_id parameter to the
		# twitter search feature. This ensures we only pull tweets with an ID 
		# greater than defined, and therefor only new tweets since the last poll
		@last_id = @tweets[0].id;
		# so this works fine if there are actually tweets returned, otherwise
		# it will cause an error with the since_id and the script will pull 
		# duplicate tweets, we will fix this issue below
		if (@tweets.length == 0)
			# we know that we retrieved no tweets, let's try and fix since_id
			# without a tweet list 
			if @db.hasConnection?
				# this means a tweets database is open and we can get out last_id
				# from there
				@last_id = @db.getLastID;
			else
				# I have not really thought of a good way to handle this case. 
				# this will only be hit if the first poll of tweets is 0, which 
				# is illogical because if you are tracking tweets and there has
				# never been a hit of your query in twitter history I doubt you 
				# will be pulling much data subsequently either
				puts "[!] Found no initial tweets, continuing";
			end;		
		end;
		# handling of 0 tweet result ends here
	end; # end of parseResponse method

	def pollController() 
		# pollController is to every 60 seconds call the polling feature of the 
		# class, it will facilitate the flow of the tweet from parsing it out of
		# the JSON response all the way to inserting it into our database
		@db = Database.new;
		# we instantiate the Database class to make sure our DB and table
		# exist and are ready to accept data
		# create a poll counter
		polls = 0;	
		while (polls < MAX_POLLS) do
			searchRequest();
			parseResponse();
			# after we parse the response we now have a tweet list @tweets
			@tweets.each() { |tweet|
				# we will go through and insert each tweet into our database 
				# I know, I know, batch insert should be used here for efficiency,
				# but I am going to be lazy for now since it's a SQLite DB
				@db.insertTweet(tweet);
			}
			polls += 1;
			sleep(60);
			# you are welcome to change the sleep wait time, but keep in mind
			# twitter has a 350 request per hour rate limit for search, I chose 
			# 60 as the sleep time because that would allow up to five instances 
			# of the script to poll at the same time without exceeding the rate 
			# limit
		end; # end of while
	end; # end of pollController method
end; # end of SearchPoll class


class Database 
	# the Database class will handle working with our local SQLite DB, it will 
	# make sure our DB and table are initialized and it will also handle storing
	# and retrieving data for the script
	def initialize()
		# make sure the DB and table are there, if they aren't then create them
		if(FileTest::exist?(DB) == false)
			# we will need to initialize the DB and table
			@db = SQLite3::Database.new(DB);
			# create the table
			sql = "
				CREATE TABLE `tweets` 
				(id int, user_id int, user_name varchar, content varchar, 
				created date);
			";
			@db.execute(sql);
		else
			@db = SQLite3::Database.new(DB);
		end;
	end; # end of constructor

	def insertTweet(tweet) 
		# this method will insert the tweet into the database
		sql = "
			INSERT INTO `tweets`
			VALUES (
				'#{tweet.id}', 
				'#{tweet.user_id}', 
				'#{tweet.user_name}',
				'#{tweet.content}', 
				'#{tweet.date}'
			);
		";
    begin
		  @db.execute(sql);
    rescue
      # the database was locked, sleep then try again
      sleep(5);
      @db.execute(sql);
    end;
	end; # end of insertTweet method

	def hasConnection?
		if (@db != nil)
			return true;
		else
			return nil;
		end;
	end; # end of hasConnection method

	def getLastID() 
		sql = "
			SELECT `id` 
			FROM `tweets`
			ORDER BY id DESC
			LIMIT 1;
		";
		row = @db.execute(sql);
		return row;
	end; # end of getLastID method
end; # end of the Database class


def main()
	s = SearchPoll.new;
	s.pollController;
end;

if (__FILE__ == $0)
	main;
end;
