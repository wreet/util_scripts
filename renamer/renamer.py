#!/usr/bin/env python

import os;
from sys import argv;

class renamer:
	def __init__(self):
		try:
			self.path = os.path.abspath(argv[1]);
		except:
			exit(1);
		try:
			self.prefix = argv[2];
		except:
			self.prefix = argv[1];
		self.filenames = os.listdir(argv[1]);
		self.extensions = ['jpg', 'gif', 'png'];
		self.files = [];

	def getImages(self):
		for file in self.filenames:
			if (file.rfind('.') != -1):
				ext = file[(file.rfind('.')+1):].lower();
				for extension in self.extensions:
					if (ext == extension.lower() and os.path.isfile(os.path.join(self.path, file))):
						self.files.append(file);
						self.rename(file);

	def rename(self, file):
		image_path = os.path.join(self.path, file);
		os.rename(image_path, os.path.join(self.path, self.prefix + file));
	

def main():
	rename = renamer();
	rename.getImages();


if (__name__ == "__main__"):
	main();	
