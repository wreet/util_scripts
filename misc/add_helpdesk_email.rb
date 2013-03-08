#!/usr/bin/env ruby
###############################################################################
# Add jobs to the American Financing Help Desk utility from an IMAP inbox
##############################################################################
# We will query the box at helpdesk@americanfinancing.net (from Gmail) and 
# then parse the data from the email into a helpdesk job. After that, we will
# need to process the data, and insert it into our jobs table. 
##############################################################################
# Format of message:
	# Subject: [helptype] / [issue title]
	# Message
##############################################################################
# TODO:
	# more extensive regex handling for isue types
###############################################################################

# include our libs
require 'rubygems';
require 'net/imap';
require 'mail';
require 'tiny_tds';
# include the custom email script for accounting
load '/root/dev/email_accounting.rb';


class Job
	# the Job class wil handle storing the job data that we parse from the IMAP 
	# box, it will also handle the methods needed such as inserting into DB
	attr_accessor :employee, :title, :body, :date, :priority; # out of obj access
	def initialize(employee, title, body, date, priority, type)
		@title = title.gsub(/'/, '');
		@employee = employee[0];
		@body = body.gsub(/'/, '');
		@date = date;
		@priority = priority;	
		@type = type;
	end; # end imapstructor

	def insertJob
		# add it to the DB
		sql = "
			INSERT INTO helpdesk.dbo.helpissues (
				clientname, requestdatetime, status,
				clientpriorty, clientdescription, title, 
				helptype, laststatuschange
			)
			VALUES (
				'#{@employee}', getdate(), 'New',
				'#{@priority}', '#{@body}', '#{@title}',
				'#{@type}', getdate()
			)
		";
		db = DB.new;
		db.execQuery(sql);
	end; 

end; # end Job class


class Email
	# Email class will handle imapnecting, retrieving, and parsing of the data
	# that comes with each job. It will iterate the box for all new job emails,
	# get the data, mark the messages read, and instantiate job objects
	attr_accessor :jobs;
	@jobs = Array.new;
	def initialize()
  	# go ahead and initialize a connection to the inbox
  	imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false);
  	imap.login('email', 'password');
  	imap.select('INBOX');
  	# we should have a imapnection now, if not something got fucked, exit
		# .. but if we didn't exit, search the box
		jobs = Array.new; # store jobs for return to main class
		imap.search(['UNSEEN']).each { |msg| 
			# iterate each new mail, handle the data, instantiate job
			msg = imap.fetch(msg, 'RFC822')[0].attr['RFC822'];
			msg = Mail.read_from_string(msg);
			from = msg.from;
			subj = msg.subject;
			if msg.body.to_s =~ /8859-1/
				body = cleanBody(msg.body.to_s);
			else
				body = msg.body.to_s;
			end;
			msg_date =  msg.date;
			# now we need to turn these things into the data Job.new expects
			subj_parts = subj.split('/');
			if (subj_parts.length == 2)
				# if there are two parts, we know that the user included a type
				type = subj_parts[0];
				title = subj_parts[1];
			else
				type = nil;
				title = subj_parts[0];
			end;
			if (type)
				# we will need to determine type and set it's DB id 
				type = case type
					when /I.?T.?\s?(Issue)?/i then 1;
					when /payroll\s?(issue)?/i then 4;
					when /accounting\s?(issue)?/i then 2;
					when /report\s?(issue)?/i then 3;
					else type = 1; # defualt is 1, which it I.T. Issue
				end;
			else 
				type = 1;
			end;
			# accounting type check, if 2, email accounting group
			if type == 2
				Emailer.new('localhost', 25, title);
			end;
			p = body.to_s.split(/\n+/)[0].downcase;
			# check if a priority was included
			priority = case p
				when 'low' then 'Low';
				when 'medium' then 'Medium';
				when 'high' then 'High';
				when 'urgent' then 'Urgent';
				else nil; # so we can not mess up the issue text if there is no priority
			end;
			# now we can remove the priority from the message body
			parts = body.split(/\n+/);
			body = "";
			if (priority)
				# if there is a priority, grab all message parts, skip priority
				count = -1;
				parts.each { |part|
					count += 1;
					if (count == 0)
						next;
					end;
					body += "\n" + part;	
				}
			else
				parts.each { |part|
				body += "\n" + part;
				}
				priority = "Low";
			end;
			# cool, we should be ready to instantiate a job object out of this now
			# Job.new(employee, title, body, date, priority, type)
			j = Job.new(from, title, body, msg_date, priority, type);
			jobs << j; # add it to our jobs array	
		} # end of email parsing
		# we are now done with iteration
		# send the jobs back to whoever called for them
		@jobs = jobs;
	end; # end of imapstructor

	def cleanBody(body)
		# unforunately people send complicated HTML formatted emails that must
		# be cleaned up in order to be useful to us
		# first, get rid of the header information, it is the first 3 lines
		body = body.to_s;
		begin
			body = body.split(/8859-1\n\n/)[1];
		rescue
			body = body;
		end;
		# now ditch the html tags
		begin
			body = body.gsub(/<[^<]+?>/, '');
		rescue
			body = body;
		end;
		# now strip out the signatures
		begin
			body = body.split(/--/)[0]; 
		rescue 
			body = body;
		end;
		return body;
	end; # end cleanBody method

end; # end Email class


class DB
	# handle DB functionality we will need, in this case job insertion
	attr_accessor :con;
	def initialize 
		@con = TinyTds::Client.new(:username => 'user', :password => 'pass', :host => '192.168.100.170');
	end; # end constructor

	def execQuery(sql)
		res = @con.execute(sql);
		res.insert;
		return res;		
	end; # end execQuery method
end; # end DB class


class AddJobs 
	# this class will handle the main functions of the script, store the jobs, etc
	attr_accessor :jobs; # allow out of class access if needed
	# fire it up
	e = Email.new;
	e.jobs.each { |job| 
		job.insertJob;
		puts "Added #{job.title} at #{Time.now}"; 
	}
end; # end AddJobs class 


AddJobs.new;









