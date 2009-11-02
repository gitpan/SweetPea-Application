package SweetPea::Application::Builder;

use warnings;
use strict;

=head1 NAME

SweetPea::Application::Builder - HTML generator for SweetPea-Application.

=cut

=head1 SYNOPSIS

    ** EXPERIMENTAL - UNSTABLE (Thrown Together) **

    ... from inside SweetPea::Application or a Controller;
    my $profile = 'users'; # users table yaml profile
    my $form_object = $s->builder->form($profile);
    $s->builder->form($profile)->render;
    $s->builder->grid($profile)->render;

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Builder object
    which is responsible for automatically generating form or grid elements,
    performing validation and . 
    
    $s->plug( 'builder', sub { return SweetPea::Application::Builder->new($s); });

=cut

sub new {
    my ($class, $s)     = @_;
    my $self            = {};
    bless $self, $class;
    $self->{base}       = $s;
    $self->{type}       = '';
    $self->{elements}   = [];
    $self->{data}       = '';
    return $self;
}

=head2 form

    The form method generates html elements for use in web forms. This method
    is intended to reduce tedium when creating html forms.
    
    $s->builder->form('/table/users');
    
    Take 4 args.
    arg 1: required - yaml profile
    arg 2: optional - datasource resultset (arrayref of hashref)
    arg 3: optional - ordered list of fields (must also exist under the
            form > fields section in the yaml profile)
    arg 4: optional - element template
    
    ** NOTE **
    The returned html data is not wrapped in a html <form> tag and does not
    contain submit buttons for flexibility.

=cut

sub form {
    my $self    = shift;
    my $profile = shift;
    my $results = shift;
    my $order   = shift;
    my $template= shift || 'form';
        $profile =~ s/^\///;
    my $s       = $self->{base};
    my $store   = $s->config->get('/application')->{datastore};
    my $t       = $s->config->get("/datastores/$store/$profile");
    
    if (defined $t->{form}) {
        if (defined $t->{form}->{fields}) {
            $self->{type} = 'form';
            $s->store->{template}->{builder}->{elements} = $order || [keys %{$t->{form}->{fields}}];
            $s->store->{template}->{builder}->{configuration} = $t;
            $s->store->{template}->{builder}->{resultset} = $results;
        }
        my $data = $s->template->render("/elements/$template")->{data};
        $self->{data} = $data;
        $s->template->clear;
        return ($data, $self);
    }
}

=head2 grid

    The grid method generates html table columns, rows and navigation for use
    in web pages. This method is intended to reduce tedium when creating html
    tables.
    
    $s->builder->grid('/table/users');
    
    Take 4 args.
    arg 1: required - yaml profile
    arg 2: optional - datasource resultset (arrayref of hashref)
    arg 3: optional - ordered list of fields (must also exist under the
            form > fields section in the yaml profile)
    arg 4: optional - element template
    
    ** NOTE **
    The returned html data is not wrapped in a html <table> tag for flexibility.

=cut

sub grid {
    my $self    = shift;
    my $profile = shift;
    my $results = shift;
    my $order   = shift;
    my $template= shift || 'grid';
        $profile =~ s/^\///;
    my $s       = $self->{base};
    my $store   = $s->config->get('/application')->{datastore};
    my $t       = $s->config->get("/datastores/$store/$profile");
    
    if (defined $t->{grid}) {
        if (defined $t->{grid}->{columns}) {
            $self->{type} = 'grid';
            $s->store->{template}->{builder}->{elements} = $order || [keys %{$t->{grid}->{columns}}];
            $s->store->{template}->{builder}->{configuration} = $t;
            $s->store->{template}->{builder}->{resultset} = $results;
        }
        my $data = $s->template->render("/elements/$template")->{data};
        $self->{data} = $data;
        $s->template->clear;
        return ($data, $self);
    }
}

=head2 to

    The "to" method stores the returned html data in a specified section of the
    store (sweetpea stash) for use in another template or layout.

=cut

sub to {
    my ($self, $to) = @_;
    my $data = $self->{data};
    my $s = $self->{base};
    if ($data && $to) {
        $s->store->{template}->{$to} = $data;
    }
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Builder
