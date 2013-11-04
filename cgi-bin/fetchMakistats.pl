#!/usr/bin/perl -w
#exec('ulimit -n 2048; vendor_process');
#use strict;
no warnings;
use CGI;
use lib qw(/var/www/web85/html/makiscrape/cgipan/mylib/);
use YAML;
use lib qw(/var/www/web85/html/makiscrape/cgipan/build/Web-Scraper-0.32/lib/);
use Web::Scraper;
use LWP::UserAgent;
use HTTP::Cookies;
use lib qw(/var/www/web85/html/makiscrape/cgipan/Crypt-SSLeay-0.58/lib/);
use Crypt::SSLeay;
use LWP::Protocol::https;
use Data::Dumper;
use String::Util 'trim';
use DateTime;
use JSON;


#open (MYFILE, '</var/www/web85/html/makiscrape/makiscrape.json') or die $!;
open (MYFILE, '<makiscrape.json') or die $!;

print "Access-Control-Allow-Origin: *\n";
print "Content-Type: application/json\n\n";

while (<MYFILE>) {
  print $_;
}

close (MYFILE);


