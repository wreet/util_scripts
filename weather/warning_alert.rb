#!/usr/bin/env ruby
###############################################################################
# Severe Weather Email Alert System 0.1.0a by Chase Higgins
###############################################################################
# contact the weather underground site to retrieve the severe weather alerts
# for a given area, which is passed by the command line. The script will run 
# as a daemon and will contact wunderground every 10 minutes, and should a 
# severe alert exist the script will email an address, which should also be 
# provided as a command line arg. In addition we will store all of the alerts
# into a local SQLite3 DB, this has two benefits, since we don't want duplicate
# alerts we can check if they were already sent, and also it lets us keep a 
# severe weather log for historical purposes.
###############################################################################

# include the required libraries
require 'rubygems';
require 'json';
require 'open-uri';
require 'net/smtp';
require 'sqlite3';
require 'parsedate';

Alert = Struct.new(:id, :type, :start_date, :end_date, :message);

class Request
	attr_accessor :alerts;
	def initialize(location)
	  # define the request uri
	  uri = "http://api.wunderground.com/api/70b22f67a2d9da65/alerts/q/#{location}.json";
	  # attempt to get the json response
	  begin
	    resp = open(uri).read;
	  rescue => exception
	    # if we don't get a response we will log that, then return from the function
	    # at which point we will just wait until the next request
	    puts "[!] Could not retrieve json response from wunderground: " << exception;      
	    return -1;
	  end; # end of exception handling
	  # if that doesn't fail then we can send it to the parseResponse method
	  parseResponse(resp);
	end; # end of constructor

	def parseResponse(resp)
	  # take the json response and instantiate alert objects from it
	  alerts_list = Array.new;
	  alerts = JSON.parse(resp);
	  alerts['alerts'].each() { |alert| 
	    alerts_list << Alert.new(
        Logging::strtotime(alert['date']),
	      alert['description'],
	      alert['date'],
	      alert['expires'],
	      alert['message']
	    );  
	  } # end of alerts JSON iteration
	  @alerts = alerts_list;
    if (@alerts.length == 0)
      puts "[+] No alerts found for given area";
    end;
	end; # end of parseResponse method
end; # end of Request class


class Emailer 
	def initialize(host, port, alerts, location, email) 
	  # initialize the smtp connection
	  Net::SMTP.start(host, port) { |smtp|
	    # iterate each alert for the area and email them to the specified email
	    alerts.each() { |alert|
	      msg = "MIME-Version: 1.0
			Content-Type:text/html;charset=iso-8859-1
			From: Severe Alerts <severe_alerts@chasehiggins.com>
			To: #{email}
			Subject: #{alert.type} For #{location} Until #{alert.end_date}!

			A severe weather alert has been issued in your area!
			It was issued at #{alert.start_date} and expires #{alert.end_date}.
			The alert is a #{alert.type}. The text of the warning from the NWS follows:\n\n

			#{alert.message}
	      ";
	      begin 
	        smtp.send_message(msg.gsub(/\t/, ''), 'severe_alerts@chasehiggins.com', email);
          puts "[+] Sent #{alert.type} to #{email}";
	      rescue => exception
	        # log the failure to send the message
	        puts "[!] Failed to send weather alert(#{alert.type}) to #{email} " << exception; 
	      end; # end try and catch
	    } # end alerts iteration 
	  } # end smtp block
	end; # end of constructor
end; # end of Emailer class


class Logging
  # since we don't want duplicate weather alerts we will be keeping a database of past alerts
  def initialize(db)
    # make sure that we have a db going, if we don't then create one
    if (FileTest::exist?(db) == false)
      # we will initialize the db and table
      @db = SQLite3::Database.new(db);
      sql = "
        CREATE TABLE `alerts`
        (id int, type varchar, start_date date, 
        end_date date, message varchar);        
      ";
      @db.execute(sql);
    else 
      @db = SQLite3::Database.new(db);
    end;
  end; # end of constructor  
   
  def insertAlert(alert)
    # insert an alert into the database
    sql = "
      INSERT INTO `alerts`
      VALUES (
        '#{alert.id}',
        '#{alert.type}',
        '#{alert.start_date}',
        '#{alert.end_date}',
        '#{alert.message}'
      );
    ";
    begin
      @db.execute(sql);
    rescue
      # database was probably busy, sleep and try again
      sleep(5);
      @db.execute(sql);
    end;
  end; # end of insertAlert method

  def alertLogged?(alert)
    # make sure an alert is not already in the database and therefor handled
    sql = "
      SELECT COUNT(*) as count
      FROM `alerts`
      WHERE id = #{alert.id.to_s}
    ";
    begin
      res = @db.execute(sql);
    rescue => exception
      puts "[!] Could not check if alert has already been logged " << exception;
      return nil;
    end;
    if (res[0][0].to_i != 0)
      # already got it, return from method
      puts "[+] No new alerts found";
      return true;
    else
       return nil;
    end;
  end; # end of checkForAlert method
 
  def self.strtotime(time)
    return Time.local(*ParseDate::parsedate(time)).to_i
  end; # clone php strtotime for convenience 
end; # end of the logging class

def main
	# collect the arguments
	begin
	  location = ARGV[0].dup;
	  email = ARGV[1].dup;
    db_name = ARGV[2].dup;
	rescue
	  puts "Usage: #{$0} <location> <email> <dbname>";
	  exit;
	end; 
	# initialize the request object for the given area
	r = Request.new(location);
	# all request objects are now stored in r.alerts
	# we should check to see if the alert is already logged
  db = Logging.new(db_name);
  alerts = Array.new;
  r.alerts.each() { |alert|
    if (db.alertLogged?(alert))
      # already have it, so we skip this alert
      next;
    else
      # otherwise we will go ahead and log this alert
      db.insertAlert(alert);
      alerts << alert;
    end;
  }; # end alerts iteration
  # now we can email the alerts that are new
  Emailer.new('localhost', 25, alerts, location, email);
end; # end of main

if (__FILE__ == $0)
	main;
end;
