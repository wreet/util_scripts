#!/usr/bin/env ruby

#############################
# Todo:
  # script can't run standalone, create options parser
  # also I think a wizard style use case would be tight
  # script is mysql specific at the moment, look into DBI or ODBC
#############################

require("mysql");

class HashField
  # we will connect to a database, read a specified password field, hash the value,
  # then reinsert the new hashed password into the tables password field
  
  def getSQLConnection(host, user, password, db);
    # get a connection to the specified DB and return a connection handle object
    begin
      con = Mysql.real_connect(host, user, password, db);
      # print the server information for the user
      puts(con.get_server_info());
    rescue
      puts("[-] We ran into an error");
      exit();
    end; # end of exception handle
    # if we made it here, set the handle 
    @con = con;
  end; # end of getSQLConnection

  def setHashMethod(method, salt = nil)
    # we need to determine what hash algo to use as well as the desired salt (if any)
    case method
      when 'sha1'
        require('digest/sha1');
      when 'md5'
        require('digest/md5');
    end;
    if (salt)
      # save the salt 
      @salt = salt;
      @method = method;
    end;
  end; # end of hash method

  def setTableSchema(table, pass_field, id_field)
    # get the table we will use as well as the password field we will be updating
    # first we should check if the table and column exist
    begin
      res = con.query("SELECT `#{pass_field}`, `#{id_field}` FROM `#{table}` LIMIT 1");
    rescue
      # looks like the table probably didn't exist, tell the user and kill script
      puts("[-] The table and columns you specified doesn't appear to be in this database");
      exit();
    # if we make it out the table and column *should* be there
    @schema = {
      :table => table,
      :pass_field => pass_field,
      :id_field => id_field
    }
    @pass_field = pass_field;
    @id_filed = id_field;
    @table = table;
  end; # end of setTableSchema

  def collectRecords()
    sql = "SELECT `#{@pass_field}`, `#{@id_field}` FROM `#{@table}`";
    res = con.query(sql);
    results = [];
    puts("[+] Hashing password field for #{res.num_rows} records using #{@method} with salt '#{@salt}'");
    # now we can store the records
    res.each { |row| 
      results << {
        :passwd => row[0], 
        :id => row[1]
      }
    }
    @results = results;
    # that should be all the records
  end; # end of collectRecords

  def hashPasswords() 
    # now hash the password field for each record
    @results.each() { |result|
      case @method
        when 'sha1'
          Digest::SHA1
      end; # end case
    }
  end;


end; # end of HashField class


















