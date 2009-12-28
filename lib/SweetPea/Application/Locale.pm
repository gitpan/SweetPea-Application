package SweetPea::Application::Locale;

use warnings;
use strict;

use base 'Config::Any';
use YAML::Syck;
use File::Find;

=head1 NAME

SweetPea::Application::Locale - Localization handling for SweetPea-Application.

=cut

=head1 SYNOPSIS
    ... from inside SweetPea::Application or a Controller;
    $s->locale->language('en');
    my $text = $s->locale->text('hello_message');

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Locale object
    which use Config::Any w/ YAML::Syck as a base class to provide access
    to the yml locales.
    
    $s->plug( 'config', sub { return SweetPea::Application::Locale->new($s); });

=cut

sub new {
    my ($class, $s) = @_;
    my $self        = {};
    my $keys        = {};
    my @files       = ();
    my $path        = $s->path('/sweet/locales');
    bless $self, $class;
    if (-e $path) {
        find( sub{
            if ($File::Find::name =~ /\.yml$/) {
                my $id = $File::Find::name ;
                push @files, $File::Find::name ;
                $id =~ s/(^$path|\.yml$)//;
                $id =~ s/\.yml$//;
                $keys->{$id} = $File::Find::name ;
            }
        }, $path);
        $self->{data} = $self->load_files( {
            files => \@files, use_ext => 1, flatten_to_hash => 1
        } );
    }
    $self->{keys} = $keys;
    $self->{base} = $s;
    $self->{lang} = '';
    return $self;
}

=head2 language

    The language method selects the specific localization data(yml) file to be
    used to provide translations to the application.
    
    $s->locale->language('/en');

=cut

sub language {
    my ($self, $key) = @_;
    if ( $key ) {
        if (defined $self->{keys}->{$key}) {
            $self->{lang} = $self->{data}->{$self->{keys}->{$key}} if defined
                $self->{data}->{$self->{keys}->{$key}};
            return 1;
        }
    }
    return undef;
}

=head2 text

    The text method retrieves the translation text from the locale file selected
    with the "language" method. Defaults to "en" (english) translation.

=cut

sub text {
    my ($self, $key, @text) = @_;
    if ($self->{lang}) {
        if (defined $self->{lang}->{$key}) {
            return $self->{lang}->{$key};
        }
    }
    else {
        $self->language('/en');
        if (defined $self->{lang}->{$key}) {
            if (@text) {
                for (my $i=0; $i < @text; $i++) {
                    my $replacement = $text[$i];
                    $self->{lang}->{$key} =~ s/\$$i/$replacement/g;
                }
            }
            return $self->{lang}->{$key};
        }
    }
    return undef;
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Locale