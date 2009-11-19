package SweetPea::Application::Plugin::Ajax::Jquery;

use warnings;
use strict;

use base 'JSON';

=head1 NAME

SweetPea::Application::Plugin::Ajax::Jquery - Generate Ajax requests and
responses in jQuery using SweetPea-Application.

=cut

=head1 SYNOPSIS

    ** NOT REAL CODE **

    ... from inside SweetPea::Application or a Controller;
    $s->ajax->request('/services/accounts', 'post', ['a > span', 'input']);
    or maybe
    get http://localhost/service/accounts id=12
    put http://localhost/service/accounts id=12 email=newone
    
    $s->ajax->function('login_checker', 'get', '/service/accounts');
    $s->ajax->script('tag');
    
    # generates the javascript code with or without the script tag
    # useful for hidding alot of methods [% s.ajax.script %]
    
    ... in html
    onclick="login_checker();"

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Plugin::Ajax::Jquery
    object which automatically generates the neccessary jQuery javascript code
    to submit a request to the appropriate Controller and Action. 
    
    $s->plug( 'ajax', sub { return SweetPea::Application::Plugin::Ajax::Jquery->new($s); });

=cut

sub new {
    my ($class, $s) = @_;
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Plugin::Ajax::Jquery
