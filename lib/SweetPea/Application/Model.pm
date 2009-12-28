package SweetPea::Application::Model;

use warnings;
use strict;

=head1 NAME

SweetPea::Application::Model - Model support for SweetPea-Application.

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

    ... from inside SweetPea::Application or a Controller;
    #access Model::Users::create_account()
    $s->model('Users')->create_account();

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Model object
    which loads model packages on requests ands provides accessors to it's
    functions. 
    
    $s->plug( 'model', sub { return SweetPea::Application::Model->new($s); });

=cut

sub new {
    my ($class, $s, $model) = @_;
    my $self        = {};
    my $pckg        = $model;
    bless $self, $class;
    $model          =~ s/^\///;
    $pckg           =~ s/[\\\:]/\//g;
    $pckg           = 'Model::' . $model;
    $model          = 'Model/' . $model . '.pm';
    
    require $model;
    return  $pckg->new($s);
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Model
