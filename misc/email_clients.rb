#!/usr/bin/env ruby
################################################################################
# Take a CSV file and parse the email addresses from it, and instantiate them
# into lead objects. Then we take that list of leads and send each an email
################################################################################

require 'csv';
require 'net/smtp';

class Lead 
	# make the attributes accessable outside the object
	attr_accessor :first_name, :last_name, :email;
	def initialize(fname, lname, email) 
		@first_name = fname;
		@last_name = lname;
		@email = email;
	end; # end of constructor
end; # end of Lead class


class CSVList
	attr_accessor :leads;
	def initialize(in_file, columns)
		# let's parse the leads out of there
		begin
			leads = CSV.read(in_file);
			leads_list = Array.new;
		rescue
			puts "[!] Could not open #{in_file}, please ensure you have permission " \
					 "to read it, and that it is a CSV file";
		end; 
		count = 1;
		leads.each() { |row| 
			# iterate the leads object and build a list of leads from it
			begin
				fname = row[columns[:fname]];
				lname = row[columns[:lname]];
				email = row[columns[:email]];
			rescue
				puts "[!] Encountered an issue at row #{count}, please ensure it was " \
						 "successfully read";
			end;
			# now we can go ahead and instantiate some lead objects
			lead = Lead.new(fname, lname, email);
			leads_list << lead;
			# increment our row count
			count += 1;
		}
		# and there's your leads list, return it
		@leads = leads_list;
	end; # end of constructor
end; # end of CSVList class


class Email
	def initialize(host, port, leads)
		# initiate an smtp connection
		Net::SMTP.start(host, port) { |smtp| 
			# iterate the leads list
			leads.each() { |lead| 
				message = "MIME-Version: 1.0
					Content-type:text/html;charset=iso-8859-1
					From: American Financing <info@americanfinancing.net>
					To: #{lead.email}
					Subject: Pay Your Mortgage Contest

	
					Thank you for entering the KOA/American Financing 'Pay Your Mortgage' Contest.
					Please click the link to print your certificate for a free appraisal(valid with a loan closing with American Financing).
					Whether you are purchasing a new home or refinancing American Financing has a program that will work for you.
					Contact us at: 303-695-7000 or at <a href='http://americanfinancing.net/?source=koa_contest_email'>americanfinancing.net</a>";
				begin
					smtp.send_message(message.gsub(/\t/, ''), 'info@americanfinancing.net', lead.email);
				rescue => exception
					# we will alert the user and continue the execution
					puts "[!] Failed to send mail to: #{lead.email} - #{exception}";
				end;
			}
		}
	end; # end of constructor
end; # end of email class


def main
	# collect the command line arguments
	# the *_col fields expect a field index for the column number in the relevant
	# csv represented as integers, starting with 0, for field a
	begin
		bin = $0;
		csv = ARGV[0].dup;
		fname_col = ARGV[1].dup;
		lname_col = ARGV[2].dup;
		email_col = ARGV[3].dup;
		smtp_host = ARGV[4].dup;
		if (ARGV[5])
			smtp_port = ARGV[5].dup;
		else 
			smtp_port = 25;
		end;
	rescue
		puts "Usage: #{bin} <in_file> <fname_col> <lname_col> <email_col> <smtp_host> [<smtp_port>]";
		exit;
	end;
	# make a columns hash and pass it to the csv class
	# lets go ahead and try out that csv
	columns = {
		:fname => fname_col.to_i,
		:lname => lname_col.to_i,
		:email => email_col.to_i
	}
	leads = CSVList.new(csv, columns);
	# well now we have leads(stored in leads.leads), so we can go ahead and email them
	email = Email.new(smtp_host, smtp_port, leads.leads);
end; # end of main

if __FILE__ == $0
	main; # call dat.. i'd call dat
end;
