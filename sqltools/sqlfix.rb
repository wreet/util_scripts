#!/usr/bin/env ruby
###################
#TODO
	# add more reserved sql words
	# add lookarounds to reduce mistaken SQL statements
	# add -o switch so user can choose outfile
	# add wildcard file in support for mass syntax repair
	# for column fixing add ability to remember already found columns
###################
class Errors
	def self.fileReadError(fin)
		puts("[-] Could not read #{fin}, please ensure the file exists and you have permission to read it");
		exit();
	end;

	def fileWriteError(fin)
		puts("[-] Could not write fixed #{fin}, please make sure you have permission to write in this directory");
		exit()
	end;

	def regexError(patt, subject)
		puts("[-] Could not match #{patt} to #{subject}");
		exit();
	end;
	
	def noActionError()
		puts("[-] Please choose an action");
		exit();
	end;
end;

class ColumnFinderErrors < Errors
	def self.argLengthError()
		ColumnFinder.showUsage();
	end;
end;

class UpperSQLErrors < Errors
	def self.argLengthError()
		UpperSQL.showUsage();
	end;
end;
	
class UpperSQL
	def initialize()
		@reserved_sql = ["SELECT", "UNIQUE", "DISTINCT", "LIMIT", "ASC", "DESC", "FROM", "INSERT INTO", "IN", "AND", "LIKE", "NULL", "WHEN", "TOP", "CASE", "END", "AS", "UPDATE", "DELETE", "ORDER", "GROUP", "BY", "COUNT", "SUM", "ALTER", "DROP", "LEFT", "RIGHT", "JOIN", "INNER", "THEN", "ELSE", "BETWEEN", "WHERE", "VALUES", "IS", "OR", "NOT", "CONVERT", "CAST"];
	end;
	
	def upperFix(to_upper, fin = nil)
		if (fin)
			begin
				to_upper = File.read(fin);
			rescue 
				Errors.fileReadError(fin);
			end;
		end;
			@reserved_sql.each() { |word|
				begin
					to_upper.gsub!(/\b#{Regexp.quote(word)}\b/i, word);
				rescue 
					next;
				end;
			}
		if (fin) 
			# we have already read and corrected the contents, write them to a file
			begin
				File.open(fin + '.sqlfixed', 'w') { |fout|
					fout.write(to_upper);
				}
			rescue
				Errors.fileWriteError(fin);
			end;
		else
			# just print it 
			puts(to_upper);
		end;
	end;
	
	def self.showUsage()
		puts("Usage: #{$0} [-f] <string or file in>");
		exit();
	end;
end; # end of upper sql class


class ColumnFinder
	def initialize(fin, driver)
		# this class can only be used with a file input, as it reads the columns required by a 
		# script and then generates a select based on them
		@fin = fin;
		begin
			@script = File.read(fin);
		rescue 
			Errors::fileReadError(fin);
		end;
		# we have our input, now we need to determine the pattern based on db driver
		case driver
			when 'odbc_do'
				@patt = /odbc_result\(\$row,\s?'([\w\d]+)'\)/i;
			when 'raw'
				@patt = /\$row\['([\w\d_]+)'\]/i;
			when 'odbc_exec'
				@patt = /\$row\['([\w\d_]+)'\]/i; # use the same as normal mysql
		end;
	end;

	def findColumns()
		# we will parse our input file and collect all the column names
		@columns = Array.new; # we will hold our matches here
		begin
			@script.scan(@patt) { |match|
				# we are now iterating through our matches
				@columns << match;				
			}
		rescue
			Errors.regexError(patt, subject);
		end;
	end;

	def generateSelect()
		sql = "SELECT ";
		@columns.each() { |column|
			sql += "#{column[0]}, ";
		}
		# after we create the select just print it to the screen
		puts sql;
	end;

	def self.showUsage()
		puts("Usage: #{$0} columnfinder|cf <infile> <driver>");
		exit();
	end;

end; # end of column finder class

def main()
	if (ARGV.length < 1) 
		Errors.noActionError();
	end;
	case ARGV[0]
	# determine what we are going to do
		when 'columnfinder' 
			if (ARGV.length < 3)
				ColumnFinderErrors::argLengthError();
			end;
			cf = ColumnFinder.new(ARGV[1].dup, ARGV[2].dup);
			cf.findColumns();
			cf.generateSelect();
		# end of  columnfinder
		when 'uppersql' 
			if (ARGV.length < 2)
				UpperSQLErrors::argLengthError();
			end;
			if (ARGV[1] == '-f')
				# we will be using a file input
				us = UpperSQL.new;
				us.upperFix(nil, ARGV[2]);
			else
				# we will be using string input
				us = UpperSQL.new;
				us.upperFix(ARGV[1].dup);
			end;
		 #end of uppersql
	end;
	
end; # end of main

if (__FILE__ == $0)
	main();
end;
