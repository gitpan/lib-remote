#!perl -T

use Data::Dumper;

use Test::More tests => 1;

#BEGIN {
#    use_ok( 'lib::remote' ) || print "Bail out!\n";
#}

#~ =pod
use lib::remote
	#~ 'http://api.metacpan.org/source/MNUNBERG/Module-Stubber-0.03/lib/',
	'Module::Stubber'=>{
		url=>'http://api.metacpan.org/source/MNUNBERG/Module-Stubber-0.03/lib/Module/Stubber.pm',
		#~ import=>[[qw(some symbols),],  ],
		import=>[qw(Unavailable::Module::As::Stub), [qw(some symbols)], ],
		debug=>0,
	},
	
	;
my $stub = Unavailable::Module::As::Stub->new;
use Module::Stubber 'Unavailable::Module::As::Stub2' => [qw(some symbols)], 'silent'=>1,;#qw(some symbols)
my $stub2 = Unavailable::Module::As::Stub2->new;
#~ some();

use lib::remote
	'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib',
	{debug=>1,},
	'Module::Hash'=>{
		#~ url=>'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib/Module/Hash.pm', 
		#~ import=>[{prefix => "Math"}],
		debug=>0,
	};
	;

my %MOD;
use Module::Hash \%MOD; # OK
#~ tie %MOD, "Module::Hash"; # OK
my $num2 = 
	#~ $MOD2->{"BigInt"}->new(24_000_000_000_000_000)->bsqrt()
	#~ + 
	$MOD{"Math::BigInt"}->new(42_000_000_000_000_001)->blog()
;



ok($stub && $stub2 && $num2, 'Test failed');
diag( "Testing lib::remote Module::Stubber($Module::Stubber::VERSION)=[$stub]&[$stub2] Module::Hash($Module::Hash::VERSION)::Math::BigInt=[$num2]\n",  );#Dumper(\%INC)

#~ __END__
#~ =cut

=pod
use lib::remote
	'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib',
	'Module::Hash'=>{
		#~ url=>'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib/Module/Hash000.pm', 
		#~ require=>0,
	};
#~ use Module::Hash; #dont need 
 
tie my %MOD, "Module::Hash";
#~ warn $MOD;
my $num = $MOD{"Math::BigInt"}->new(42_000_000_000_000_000)->bsqrt();

ok($num, 'Test Module::Hash');

diag( "Testing lib::remote Module::Hash [$Module::Hash::VERSION] Math::BigInt::bsqrt(42_000_000_000_000_000)=[$num]\n", );# Dumper(\%INC)

=cut

=pod
#~ my $MOD = my $MOD2 = {};
use lib::remote
	'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib',
	'Module::Hash'=>{
		#~ url=>'http://api.metacpan.org/source/TOBYINK/Module-Hash-0.001/lib/Module/Hash.pm', 
		#~ import=>[$MOD],
	};
	;
#~ use Module::Hash;
#~ require Module::Hash;
my $MOD2;
use Module::Hash $MOD2;
tie my %MOD, "Module::Hash";
#~ 'Module::Hash'->import($MOD, $MOD2);
#~ warn $MOD;
my $num2 = 
	$MOD2->{"Math::BigInt"}->new(24_000_000_000_000_000)->bsqrt()
	+ 
	$MOD{"Math::BigInt"}->new(42_000_000_000_000_001)->blog()
;

ok($num2, 'Test Module::Hash');
diag( "Testing lib::remote Module::Hash [$Module::Hash::VERSION] Math::BigInt=[$num2]\n", );# Dumper(\%INC)
=cut
