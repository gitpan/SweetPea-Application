package SweetPea::Application::Template;

use warnings;
use strict;

use base 'Template';

=head1 NAME

SweetPea::Application::Template - Template handling for SweetPea-Application.

=cut

=head1 SYNOPSIS

    ... from inside SweetPea::Application or a Controller;
    $s->template->render('/index');
    $s->template->render({ template => '/newletter', layout => '/email'});
    $s->template->render('/index')->to('content');
    $s->template->render('/layouts/default');

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Template object
    which use Template as a base class to provide methods for rendering
    data and documents using templates.
    
    $s->plug('template', sub {return SweetPea::Application::Template->new($s)});

=cut

sub new {
    my ($class, $s) = @_;
    my %options = (
        INCLUDE_PATH => $s->path('/sweet/templates'),
        EVAL_PERL    => 1,
        ANYCASE      => 1
    );
    my $self        = Template->new(\%options) unless Template->error();
    bless $self, $class;
    $self->{data} = "";
    $self->{base} = $s;
    $self->{fext} = ".tt";
    return $self;
}

=head2 clear

    The clear method resets all data variables pertaining to the template
    in its present context. The clear method is called automatically after
    processing the "to" method.
    
    $s->template->clear;

=cut

sub clear {
    my $self = shift;
    $self->{data} = "";
}

=head2 render

    The render method prepares a template document for parsing.
    
    $s->template->render('/index');
    $s->template->render({ template => '/newletter', layout => '/email'});

=cut

sub render {
    my ($self, $render) = @_;
    my $s = $self->{base};
    if ($render) {
        if (ref($render) eq "HASH") {
            if ( defined $render->{template} ) {
                my $ext = $self->{fext};
                my $data;
                $render->{template} =~ s/^\///;
                $render->{template} .= $ext if $render->{template} !~ /$ext$/;
                if ($self->_check_template($render->{template})) {
                    $self->process(
                        $render->{template},
                        { 's' => $s, 't' => $s->{store}->{template} },
                        \$data
                    );
                    $self->{data} = $data;
                }
            }
            if ( defined $render->{layout} ) {
                my $ext = $self->{fext};
                my $data;
                $render->{layout} =~ s/^\///;
                $render->{layout} .= $ext if $render->{layout} !~ /$ext$/;
                $render->{layout} = "layouts/$render->{layout}"
                    if $render->{layout} !~ /^\/?layouts\//;
                if ($self->_check_template($render->{layout})) {
                    $self->process(
                        $render->{layout},
                        { 's' => $s,
                          't' => $s->{store}->{template},
                          'content' => $self->{data}
                        },
                        \$data
                    );
                    $self->{data} = $data;
                }
            }
        }
        else {
            my $ext = $self->{fext};
            $render =~ s/^\///;
            $render .= $ext if $render !~ /$ext$/;
            if ($self->_check_template($render)) {
                $self->process(
                    $render,
                    { 's' => $s, 't' => $s->{store}->{template} },
                    \$self->{data}
                );
            }
        }
    }
    return $self;
}

=head2 to

    The "to" method renders the template in its present context to a special
    area in the sweetpea application stash(store) for template identified by
    the label passed in.
    
    $s->template->render('/dashboard')->to('main');
    $s->template->render('/options')->to('sidebar');
    $s->template->render('/layouts/default')->to;

=cut

sub to {
    my ($self, $label) = @_;
    my $s = $self->{base};
    if (defined $self->{data}) {
        if (defined $label) {
            $s->{store}->{template}->{$label} = $self->{data};
        }
        else {
            $s->{store}->{template}->{data}   = $self->{data};
        }
    }
    $self->clear;
    return $self;
}

sub _check_template {
    my ($self, $template) = @_;
    my $s   = $self->{base};
    if (-e $s->path("/sweet/templates/$template")) {
        return 1;
    }
    else {
        die "Can't render " .
        $s->path("/sweet/templates/$template") .
        ", that file doesn't exist.";
    }
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Template
