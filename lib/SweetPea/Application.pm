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

Version 0.022

=cut

our $VERSION = '0.022';

=head1 SYNOPSIS

SweetPea::Application is an extention of the SweetPea web framework which is
considered the core whereas SweetPea::Application is a full stack web
application framework utilizing conventional wisdom and granular configuration
over a highly sophisticated Push MVC architecture. (IT acronyms rock...)

SweetPea::Application overwrites the generator created by the core SweetPea
install updating its functionality. The sweetpea cli now uses the following:

    ... at the cli (command-line interface)
    
    # build a single-script application (go minimalist)
    sweetpea make --script
    
    # build a micro web application (i need more structure)
    sweetpea make --application
    
    # build a full-stack web application (i need more power)
    sweetpea make --stack [dbi:mysql:database root [pass]]

=head1 EXPORTED

    sweet (shortcut to SweetPea object instantiation)

=head1 METHODS

=head2 sweet

=cut

sub sweet {
    return SweetPea::Application->new;
}

=head2 new

=cut

sub new {
    my $class   = shift;
    my $options = shift;
    my $self    = {};
    bless $self, $class;

    #declare config stuff
    $self->{store}->{application}->{html_content}     = [];
    $self->{store}->{application}->{action_discovery} = 1;
    $self->{store}->{application}->{local_session}    = 0; # for debugging
    $self->{store}->{application}->{content_type}     = 'text/html';
    $self->{store}->{application}->{path}             = $FindBin::Bin;
    $self->{store}->{application}->{local_session}    =
        $options->{local_session} ? $options->{local_session} : 0; # debugging
    $self->{store}->{application}->{session_folder}   =
        $options->{session_folder} if $options->{session_folder};
    $self->{store}->{template}->{data}                = '';
    return $self;
}


=head2 _plugins

=cut

sub _plugins {
    my $self = shift;

    # NOTE! The database and email plugins are not used internally so changing
    # them to a module of you choice won't effect any core functionality. Those
    # modules/plugins should be configured in App.pm.
    # load modules using the following procedure, they will be available to the
    # application as $s->nameofobject.

    # browser support
    $self->plug(
        'cgi',
        sub {
            my $self = shift;
            return CGI->new;
        }
    );

    # cookie support
    $self->plug(
        'cookie',
        sub {
            require 'CGI/Cookie.pm';
            my $self = shift;
            push @{ $self->{store}->{application}->{cookie_data} },
              CGI::Cookie->new(@_);
            return $self->{store}->{application}->{cookie_data}
              ->[ @{ $self->{store}->{application}->{cookie_data} } ];
        }
    );

    # session support
    $self->plug(
        'session',
        sub {
            require 'CGI/Session.pm';
            my $self = shift;
            my $opts = {};
            my $session_folder = $ENV{HOME} || "";
            $session_folder = (split /[\;\:\,]/, $session_folder)[0]
             if $session_folder =~ m/[\;\:\,]/;
            $session_folder =~ s/[\\\/]$//;
            CGI::Session->name("SID");
            if ( -d -w "$session_folder/tmp" ) {
                $opts->{Directory} = "$session_folder/tmp";
            }
            else {
                if ( -d -w $session_folder ) {
                    mkdir "$session_folder/tmp", 0777;
                }
                if ( -d -w "$session_folder/tmp" ) {
                    $opts->{Directory} = "$session_folder/tmp";
                }    
            }
            if ($self->{store}->{application}->{local_session}
                && !$opts->{Directory}) {
                mkdir "sweet"
                unless -e
                "$self->{store}->{application}->{path}/sweet";
                
                mkdir "sweet/sessions"
                unless -e
                "$self->{store}->{application}->{path}/sweet/sessions";
                
                $opts->{Directory} = 'sweet/sessions';
            }
            my $sess = CGI::Session->new("driver:file", undef, $opts);
            $sess->flush;
            return $sess;
        }
    );
    
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
    
    # errors class
    $self->plug(
        'error',
        sub {
            require 'SweetPea/Application/Error.pm';
            my $self = shift;
            return SweetPea::Application::Error->new($self);
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

=head2 finish

=cut

sub finish {
    my $self = shift;
    
    # return captured data for mock transactions
    if ($self->{store}->{application}->{mock_run}) {
        if (length($self->{store}->{template}->{data}) > 1) {
            $self->html($self->{store}->{template}->{data});
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
