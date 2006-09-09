#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use Test::Exception;
use Data::Dumper;
use Exception::Class::TryCatch;

use Getopt::Lucid ':all';
use Getopt::Lucid::Exception;

# Work around win32 console buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

sub why {
    my %vars = @_;
    $Data::Dumper::Sortkeys = 1;
    return "\n" . Data::Dumper->Dump([values %vars],[keys %vars]) . "\n";
}

#--------------------------------------------------------------------------#
# Test cases
#--------------------------------------------------------------------------#

my ($num_tests, @good_specs);

BEGIN {
    
    push @good_specs, { 
        label => "negation test",
        spec  => [
            Switch("test|t")->default(1),
            Counter("verbose|v")->default(2),
            Param("file|f")->default("foo.txt"),
            List("lib|l")->default(qw( /var /tmp )),
            Keypair("def|d")->default({os => 'linux', arch => 'i386'}),
        ],
        cases => [
            { 
                argv    => [ qw( --no-test --no-verbose --no-file --no-lib
                                 --no-def ) ],
                result  => { 
                    "test" => 0, 
                    "verbose" => 0,
                    "file" => "",
                    "lib" => [],
                    "def" => {},
                },
                desc    => "long-form negate everything"
            },          
            { 
                argv    => [ qw( no-test no-verbose no-file no-lib
                                 no-def ) ],
                result  => { 
                    "test" => 0, 
                    "verbose" => 0,
                    "file" => "",
                    "lib" => [],
                    "def" => {},
                },
                desc    => "bareword-form negate everything"
            },          
            { 
                argv    => [ qw( no-lib=/var --no-def=os ) ],
                result  => { 
                    "test" => 1, 
                    "verbose" => 2,
                    "file" => "foo.txt",
                    "lib" => [qw( /tmp )],
                    "def" => { arch => "i386" },
                },
                desc    => "negate list item and keypair key"
            },          
            # test negate specific list item or keypair key
            # test no-switch, switch (shouldn't complain about repeats)
            # test no-switch=n -- should complain, ditto counter,param
            
        ]
    };


} #BEGIN 

for my $t (@good_specs) {
    $num_tests += 1 + 2 * @{$t->{cases}};
}

plan tests => $num_tests;

#--------------------------------------------------------------------------#
# Test good specs
#--------------------------------------------------------------------------#

my ($trial, @cmd_line);

while ( $trial = shift @good_specs ) {
    try eval { Getopt::Lucid->new($trial->{spec}, \@cmd_line) };
    catch my $err;
    is( $err, undef, "$trial->{label}: spec should validate" );
    SKIP: {    
        if ($err) {
            my $num_tests = 2 * @{$trial->{cases}};
            skip "because $trial->{label} spec did not validate", $num_tests;
        }
        for my $case ( @{$trial->{cases}} ) {
            my $gl = Getopt::Lucid->new($trial->{spec}, \@cmd_line);
            @cmd_line = @{$case->{argv}};
            my %opts;
            try eval { %opts = $gl->getopt };
            catch my $err;
            if (defined $case->{exception}) { # expected
                ok( $err && $err->isa( $case->{exception} ), 
                    "$trial->{label}: $case->{desc} should throw exception" )
                    or diag why( got => ref($err), expected => $case->{exception});
                is( $err, $case->{error_msg}, 
                    "$trial->{label}: $case->{desc} error message correct");
            } elsif ($err) { # unexpected
                fail( "$trial->{label}: $case->{desc} threw an exception")
                    or diag "Exception is '$err'";
                pass("$trial->{label}: skipping \@ARGV check");
            } else { # no exception
                is_deeply( \%opts, $case->{result}, 
                    "$trial->{label}: $case->{desc}" ) or
                    diag why( got => \%opts, expected => $case->{result});
                my $argv_after = $case->{after} || [];
                is_deeply( \@cmd_line, $argv_after,
                    "$trial->{label}: \@cmd_line correct after processing") or
                    diag why( got => \@cmd_line, expected => $argv_after);
            }
        }
    }
}


