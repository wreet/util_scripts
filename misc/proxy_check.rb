#!/usr/bin/env ruby
###############################################################################
# Proxy Check for American Financing by Chase Higgins
###############################################################################
# ensure that the reverse proxying scheme is running through apache, the other
# component will be to ensure access to the DTO server (192.168.200.22)
###############################################################################

require 'net/smtp';

class ProxyCheck
	attr_accessor :dto, :rev_proxy;
	def initialize()
		# these will be the vars that hold current state
		@dto = nil;
		@rev_proxy = nil;
		@prox_rev_attempt = 0;
		@dto_rev_attempt = 0;
	end; # end of constructor

	def checkApache()
		# we will call ps aux | grep apache2 | wc -l
		# this will give us a line count, more than 1 line means that we have
		# an instance of apache running
		lines = `ps aux | grep apache2 | wc -l`;
		if (lines.to_i > 2)
			# we are up and running
			@rev_proxy = 'alive';
			return true;
		else
			@rev_proxy = 'dead';
			if (@prox_rev_attempt == 0)
				reviveApache();
			else
				puts "[!] Already attempted to revive apache, will try next run. Now " \
						 "sending an email alert to admins.";
				Email.new('Apache Reverse Proxy');
			end;
		end;			
	end; # end of checkApache method

	def checkDTO()
		# pinging DTO should be sufficient
		res = `ping -qc4 192.168.200.22`;
		if ($?.exitstatus == 0)
			@dto = 'alive';
			return true;
		else
			# try and bring it back, we will repair the routes
			@dto = 'dead';
			if (@dto_rev_attempt == 0)
				reviveDTOLink();
			else 
				puts "[!] Already attempted to revive DTO, will try next run. Now " \
						 "sending an email alert to admins.";
				Email.new('DTO'); 
			end;
		end;
	end; # end of checkDTO method

	def reviveDTOLink()
		# basically, we are going to bring down eth0(our connection to 200.0/24) and 
		# bring it back up. We will then attempt to repair the route to the network
		puts "[!] Attempting to revive DTO on: " << Time.now.to_s;
		`ifdown eth0`;
		`ifup eth0`;
		# repair the routes
		`route add -net 192.168.200.0 gw 192.168.1.3 netmask 255.255.255.0 eth0`;
		# we attempted to repair the connection, set it
		@dto_rev_attempt += 1;
		# see if we made it happen
		checkDTO();
	end; # end of reviveDTOLink method

	def reviveApache()
		# if apache is down, issues a service command to restart it
		puts "[!] Attempting to revive apache on: " << Time.now.to_s;
		`service apache2 restart`;
		@prox_rev_attempt += 1;
		# that's it for apache, go ahead and check it
		checkApache();
	end; # end of reviveApache method
end; # end of ProxyCheck class


class Logging
	def self.showRunTime() 
		puts "[+] Ran proxycheck on: " << Time.now.to_s;
	end; # end of showRunTime static method

	def self.showApacheStatus(status)
		if (status == 'alive')
			puts "[+] Apache is up and running";
		else
			puts "[!] Apache appears to be down";
		end;
	end; # end of showApacheStatus method

	def self.showDTOStatus(status)
		if (status == 'alive')
			puts "[+] DTO is up and we have a connection to it";
		else
			puts "[!] Unable to connect to DTO";
		end;
	end; # end of showDTOStatus method
end; # end of Logging class


class Email
	def initialize(service)
		Net::SMTP.start('localhost', 25) { |smtp|
			msg = "MIME-Version: 1.0
				Content-Type:text/html;charset=iso-8859-1
				From: Proxy Check <proxy_check@americanfinancing.net>
				To: chase.higgins@americanfinancing.net
				Bcc: wlewis@americanfinancing.net
				Subject: #{service} IS DOWN!!

				Proxy Check detected that #{service} has gone down and could not be revived.
				Manual action is required at this point.
			";
			smtp.send_message(msg.gsub(/\t/, ''), 'proxy_check@americanfinancing.net', ['chase.higgins@americanfinancing.net','wlewis@americanfinancing.net']);
		}
	end;
end; # end of Email class

def main()
	Logging::showRunTime;
	check = ProxyCheck.new;
	check.checkApache();
	check.checkDTO();
	Logging::showApacheStatus(check.rev_proxy);
	Logging::showDTOStatus(check.dto);
end; # end main

if __FILE__ == $0
	main;
end;
