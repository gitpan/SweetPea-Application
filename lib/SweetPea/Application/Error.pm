package SweetPea::Application::Error;

use warnings;
use strict;

=head1 NAME

SweetPea::Application::Error - Error handling for SweetPea-Application.

=cut

=head1 SYNOPSIS

    ... from inside SweetPea::Application or a Controller;
    $s->error->message('The application did something very wrong here');
    $s->error->message('I made a boo boo', 'Im still not working');
    die if $s->error->count;
    print $s->error->report;
    print $s->error->report("\n"); $s->error->{delimiter} = "<br/>";

=head1 METHODS

=head2 new

     The new method instantiates a new SweetPea::Application::Error object
    which stores and renders error messages for the application.
    
    $s->plug( 'error', sub { return SweetPea::Application::Error->new($s); });

=cut

sub new {
    my ($class, $s)     = @_;
    my $self            = {};
    bless $self, $class;
    $self->{base}       = $s;
    $self->{errors}     = [];
    $self->{delimiter}  = "<br/>";
    return $self;
}

=head2 message

    The message method is responsible for storing passed in error messages for
    later retrieval and rendering.
    
    $s->error->message('Mail document was not sent');
    $s->error->message('Mail document was not sent', 'SMTP connection error');

=cut

sub message {
    my $self = shift;
    foreach my $message (@_) {
        push @{$self->{errors}}, $message;
    }
    return $self;
}

=head2 count

    The count method returns the number of error messages currently existing in 
    the error messages container.
    
    die if $s->error->count;

=cut

sub count {
    return @{shift->{errors}};
}

=head2 clear

    the clear method resets the error message container.
    
    $s->error->clear;

=cut

sub clear {
    shift->{errors} = [];
}

=head2 report

    The report method is responsible for displaying all stored error messages
    using the defined message delimiter.
    
    print $s->error->report;
    print $s->error->report("\n");
    

=cut

sub report {
    my ($self, $delimiter) = @_;
    $self->{delimiter} = $delimiter if $delimiter;
    return join $self->{delimiter}, @{$self->{errors}};
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Error
