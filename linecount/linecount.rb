#!/usr/bin/env ruby
#####################
# Line Count v0.1b By Chase Higgins
####################
# count lines of script ignoring comments
# TODO:
	# Add wilcard support for line count of multiple files at once
	# Add support to pipe to script from stdin
	# don't count whitespace
#####################

class LineCount
	def initialize()
		@comment_chars = ['\#', '\%', '\/\/', '\/\*', '\*\/', '!'];
	end;
	
	def count(fin, count_comments = 0)
		@fin = fin;
		@count = 0;
		File.open(@fin, 'r') { |fh|
			while (line = fh.gets())
				@count += 1;
				@comment_chars.each() { |char|
					patt = "^#{char}";
					if (line.strip.match(patt))
						if (count_comments != 0)
							next;
						end;
						@count -= 1;
					end;
				}
			end;
		}
	end;
	
	def showCount()
		puts("[+] Line Count: #{@count}");
	end;

	def showUsage()
		puts("Usage: #{$0} <file>");
		exit();
	end;
end; # end of linecount class

def main()
	lc = LineCount.new;
	if (ARGV.count < 1)
		lc.showUsage();
	end;

	lc.count(ARGV[0]);
	lc.showCount();
end;

if (__FILE__ == $0)
	main();
end;
