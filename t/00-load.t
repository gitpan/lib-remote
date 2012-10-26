#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'lib::remote' ) || print "Bail out!\n";
}

diag( "Testing lib::remote $lib::remote::VERSION, Perl $], $^X" );
