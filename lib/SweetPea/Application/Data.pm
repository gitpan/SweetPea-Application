package SweetPea::Application::Data;

use warnings;
use strict;

use base 'DBIx::Simple';
use SQL::Abstract;

=head1 NAME

SweetPea::Application::Data - Datasource handling for SweetPea-Application.

=cut

=head1 SYNOPSIS
    ... from inside SweetPea::Application or a Controller;
    $s->data;
    $s->data->abstract;

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Data object
    which uses DBIx::Simple as a base class to provide methods for retrieving
    and manipulating datasources (mainly databases).
    
    $s->plug( 'data', sub { return SweetPea::Application::Data->new($s); });

=cut

sub new {
    my ($class, $s) = @_;
    my  $app    = $s->config->get('/application');
    my  $ds     = $s->config->get('/datastores');
        $ds     = $ds->{datastores}->{$app->{datastore}};
    my  $self   = DBIx::Simple->connect(
                    $ds->{dsn}, $ds->{username}, $ds->{password})
                  or die DBIx::Simple->error;
                  $self->abstract = SQL::Abstract->new;
    bless $self, $class;
    return $self;
}


=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Data
