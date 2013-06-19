#!perl -T

use Test::More tests => 2;

#BEGIN {
#    use_ok( 'lib::remote' ) || print "Bail out!\n";
#}

use lib::remote
	'lib::remote'=> {autouse=>0},
	#'Module::Stubber'=>'http://api.metacpan.org/source/MNUNBERG/Module-Stubber-0.03/lib/Module/Stubber.pm',
	'http://api.metacpan.org/source/MNUNBERG/Module-Stubber-0.03/lib/',
	;

use Module::Stubber 'Some::Unavailable::Module::As::Stub' => [], 'silent'=>1,;#qw(some symbols)
my $stub = Some::Unavailable::Module::As::Stub->new;

ok($stub, 'Test Module::Stubber');
diag( "Testing lib::remote Module::Stubber[$Module::Stubber::VERSION] [$stub]" );



use lib::remote 'Module::Hash'=>['http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib/Module/Hash.pm', autouse=>1];
#use Module::Hash; dont need 
 
tie my %MOD, "Module::Hash";
my $num = $MOD{"Math::BigInt"}->new(42_000_000_000_000_000);

ok($num, 'Test Module::Hash');

diag( "Testing lib::remote Module::Hash [$Module::Hash::VERSION] Math::BigInt::[$num]" );


