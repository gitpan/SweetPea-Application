package SweetPea::Application::Rbac;

use warnings;
use strict;

=head1 NAME

SweetPea::Application::Rbac - Role-Based Access Control for SweetPea-Application.

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

    # Based on a common example
    permissions.yml
    ---
    roles:
      administrator:
        permissions:
          manage accounts:
            operations:
              create account
              update account
              delete account
      manager:
        permissions:
          manager accounts:
            operations:
              create account
      guests:
        permissions:
    
    ... from inside SweetPea::Application or a Controller;
    
    # verify user access
    $s->rbac->authorize($login, $password);
    
    # change user
    $s->rbac->subject($user_id);
    
    # verify target user has permission to perform "create account" operation
    $s->rbac->subject($user_id)->can('/manage accounts/create account');
    
    # change user to default set by authenticate method
    $s->rbac->subject;
    
    # verify has the following role
    $s->rbac->role('administrator');
    $s->rbac->role('guests');
    
    $s->rbac->can('/manage accounts/delete account');

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Rbac object
    which uses Yaml (via SweetPea::Application::Config) to provide methods
    for retrieving authenticating and verifying system access permissions.
    
    $s->plug( 'rbac', sub { return SweetPea::Application::Rbac->new($s); });

=cut

sub new {
    my ($class, $s) = @_;
    my $self        = {};
    bless $self, $class;
    $self->{base}   = $s;
    $self->{subject}= '0';
    return $self;
}

=head2 authorize

    The authorize method check whether the login and password passed to it
    belong to an active system user, if not report the error.
    
    $s->rbac->authorize($login, $password);

=cut

sub authorize {
    my ($self, $login, $password) = @_;
    my $s = $self->{base};
    if ($login && $password) {
        my $user = $s->data->select(
            'users', ['id','login','password','status'], {
                login    => $login,
                password => $password
            }
        )->hash;
        if ($user) {
            if ($user->{status}) {
                $s->session->param('authenticated', 'true');
                $s->session->param('user_id', $user->{id});
                $s->session->param('user_login', $user->{login});
                $s->session->param('original_user_id', $user->{id});
                $s->session->param('original_user_login', $user->{login});
                $s->session->flush;
                $self->{subject} = $user->{id};
                return $self;
            }
            else {
                $s->error->message($s->locale->text('account_disabled'));
            }
        }
        else {
            $s->error->message($s->locale->text('no_account'));
        }
    }
    return 0;
}

=head2 authorized

    The authorized method check whether a user has been authenticated.
    
    if $s->rbac->authorized;

=cut

sub authorized {
    my ($self, $login, $password) = @_;
    my $s = $self->{base};
    return $s->session->param('authenticated');
}

=head2 unauthorize

    The unauthorize method revokes the currently authenticated users
    authentication status. (Kinda like a logout function)

=cut

sub unauthorize {
    my ($self, $login, $password) = @_;
    my $s = $self->{base};
    $s->session->param('authenticated', '');
    return $self;
}

=head2 override

    The override method re-authenticates as another system user while retaining
    the originally logged in user's credentials. Thie method is useful for
    applications that need to provide a means to temporarily switch accounts.
    
    $s->rbac->override($login, $password);
    
    # change back to the original user
    $s->rbac->override;

=cut

sub override {
    my ($self, $login, $password) = @_;
    my $s = $self->{base};
    if ($login && $password) {
        my $user = $s->data->select(
            'users', ['id','login','password','status'], {
                login    => $login,
                password => $password
            }
        )->hash;
        if ($user) {
            if ($user->{status}) {
                $s->session->param('authenticated', 'true');
                $s->session->param('user_id', $user->{id});
                $s->session->param('user_login', $user->{login});
                $s->session->flush;
                $self->{subject} = $user->{id};
                return $self;
            }
            else {
                $s->error->message($s->locale->text('account_disabled'));
            }
        }
        else {
            $s->error->message($s->locale->text('no_account'));
        }
    }
    else {
        $s->session->param('authenticated', 'true');
        $s->session->param('user_id',
            $s->session->param('original_user_id'));
        $s->session->param('user_login',
            $s->session->param('original_user_login'));
        $s->session->flush;
        $self->{subject} = $s->session->param('original_user_id');
        return $self;
    }
    return 0;
}

=head2 subject

    The subject method specifies the user account permissions will be validated
    against using the user id pass to it, if called with no parameters the
    authenticated user's account will be used.
    
    $s->rbac->subject($user_id);
    $s->rbac->subject;

=cut

sub subject {
    my ($self, $id) = @_;
    my $s = $self->{base};
    if ($id =~ /^\d+$/) {
        $self->{subject} = $id;
        return $self;
    }
    else {
        if ($s->session->param('user_id')) {
            $self->{subject} = $s->session->param('user_id');
            return $self;
        }
    }
    return 0;
}

=head2 role

    The role method verifies whether the subject (target user) has the role
    specified.
    
    if $s->rbac->role('administrator');

=cut

sub role {
    my ($self, $role) = @_;
    my $s = $self->{base};
    if ($role) {
        my $has_role = $s->data->select(
            'permissions', ['id','user','role','permission','operation'], {
                user    => $self->{subject},
                role    => $role
            }
        )->rows;
        return $has_role;
    }
    return 0;
}

=head2 can

    The "can" method verifies whether the subject (target user) has a specific
    permission or has permission to perform a specific action.
    
    # check if subject (target user) has permission generally
    if $s->rbac->can('/manage accounts');
    
    # check if subject (target user) has permission to perform a specific operation
    if $s->rbac->can('/manage accounts/create account');

=cut

sub can {
    my ($self, $request) = @_;
    my $s = $self->{base};
    if ($request) {
        $request =~ s/^\///;
        my ($permission, $operation) = split /\//, $request;
        return 0 if !$permission;
        
        my  $where = {};
            $where->{user}       = $self->{subject};
            $where->{permission} = $permission if $permission;
            $where->{operation}  = $operation if $operation;
        
        # check that permission and operation is defined
        my  $permissions = $s->config->get('/permissions');
        my  ($permission_check, $operation_check);
        
        foreach my $r (keys %{$permissions->{roles}}) {
            foreach my $p (keys %{$permissions->{roles}->{$r}->{permissions}}) {
                $permission_check++ if lc($permission) eq lc($p);
                if ($operation) {
                    foreach my $o (
                        @{$permissions->{roles}->{$r}->{permissions}
                          ->{$p}->{operations}}
                        ) {
                        $operation_check++ if lc($operation) eq lc($o);
                    }
                }
            }
        }
        die "Permission ($permission) has not been defined."
            unless $permission_check;
        if ($operation) {
            die "Operation ($operation) has not been defined."
                unless $operation_check;
        }
        
        my $can = $s->data->select(
            'permissions', ['id','user','role','permission','operation'], $where
        )->rows;
        
        return $can;
    }
    return 0;
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Rbac
