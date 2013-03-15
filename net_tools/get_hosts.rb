#!/usr/bin/env ruby
###############################################################################
# Collect Hosts 0.2.0b by Chase Higins 
# Windows Support by Jon Cornwell
###############################################################################
# As the name would imply, this script will scan the local network and 
# retrieve a list of hosts that are currently alive. 
##############################################################################
# TODO:
	#
###############################################################################

class FindHosts
	def self.mkIP(local_net)
		ip_parts = local_net.split('.');
		local_net = ''; 
		# reconstruct the ip
		i = 0;
		ip_parts.each { |part|
			if i == 3
				break;
			end; 
			local_net += part + '.';  
			i += 1;
		};
		i = 1;
		ips = Array.new;
		254.times { # run 254 times to get all IPs on the subnet
			ips << local_net + i.to_s;
			i += 1;
		};
		return ips;	
	end; # end mkIP method

	def self.findHosts(local_net)
		# the findHosts method takes the local network address as its argument it 
		# will then scan the network using the ping command from the system.
		# local net should look like 192.168.1.0
		# we will need to remove the last octet to work with the loop
		ips = mkIP(local_net);
		live_hosts = Array.new;
		threads = Array.new;
		for ip in ips
			threads << Thread.new(ip) { |tip|
				# Edited to check for windows or unix operating system to use proper ping command
				if(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
					out = `ping -n 2 -w 1 #{tip}`; #WINDOWS
				else
					out = `ping -qc2 -w 1 #{tip}`; #UNIX
				end
				
				if not out =~ /100%/
					# this would mean 0% packet loss
					live_hosts << tip;
				end;
			};
		end;
		threads.each { |t| t.join};	
		return live_hosts;
	end; # end findHosts method

	def self.findOpenIPs(local_net)
		# sometimes it is handy to know all the free IPs on the network
		ips = mkIP(local_net);
		threads = Array.new;
		free_hosts = Array.new;
		for ip in ips
			threads << Thread.new(ip) { |tip|
				if(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
					out = `ping -n 2 -w 1 #{tip}`; #WINDOWS
				else		
					out = `ping -qc2 -w 1 #{tip}`; #UNIX
				end;
				if out =~ /100%/
					# that means packets came back and host is in use
					free_hosts << tip;
				end;
			};
		end; # end IP iteration
		threads.each { |t| t.join};
		return free_hosts;
	end; # end findOpenIPs method

end; # end FindHosts class

