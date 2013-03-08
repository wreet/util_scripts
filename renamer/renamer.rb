#!/usr/bin/env ruby

require 'pathname';

class Renamer
	def initialize()
		@path = Pathname.new(ARGV[0]).realpath;
		@prefix = ARGV[1];
		@extensions = ['jpg', 'png' , 'gif'];
		@all_files = Array.new;
		@images = Array.new;
		Dir.foreach(@path) { |file|
			@all_files << file;
		}		
	end;

	def getImages() 
		@all_files.each() { |file|
			ext = file.split(/([\w\d]{3}$)/)[1];
			@extensions.each() {
				|extension|
				if (ext == extension) 
					@images << file;
					self.rename(file);					
				end;
			}	
		}
	end;

	def rename(file) 
		File.rename(File.join(@path, file), File.join(@path, @prefix + file));			
	end;
end;


def main() 
	rename = Renamer.new;
	rename.getImages();
end;

if (__FILE__ == $0) 
	main();
end;                                     
