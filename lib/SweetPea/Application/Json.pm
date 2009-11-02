package SweetPea::Application::Json;

use warnings;
use strict;

use base 'JSON';

=head1 NAME

SweetPea::Application::Json - JSON support for SweetPea-Application.

=cut

=head1 SYNOPSIS

    ... from inside SweetPea::Application or a Controller;
    $s->json->encode($hashref);
    my $hashref = $s->json->decode($incoming);

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Json object
    which use JSON as a base for encoding and decoding input to and from JSON
    ojbects. 
    
    $s->plug( 'json', sub { return SweetPea::Application::Json->new($s); });

=cut

sub new {
    my ($class, $s) = @_;
    my $self        = JSON->new;
    bless $self, $class;
    $self->{base} = $s;
    return $self;
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Json
