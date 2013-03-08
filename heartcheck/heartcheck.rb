#!/usr/bin/env ruby
###############################################################################
# Heartcheck 0.1beta by Chase Higgins 
###############################################################################
# This script is designed to help make the job of monitoring the status of your
# server easier. This script will monitor the logs of your server to check for 
# mysterious and potentially malicous requests, monitor the status of the web
# server, the status of the MySQL server, the status of the SFTP/SSH server, 
# the vitals of the server(free mem, CPU usage, disk space etc) among many
# other things. 
# The script is designed to send an email to the server administrator when 
# something is amiss. Since the script will attempt to remedy problems on it's
# own, the email may or may not require action from the administrator.  
##############################################################################
# Why write a script such as this when there are already powerful, open source
# tools that do the same? Simple, for low memory server environments adding 
# more overhead to the server with a large monitoring program is too taxing, 
# so I have made a standalone script that can be used and modified easily, 
# as well as extended easily without sucking up too many resources.
###############################################################################

# first we need to define a few constants so the script knows what to look for
# since not everyone needs all the same features, an easy way to turn off 
# monitoring for a specific service or feature is to just not define it's 
# setting in the constants below, so for example if you have no MySQL server 
# to monitor, simply do not set the log file location below. 
ADMIN = 'chasehx@gmail.com';
MESSAGES = '/var/log/messages';
SQL_LOG = '/var/log/mysqld.log';
ACCESS_LOG = '/var/log/apache2/access.log';
ERROR_LOG = '/var/log/apache2/error.log';
MAIL_LOG = '/var/log/maillog';
# now we can define our classes for monitoring various services

