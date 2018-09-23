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
	$fname = $ARGV[0];
}

my $byte;
my $counter = 1;
my $block_size = 65536;
my $first_remembered_byte = undef;
my $second_remembered_byte = undef;

if (defined($fname)){
	sysopen(STDIN, $fname, O_RDONLY) or die "Can not open file $fname!\n";
	sysopen(STDOUT, "$fname.rle", O_WRONLY|O_TRUNC|O_CREAT) or die "Can not open file $fname.rle!\n";
}
binmode(STDIN);
binmode(STDOUT);

exit 0 if ((sysread(STDIN, $byte, 1)) == 0);

$first_remembered_byte = $byte;
my $output_buf_byte_counter = 0;
my $output_buf = '';
my $input_buf = '';

while ( 1 ) {
	my $read_bytes = sysread(STDIN, $input_buf, $block_size);
	last if($read_bytes == 0);
	my $i = 0;
	for ( $i = 0; $i < $read_bytes; $i++ ) {
		$byte = substr( $input_buf, $i, 1);
		last unless(defined($byte));
		$second_remembered_byte = $first_remembered_byte;
		$first_remembered_byte = $byte;

		if(($first_remembered_byte eq $second_remembered_byte) and ($counter <= 254)){
			$counter++;
			next;
		}

		if ($output_buf_byte_counter == $block_size){
			syswrite STDOUT, $output_buf || die "Cannot write output stream!\n";
			$output_buf = '';
			$output_buf_byte_counter = 0;
		}else{
			$output_buf_byte_counter++;
		}

		$output_buf .= chr($counter) . $second_remembered_byte;
		$second_remembered_byte = $first_remembered_byte;
		$counter = 1;
	}
	undef $i;
	undef $read_bytes;
}
close(STDIN);
# 0-byte string
exit 0 unless (defined($first_remembered_byte));
# 1-byte string
unless(defined($second_remembered_byte)){
	$output_buf =  chr($counter) . $first_remembered_byte;
}else{
# 2+ bytes string
	$output_buf .= chr($counter) . $second_remembered_byte;
}
syswrite STDOUT, $output_buf || die "Cannot write output stream!\n";
close(STDOUT);
undef $fname;
undef $counter;
undef $first_remembered_byte;
undef $second_remembered_byte;
undef $byte;
undef $input_buf;
undef $output_buf;
