#!/usr/bin/env perl
# Author : Hatim Bookwala
# Date : 20th March 2021
use strict;
use warnings;
use WWW::Mechanize;
use LWP::Simple;
$| = 1;

my $home = 'https://xossipy.com/';
my $thread_id = $ARGV[0];
my $url = "";
my $name = '';
my $count = 0;
my $debug = 1;
my $lastpagenum = 1;
my $imgfolder = "";

my $startpagenum = 1;


my @imglist;
my $m = WWW::Mechanize->new(autocheck => 0);

#thread homepage
$url = $home . 'thread-' . $thread_id . '.html';
$m->get( $url ) or die "unable to get $url";
if(!$m->success() || $m->status() != 200) { die "unable to get $url"; }

#see if the thread has a last page
FindLastPage();

if($startpagenum == 1) {
	@imglist = $m->find_all_images(url_abs_regex => qr/https:\/\/.*\/(.*(\.(jpg|png|gif)))/i, alt_regex => qr/\[Image:/i);
}

#loop through other pages
if ($lastpagenum > 1)
{
	my @pages = ($startpagenum..$lastpagenum);
	for my $page (@pages) {
		$url = $home . 'thread-' . $thread_id . '-page-' . $page . '.html';
		$m->get( $url ) or die "unable to get $url";
		if(!$m->success() || $m->status() != 200) { die "unable to get $url"; }
		
		push @imglist, $m->find_all_images(url_abs_regex => qr/https:\/\/.*\/(.*(\.(jpg|png|gif)))/i, alt_regex => qr/\[Image:/i);	
	}
}

printf("Images Found %d\n", scalar @imglist); 
if(scalar @imglist > 0) { 
	print "Do you want to start download (Y/N) ? \n ";

	#download
	if(<STDIN> =~ m/[y|Y]/)
	{
		$imgfolder = "Images\\" . $thread_id;
		system( 'mkdir ' . "$imgfolder" ) if ( ! -d "$imgfolder" );
		foreach (@imglist) {
			my $temp = $_->url();
			if ($temp =~ m/https:\/\/.*\/(.*(\.(jpg|png|gif)))/is) {
				$name = $1;
				$count++;
				my $filename = $imgfolder . "\\" . $name;
				print "Filename = $filename\n";
				if(-e $filename) { print "File $filename exists\n"; }
				else {	
					my $rc = getstore($temp, $filename);
					if($debug) {
						if(is_success($rc)) { print "Image $filename Downloaded\n\n\n"; }
						else                { print "Image $filename Failed to Download\n\n\n"; }
					}
				}
			}
			printf("\rDownloaded  %d\\%d ", $count, $#imglist+1); 
		}
	}
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
