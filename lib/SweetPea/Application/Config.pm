package SweetPea::Application::Config;

use warnings;
use strict;

use base 'Config::Any';
use YAML::Syck;
use File::Find;
use File::Util;

=head1 NAME

SweetPea::Application::Config - Configuration handling for SweetPea-Application.

=cut

=head1 SYNOPSIS
    ... from inside SweetPea::Application or a Controller;
    my $configuration = $s->config->get('/application');
    my $datasources = $s->config->get('/datasourses');

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Config object
    which use Config::Any as a base class to provide access to the yml documents.
    
    $s->plug( 'config', sub { return SweetPea::Application::Config->new($s); });

=cut

sub new {
    my ($class, $s, $path) = @_;
    my $self        = {};
    my $keys        = {};
    my @files       = ();
    if (!$path) {
       $path        = $s->path('/sweet/configuration');
    }
    else {
        $path       .= '/sweet/configuration';
    }
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
    $self->{file} = File::Util->new;
    $self->{keys} = $keys;
    $self->{base} = $s;
    return $self;
}

=head2 get

    The get method returns a reference to the specific configuration data of
    the key passed to it or returns undefined.
    
    my $foo = $s->config->get('/application');
    if (defined $foo) {
        $foo->{datasource} = 'production';
    }
    else {
        die '/application config file is undefined';
    }

=cut

sub get {
    my ($self, $key) = @_;
    if ( $key ) {
        if (defined $self->{keys}->{$key}) {
            return $self->{data}->{$self->{keys}->{$key}} if defined
                $self->{data}->{$self->{keys}->{$key}};
        }
    }
    return undef;
}

=head2 set

    The set method saves any changes to the configuration data of the file
    identified by the key passed to it or returns undefined.

=cut

sub set {
    my ($self, $key, $hash) = @_;
    my $s = $self->{base};
    if ( $key ) {
        if (defined $self->{keys}->{$key}) {
            if (defined $self->{data}->{$self->{keys}->{$key}}) {
                my $yaml = Dump($self->{data}->{$self->{keys}->{$key}});
                unlink "sweet/configuration$key.yml";
                $self->{file}->write_file(
                    'file'    => "sweet/configuration$key.yml",
                    'content' => 'temporary placeholder',
                    'bitmask' => 0644
                );
                $s->file('>', "sweet/configuration$key.yml",
                         ($hash ? Dump($hash) : $yaml));
                return $self;
            }
        }
        else {
            if ($key && ref($hash) eq "HASH") {
                my $yaml = Dump($hash);
                unlink "sweet/configuration$key.yml";
                $self->{file}->write_file(
                    'file'    => "sweet/configuration$key.yml",
                    'content' => 'temporary placeholder',
                    'bitmask' => 0644
                );
                $s->file('>', "sweet/configuration$key.yml", $yaml);
                return $self;
            }
        }
    }
    return undef;
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Config
