#! perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::BiaB' );
}

diag( "Testing Data::BiaB $Data::BiaB::VERSION, Perl $], $^X" );
