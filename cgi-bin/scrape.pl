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
use Encode;
use JSON;
# use Test::Deep;
#use LWP::Simple "get";

my $path = '/var/www/web85/html/makiscrape/';
# my $path = ''; # local
my $changes = 0;

sub ifDateAvail {
    if ( $_[0]->{year} ne 'n/a') {
      return $_[0]->{year} . '-' . $_[0]->{month} . '-' . $_[0]->{day};
    } else {
      return '';
    }
 };

sub getDate {
	my $month = -1;
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
	if ( ($month < 1) or ($month > 12) ) { # sanity check
		$month = -1;
	};
	return $month;
};



# get old data to check for changes / calculate lastEdited date
my $old_data;
local $/;
open (MYFILE, '<'.$path.'makiscrape_full.json');
my $encoding = 'cp932';
my $unicode_json_text = decode( $encoding, <MYFILE> ); # UNICODE
close (MYFILE);
if ( defined $unicode_json_text && $unicode_json_text ne '' ) {
	$old_data = from_json($unicode_json_text);
};
# print Dumper $old_data;


#open (MYFILE, '>makiscrape.json');

#print MYFILE "Access-Control-Allow-Origin: *\n";
#print MYFILE "Content-Type: application/json\n\n";

# print "McReeds Master Scraper v0.1\n";
# print "--------------------------------------------\n";

my $domain = 'http://makibox.com/';

my $extractPages = scraper {
	process 'div.topcontrols > span > a.pagenavlink', 'links[]' => '@href'; 
};

my $extractData = scraper {
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

my $ua  = LWP::UserAgent->new;
$ua->cookie_jar( {} );
my $response = $ua->get($domain . 'forum/topic/2042');
my $data = $response->decoded_content;
my $res = $extractPages->scrape($data);

for my $i ( 0 .. $#{$res->{links}} ) {
	$response = $ua->get($domain . $res->{links}[$i]);
	$data .= $response->decoded_content;
};
$res = $extractData->scrape($data);
my $server_res = $extractData->scrape($data);

# prepare csv output
@header = ('Name', 'Type', 'Ramen', 'Color', 'Country', 'Shipping', 'Order', 'Notice', 'Tracking', 'Received', 'LastEdited', 'Link', 'OriginalPost');
my $csv_output = join(';', @header);
$csv_output .= "\r\n";

# add date for reference
my $dt = DateTime->now();
$res->{scraped} = $dt->ymd('-') . ' ' . $dt->hms(':');
$server_res->{scraped} = $res->{scraped};

# lead post
delete $res->{messages}[0]->{content};
delete $server_res->{messages}[0]->{postDate};

for my $i ( 1 .. $#{$res->{messages}} ) {
# print $res->{messages}[$i]->{content} eq $old_data->{messages}[$i]->{content};
	# print Dumper $old_data;
	# print Dumper $unicode_json_text;

	# test for changes
	if ( $res->{messages}[$i]->{content} ne $old_data->{messages}[$i]->{content} ) {
		$changes = 1;
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
		$server_res->{messages}[$i]->{lastEdited} = $res->{messages}[$i]->{lastEdited};
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
	} elsif (( index($txt, 'stainless') > -1 ) or ( index($txt, 'steel') > -1 )) {
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
	my $day = '??';
	my $month = '??';
	my $year = '??';
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
	my $y = 'n/a';
	my $m = 'n/a';
	my $d = 'n/a';
	if ( 	($year >= 2011) and ($year <= 2013)
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
	$day = '??';
	$month = '??';
	$year = '??';
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
	$y = 'n/a';
	$m = 'n/a';
	$d = 'n/a';
	if ( 	($year >= 2011) and ($year <= 2013)
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
	$day = '??';
	$month = '??';
	$year = '??';
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
	$y = 'n/a';
	$m = 'n/a';
	$d = 'n/a';
	if ( 	($year >= 2011) and ($year <= 2013)
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
	if ( (index($parts[1], 'expres') > -1) or index($parts[1], 'speed') > -1 ) {
		$shipping = 'Express';
	} elsif ( (index($parts[1], 'standar') > -1) or (index($parts[1], 'slow') > -1) ) {
		$shipping = 'Standard';
	} elsif ( index($parts[1], 'pick') > -1 ) {
		$shipping = 'Pickup'
	}
	#$res->{messages}[$i]->{data}->{countryRaw} = $txt;
	my $country = trim($parts[0]);
	if ( (length($country) > 25) or (length($country) < 2) ) {
		$country = 'n/a';
	} else {
		my $posC = index( lc($stringOrig), $country );
		$country = substr( $stringOrig, $posC, length($country) );
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
			$end = length($string)-1;
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
	$day = '??';
	$month = '??';
	$year = '??';
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
	$y = 'n/a';
	$m = 'n/a';
	$d = 'n/a';
	if ( 	($year >= 2011) and ($year <= 2013)
		and ($month > -1)
		and ($day >= 1) and ($day <= 31) ) {
		$y = $year;
		$m = $month;
		$d = $day;
	}
	$res->{messages}[$i]->{data}->{received}->{year} = $y;
	$res->{messages}[$i]->{data}->{received}->{month} = $m;
	$res->{messages}[$i]->{data}->{received}->{day} = $d;

	#$res->{messages}[$i]->{data}->{received}->{raw} = $txt;

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
	$day = '??';
	$month = '??';
	$year = '??';
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
	$y = 'n/a';
	$m = 'n/a';
	$d = 'n/a';
	if ( 	($year >= 2011) and ($year <= 2013)
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
	    				$res->{messages}[$i]->{data}->{lastEdited},
	    				$res->{messages}[$i]->{link},
	    				$res->{messages}[$i]->{content}
	    				);
    $csv_output .= join(';', @csv_message);
	$csv_output .= "\r\n";

	delete $res->{messages}[$i]->{content};
};



# print "Access-Control-Allow-Origin: *\n";
# print "Content-Type: application/json\n\n";

# output for IdleBot
if ( $changes == 0 ) {
	print 'No changes since last scrape.'
} else {
	print 'Found new data!'
};
# print $changes;

# writing server JSON (to later compare the content)
my $json_text = encode_json($server_res);
open (MYFILE, '>'.$path.'makiscrape_full.json');
print MYFILE $json_text;
close (MYFILE);

# writing client JSON
$json_text = encode_json($res);
open (MYFILE, '>'.$path.'makiscrape.json');
print MYFILE $json_text;
close (MYFILE);

# writing CSV
# open (MYFILE, '>/var/www/web85/html/makiscrape/makiscrape_' . $dt->ymd('-') . '_' . $dt->hms('') . '.csv');
open (MYFILE, '>'.$path.'makiscrape.csv');
# open (MYFILE, '>makiscrape.csv');
print MYFILE $csv_output;
close (MYFILE);
