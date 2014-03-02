#!/usr/bin/perl -w
use strict;
# no warnings;

use lib qw(/var/www/web85/html/makiscrape/cgipan/mylib/);
# use lib qw(/var/www/web85/html/makiscrape/cgipan/Crypt-SSLeay-0.58/lib/);
use lib qw(/var/www/web85/html/makiscrape/cgipan/build/Web-Scraper-0.32/lib/);

# use CGI;
# use YAML;
use Web::Scraper;
use LWP::UserAgent;
# use HTTP::Cookies;
# use Crypt::SSLeay;
# use LWP::Protocol::https;
use Data::Dumper;
use String::Util 'trim';
use DateTime;
use Encode;
use JSON;
use Try::Tiny;
use HTML::Entities;
# use Async;

# ////// Debug and Environment Settings /////////////////////////////////////////////////

my $path = '/var/www/web85/html/makiscrape/';
# my $path = ''; # local
my $debug = 1;
my $proxify = 0;
# ///////////////////////////////////////////////////////////// PROXY ////////////////////////////////////////////
sub proxify {
	$_[0]->agent('Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; WOW64; Trident/4.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; .NET4.0E)');
	$_[0]->proxy(['http'], 'http://');
	return $_[0];
}
# ///////////////////////////////////////////////////////////// PROXY ////////////////////////////////////////////

# ///////////////////////////////////////////////////////////////////////////////////////

my $changes = 0;

# ////// Variable Declaration /////////////////////////////////////////////////

my $old_data;
my $encoding;
my $unicode_json_text;
my $domain;
my $extractPages;
my $extractData;
my $ua;
my $response;
my $data;
my $res;
my $repeat;
my $oldLastLink;
my $linkData;
my $linkRes;
my $ol;
my $nl;
my $server_res;
my $csv_output;
my $dt;
my $outputbuffer;
my $outputmessage;

# ////// Functions /////////////////////////////////////////////////

sub ifDateAvail {
    if ( $_[0]->{year} ne 'n/a') {
      return $_[0]->{year} . '-' . $_[0]->{month} . '-' . $_[0]->{day};
    } else {
      return '';
    }
 };

 sub getDate {
	my $month = -1;
	if ( defined $_[0] ) {
		if ( length($_[0]) > 2 ) {
			# assume string
			if ( index($_[0], 'jan') > -1 ) {
				$month = 1;
			} elsif ( index($_[0], 'feb') > -1 ) {
				$month = 2;
			} elsif ( index($_[0], 'mar') > -1 ) {
				$month = 3;
			} elsif ( index($_[0], 'apr') > -1 ) {
				$month = 4;
			} elsif ( index($_[0], 'may') > -1 ) {
				$month = 5;
			} elsif ( index($_[0], 'jun') > -1 ) {
				$month = 6;
			} elsif ( index($_[0], 'jul') > -1 ) {
				$month = 7;
			} elsif ( index($_[0], 'aug') > -1 ) {
				$month = 8;
			} elsif ( index($_[0], 'sep') > -1 ) {
				$month = 9;
			} elsif ( index($_[0], 'oct') > -1 ) {
				$month = 10;
			} elsif ( index($_[0], 'nov') > -1 ) {
				$month = 11;
			} elsif ( index($_[0], 'dec') > -1 ) {
				$month = 12;
			};
		} else {
			# assume int
			$month = int($_[0]);
		};
	};
	if ( ($month < 1) or ($month > 12) ) { # sanity check
		$month = -1;
	};
	return $month;
};

sub isNumber {
	if ( defined $_[0] ) {
		if ($_[0] =~ /^[+-]?\d+$/ ) {
		    # print "Is a number\n";
		    return 1;
		} else {
		    # print "Is not a number\n";
		    return 0;
		}
	} else {
		return 0;
	}
}

# ////// Partitioned Program Segments (to be called asynchronously) /////////////////////////////////////////////////

sub scrape_prep {


};

sub scrape_next {


};

# ////// Main Program (entry point) /////////////////////////////////////////////////

BEGIN { $| = 1 }

if ($debug) { $outputmessage = "scrape.pl running...\n"; print $outputmessage; $outputbuffer .= $outputmessage };

# print "Scrape preparation...";
# my $proc = Async->new(sub { 
# 	#any perl code you want executed 
# 	scrape_prep();
# });

# if ($proc->ready) {
# 	# the code has finished executing
# 	if ($proc->error) {
# 	  	# something went wrong
# 		print "An error occured.";
# 	} else {
# 	  	my $result = $proc->result;  # The return value of the code
# 		print "prep done.";
# 		scrape_next();
# 	}
# }

# get old data to check for changes / calculate lastEdited date
	local $/;
	my $fileexists = 1;
	if ($debug) { $outputmessage = "Reading makiscrape_full.json (old raw data)..."; print $outputmessage; $outputbuffer .= $outputmessage };
	open (MYFILE, '<'.$path.'makiscrape_full.json') or $fileexists = 0;
	# my $encoding = 'cp932';
	$encoding = 'utf8';
	if ($fileexists) {	
		$unicode_json_text = decode( $encoding, <MYFILE> ); # UNICODE	
		close (MYFILE);
		if ($debug) { $outputmessage = "done.\n"; print $outputmessage; $outputbuffer .= $outputmessage };
	} else {
		if ($debug) { $outputmessage = "no such file. (not a problem!)\n"; print $outputmessage; $outputbuffer .= $outputmessage };
	}	
	if ( defined $unicode_json_text && $unicode_json_text ne '' ) {
		$old_data = from_json($unicode_json_text);
	};		
	# print Dumper $old_data;


	#open (MYFILE, '>makiscrape.json');

	#print MYFILE "Access-Control-Allow-Origin: *\n";
	#print MYFILE "Content-Type: application/json\n\n";

	# print "McReeds Master Scraper v0.1\n";
	# print "--------------------------------------------\n";

	$domain = 'http://makibox.com/';

	$extractPages = scraper {
		process 'div.topcontrols > span > a.pagenavlink', 'links[]' => '@href'; 
	};

	$extractData = scraper {
		process 'div.message-container', 'messages[]' => scraper { 
				process 'div.messagelink > a', 'link' => '@href';
				process 'div.poster', 'poster' => 'TEXT';
				process 'div.helpdesk-messageblock', 'content' => 'TEXT';
				# scraper {
				# 	process 'b', 'type' => 'TEXT';
				# 	process 'b+b', 'color' => 'TEXT';
				# 	process 'b+b+b', 'notice' => 'TEXT';
				# 	process 'b+b+b+b', 'tracking' => 'TEXT';
				# 	process 'b+b+b+b+b', 'country' => 'TEXT';
				# 	process 'b+b+b+b+b+b', 'shipping' => 'TEXT';
				# 	process 'b+b+b+b+b+b+b', 'received' => 'TEXT';
				# };
				process 'div.bottom-left', 'postDate' => 'TEXT';
		};
	};

	$ua = LWP::UserAgent->new;
	$ua->cookie_jar( {} );	

	if ($proxify) { $ua = proxify($ua); };

	if ($debug) { $outputmessage = "Scraping first page for page links..."; print $outputmessage; $outputbuffer .= $outputmessage };
	$response = $ua->get($domain . 'forum/topic/2042');
	$data = $response->decoded_content;
	$res = $extractPages->scrape($data);	
	if ($debug) { $outputmessage = "done.\n"; print $outputmessage; $outputbuffer .= $outputmessage };

	# print $res->{links}[ $#{$res->{links}} ] . "\n\n";
	# print Dumper $res->{links};

	$repeat = 1;

	if ($debug) { $outputmessage = "Scraping all page links of the thread"; print $outputmessage; $outputbuffer .= $outputmessage };
	try {

		do {
			# save oldLastLink
			$oldLastLink = $res->{links}[ $#{$res->{links}} ];
			# get last link
			$response = $ua->get($domain . $res->{links}[ $#{$res->{links}} ]);
			# extract pages
			$linkData = $response->decoded_content;
			$linkRes = $extractPages->scrape($linkData);
			# add new pages to original list
			$ol = 0;
			do {
				for $nl ( 0 .. $#{$linkRes->{links}} ) {
					# print "is " . $res->{links}[$ol] . " eq " .$linkRes->{links}[$nl]. " ?\n";
					if ( $res->{links}[$ol] eq $linkRes->{links}[$nl] ) {
						# print "yup\n";
						# link already in old list
						splice(@{$linkRes->{links}}, $nl, 1); 	
						last;
					};
				};
				$ol++;
			} while ($ol <= $#{$res->{links}});
			push(@{$res->{links}}, @{$linkRes->{links}});
			
			# if last link eq oldLastLink exit else repeat
			# print $res->{links}[ $#{$res->{links}} ]." eq ".$oldLastLink."?\n";
			if ( $res->{links}[ $#{$res->{links}} ] eq $oldLastLink ) {
				$repeat = 0;
			};
			if ($debug) { $outputmessage = "."; print $outputmessage; $outputbuffer .= $outputmessage };
		} while ($repeat == 1);
		# print Dumper $res->{links};
		# die;
		# print "\n\n\n";
	} catch {
		print "caught error: $_"; # not $@
		print "Error is in the scraping of pagelinks..."
	};
	if ($debug) { $outputmessage = "done.\n"; print $outputmessage; $outputbuffer .= $outputmessage };

	if ($debug) { $outputmessage = "Fetching html content of all scraped pages"; print $outputmessage; $outputbuffer .= $outputmessage };
	try {

		for my $i ( 0 .. $#{$res->{links}} ) {
			$response = $ua->get($domain . $res->{links}[$i]);
			$data .= $response->decoded_content;			
			if ($debug) { $outputmessage = "."; print $outputmessage; $outputbuffer .= $outputmessage };
		};
		$res = $extractData->scrape($data);
		$server_res = $extractData->scrape($data);

		# prepare csv output
		my @header;
		@header = ('Name', 'Type', 'Ramen', 'Color', 'Country', 'Shipping', 'Order', 'Notice', 'Tracking', 'Received', 'Cancelled', 'LastEdited', 'Link', 'OriginalPost');
		$csv_output = join(';', @header);
		$csv_output .= "\r\n";

		# add date for reference
		$dt = DateTime->now();
		$res->{scraped} = $dt->ymd('-') . ' ' . $dt->hms(':');
		$server_res->{scraped} = $res->{scraped};

		# lead post
		delete $res->{messages}[0]->{content};
		delete $server_res->{messages}[0]->{postDate};

	} catch {
		print "caught error: $_"; # not $@
		print "Error is in the preparation block..."
	};
	if ($debug) { $outputmessage = "done.\n"; print $outputmessage; $outputbuffer .= $outputmessage };




try {

	if ($debug) { $outputmessage = "Iterating through all messages"; print $outputmessage; $outputbuffer .= $outputmessage };
	for my $i ( 1 .. $#{$res->{messages}} ) {
	# print $res->{messages}[$i]->{content} eq $old_data->{messages}[$i]->{content};
		# print Dumper $old_data;
		# print Dumper $unicode_json_text;

		if ( defined $old_data->{messages}[$i] ) {
			# test for changes
			if ( $res->{messages}[$i]->{content} ne $old_data->{messages}[$i]->{content} ) {
				$changes = 1;
			};
		};

		$dt = DateTime->now(); # strange bug otherwise with changing dates

		# try to find out if the content was altered and set new lastEdited date
		if ( defined $old_data->{messages}[$i]->{lastEdited} && $old_data->{messages}[$i]->{lastEdited} ne '' ) {
			if ( $res->{messages}[$i]->{content} eq $old_data->{messages}[$i]->{content} ) {
				$res->{messages}[$i]->{lastEdited} = $old_data->{messages}[$i]->{lastEdited};
				$server_res->{messages}[$i]->{lastEdited} = $res->{messages}[$i]->{lastEdited};
			} else {
				$res->{messages}[$i]->{lastEdited} = $dt->year() . '-' . $dt->month() . '-' . $dt->day();
				$server_res->{messages}[$i]->{lastEdited} = $res->{messages}[$i]->{lastEdited};
			};
		} else {
			my $postDate = $res->{messages}[$i]->{postDate};
			$postDate = lc( substr($postDate, 0, index($postDate, ' ')) );


			if ( index($postDate, 'today') > -1 ) {
				$postDate = $dt;
				$postDate = substr($postDate, 0, index($postDate, 'T'));
			}
			if ( index($postDate, 'yesterday') > -1 ) {
				$postDate = $dt->subtract(days => 1);
				$postDate = substr($postDate, 0, index($postDate, 'T'));
			}
			$res->{messages}[$i]->{lastEdited} = $postDate;
			my @dateparts = split('-', $res->{messages}[$i]->{lastEdited});
			$day = '-1';
			$month = '-1';
			$year = '-1';
			if (isNumber($dateparts[0])) {
				# yyyy-mm-dd
				$year = int($dateparts[0]);						
				$day = int($dateparts[2]);
				$month = &getDate($dateparts[1]);
			}
			my freshLastEditedString = $year . '-' . $month . '-' . $day;
			$server_res->{messages}[$i]->{lastEdited} = freshLastEditedString;
		};
		delete $res->{messages}[$i]->{postDate};
		delete $server_res->{messages}[$i]->{postDate};
	# die;
		my $stringOrig = $res->{messages}[$i]->{content};
		my $string = lc( $res->{messages}[$i]->{content} );

		#type
		my $startstring = lc( '1. Ordered' );
		my $endstring = lc( 'color' );
		my $beg = index($string, $startstring);
		my $bl = length($startstring); 
		my $end = index($string, $endstring);
		my $txt = substr($string, $beg+$bl, $end-$beg-$bl);
		my $type = 'n/a';
		if ( index($txt, 'ht') > -1 ) {
			$type = 'HT';
		} elsif ( index($txt, 'lt') > -1 ) {
			$type = 'LT';
		}
		if ( index($txt, 'ramen') > -1 ) {
			$res->{messages}[$i]->{data}->{ramen} = 1;
		} else {
			$res->{messages}[$i]->{data}->{ramen} = 0;
		}
		$res->{messages}[$i]->{data}->{type} = $type;

		#color
		$startstring = lc( 'color' );
		$endstring = lc( 'on' );
		$beg = index($string, $startstring);
		$bl = length($startstring); 
		$end = index($string, $endstring);
		$txt = substr($string, $beg+$bl, $end-$beg-$bl);
		my $color = 'n/a';
		if ( (index($txt, 'cle') > -1) or (index($txt, 'transp') > -1) ) {
			$color = 'Clear';
		} elsif ( index($txt, 'yel') > -1 ) {
			$color = 'Yellow';
		} elsif ( index($txt, 'bl') > -1 ) {
			$color = 'Black';
		} elsif (( index($txt, 'stainless') > -1 ) or ( index($txt, 'steel') > -1 ) or ( index($txt, 'ss') > -1 )) {
			$color = 'Stainless Steel';
		}
		$res->{messages}[$i]->{data}->{color} = $color;

		#ordered
		#my $switchDate = { 0, 0, 0, 0 };
		$startstring = lc( 'on' );
		$endstring = lc( '2.' );
		$beg = index($string, $startstring);
		$bl = length($startstring); 
		$end = index($string, $endstring);
		$txt = substr($string, $beg+$bl, $end-$beg-$bl);
		$txt =~ s/://;
		$txt = trim($txt);
		my $divider = ' ';
		if ( index($txt, '/') > -1 ) {
			if ( index($txt, '/', index($txt, '/')+1) > -1 ) {
				$divider = '/';
			}
		} elsif ( index($txt, '-') > -1 ) {
			if ( index($txt, '-', index($txt, '-')+1) > -1 ) {
				$divider = '-';
			}
		}
		my @dateparts = split($divider, $txt);
		my $day = '-1';
		my $month = '-1';
		my $year = '-1';
		if (isNumber($dateparts[0])) {
			if (index($dateparts[2], ' ') > -1) { $dateparts[2] = substr($dateparts[2], 0, index($dateparts[2], ' ')); } 
			if ( length($dateparts[0]) == 4 ) {
				# assume yyyy-mm-dd
				# ISO 8601 all the way!				
				$year = int($dateparts[0]);				
				$day = int($dateparts[2]);
				$month = &getDate($dateparts[1]);
			} else {
				# assume mm-dd-yyyy
				if ( int($dateparts[0]) > 12 ) {
					# assume dd-mm-yyyy
					$year = int($dateparts[2]);
					$day = int($dateparts[0]);
					$month = &getDate($dateparts[1]);
				} else {
					$year = int($dateparts[2]);
					$day = int($dateparts[1]);
					$month = &getDate($dateparts[0]);
				}
			}
		}
		my $y = 'n/a';
		my $m = 'n/a';
		my $d = 'n/a';
		if ( 	($year >= 2011) and ($year <= 2014)
			and ($month > -1)
			and ($day >= 1) and ($day <= 31) ) {
			$y = $year;
			$m = $month;
			$d = $day;
		}
		$res->{messages}[$i]->{data}->{orderDate}->{year} = $y;
		$res->{messages}[$i]->{data}->{orderDate}->{month} = $m;
		$res->{messages}[$i]->{data}->{orderDate}->{day} = $d;

		# notice
		$startstring = lc( 'notice' );
		$endstring = lc( '3.' );
		$beg = index($string, $startstring);
		$bl = length($startstring); 
		$end = index($string, $endstring);
		$txt = substr($string, $beg+$bl, $end-$beg-$bl);
		if ( index($txt, 'on') > -1 ) {
			$txt = substr($txt, index($txt, 'on')+2);
		}
		$txt =~ s/://;
		$txt = trim($txt);
		$divider = ' ';
		if ( index($txt, '/') > -1 ) {
			if ( index($txt, '/', index($txt, '/')+1) > -1 ) {
				$divider = '/';
			}
		} elsif ( index($txt, '-') > -1 ) {
			if ( index($txt, '-', index($txt, '-')+1) > -1 ) {
				$divider = '-';
			}
		}
		@dateparts = split($divider, $txt);
		$day = '-1';
		$month = '-1';
		$year = '-1';
		if (isNumber($dateparts[0])) {
			if (index($dateparts[2], ' ') > -1) { $dateparts[2] = substr($dateparts[2], 0, index($dateparts[2], ' ')); } 
			if ( length($dateparts[0]) == 4 ) {
				# assume yyyy-mm-dd						
				$year = int($dateparts[0]);						
				$day = int($dateparts[2]);
				$month = &getDate($dateparts[1]);
			} else {
				# assume mm-dd-yyyy
				if ( int($dateparts[0]) > 12 ) {
					# assume dd-mm-yyyy
					$year = int($dateparts[2]);
					$day = int($dateparts[0]);
					$month = &getDate($dateparts[1]);
				} else {
					$year = int($dateparts[2]);
					$day = int($dateparts[1]);
					$month = &getDate($dateparts[0]);
				}
			}
		}
		$y = 'n/a';
		$m = 'n/a';
		$d = 'n/a';
		if ( 	($year >= 2011) and ($year <= 2014)
			and ($month > -1)
			and ($day >= 1) and ($day <= 31) ) {
			$y = $year;
			$m = $month;
			$d = $day;
		}
		$res->{messages}[$i]->{data}->{notice}->{year} = $y;
		$res->{messages}[$i]->{data}->{notice}->{month} = $m;
		$res->{messages}[$i]->{data}->{notice}->{day} = $d;
		# $res->{messages}[$i]->{data}->{notice}->{lengthOfFirstElement} = length($dateparts[0]);
		# $res->{messages}[$i]->{data}->{notice}->{divider} = $divider;
		# $res->{messages}[$i]->{data}->{notice}->{datestring} = $txt;

		# tracking
		$startstring = lc( 'tracking' );
		$endstring = lc( '4.' );
		$beg = index($string, $startstring);
		$bl = length($startstring); 
		$end = index($string, $endstring);
		$txt = substr($string, $beg+$bl, $end-$beg-$bl);
		if ( index($txt, 'on') > -1 ) {
			$txt = substr($txt, index($txt, 'on')+2);
		}
		$txt =~ s/://;
		$txt = trim($txt);
		$divider = ' ';
		if ( index($txt, '/') > -1 ) {
			if ( index($txt, '/', index($txt, '/')+1) > -1 ) {
				$divider = '/';
			}
		} elsif ( index($txt, '-') > -1 ) {
			if ( index($txt, '-', index($txt, '-')+1) > -1 ) {
				$divider = '-';
			}
		}
		@dateparts = split($divider, $txt);
		$day = '-1';
		$month = '-1';
		$year = '-1';
		if (isNumber($dateparts[0])) {
			if (index($dateparts[2], ' ') > -1) { $dateparts[2] = substr($dateparts[2], 0, index($dateparts[2], ' ')); } 
			if ( length($dateparts[0]) == 4 ) {
				# assume yyyy-mm-dd
				$year = int($dateparts[0]);
				$day = int($dateparts[2]);
				$month = &getDate($dateparts[1]);
			} else {
				# assume mm-dd-yyyy
				if ( int($dateparts[0]) > 12 ) {
					# assume dd-mm-yyyy
					$year = int($dateparts[2]);
					$day = int($dateparts[0]);
					$month = &getDate($dateparts[1]);
				} else {
					$year = int($dateparts[2]);
					$day = int($dateparts[1]);
					$month = &getDate($dateparts[0]);
				}
			}
		}
		$y = 'n/a';
		$m = 'n/a';
		$d = 'n/a';
		if ( 	($year >= 2011) and ($year <= 2014)
			and ($month > -1)
			and ($day >= 1) and ($day <= 31) ) {
			$y = $year;
			$m = $month;
			$d = $day;
		}
		$res->{messages}[$i]->{data}->{tracking}->{year} = $y;
		$res->{messages}[$i]->{data}->{tracking}->{month} = $m;
		$res->{messages}[$i]->{data}->{tracking}->{day} = $d;

		# country, shipping
		$startstring = lc( 'shipped' );
		$endstring = lc( '5.' );
		$beg = index($string, $startstring);
		$bl = length($startstring); 
		$end = index($string, $endstring);
		$txt = substr($string, $beg+$bl, $end-$beg-$bl);
		if ( index($txt, 'to') > -1 ) {
			$txt = substr($txt, index($txt, 'to')+2);
		}
		$txt =~ s/://;
		$txt = trim($txt);
		$divider = 'by';
		if ( index($txt, 'via') > -1 ) {
			$divider = 'via';
		}
		my @parts = split($divider, $txt);
		my $shipping = 'n/a';
		if (defined $parts[1]) {
			if ( (index($parts[1], 'expres') > -1) or index($parts[1], 'speed') > -1 ) {
				$shipping = 'Express';
			} elsif ( (index($parts[1], 'standar') > -1) or (index($parts[1], 'slow') > -1) ) {
				$shipping = 'Standard';
			} elsif ( index($parts[1], 'pick') > -1 ) {
				$shipping = 'Pickup'
			}
		}
		#$res->{messages}[$i]->{data}->{countryRaw} = $txt;
		my $country;
		$country = trim($parts[0]);			
		if ( (!defined $country) or (length($country) > 25) or (length($country) < 2) ) {
			$country = 'n/a';
		} else {
			my $posC = index( lc($stringOrig), $country );
			$country = substr( $stringOrig, $posC, length($country) );
			$country =~ s/\[//;
			$country =~ s/\]//;
			# $country =~ s/([\w']+)/\u\L$1/g; # capitalize first letter of each word
		}
		$res->{messages}[$i]->{data}->{country} = $country;
		$res->{messages}[$i]->{data}->{shipping} = $shipping;

		# received
		$startstring = lc( '5.' );
		$endstring = lc( 'as of' );
		$beg = index($string, $startstring);
		$bl = length($startstring); 
		$end = index($string, $endstring);
		if ( $end == -1 ) {
			$endstring = lc( 'updated' );
			$end = index($string, $endstring);
			if ( $end == -1 ) {
				$endstring = lc( '6.' );
				$end = index($string, $endstring);
				if ( $end == -1 ) {
					$end = length($string);
				}
			}
		}
		$txt = substr($string, $beg+$bl, $end-$beg-$bl);
		if ( index($txt, 'on') > -1 ) {
			$txt = substr($txt, index($txt, 'on')+2);
		}
		$txt =~ s/://;
		$txt = trim($txt);
		$divider = ' ';
		if ( index($txt, '/') > -1 ) {
			if ( index($txt, '/', index($txt, '/')+1) > -1 ) {
				$divider = '/';
			}
		} elsif ( index($txt, '-') > -1 ) {
			if ( index($txt, '-', index($txt, '-')+1) > -1 ) {
				$divider = '-';
			}
		}
		@dateparts = split($divider, $txt);
		$day = '-1';
		$month = '-1';
		$year = '-1';
		if (isNumber($dateparts[0])) {
			if (index($dateparts[2], ' ') > -1) { $dateparts[2] = substr($dateparts[2], 0, index($dateparts[2], ' ')); } 
			if ( length($dateparts[0]) == 4 ) {
				# assume yyyy-mm-dd
				$year = int($dateparts[0]);
				$day = int($dateparts[2]);
				$month = &getDate($dateparts[1]);
			} else {
				# assume mm-dd-yyyy
				if ( int($dateparts[0]) > 12 ) {
					# assume dd-mm-yyyy
					$year = int($dateparts[2]);
					$day = int($dateparts[0]);
					$month = &getDate($dateparts[1]);
				} else {
					$year = int($dateparts[2]);
					$day = int($dateparts[1]);
					$month = &getDate($dateparts[0]);
				}
			}
		}
		$y = 'n/a';
		$m = 'n/a';
		$d = 'n/a';
		if ( 	($year >= 2011) and ($year <= 2014)
			and ($month > -1)
			and ($day >= 1) and ($day <= 31) 
			and (index($string, 'cancel') == -1) ) {
			$y = $year;
			$m = $month;
			$d = $day;
		}
		$res->{messages}[$i]->{data}->{received}->{year} = $y;
		$res->{messages}[$i]->{data}->{received}->{month} = $m;
		$res->{messages}[$i]->{data}->{received}->{day} = $d;

		#$res->{messages}[$i]->{data}->{received}->{raw} = $txt;

		#cancelation
		$y = 'n/a';
		$m = 'n/a';
		$d = 'n/a';
		$startstring = lc( 'Cancel' );
		$beg = index($string, $startstring);
		if ( $beg > -1 ) {
			$bl = length($startstring); 
			$end = length($string);
			$txt = substr($string, $beg+$bl, $end-$beg-$bl);
			if ( index($txt, 'on') > -1 ) {
				$txt = substr($txt, index($txt, 'on')+2);
			}
			$txt =~ s/://;
			$txt = trim($txt);
			$divider = ' ';
			if ( index($txt, '/') > -1 ) {
				if ( index($txt, '/', index($txt, '/')+1) > -1 ) {
					$divider = '/';
				}
			} elsif ( index($txt, '-') > -1 ) {
				if ( index($txt, '-', index($txt, '-')+1) > -1 ) {
					$divider = '-';
				}
			}
			@dateparts = split($divider, $txt);
			$day = '-1';
			$month = '-1';
			$year = '-1';
			if (isNumber($dateparts[0])) {
				if (index($dateparts[2], ' ') > -1) { $dateparts[2] = substr($dateparts[2], 0, index($dateparts[2], ' ')); } 
				if ( length($dateparts[0]) == 4 ) {
					# assume yyyy-mm-dd
					$year = int($dateparts[0]);
					$day = int($dateparts[2]);
					$month = &getDate($dateparts[1]);
				} else {
					# assume mm-dd-yyyy
					if ( int($dateparts[0]) > 12 ) {
						# assume dd-mm-yyyy
						$year = int($dateparts[2]);
						$day = int($dateparts[0]);
						$month = &getDate($dateparts[1]);
					} else {
						$year = int($dateparts[2]);
						$day = int($dateparts[1]);
						$month = &getDate($dateparts[0]);
					}
				}	
			}
			if ( 	($year >= 2011) and ($year <= 2014)
				and ($month > -1)
				and ($day >= 1) and ($day <= 31) ) {
				$y = $year;
				$m = $month;
				$d = $day;
			}
		}
		
		$res->{messages}[$i]->{data}->{cancelled}->{year} = $y;
		$res->{messages}[$i]->{data}->{cancelled}->{month} = $m;
		$res->{messages}[$i]->{data}->{cancelled}->{day} = $d;

		# as of
		$startstring = lc( 'as of' );
		#$endstring = lc( ' ' );
		$beg = index($string, $startstring);
		if ( $beg == -1 ) {
			$startstring = lc( 'updated' );
			$beg = index($string, $startstring);
		}
		$bl = length($startstring); 
		#$end = index($string, $endstring);
		$txt = substr($string, $beg+$bl);
		if ( $beg == -1 ) {
			$txt = '';
		}
		if ( index($txt, 'on') > -1 ) {
			$txt = substr($txt, index($txt, 'on')+2);
		}
		if ( index($txt, 'at') > -1 ) {
			$txt = substr($txt, index($txt, 'at')+2);
		}
		$txt =~ s/://;
		$txt = trim($txt);
		$divider = ' ';
		if ( index($txt, '/') > -1 ) {
			if ( index($txt, '/', index($txt, '/')+1) > -1 ) {
				$divider = '/';
			}
		} elsif ( index($txt, '-') > -1 ) {
			if ( index($txt, '-', index($txt, '-')+1) > -1 ) {
				$divider = '-';
			}
		}
		@dateparts = split($divider, $txt);
		$day = '-1';
		$month = '-1';
		$year = '-1';
		if (isNumber($dateparts[0])) {
			if (index($dateparts[2], ' ') > -1) { $dateparts[2] = substr($dateparts[2], 0, index($dateparts[2], ' ')); } 
			if ( length($dateparts[0]) == 4 ) {
				# assume yyyy-mm-dd
				$year = int($dateparts[0]);
				$day = int($dateparts[2]);
				$month = &getDate($dateparts[1]);
			} else {
				# assume mm-dd-yyyy
				if ( int($dateparts[0]) > 12 ) {
					# assume dd-mm-yyyy
					$year = int($dateparts[2]);
					$day = int($dateparts[0]);
					$month = &getDate($dateparts[1]);
				} else {
					$year = int($dateparts[2]);
					$day = int($dateparts[1]);
					$month = &getDate($dateparts[0]);
				}
			}
		}
		$y = 'n/a';
		$m = 'n/a';
		$d = 'n/a';
		if ( 	($year >= 2011) and ($year <= 2014)
			and ($month > -1)
			and ($day >= 1) and ($day <= 31) ) {
			$y = $year;
			$m = $month;
			$d = $day;
		}
		$res->{messages}[$i]->{data}->{asOf}->{year} = $y;
		$res->{messages}[$i]->{data}->{asOf}->{month} = $m;
		$res->{messages}[$i]->{data}->{asOf}->{day} = $d;

		# $res->{messages}[$i]->{data}->{asOf}->{raw} = $txt;

		# my $asOf = $res->{messages}[$i]->{lastEdited};
		# $asOf = lc( substr($asOf, 0, index($asOf, ' ')) );


		# if ( index($asOf, 'today') > -1 ) {
		# 	$asOf = $dt;
		# 	$asOf = substr($asOf, 0, index($asOf, 'T'));
		# }
		# if ( index($asOf, 'yesterday') > -1 ) {
		# 	$asOf = $dt->subtract(days => 1);
		# 	$asOf = substr($asOf, 0, index($asOf, 'T'));
		# }
		# @dateparts = split('-', $asOf);
		# $y = int($dateparts[0]);
		# $d = int($dateparts[2]);
		# $m = int($dateparts[1]);
		# $res->{messages}[$i]->{data}->{lastEdited}->{year} = $y;
		# $res->{messages}[$i]->{data}->{lastEdited}->{month} = $m;
		# $res->{messages}[$i]->{data}->{lastEdited}->{day} = $d;
		# $res->{messages}[$i]->{data}->{lastEdited} = $asOf;
		# delete $res->{messages}[$i]->{lastEdited};

		# build csv entry
		my $orderD = ifDateAvail( $res->{messages}[$i]->{data}->{orderDate} );
		my $noticeD = ifDateAvail( $res->{messages}[$i]->{data}->{notice} );
	    my $trackingD = ifDateAvail( $res->{messages}[$i]->{data}->{tracking} );
	    my $receivedD = ifDateAvail( $res->{messages}[$i]->{data}->{received} );
	    my $cancelledD = ifDateAvail( $res->{messages}[$i]->{data}->{cancelled} );
	    if (!defined $res->{messages}[$i]->{data}->{lastEdited}) {
	    	$res->{messages}[$i]->{data}->{lastEdited} = "n/a";
	    }
	    my @csv_message = (	$res->{messages}[$i]->{poster},
		    				$res->{messages}[$i]->{data}->{type},
		    				$res->{messages}[$i]->{data}->{ramen},
		    				$res->{messages}[$i]->{data}->{color},
		    				$res->{messages}[$i]->{data}->{country},
		    				$res->{messages}[$i]->{data}->{shipping},
		    				$orderD,
		    				$noticeD,
		    				$trackingD,
		    				$receivedD,
		    				$cancelledD,
		    				$res->{messages}[$i]->{data}->{lastEdited},
		    				$res->{messages}[$i]->{link},
		    				$res->{messages}[$i]->{content}
		    				);
	    $csv_output .= join(';', @csv_message);
		$csv_output .= "\r\n";

		delete $res->{messages}[$i]->{content};
		if ($debug) { $outputmessage = "."; print $outputmessage; $outputbuffer .= $outputmessage };
	};
} catch {
	print "caught error: $_"; # not $@
	print "Error is in that awfully long for loop..."
};
if ($debug) { $outputmessage = "done.\n"; print $outputmessage; $outputbuffer .= $outputmessage };


# print "Access-Control-Allow-Origin: *\n";
# print "Content-Type: application/json\n\n";

if ($debug) { $outputmessage = "Idlebot output:\n"; print $outputmessage; $outputbuffer .= $outputmessage; };
# output for IdleBot
if ( $changes == 0 ) {
	$outputmessage =  'No changes since last scrape.';
	print $outputmessage;
	$outputbuffer .= $outputmessage;
} else {
	$outputmessage =  'Found new data!';
	print $outputmessage;
	$outputbuffer .= $outputmessage;
};
# print $changes;

if ($debug) { $outputmessage = "\nWriting files to disk...\n"; print $outputmessage; $outputbuffer .= $outputmessage };
try {

	if ($debug) { $outputmessage = "makiscrape_full.json..."; print $outputmessage; $outputbuffer .= $outputmessage };
	# writing server JSON (to later compare the content)
	my $json_text = encode_json($server_res);
	open (MYFILE, '>'.$path.'makiscrape_full.json');
	print MYFILE $json_text;
	close (MYFILE);
	if ($debug) { $outputmessage = "done.\n"; print $outputmessage; $outputbuffer .= $outputmessage };

	if ($debug) { $outputmessage = "makiscrape.json..."; print $outputmessage; $outputbuffer .= $outputmessage };
	# writing client JSON
	$json_text = encode_json($res);
	open (MYFILE, '>'.$path.'makiscrape.json');
	print MYFILE $json_text;
	close (MYFILE);
	if ($debug) { $outputmessage = "done.\n"; print $outputmessage; $outputbuffer .= $outputmessage };

	if ($debug) { $outputmessage = "makiscrape.csv..."; print $outputmessage; $outputbuffer .= $outputmessage };
	# writing CSV
	# open (MYFILE, '>/var/www/web85/html/makiscrape/makiscrape_' . $dt->ymd('-') . '_' . $dt->hms('') . '.csv');
	open (MYFILE, '>'.$path.'makiscrape.csv');
	# open (MYFILE, '>makiscrape.csv');
	print MYFILE $csv_output;
	close (MYFILE);
	if ($debug) { $outputmessage = "done.\n"; print $outputmessage; $outputbuffer .= $outputmessage };
} catch {
    print "caught error: $_"; # not $@
    print "Error occurs during file write..."
};


my $callback = $ARGV[0];

if (defined $callback) {
	if ($debug) { $outputmessage = "Calling callback address...\n"; print $outputmessage; $outputbuffer .= $outputmessage };
	if ($debug) { $outputmessage = "\nScript finished!\n"; $outputbuffer .= $outputmessage };
	$response = $ua->get($callback . "?output=" . encode_entities($outputbuffer));
};

if ($debug) { print "\nScript finished!\n"; };