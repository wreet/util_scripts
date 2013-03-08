#!/usr/bin/ruby

patt = /[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/;
fin = File.read ARGV[0];
emails = Array.new;
emails = fin.scan(patt);
emails.each() { |email|
  puts email.downcase; 
}
