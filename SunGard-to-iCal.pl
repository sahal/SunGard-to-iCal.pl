#! /usr/bin/perl
# Convert Student Schedule by Sahal Ansari - github.com/sahal
# Concise to iCalendar (via any* SunGard Banner install)

### --- TODO --- ###
# * need to completly rewrite this (soooo ugly)
# * iCalendar format requires a timezone to be set, but i'm not sure
# 	how to extract it from the SunGard Banner Concise schedules
#		this script assumes America/Chicago -- for now
# * automatically detect semester/ school
# * more complex class schedules - i.e. meet every other week?
# * blah, can't think of way to stop final , from printing on the weekday list
# * if you want to finish supporting everything: https://www.ietf.org/rfc/rfc2445.txt

### --- options --- ###

use strict;
use warnings;
use CGI qw(:standard escapeHTML);
use CGI::Carp 'fatalsToBrowser';
#don't DoS my shell provider, please
$CGI::POST_MAX=1024*3; #max 3kb => if your schedule is over 3kb, drop some classes seriously...
$CGI::DISABLE_UPLOADS = 1;

### --- declarations ---- ###
sub form($);
sub results($);
my $q = new CGI;
my $semester = "Fall11";
my $zero=0;
my %month2num = ( 'Jan', '01', 'Feb', '02', 'Mar', '03', 'Apr', '04', 'May', '05', 'Jun', '06', 'Jul', '07', 'Aug', '08', 'Sep', '09', 'Oct', '10', 'Nov', '11', 'Dec', '12' );
# wtf is sunday/saturday in Banner?
my %weekconvert = ( 'S', 'SU' , 'M', 'MO' , 'T',  'TU', 'W',  'WE' , 'R' , 'TH', 'F', 'FR' , 'U', 'SA');

### --- main code --- ###
#print $q->header();

if ($q->param()) {
	results($q);
} else {
	form($q);
}

exit 0;

### --- subroutines --- ###

### --- this is displayed if there is no parameters given (i.e. on first page visit) --- ###

sub form($) {
my ($q) = @_;
print $q->header();
print <<"EOF1";
<html>
<head>
<title>Convert Student Schedule</title>

<style>
input {
#margin:auto;
display:block;}
dt {font-weight:bold;}
</style>
</head>
<body>
<h1>Convert Student Schedule</h1>
<p>Convert a Concise schedule exported via copy/paste from SunGard's Banner v8+ into <a href="http://en.wikipedia.org/wiki/ICalendar">iCalendar</a> format. Then import into many  different softwares including Google Calendar.  This is a shitty reimplementation of <a target="_new" href="http://uiuccalendar.appspot.com/">UIUC Calendar Converter</a>.  I just did  this as a proof of concept as the source was not available.  Here's the source to this file: <code><a target="_new" href="saved-source">SunGard-to-iCal.pl</a></code>.</p>
<!--<p>I'm also trying to make this a universal application, but I'm not sure if all Concise formats are exactly the same and I make a lot of assumptions  in the script.</p> -->

<h2>Where do I get my Concise Schedule?</h2>
<dl>
<dt>UIUC/UIC/UIS</dt>
<dd><a target="_new" href="https://apps.uillinois.edu/selfservice/">https://apps.uillinois.edu/selfservice/</a>.
<!--<dt>Purdue</dt>
<dd><a target="_new" href="https://mypurdue.purdue.edu/cp/home/loginf">https://mypurdue.purdue.edu/cp/home/loginf</a></dd>-->
<!--<dt>Other Schools?</dt>
<dd><a target="_new" 
href="http://google.com/search?q=Release:+8*+User+Login+site:edu">http://google.com/search?q=Release:+8*+"User+Login"+site:edu</a></dd>
</dd>-->
</dl>

<p><strong>e.g. line</strong>: <code>47510 	HIST 367 A 	History of Western Medicine 	Urbana-Champaign 	3.000 	1U 	Aug 22, 2011 	 Dec 07, 2011 	TR 	9:30 am - 10:50 am 	Gregory Hall 307 	Melhado</code></p>

<h2>Just paste it in the textbox</h2>
EOF1

print $q->start_form(
	-name    => 'main',
	-method  => 'POST',
	-enctype => &CGI::URL_ENCODED,
);

print $q->textarea(
	-name  => 'concise',
	-value => '',
	-cols  => 90,
	-rows  => 15,
);

print $q->submit(
	-name     => 'submit',
	-value    => 'Convert It!',	
);

print $q->end_form;

print <<"EOF1";
<hr>
<p><a href="http://sahal.info/">Sahal Ansari</a> -- feel free to steal what you need -- source: <code><a target="_new" href="http://github.com/sahal/SunGard-to-iCal.pl">SunGard-to-iCal.pl</a></code></p>
</body>
</html>
EOF1
}

### --- this is the resultant .ics file --- ###
sub results($) {
my ($q) = @_;

my $concise = escapeHTML(param('concise'));
$concise=~ s/\s+$//; #used instead of chomp in case we're getting input from a Windows box
my @classes = split ('\n',$concise); # creates an array with one class per entry

my $filename = "$semester"."_Schedule.ics";
print <<"EOF3";
Content-Disposition: attachment; filename=$filename\r\n
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Sahal Ansari//SunGard to iCal//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:$semester Classes
X-WR-TIMEZONE:America/Chicago
X-WR-CALDESC:$semester \@ UNIVERSITY
EOF3

foreach my $class (@classes) {
if (($class =~ /^[0-9]/) && ($class =~ /\t/)) { # a quick check to see if i'm getting something that looks even remotely like a CRN...
	my @anitem = split(/\t/, $class); # this splits each line into an array that includes everythang we need

# all the places that the progrma could fail is listed here
	# CRN
	$anitem[0] =~ s/\s+$//;
	if ($anitem[0] !~ /\d{5}/) {
		die "Invalid CRN for: @anitem";
	}

	# class name+section
	$anitem[1] =~ s/\s+$//;
	my $classname_1 = $anitem[1];
	$classname_1 =~ s/\s[A-Z0-9]*$//;
	my $section = $anitem[1];
	$section =~ s/^.*[0-9]*\s//;

	# full class name
	$anitem[2] =~ s/\s+$//;
	
# unused members of the array
#	$anitem[3] #campus
#	$anitem[4] # credit hours
#	$anitem[5] # units(?)

	# start date
	$anitem[6] =~ s/\s+$//;
	my $st_year = $anitem[6];
	$st_year =~ s/.*\s//;
	my $st_day = $anitem[6];
	$st_day =~ s/^[A-Za-z]{3}\s//;
	$st_day =~ s/[0-9]{4}$//;
	$st_day =~ s/\,\s//;
	my $st_month = $anitem[6];
	$st_month =~ s/\s.*$//;

	# end date
	$anitem[7] =~ s/\s+$//;
	my $en_year = $anitem[7];;
	$en_year =~ s/.*\s//;
	my $en_day = $anitem[7];
	$en_day =~ s/^[A-Za-z]{3}\s//;
	$en_day =~ s/[0-9]{4}$//;
	$en_day =~ s/\,\s//;
	my $en_month = $anitem[7];
	$en_month =~ s/\s.*$//;

	#days
	$anitem[8] =~ s/\s.*$//;
	my @days = split(undef,$anitem[8]);
	my $days = @days -1;
	my $classdays;
	foreach my $day (@days) {
		$classdays = $classdays . "$weekconvert{$day},";
	}

	# times
	$anitem[9] =~ s/\s+$//;
	my $st_time = $anitem[9];
	$st_time =~ s/\s-\s[0-9].*//;
	$st_time =~ s/(\d+)(:\d+)\s+(a|p)m/($3 eq 'a')?($1%12).$2:($1%12+12).$2/e;
	my @hr_sec = split(/:/,$st_time);	
	my $hh = @hr_sec[0];
	$hh = sprintf("%2d", $hh);
	$hh =~ tr/ /0/;
	$st_time = $hh . $hr_sec[1];
	my $en_time = $anitem[9];    
	$en_time =~ s/^[0-9]+\:[0-9]+\s[a-z]+\s\-\s//;
	$en_time =~ s/(\d+)(:\d+)\s+(a|p)m/($3 eq 'a')?($1%12).$2:($1%12+12).$2/e;
	my @hr_sec2 = split(/:/,$en_time);
	my $hh = @hr_sec2[0];
	$hh = sprintf("%2d", $hh);
	$hh =~ tr/ /0/;
	$en_time = $hh . $hr_sec2[1];

	#where is the class?
	$anitem[10] =~ s/\s+$//;

	#instructor
	$anitem[11] =~ s/\s+$//;

print <<"EOF4";
BEGIN:VEVENT
SUMMARY:$classname_1 - $anitem[2] $section
LOCATION:$anitem[10]
DESCRIPTION:$section - $anitem[11]\\nCRN: $anitem[0]
DTSTART;TZID=America/Chicago:$st_year$month2num{$st_month}$st_day\T$st_time$zero$zero
DTEND;TZID=America/Chicago:$st_year$month2num{$st_month}$st_day\T$en_time$zero$zero
RRULE:FREQ=WEEKLY;WKST=MO;UNTIL=$en_year$month2num{$en_month}$en_day\T235900;BYDAY=$classdays
TRANSP:OPAQUE
END:VEVENT\n
EOF4
}}
print "END:VCALENDAR";
}
