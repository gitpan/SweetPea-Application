package SweetPea::Application::View;

use warnings;
use strict;

=head1 NAME

SweetPea::Application::View - Model support for SweetPea-Application.

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

    ... from inside SweetPea::Application or a Controller;
    #access View::Email::welcome_letter()
    $s->view('Email')->welcome_letter();

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::View object
    which loads view packages on requests ands provides accessors to it's
    functions. 
    
    $s->plug( 'view', sub { return SweetPea::Application::View->new($s); });

=cut

sub new {
    my ($class, $s, $view) = @_;
    my $self        = {};
    my $pckg        = $view;
    bless $self, $class;
    $view          =~ s/^\///;
    $pckg          =~ s/[\\\:]/\//g;
    $pckg          = 'View::' . $view;
    $view          = 'View/' . $view . '.pm';
    
    require $view;
    return  $pckg->new($s);
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::View
