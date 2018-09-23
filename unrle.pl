#!/usr/bin/perl

use strict;
use warnings "all";
use Fcntl;

my $fname = undef;
if(defined($ARGV[0])){
	if($ARGV[0] eq "--help"){
		syswrite STDOUT, "Usage: $0 <filename>\n";
		syswrite STDOUT, "or pipe data thrugh $0's STDIN to $0 STDOUT\n";
		exit 0;
	}
	exit unless ($ARGV[0] =~ /\.rle$/);
	$fname = $ARGV[0];
	$fname = substr($fname, 0, -4);
}

my $byte = '';
my $dbyte = '';
my $block_size = 65536;

if (defined($fname)){
	sysopen(STDIN, "$fname.rle", O_RDONLY) or die "Can not open file $fname!\n";
	sysopen(STDOUT, $fname, O_WRONLY|O_TRUNC|O_CREAT) or die "Can not open file $fname.rle!\n";
}
binmode(STDIN);
binmode(STDOUT);

my $output_buf_byte_counter = 0;
my $output_buf = '';
my $input_buf ='';

while ( 1 ) {
	my $read_bytes = sysread(STDIN, $input_buf, $block_size);
	last unless(defined($read_bytes));
	last if($read_bytes == 0);
	my $i = 0;
	for ( $i = 0; $i < $read_bytes; $i++ ) {
		$dbyte = substr( $input_buf, $i, 1);
		last unless(defined($dbyte));
		$i++;
		$byte = substr( $input_buf, $i, 1);
		last unless(defined($byte));

		for(my $i = 0; $i < ord($dbyte); $i++){
			if ($output_buf_byte_counter == $block_size){
				syswrite STDOUT, $output_buf || die "Cannot write output stream!\n";
				$output_buf = '';
				$output_buf_byte_counter = 0;
			}else{
				$output_buf_byte_counter++;
			}
			$output_buf .= $byte;
		}
	}
	undef $i;
	undef $read_bytes;
}
close(STDIN);
syswrite STDOUT, $output_buf || die "Cannot write output stream!\n";
close(STDOUT);
undef $fname;
undef $byte;
undef $dbyte;
undef $block_size;
undef $output_buf_byte_counter;
undef $output_buf;
undef $input_buf;
