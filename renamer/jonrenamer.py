#!/usr/bin/env python
import os
from sys import argv
import random


##This function is responsible for figuring out the precise
## sequence of renames that should take place, a sequence that
## we will call the 'script'.
def makeScript(inorder, newnames, tempname):
    script = []
    for elt in inorder:
        if elt not in newnames:
            continue
        if elt == newnames[elt]:
            del newnames[elt]
            continue
        if newnames[elt] not in newnames:
            script.append((elt, newnames[elt]))
            del newnames[elt]
            continue
        chain = []
        inthechain = {}
        link = elt
##THIS IS THE LAST PART I HAVE TO ADD IN 
##The script that the existing code will find fails. You must break
##the cycle of rename dependencies. Here is how you can do it.

##Within the loop that is building a chain of rename dependencies,
##before adding an element to the chain, check if the target
##name is already in the chain (it will appear in the inthechain
##dictionary). If so, you have found a cycle. To break it, perform
##the following steps:

##Change the entry in newnames for this link so that it will be
##renamed to the temporary name.

##Add an entry to newnames for the temporary name, setting it to
##be renamed to the actual target name. These actions effectively
##"pretend" that it was supposed to be renamed in two steps all along.

##Add an entry to the chain changing the old name to the temporary name.

##Insert an entry at the beginning of the chain changing the temporary
##name to the actual target name. Use the insert method of python lists
##to accomplish this.

##Break out of the loop.

##The existing code will reverse the chain and add the entries to the
##script as usual, with the effect that the first action will be to
##rename the entry to the temporary name, and the last action will be
##to rename the temporary name to the final target name. Everything else
##will work as usual.        
        while True:
            targetname = newnames(link)
            chain.append((link, targetname))
            inthechain[link] == True
            link = targetname
            if link not in newnames:
                break
        chain.reverse()
        for elt in chain:
            script.append(elt)
            del newnames[elt[0]]
        
    return script



##This function loops through the actions in the script and performs
## each one. Each entry in the script has an old name and a new name.
## Print a message before renaming for each one so the output will look
## like this:
## mypics4.jpg -> mypics5.jpg
## mypics3.jpg -> mypics4.jpg
## a.jpg -> mypics3.jpg
def doRenames(root, script):
    for elt in script:
        newnames = elt[1]
        oldnames = elt[0]
        newpath = os.path.join(root, newnames)
        oldpath = os.path.join(root, oldnames)
        if os.path.exists(newpath):
            print 'Error path already exists!'
            exit(1)
        else:
            print oldpath[oldpath.rfind('/')+1:].lower(), '-->', newpath[newpath.rfind('/')+1:].lower()
            os.rename(oldpath, newpath)
        print 
    return
    
        

    
##Checks files in directory to make sure they are pictures   
def filterByExtension (root, allfiles, extensions):
    results = []
    for file in allfiles:
        if (file.rfind('.') != -1):
            ext = file[file.rfind('.')+1:].lower()
            for extension in extensions:
                if (ext==extension.lower()):
                    if os.path.isfile(os.path.join(root, file)):
                        results.append(file)
                    
    return results


##Sorts the list of files by modified time
def sortByMTime(root, matching):
    timeandfile = []
    newlist = []
    
    for file in matching:
        time = os.path.getmtime(os.path.join(root, file))
        timeandfile.append((time, file)) 
        timeandfile.sort()
        
    for tup in timeandfile:
        newlist.append(tup[1])

    return newlist


##Assigns names to the files like 'Prefix+Number)
def assignNames(prefix, inorder):
    
    digits = len(str(len(inorder)))
    template = prefix + ('%%0%dd.%%s' % digits)
    newnames = {}
    i = 1
    
    for elt in inorder:
        ext = elt[elt.rfind(".")+1:].lower()
        newname = template%(i, ext)
        newnames[elt] = newname
        i+=1
        
    return newnames


##Generates a temporary file name that does not
## already exist in the list of files it is given.
def makeTempName(allfiles):
    NNN = random.randint(1,100000000)
    tempname = '__temp'+str(NNN)
    while tempname in allfiles:
        NNN += 1
        tempname = '__temp'+str(NNN)
    return tempname
    


def main():
    try:
        root = os.path.abspath(argv[1])
    except:
	print "--Usage: %s <directory> [<prefix>]--" % argv[0]
        exit(1)
    try:
        prefix = argv[2]
        
    except:
        print '--No prefix was chosen, directory name will be used!--'
        prefix = os.path.basename(argv[1])
        

    allfiles = os.listdir(argv[1])
    extensions = ['jpeg', 'jpg', 'png', 'gif', 'svg']
    matching = filterByExtension(root, allfiles, extensions)
    inorder = sortByMTime(root, matching)
    newnames = assignNames(prefix, inorder)
    tempname = makeTempName(allfiles)
    script = makeScript(inorder, newnames, tempname)
    doRenames(root, script)

    
main()
