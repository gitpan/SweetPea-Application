package SweetPea::Application;

use warnings;
use strict;

BEGIN {
    use Exporter();
    use vars qw( @ISA @EXPORT @EXPORT_OK );
    @ISA    = qw( Exporter );
    @EXPORT = qw(sweet);
}

use base 'SweetPea';

=head1 NAME

SweetPea::Application - A full stack web framework for the rest of us.

=head1 VERSION

Version 0.025

=cut

our $VERSION = '0.025';

=head1 SYNOPSIS

SweetPea::Application is a full-stack web application framework built atop
of the L<SweetPea> web framework. SweetPea::Application aims to provide all
the functionality common to building complete and robust web applications
via a suite of packages through a unified API.

    # build a full-stack web application (from the cli)
    sweetpea make -f
    
    use SweetPea;
    sweet->routes({
    
        '/' => sub {
            shift->forward('/way');
        },
        
        '/way' => sub {
            shift->html('I am the way the truth and the light!');
        }
        
    })->run;

To Get Started, Review
L<SweetPea::Cli::Documentation> or L<SweetPea::Application::Documentation>.

=cut

sub sweet {
    return SweetPea::Application->new;
}

sub _plugins {
    my $self = shift;
    
    # use existing
    SweetPea::_plugins($self);

    # configuration support
    $self->plug(
        'config',
        sub {
            require 'SweetPea/Application/Config.pm';
            my $self = shift;
            return SweetPea::Application::Config->new($self);
        }
    );
    
    # template support
    $self->plug(
        'template',
        sub {
            require 'SweetPea/Application/Template.pm';
            my $self = shift;
            return SweetPea::Application::Template->new($self);
        }
    );
    
    # database support
    $self->plug(
        'data',
        sub {
            require 'SweetPea/Application/Data.pm';
            my $self = shift;
            return SweetPea::Application::Data->new($self);
        }
    );
    
    # object mapping support
    $self->plug(
        'dbo',
        sub {
            require 'SweetPea/Application/Orm.pm';
            my $self = shift;
            return SweetPea::Application::Orm->new($self);
        }
    );    
    
    # localization support
    $self->plug(
        'locale',
        sub {
            require 'SweetPea/Application/Locale.pm';
            my $self = shift;
            return SweetPea::Application::Locale->new($self);
        }
    );
    
    # role-based access control support
    $self->plug(
        'rbac',
        sub {
            require 'SweetPea/Application/Rbac.pm';
            my $self = shift;
            return SweetPea::Application::Rbac->new($self);
        }
    );
    
    # email support
    $self->plug(
        'email',
        sub {
            require 'SweetPea/Application/Email.pm';
            my $self = shift;
            return SweetPea::Application::Email->new($self);
        }
    );
    
    # input validation support
    $self->plug(
        'validate',
        sub {
            require 'SweetPea/Application/Validate.pm';
            my $self = shift;
            return SweetPea::Application::Validate->new($self);
        }
    );
    
    # model accessor
    $self->plug(
        'model',
        sub {
            require 'SweetPea/Application/Model.pm';
            my $self = shift;
            return SweetPea::Application::Model->new($self, @_);
        }
    );
    
    # view accessor
    $self->plug(
        'view',
        sub {
            require 'SweetPea/Application/View.pm';
            my $self = shift;
            return SweetPea::Application::View->new($self, @_);
        }
    );
    
    # html elements builder
    $self->plug(
        'builder',
        sub {
            require 'SweetPea/Application/Builder.pm';
            my $self = shift;
            return SweetPea::Application::Builder->new($self);
        }
    );    

    # load non-core plugins from App.pm
    if (-e "sweet/App.pm") {
        eval 'require q(App.pm)';
        if ($@) {
            warn $@;
        }
        else {
            eval { App->plugins($self) };
        }
    }

    return $self;
}

sub finish {
    my $self = shift;
    
    # return captured data for mock transactions
    if ($self->{store}->{application}->{mock_run}) {
        if ($self->{store}->{template}) {
            if (length($self->{store}->{template}->{data}) > 1) {
                $self->html($self->{store}->{template}->{data});
            }
        }
        # check for laziness
        elsif (length($self->template->{data}) > 1) {
            $self->html($self->template->{data});
        }
        $self->session->flush();
        return 1;
    }
    
    # check if template data exists
    if (length($self->{store}->{template}->{data}) > 1) {
        print $self->{store}->{template}->{data};
    }
    # check for laziness
    elsif (length($self->template->{data}) > 1) {
        print $self->template->{data};
    }
    # print gathered html
    else {
        foreach ( @{ $self->html } ) {
            print "$_\n";
        }
    }

    # commit session changes if a session has been created
    $self->session->flush();
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sweetpea-application at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SweetPea-Application>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SweetPea::Application

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SweetPea-Application>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SweetPea-Application>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SweetPea-Application>

=item * Search CPAN

L<http://search.cpan.org/dist/SweetPea-Application/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Al Newkirk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SweetPea::Application
