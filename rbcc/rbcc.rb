#!/usr/bin/env ruby
################################################################################
# Ruby Command and Control Server 0.1 Beta by Chase Higgins
################################################################################
# The Ruuby Command and Control Server will listen a specified port and give 
# commands to clients that are slaves to our server. The commands will be loaded
# from a SQLite3 DB. We will keep track of all previous clients, as well as 
# their last completed task, in the SQLite3 DB. This script is written to be as 
# platform independent as possble, with an Android client script planned first,
# however any device that can send/receive and understand the requests and
# commands should be supported, regardless of platform or language used for the 
# client.
################################################################################
# TODO:
	#
################################################################################

# we will use SQLite3 for keeping track of our information
require 'sqlite3';
# define a couple of the constants that the program will use
DB = 'rbcc'; # path to DB 
LISTEN_PORT = '1337'; # master listen, port can be any unused port on the system
GUI_PORT = '8080'; # port for the web GUI, can be any unused port on the system
# create the data structure to hold information from the commands table
Command = Struct.new(:id, :device_id, :command, :executed, :issue_date);
# at this point we have a very simple table in db we are working with
# you can modify the table however you want, just make sure to update the struct
# to accept match the new table structure, protip: avoid mass assignment here
# we will want to define the command handling class 
class CommandHandler 
	# CommandHandler will be where the breadth of the application is defined,
	# we will be using this class to handle executing the commands on the remote
	# client. Command handler will pass it's results to the GUI class to create 
	# a simple web interface for the script
	def initialize()

	end; # end of constructor


end; # end of CommandHandler class

class RequestHandler
	# RequestHandler is tasked with parsing and analyzing client requests from 
	# the listener class. This will be the way in which remote clients can 
	# influence the server. After handling the request it will get the pending
	# commands for that device from the server

end; # end of RequestHandler method

class Listener
	# listener is the class that will listen for requests to the control server
	# from remote clients. It will simply listen, it's only job is to pass the 
	# request to RequestHandler, which will analyze the request and call the
	# appropriate handler in the ComamndHandler class

end; # end of Listener class

class GUI 
	
end; # end of GUI class
