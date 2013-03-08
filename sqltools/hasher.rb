#!/usr/local/bin/ruby 
###############################################################################
# Script to hash credential storage. It expects an array for which columns
# to use to be set when the class is called. It includes the db class from
# the file in this working directory called db.rb
###############################################################################

# db.rb will be different per application. It is included like this, since 
# people use many different db and drivers. The script expects, however,
# that when it calls for a DB.new, the object will contain a method called
# execQuery, that will be used when the script needs to query. That method
# will need to be written by the user, and placed in the db.rb file in a 
# class called DB.	
load 'db.rb'; 
require 'digest/md5';

class Hash
	# this class simply wraps the hashing method and returns the resulting string
	def self.hash(pass, salt)
		begin
			hash = Digest::MD5.hexdigest(pass + salt);	
		rescue 
			puts "[-] Could not salt #{pass}";
		end;
			return hash;
	end;
end; # end Hash class


class Entry
	# entry object will want the orignal text password, the relevant columns,
	# and the new hashed password to be passed to it
	attr_accessor :pt, :hashed, :salt, :id; # allow external access
	def initialize(plaintext, id, hashed, salt = nil)
		@pt = plaintext;
		@hashed = hashed;
		@salt = salt; # optional
		@id = id;
	end; # end constructor
end; # end Entry class


class Hasher
	# handle the retrieval and hashing of information
	def initialize(con, params)
		# the constructor takes a database connection handle, and a list of fields.
		# fields should be a hash of fields, at minimum 1 field where the curent
		# plaintext password lives. It should be :plaintext, in the hash. The 
		# optional fields are :salt, which is where a custom salt should be stored,
		# and :hashed, an optional field to put the new passwords if we are not 
		# ready to get rid of the plaintext ones.
		@con = con;
		if (params[:salt])
			@salt_col = params[:salt];
		end;
		if (params[:hashed])
			@hashed_col = params[:hashed];	
		end;
		# now the required fields
		if (params[:db])
				@db = params[:db];
			else
				puts "[!] Hasher must be told what database it will be working with";
			end;
	
		if (params[:table])
			@table = params[:table];
		else
			puts "[!] Hasher must be told what table it will be working with";
		end;
		if (params[:identifier])
			@id_col = params[:identifier];
		else
			puts "[!] Hasher expects an identifier column to be defined";
			exit;
		end;
		if (params[:plaintext])
			@pt_col = params[:plaintext];
		else 
			puts "[!] Hasher requires at minumum the name of the field where the \
						plaintext password is stored";
			exit;
		end;
		# if we made it out of there then we can collect all the passwords
	end; # end constructor

	def getEntries
		# collect the passwords from the database, hash them, and istantiate them 
		# into a list of entry objects
		@entries = Array.new;
		# we will need to build a sql query out to collect the information
		sql = "
			SELECT #{@pt_col}, #{@id_col} \
			FROM #{@db}.#{@table} \
		";
		res = @con.execQuery(sql);		
		res.each { |row|
			puts row;
			plaintext = row[@pt_col];
			id = row[@id_col];
			# now we can hash the password
			hashed = Hash::hash(plaintext, @salt.to_s);
			# instantiate entry
			e = Entry.new(plaintext, id, hashed, @salt);
			@entries << e; 
		}; # end result set iteration
		res.do;
	end; # end getEntries method

	def updateEntries
		# this method will iterate the entries objects that should have been 
		# instantiated. It will insert the new hashed password, the salt if
		# applicable. It should also check to make sure we are updating the 
		# original field, if @hashed exists, that is where it goes
		@entries.each { |e|
			# add the hashes to the database
			# insert salt, and new hash into a special hashed column
			if (e.salt && @salt_col && @hashed_col)
				sql = "
					UPDATE #{@db}.#{@table} \
					SET #{@salt_col} = '#{e.salt}', \
					#{@hashed_col} = '#{e.hashed}' \
					WHERE #{@id_col} = '#{e.id}' \
				";
			# replace the plaintext password with the hashed one, store the salt
			elsif (e.salt && @salt_col)
				sql = "
					UPDATE #{@db}.#{@table} \ 
					SET #{@salt_col} = '#{e.salt}', \
					#{@pt_col} = '#{e.hashed}' \
					WHERE #{@id_col} = '#{e.id}' \ 
				";
			# insert new hash into special hashed column, no salts
			elsif (@hashed_col) 
				sql = " 
					UPDATE #{@db}.#{@table} \
					SET #{@hashed_col} = '#{e.hashed}'
					WHERE #{@id_col} = '#{e.id}' \
				";
			end; # end the craziness of else if
			res = @con.execQuery(sql);
			res.do;
		}; # end entries iteration
	end; # end updateEntries class

end; # end Hasher class















