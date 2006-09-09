#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use Test::Exception;
use Data::Dumper;
use Exception::Class::TryCatch;

use Getopt::Lucid;
use Getopt::Lucid::Exception;

sub why {
    my %vars = @_;
    $Data::Dumper::Sortkeys = 1;
    return "\n" . Data::Dumper->Dump([values %vars],[keys %vars]) . "\n";
}

#--------------------------------------------------------------------------#
# Test cases
#--------------------------------------------------------------------------#

my $spec = [
    Switch('t'),
    Counter('v'),
    Param('f'),
    List('I'),
    Keypair('d'),
];

my $num_tests = 6 ;
plan tests => $num_tests ;

my ($gl, $err);

eval { $gl = Getopt::Lucid->new() };
catch $err;
is( $err, "Getopt::Lucid->new() requires an option specification array reference",
    "new without spec throws exception");

eval { $gl = Getopt::Lucid->new( $spec ) };
catch $err;
is( $err, undef,
    "new with spec succeeds");
isa_ok( $gl, "Getopt::Lucid" );

eval { $gl = Getopt::Lucid->getopt() };
catch $err;
is( $err, "Getopt::Lucid->getopt() requires an option specification array reference",
    "getopt (as class method) without spec throws exception");

eval { $gl = Getopt::Lucid->getopt( $spec ) };
catch $err;
is( $err, undef,
    "getopt (as class method) with spec succeeds");
isa_ok( $gl, "Getopt::Lucid" );


