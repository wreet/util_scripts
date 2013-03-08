#!/usr/bin/env ruby

class Tag
	def initialize(tag)
		@tag = tag;
		@attributes = '';
	end;
	
	def setId(id)
		# save the id to our object
		@tag_id = id;
	end;
	
	def addClasses(classes)
		@classes = 'class="';
		ctrl = 0;
		classes.each { |class_name|
			if (ctrl == 0)
				@classes += "#{class_name}";
			else
				@classes += " #{class_name}";
			end;
			ctrl += 1;
		}
		@classes += '"';
	end;
	
	def addAttributes(attributes)
		# we will use a hash for the attributes	
		ctrl = 0;
		attributes.each_pair { |key, val|
			if (ctrl == 0)
				@attributes += "#{key}=\"#{val}\"";
			else 
				@attributes += " #{key}=\"#{val}\"";
			end;
			ctrl += 1;
		}
	end;
	
	def getAttributes()
		return @attributes;
	end;
	
	def makeTag(inner_html)
		return "<#{@tag} #{@classes} #{@attributes}>#{inner_html}</#{@tag}>";
	end;
end; # end of the tag class

class BlockTag < Tag
	def makeTag(inner_html)
		# over ride maketag to prepend a newline
		return "\n<#{@tag} #{@classes} #{@attributes}>#{inner_html}</#{@tag}>";
	end;
end; # end of the block tag class

class SelfClosing < Tag
	def makeTag()
		# over ride maketag to self close
		return "<#{@tag} #{@classes} #{@attributes} />";
	end;
end; # end of self closing class

class Container < Tag
	def addTag(tag) 
		next;
	end;	

	def addText(text)
		next;
	end;
end; # end of the container class


def main()
	atts = {
		'height' => '400',
		'width' => '600',
		'style' => 'margin-top: 10px;'
	};
	classes = ['top_banner', 'main', 'error'];
	tag = Tag.new('p');
	tag.setId('test');
	tag.addClasses(classes);
	tag.addAttributes(atts);
	puts(tag.makeTag('this text is in a paragraph'));
	# test out blocktag
	block = BlockTag.new('div');
	block.setId('test2');
	block.addClasses(classes);
	block.addAttributes(atts);
	puts(block.makeTag('I am in a div'));
	# test self closing
	sc = SelfClosing.new('img');
	sc.setId('self_closing');
	sc.addClasses(classes);
	sc.addAttributes(atts);
	puts(sc.makeTag());
	
end;

if (__FILE__ == $0)
	main();
end;
