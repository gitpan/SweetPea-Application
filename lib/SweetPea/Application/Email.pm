package SweetPea::Application::Email;

use warnings;
use strict;

use base 'Email::Stuff';

=head1 NAME

SweetPea::Application::Email - Email handling for SweetPea-Application.

=cut

=head1 SYNOPSIS
    ... from inside SweetPea::Application or a Controller;
    $s->email->message({
        to          => 'me@abc.com',
        from        => 'you@abc.com,
        subject     => 'Have you heard, the bird is the word',
        message     => 'Everybodys heard that the bird is the word',
       type         => 'text',
        attachments => [
            'avatar.gif'  => 'your_photo.gif',
            'invoice.xls' => 'invoice.xls'
        ]
    })->send;
    
    $s->email->message({
        to          => 'me@abc.com',
        from        => 'you@abc.com,
        cc          => 'him@abc.com, her@abc.com',
        subject     => 'Have you heard, the bird is the word',
        message     => 'Everybodys heard that the bird is the word',
        webpages    => [
            '/email/letters/welcome' => 'welcome.html',
            '/email/letters/terms'   => 'service_terms.html'
        ]
    })->send;

    # defaults to sendmail, if you want to send using smtp
    $s->email->message->send(uc('smtp'),'mail.domain.tld');

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Email object
    which use Email::Stuff as a base class to provide a a host of email
    functionality. 
    
    $s->plug( 'email', sub { return SweetPea::Application::Email->new($s); });

=cut

sub new {
    my ($class, $s) = @_;
    my $self        = Email::Stuff->new;
    bless $self, $class;
    $self->{base}   = $s;
    return $self;
}

=head2 message

    The message method provides a unified interface for sending emails via
    the Email::Stuff package.
    
    $s->email->message({
        to          => 'me@abc.com',
        from        => 'you@abc.com,
        subject     => 'Have you heard, the bird is the word',
        message     => 'Everybodys heard that the bird is the word',
        webpages    => [
            '/email/letters/welcome' => 'welcome.html',
            '/email/letters/terms'   => 'service_terms.html'
        ]
    })->send;
    
    # Note! webpage option lets you send the output from a dispatched url using
    SweetPea's mock method e.g.
    
    The exmaple above capture the output from the following request and attaches
    it as a file.
    
    http://localhost/email/letters/welcome

=cut

sub message {
    my ($self, $options) = @_;
    my $s = $self->{base};
    
    # process to
    if ($options->{to}) {
        $self->to($options->{to});
    }
    # process from
    if ($options->{from}) {
        $self->from($options->{from});
    }
    # process cc
    if ($options->{cc}) {
        $self->cc(
        join ",", ( map { $_ =~ s/(^\s+|\s+$)//g; $_ } split /[\,\s]/, $options->{cc} ) );
    }
    # process bcc
    if ($options->{bcc}) {
        $self->bcc(
        join ",", ( map { $_ =~ s/(^\s+|\s+$)//g; $_ } split /[\,\s]/, $options->{bcc} ) );
    }
    # process subject
    if ($options->{subject}) {
        $self->subject($options->{subject});
    }
    # process message
    if ($options->{message}) {
        if (lc($options->{type}) == 'text') {
            $self->text_body($options->{message});
        }
        else {
            $self->html_body($options->{message});
        }
    }
    # process webpage
    if ($options->{webpages}) {
        if (ref($options->{webpages}) eq "ARRAY") {
            my %pages = @{$options->{webpages}};
            foreach my $page (keys %pages) {
                my $request = SweetPea::Application->new;
                my $doc     = join "<br/>", $request->mock($page);
                if ($doc) {
                    $self->attach($doc,
                                  'name' => $pages{$page},
                                  'content_type' => 'text/html'
                    );
                }
                undef $request;
            }
        }
    }
    # process attachments
        if ($options->{attachments}) {
        if (ref($options->{attachments}) eq "ARRAY") {
            my %files = @{$options->{attachments}};
            foreach my $file (keys %files) {
                $self->attach($s->file('<', $file), 'filename' => $files{$file});
            }
        }
    }
    return $self;
}

sub send {
    my $self = shift;
    my @args = @_;
    my $s    = $self->{base};
    if (@args == 1) {
        my $conf = $s->config->get('/application');
        if (defined $conf->{email}) {
            if (defined $conf->{email}->{$args[0]}) {
                if (lc($args[0]) eq lc("sendmail")) {
                    my $eargs = $conf->{email}->{$args[0]};
                    $self->{send_using} = [$eargs->{driver}, $eargs->{path}];
                    # failsafe
                    $Email::Send::Sendmail::SENDMAIL = $eargs->{path} unless
                        $Email::Send::Sendmail::SENDMAIL;
                }
                if (lc($args[0]) eq lc("smtp")) {
                    my $eargs = $conf->{email}->{$args[0]};
                    $self->{send_using} = [
                        $eargs->{driver}, $eargs->{host}
                    ];
                }
                if (lc($args[0]) eq lc("qmail")) {
                    my $eargs = $conf->{email}->{$args[0]};
                    $self->{send_using} = [$eargs->{driver}, $eargs->{path}];
                    # failsafe
                    $Email::Send::Qmail::QMAIL = $eargs->{path} unless
                        $Email::Send::Qmail::QMAIL;
                }
                if (lc($args[0]) eq lc("nntp")) {
                    my $eargs = $conf->{email}->{$args[0]};
                    $self->{send_using} = [
                        $eargs->{driver}, $eargs->{host}
                    ];
                }
                my $email = $self->email or return undef;
                $self->mailer->send( $email );
            }
        }
    }
    else {
        $self->using(@args) if @_; # Arguments are passed to ->using
        my $email = $self->email or return undef;
        $self->mailer->send( $email );
    }
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Email