#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SweetPea::Application' );
}

diag( "Testing SweetPea::Application $SweetPea::Application::VERSION, Perl $], $^X" );
