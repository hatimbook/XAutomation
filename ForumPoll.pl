#!/usr/bin/env perl
# Author : Hatim Bookwala
# Date : 20th March 2021
use strict;
use warnings;
use WWW::Mechanize;
use LWP::Simple;
$| = 1;

my $home = 'https://xossipy.com/';
my $forumnum = $ARGV[0];
my $url = "";
my $name = '';
my $count = 0;
my $debug = 0;
my $lastpagenum = 1;
my $imgfolder = "";

my $recentpage = "";
my $recentImage = "";
my $recentthreadnum = 0;
my $pollinterval = 10;

my @imglist = "";
my @recentthreads = "";
my $m = WWW::Mechanize->new(autocheck => 0);


$imgfolder = "Images\\";
system( 'mkdir ' . "$imgfolder" ) if ( ! -d "$imgfolder" );

while (1) {
	
	$url =  $home . 'forum-' . $forumnum . '.html';
	$m->get( $url ) or die "unable to get $url";
	if(!$m->success() || $m->status() != 200) { $pollinterval = 10; goto label_wait; }
	
	@recentthreads = $m->find_all_links(url_regex => qr/thread-\d+\.html/);
		
	#get the most recent normal thread (skip sticky, hence the magic number 4)
	$recentpage = $recentthreads[4]->url();
	if ($debug) { print "Recent Page = $recentpage\n"; }
	if(defined $recentpage && $recentpage =~ m/thread-(\d+)/) {
		$recentthreadnum = $1;
	}
	
	$url = $home . $recentpage;
	$m->get( $url ) or die "unable to get $url";
	if(!$m->success() || $m->status() != 200) { $pollinterval = 10; goto label_wait; }	
	
	#see if the thread has a last page
	FindLastPage();
	
	# move to last page if there are more pages
	if($lastpagenum > 1) {
		$url = $home . 'thread-' . $recentthreadnum . '-page-' . $lastpagenum . '.html';
		$m->get( $url ) or die "unable to get $url";
		if(!$m->success() || $m->status() != 200) { $pollinterval = 10; goto label_wait; }
	}
	
	#get all the image in the last page of the thread and download the last image if not yet downloaded.
	push @imglist, $m->find_all_images(url_abs_regex => qr/https:\/\/.*\/(.*(\.(jpg|png|gif)))/i, alt_regex => qr/\[Image:/i);
		
	#if there are images to process
	if(scalar @imglist > 0) { 
		my $last_image = pop @imglist;
		if(defined $last_image && $last_image ne "")
		{
			my $temp = $last_image->url();
			#download only if the image has changed
			if ($temp ne $recentImage && $temp =~ m/https:\/\/.*\/(.*(\.(jpg|png|gif)))/is) {
				$recentImage = $temp;
				$name = $1;
				$count++;
				if($debug) {
					print "Recent Thread - $recentthreadnum Page Number = $lastpagenum\n";
					print "image_url = $temp\n";
				}
				my $filename = $imgfolder . "\\" . $name;
				print "Filename = $filename\n";
				if(-e $filename) { print "File $filename exists\n"; }
				else {
					my $rc = getstore($temp, $filename);
					$pollinterval = 1;
					if($debug) {
						if(is_success($rc)) { print "Image $filename Downloaded\n\n\n"; }
						else                { print "Image $filename Failed to Download\n\n\n"; }
					}
				}
			}
			else {
				if($pollinterval < 10) { $pollinterval++; }
			}
		}
	}
	@imglist = "";
	@recentthreads = "";
	
	label_wait:
		sleep($pollinterval);
}

sub FindLastPage {
	my $lastpage = $m->find_link(class => 'pagination_last', url_regex => qr/thread/);
	if(defined $lastpage && $lastpage->url() =~ m/thread-\d+-page-(\d+)/) {
		$lastpagenum = $1;
	}
	#if there are less than 9 pages, then there is no last page class. Manually find the last page
	else {
		my @pages = $m->find_all_links(class => 'pagination_page', url_regex => qr/thread/);
		my $maxpage = 1;
		foreach my $page (@pages) {
			if(defined $page && $page->url() =~ m/thread-\d+-page-(\d+)/) {
				my $currentpage = $1;
				if($currentpage > $maxpage) { $maxpage = $currentpage; }
			}
		}
		if($maxpage > 1) {	$lastpagenum = $maxpage; }
		else			 {	$lastpagenum = 1;        }
	}
	
	if ($debug) { print "Last Page = $lastpagenum\n"; }
}