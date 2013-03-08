#!/usr/bin/env ruby
###############################################################################
# Server UpCheck 0.1.0b by Chase Higgins
###############################################################################
# Simple upcheck script to allow monitoring a host. The script will attempt to 
# check the status of a given host using the port specified in the hosts struct
# If we can not connect to the host, then we will print an error to std output
# and send an alert to the admins
# TODO:
	# allow user to chose smtp server information
	# create a method for file input to define the hosts
###############################################################################

require 'open-uri';
require 'socket';
require 'net/smtp';

# first we will define the admin hash and hosts struct here, feel free to add 
# or change values to your requirements
Host = Struct.new(:host, :port, :proto, :is_up);
HOSTS = Array.new;
# set some example hosts
HOSTS << Host.new('tzdev.servebeer.com', 22, 'ssh', 0);
HOSTS << Host.new('hello.world', 22, 'ssh', 0);
HOSTS << Host.new('fakewebsitelolbbqsauce.com', 80, 'http', 0);
# define our admins; name => email
ADMINS = {
	'admin' => 'admin@site.com'
}
# define the from email address we will use
FROM = 'webmonitor@site.com';
# now we can move on to defining our app logic

class UpCheck
	def initialize(hosts, admins)
		# initialize the class
		@hosts = hosts;
		@admins = admins;		
	end; # end of constructor

	def testHosts
		# go through our hosts lists and test these things
		checked_hosts = Array.new;
		@hosts.each() { |host|
			# determine the protocol
			case host.proto
				when 'http'
					# we will connect to the host as HTTP
					host.is_up = checkHTTP(host.host, host.port);
				else
					# right now we only have http support, so try a generic socket to check it
					host.is_up = checkPort(host.host, host.port);
			end; # end of protocol case
			checked_hosts << host;
		}
		# update the hosts array instance
		@hosts = checked_hosts;
		# calling function may want these
		return @hosts; 
	end;

	def checkHTTP(host, port)
		# checkHTTP differs from generic checkPort because checkPort does not care
		# what response it gets, checkHTTP will check for a properly formed http
		# header and will also get the contents of the response
		begin
			# attempt to read the response, an error will be thrown on fail
			page = open('http://' + host);
		rescue
			# we know that the page could not be opened, time to return a fail
			return false;
		end;
		# if we make it out of the exception alive then we can return a success 
		return true;
	end; # end of checkHTTP method

	def checkPort(host, port)
		# generic method to try and check protos we don't understand
		begin
			# attempt to open and read from the socket
			s = TCPSocket.new(host, port);
			s.recv(1024);
		rescue
			# this would mean that we could not open the socket
			return false;
		end;
		# again if we make it out, then the host must be alive
		return true;
	end; # end of checkPort

	def showResults(hosts = @hosts)
		# go through the new hosts list and show/handle the results
		# it can use either the instance var of hosts, or we can use hosts that came
		# from somewhere else if we want
		hosts.each() { |host| 
			if (!isUp?(host))
  	  	alertFail(host);
  	  else 
  	  	alertSuccess(host);
  	  end;
	  }
	end; # end of showResults method

	def isUp?(host)
		if (host.is_up == true)
			return true;
		else
			return nil;
		end;
	end; # end of isUp method

	def alertFail(host)
		# email the server admin(s) about the failure to connect to the host
		# print error to std out as well
		puts "[!] Could not connect to #{host.host}:#{host.port} using #{host.proto}";
		emailAlert(host);
	end; # end of alertFail method

	def alertSuccess(host)
		# we don't need to email the admin every time the host checks out, so this
		# method is more of a formality to print the success to std out
		puts "[+] #{host.host}:#{host.port} can be reached over #{host.proto}";
	end; # end of alertSuccess method

	def emailAlert(host)
		# we will send an email alert to the admins contained in the @admins 
		# instance var. 
		@admins.each() { |name, email|
			begin
				msg = "From: Web Monitor <#{FROM}>\n";
				msg << "To: #{name} <#{email}>\n";
				msg << "Subject: #{host.host} is Down!\n"
				msg << "#{name},\n\n";
				msg << "This email is to alert you that the host #{host.host} ";
				msg << "could not be reached on port #{host.port} using #{host.proto} :(";
				Net::SMTP.start('localhost', 25) { |smtp|
					smtp.send_message(msg, FROM, email);
					smtp.finish;
				}
			rescue
				# we were unable to send an email alert to the admin
				puts "[!] Failed to send email alert to #{name} for #{host.host}:#{host.port} failure";
			end;
		}
	end; # end of emailAlert method

end; # end of upCheck class


def main
	uc = UpCheck.new(HOSTS, ADMINS);
	hosts = uc.testHosts;	
	uc.showResults;	
end;

if (__FILE__ == $0)
	main;
end;
