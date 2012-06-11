#!/usr/bin/perl -w
#
# Script for downloading the most recent GPS Assist Data to a Sony DSC
# Camera with built-in GPS, such as the Sony DSC-HX5V. The script must
# be called with the mount point of a memory card for the camera as
# argument.
#
# See https://github.com/henrikbrixandersen/sony-gps-assist for more
# information.
#
# Copyright (c) 2010-2012 Henrik Brix Andersen <henrik@brixandersen.dk>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

use strict;

use Digest::MD5 qw/md5_hex/;
use File::Path 2.06_05 qw/make_path/;
use LWP::UserAgent;

# Settings
my $url_base = 'http://control.d-imaging.sony.co.jp/GPS';
my $gps_file = 'assistme.dat';
my $md5_file = 'assistme.md5';
my $subdir   = 'Private/SONY/GPS/';

# Parse and validate mountpoint argument
my $mountpoint = $ARGV[0];
unless ($mountpoint) {
	print STDERR "Usage: $0 MOUNTPOINT\n";
	exit 1;
}
die "Non-existing mount point '$mountpoint' specfied\n" unless (-d $mountpoint);

# Initialize browser
my $browser = LWP::UserAgent->new;
my ($url, $response);

# Download main file
$url = "$url_base/$gps_file";
print "Downloading '$url'\n";
$response = $browser->get($url);
die "Could not download '$url': ", $response->status_line unless ($response->is_success);
my $content = $response->content;

# Download MD5 file
$url = "$url_base/$md5_file";
print "Downloading '$url'\n";
$response = $browser->get($url);
die "Could not download '$url': ", $response->status_line unless ($response->is_success);
my $md5sum = $response->content;
chomp $md5sum;
$md5sum =~ s/^(\w{32}).*/$1/;

# Validate MD5
print "Verifying MD5 checksum '$md5sum'\n";
die "MD5 check failed, checksum was '" . md5_hex($content) . "'" if (md5_hex($content) ne $md5sum);

# Create destination directory if needed
my $destdir = "$mountpoint/$subdir";
unless (-d "$destdir") {
	print "Creating directory '$destdir'\n";
	make_path("$destdir") || die "Could not create directory '$destdir', " . $!;
}

# Write file
my $destfile = "$destdir/$gps_file";
print "Writing data to '$destfile'\n";
open(FILE, ">$destfile") || die "Could not open '$destfile' for writing, " . $!;
print FILE $content;
close(FILE);

print "Done\n";
