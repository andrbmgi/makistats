#!/usr/bin/perl -w

open (MYFILE, '<makiscrape.json') or die $!;

print "Access-Control-Allow-Origin: *\n";
print "Content-Type: application/json\n\n";

while (<MYFILE>) {
  print $_;
}

close (MYFILE);