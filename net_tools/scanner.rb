#!/usr/bin/env ruby
###############################################################################
# Port Scanner 0.1.0b by Chase Higgins
###############################################################################
# The port scanner utility does what you would expect, it accepts a host, or
# a range of hosts, to perform a port scan on. The scanner utilizes only TCP
# at the moment, but will probably add udp soon. 
###############################################################################
	#TODO:
		# look into udp scan
		# it is pretty obvious there is way too much threading going on here, and 
			# it will cause issues with low resource machines doing scans on large
			# port ranges, think 254 addresses * 65535 ports = 16645890 threads.
###############################################################################

require 'socket';
require 'timeout';

class Scanner
	def self.scan(hosts, ports)
		# scan a given set of hosts for a given set if open TCP ports
		# this method will need an array of hosts, and an array of 
		# ports to be passed to it.
		host_threads = [];
		port_threads = [];
		results = []; 
		hosts.each { |host|
			host_threads << Thread.new(host) { |h|
				ports.each { |port|
					port_threads << Thread.new(port) { |p|
						begin
							Timeout::timeout(1) {
								s = TCPSocket.open(h, p);
							};
						rescue
							next;
						rescue Timeout::Error
							# we assume the port is closed
							next;
						else
							# in this case port is probably open
							results << {:host => h, :port => p};
						end;
					}; # end port thread block
				}; # end ports loop
			}; # end hosts thread block
		}; # end hosts loop
		host_threads.each(&:join);
		port_threads.each(&:join);
		return results;
	end; # end scan method
end; # end Scanner class

