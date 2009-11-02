package SweetPea::Application::Validate;

use warnings;
use strict;

use base 'Data::FormValidator';

=head1 NAME

SweetPea::Application::Validate - Data validation for SweetPea-Application.

=cut

=head1 SYNOPSIS

    ... from inside SweetPea::Application or a Controller;
    if $s->validate->table('/users');

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Validate object
    which use Data::FormValidator as a base for validating user input. 
    
    $s->plug( 'validate', sub { return SweetPea::Application::Validate->new($s); });

=cut

sub new {
    my ($class, $s)     = @_;
    my $self            = Data::FormValidator->new;
    bless $self, $class;
    $self->{base}       = $s;
    $self->{results}    = {};
    return $self;
}

=head2 input

    The input method validates data input (usually from an HTML form) using
    Data::FormValidator syntax.
    
    Takes 2 arguments
    arg 1 - required - validation rules (hashref)
    arg 2 - optional - input parameters (hashref)

    if ($s->validate->input({
        form_field => param('some_field')
    }, {
        required => ['form_field']
    })) {
        ...
    }
    
    or
    
    if ($s->validate->input({required => ['form_field']}) {
        ...
    }

=cut

sub input {
    my $self    = shift;
    my $rules   = shift;
    my $input   = shift;
    my $s       = $self->{base};
    
    $input      = $s->cgi->Vars if !$input;
    
    my $results = $self->check($input, $rules);
    $self->{results} = $results;
    
    if ($results->has_invalid or $results->has_missing) {
        return 0;
    }
    
    return $self->{results};
}

=head2 table

    The table method validates data input automatically using
    Data::FormValidator syntax with the yaml datastore table profile supplied.
    
    Takes 1 arguments
    arg 1 - required - table yaml profile name (scalar)

    if ($s->validate->table('tablename')) {
        print $s->validate->msgs;
    }

=cut

sub table {
    my $self    = shift;
    my $profile = shift;
        $profile =~ s/^\///;
    my $s       = $self->{base};
    my $store   = $s->config->get('/application')->{datastore};
    my $t       = $s->config->get("/datastores/$store/table/$profile");
    
    # build input hash
    my $input   = {};
    
    foreach my $field (keys %{$t->{form}->{fields}}) {
        if ($t->{form}->{fields}->{$field}->{input_via} eq "session") {
            my $mapped_to = $t->{form}->{fields}->{$field}->{maps_to};
            if ($mapped_to) {
                if ($s->session->param($mapped_to) || $s->session->param($field)) {
                    $input->{$mapped_to} =
                        $s->session->param($mapped_to) ||
                        $s->session->param($field);
                }
            }
            else {
                $input->{$field} = $s->session->param($field);
            }
            next;
        }
        if ($t->{form}->{fields}->{$field}->{input_via} eq "post") {
            my $mapped_to = $t->{form}->{fields}->{$field}->{maps_to};
            if ($mapped_to) {
                if ($s->cgi->param($mapped_to) || $s->cgi->param($field)) {
                    $input->{$mapped_to} =
                        $s->cgi->param($mapped_to) ||
                        $s->cgi->param($field);
                }
            }
            else {
                $input->{$field} = $s->cgi->param($field);
            }
            next;
        }
        if ($t->{form}->{fields}->{$field}->{input_via} eq "get") {
            my $mapped_to = $t->{form}->{fields}->{$field}->{maps_to};
            if ($mapped_to) {
                if ($s->cgi->url_param($mapped_to) || $s->cgi->url_param($field)) {
                    $input->{$mapped_to} =
                        $s->cgi->url_param($mapped_to) ||
                        $s->cgi->url_param($field);
                }
            }
            else {
                $input->{$field} = $s->cgi->url_param($field);
            }
            next;
        }
    }
    
    # build validation rules using a yaml table profile
    my $rules   = $t->{form}->{validation} || {};
    
    if (defined $rules->{constraint_methods}) {
        foreach my $rule (keys %{$rules->{constraint_methods}}) {
            my $value = $rules->{constraint_methods}->{$rule};
            $rules->{constraint_methods}->{$rule} = eval $value;
            if ( ref($rules->{constraint_methods}->{$rule}) ne "CODE" || $@ ) {
                $rules->{constraint_methods}->{$rule} = $value;
            }
        }
    }
    
    my $results = $self->check($input, $rules);
    $self->{results} = $results;
    
    if ($results->has_invalid or $results->has_missing) {
        return 0;
    }
    
    return $self->{results};
}

=head2 profile

    The profile method validates data input automatically using
    Data::FormValidator syntax along with the specified yaml profile under the
    configuration folder.
    
    Takes 1 arguments
    arg 1 - required - table yaml profile name (scalar)

    if ($s->validate->profile('yamlfile')) {
        print $s->validate->msgs;
    }

=cut

sub profile {
    my $self    = shift;
    my $profile = shift;
        $profile =~ s/^\///;
    my $s       = $self->{base};
    my $store   = $s->config->get('/application')->{datastore};
    my $t       = $s->config->get("/datastores/$store/$profile");
    
    # build input hash
    my $input   = {};
    
foreach my $field (keys %{$t->{form}->{fields}}) {
        if ($t->{form}->{fields}->{$field}->{input_via} eq "session") {
            my $mapped_to = $t->{form}->{fields}->{$field}->{maps_to};
            if ($mapped_to) {
                if ($s->session->param($mapped_to) || $s->session->param($field)) {
                    $input->{$mapped_to} =
                        $s->session->param($mapped_to) ||
                        $s->session->param($field);
                }
            }
            else {
                $input->{$field} = $s->session->param($field);
            }
            next;
        }
        if ($t->{form}->{fields}->{$field}->{input_via} eq "post") {
            my $mapped_to = $t->{form}->{fields}->{$field}->{maps_to};
            if ($mapped_to) {
                if ($s->cgi->param($mapped_to) || $s->cgi->param($field)) {
                    $input->{$mapped_to} =
                        $s->cgi->param($mapped_to) ||
                        $s->cgi->param($field);
                }
            }
            else {
                $input->{$field} = $s->cgi->param($field);
            }
            next;
        }
        if ($t->{form}->{fields}->{$field}->{input_via} eq "get") {
            my $mapped_to = $t->{form}->{fields}->{$field}->{maps_to};
            if ($mapped_to) {
                if ($s->cgi->url_param($mapped_to) || $s->cgi->url_param($field)) {
                    $input->{$mapped_to} =
                        $s->cgi->url_param($mapped_to) ||
                        $s->cgi->url_param($field);
                }
            }
            else {
                $input->{$field} = $s->cgi->url_param($field);
            }
            next;
        }
    }
    
    # build validation rules using a yaml table profile
    my $rules   = $t->{form}->{validation} || {};
    
    if (defined $rules->{constraint_methods}) {
        foreach my $rule (keys %{$rules->{constraint_methods}}) {
            my $value = $rules->{constraint_methods}->{$rule};
            $rules->{constraint_methods}->{$rule} = eval $value;
            if ( ref($rules->{constraint_methods}->{$rule}) ne "CODE" || $@ ) {
                $rules->{constraint_methods}->{$rule} = $value;
            }
        }
    }
    
    
    my $results = $self->check($input, $rules);
    $self->{results} = $results;
    
    if ($results->has_invalid or $results->has_missing) {
        return 0;
    }
    
    return $self->{results};
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Validate
