#!/usr/bin/env ruby
################################################################################
# Word Collecter v0.1.1b for Twitter Analysis Suite by Chase Higgins
################################################################################
# We need a good list of words that are negative/positive and we will do a simple
# comparison of these words with the tweets we have in the database. 
################################################################################
# TODO:
	# modify this script to pull exact antonyms to a wordlist, that way we have
		# the same amount of words per list while also making sure the words we 
		# are looking for are equal opposites to keep artificially high match 
		# counts down
################################################################################
require 'open-uri';


class WordList
	# just need to create a simple way to build the word list for our script to 
	# analyze the tweets in a given DB
	def readURL(url)
		page = open(url);
		return page.read;
	end; # end of readURL
	
	def parseWords(page)
		# parse the words out from the webpage
		# so now we *should* have a string with the table of words, they are all
		# contained in cells, so we will have to parse the content further
		words = Array.new;
		patt = /<tr><td>([\w]+)<td>([\w]+)<td>([\w]+)<\/tr>/ixsm;
		page.scan(patt) { |match|
			match.each() { |word|
				words << word;
			}
		}
		return words;
	end; # end of parseWords

	def getPositive
		url = "http://www.creativeaffirmations.com/positive-words.html";
		page = readURL(url);
		@positives = parseWords(page);
		puts("[+] Collected #{@positives.length} positive verbal indicators");
		return @positives;
		# now parse the response
	end; # end of get positive 

	def getNegative
		url = "http://www.creativeaffirmations.com/negative-words.html";
		page = readURL(url);
		@negatives = parseWords(page);
		puts("[+] Collected #{@negatives.length} negative verbal indicators");
		return @negatives;
	end; # end of getNegative

	def writeList(list, out_file)
		fh = File.new(out_file, 'w');
		list.each() { |word| 
			fh.puts(word);
		}
	end; # end of writeList

	def writeLists
		# convenient method to write both lists in one 
		# first we will write the positive words
		writeList(@positives, 'positives.txt');		
		puts("[+] Wrote positives");
		writeList(@negatives, 'negatives.txt');
		puts("[+] Wrote negatives");
	end; # end of writeLists method
end; # end of word lists class


def main
	# run it
	w = WordList.new;
	w.getPositive;
	w.getNegative;
	# we now have a list of positive/negative words contained in the instance
	# variables of @positives and @negatives
	w.writeLists;
end;

if (__FILE__ == $0)
	main;
end;
