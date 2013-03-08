#!/usr/bin/env ruby

class CookieMonster
	def mkCookieString(cookies) 
		@cookies = cookies.split("; ");
		cookie_string = "";
		@cookies.each() { |cookie|
			cookie_string += "document.cookie='#{cookie}';";
		}
		@cookies = cookie_string;
		return @cookies;
	end;
	
	def showCookieString()
		puts @cookies;
	end;

	def showUsage()
		puts "Usage: CookieMonster.mkCookieString(<document.cookie output>)";
	end;
end;

def main()
	cm = CookieMonster.new;
	if (ARGV.count < 1)
		cm.showUsage();
		exit();
	end;
	cm.mkCookieString(ARGV[0]);
	cm.showCookieString();
end;

if (__FILE__ == $0) 
	main();
end;
