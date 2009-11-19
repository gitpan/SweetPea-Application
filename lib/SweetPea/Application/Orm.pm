package SweetPea::Application::Orm;

use warnings;
use strict;

=head1 NAME

SweetPea::Application::Orm - Object Relational Mapping for SweetPea-Application.

=cut

=head1 SYNOPSIS
    ... from inside SweetPea::Application or a Controller;
    this example uses table (users) in the demonstration.
    
    # SweetPea::Application::Orm is NOT a full-featured object relational
    mapper but is an ORM none the less which creates and provides database
    object accessors for use in your application code. SweetPea::Application::Orm
    uses SQL::Abstract querying syntax.
    
    # assign dbo (database object) users (users table) to local variable
    my $user = $s->dbo->users;
    
    # grab the first record, not neccessary if operating on only one record
    $user->read->next;
    
    $user->read;
    
    # SQL::Abstract where clause passed to the "read" method
    $user->read({
        'column' => 'query'
    });
    
    $user->first;
    $user->last;
    
    # how many records in collection
    $user->count
    
    for (0..$user->count) {
        print $user->column;
        $user->column('new stuff');
        $user->update($user->current, $user->id);
    }
    
    # the database objects main accessors are CRUD (create, read, update, and delete)
    
    $user->create;
      $user->read;
        $user->update;
          $user->delete;
    
    # also, need direct access to the resultset?
    $user->collection; # returns an array of hashrefs
    $user->current; # return a hash of the row in the current position of the collection
    

=head1 METHODS

=head2 new

    The new method instantiates a new SweetPea::Application::Orm object
    which uses the YAML datasource configuration files to create database
    objects for manipulating the datasource.
    
    $s->plug( 'profile', sub { return SweetPea::Application::Orm->new($s); });

=cut

sub new {
    my ($class, $s) = @_;
    my  $store  = $s->config->get('/application')->{datastore};
    my  $cfg    = $s->config;
    my  $self   = {};
    bless $self, $class;
    # define defaults
    $self->{target} = '';
    # create base accessors
    no warnings 'redefine';
    no strict 'refs';
    foreach my $file (keys %{$cfg->{data}}) {
        if ($file =~ /$store\/table\//) {
            my $data            = $cfg->{data}->{$file};
            my $table           = $data->{table}->{name};
            my $method          = $class . "::" . $table;
            my $package_name    = $class . "::" . ucfirst($table);
            my $package         = "package $package_name;" . q|
            
            use base 'SweetPea::Application::Orm';
            
            sub new {
                my ($class, $orm, $table) = @_;
                my $self            = {};
                my $s               = $orm->{base};
                bless $self, $class;
                $self->{base}       = $orm;
                $self->{table}      = $table;
                $self->{where}      = {};
                $self->{order}      = [];
                $self->{key}        = '';
                $self->{collection} = [];
                $self->{cursor}     = 0;
                $self->{current}    = {};
                
                # build database objects
                my  $store  = $s->config->get('/application')->{datastore};
                my  $config = $s->config->get("/datastores/$store/table/$table");
                $self->{configuration} = $config;
                
                foreach my $column (keys %{$config->{table}->{columns}}) {
                    $self->{current}->{$column} = '';
                    my $attribute = $class . "::" . $column;
                    *{$attribute} = sub {
                        my ($self, $data) = @_;
                        if ($data) {
                            $self->{current}->{$column} = $data;
                        }
                        else {
                            return
                                $self->{current}->{$column};
                        }
                    };
                }
                
                return $self;
            }
            1;
            |;
            eval $package;
            die print $@ if $@; # debugging
            *{$method}  = sub {
                my $self = shift;
                $self->{target} = $table;
                return $package_name->new($self, $table);
            };
            # build dbo table
            
        }
    }
    $self->{base}   = $s;
    return $self;
}

=head2 next

    The next method instructs the database object to continue to the next
    row if it exists.
    
    $s->dbo->table->next;

=cut

sub next {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    my $next    = $dbo->{cursor} <= (int(@{$dbo->{collection}})-1) ? 1 : 0;
    $dbo
    ->{current} = $dbo->{collection}->[$dbo->{cursor}] || {};
                  $dbo->{cursor}++;
    
    return  $next;
}

=head2 first

    The first method instructs the database object to continue to return the first
    row in the resultset.
    
    $s->dbo->table->first;

=cut

sub first {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    $dbo->{cursor}
                = 0;
    $dbo
    ->{current} = $dbo->{collection}->[0] || {};
    
    return $dbo;
}

=head2 last

    The last method instructs the database object to continue to return the last
    row in the resultset.
    
    $s->dbo->table->last;

=cut

sub last {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    $dbo->{cursor}
                = (int(@{$dbo->{collection}})-1);
    $dbo
    ->{current} = $dbo->{collection}->[$dbo->{cursor}] || {};
    
    return $dbo;
}

=head2 collection

    The collection method return the raw resultset object.
    
    $s->dbo->table->collection;

=cut

sub collection {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    return $dbo->{collection};
}

=head2 current

    The current method return the raw row resultset object of the position in
    the resultset collection.
    
    $s->dbo->table->current;

=cut

sub current {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    return $dbo->{current};
}

=head2 clear

    The clear method empties all resultset containers.
    
    $s->dbo->table->clear;

=cut

sub clear {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    foreach my $column (keys %{$dbo->{current}}) {
        $dbo->{current}->{$column} = '';
    }
    
    $dbo->{collection} = [];
    
    return $dbo;
}

=head2 key

    The key method finds the database objects primary key if its defined.
    
    $s->dbo->table->key;

=cut

sub key {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    my $columns = $dbo->{configuration}->{table}->{columns};
    
    if ($dbo->{key}) {
        return $dbo->{key};
    }
    else {
        foreach my $column (keys %{$columns}) {
            if ($columns->{$column}->{key} == 1) {
                $dbo->{key} = $column;
                return $dbo->{key};
            }
        }
    }
    
    return 0;
}

=head2 return

    The return method queries the database for the last created or updated
    object(s) based on whether the the last statement was a create or update command.
    
    $s->dbo->table->create({})->return;
    $s->dbo->table->update({})->return;

=cut

sub return {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    my @columns = keys %{$dbo->{configuration}->{table}->{columns}};
    
    $dbo->{collection}  = 
        $s->data->select($table, \@columns, $dbo->{where}, $dbo->{order})
            ->hashes;
    
    $dbo->{cursor}      = 0;
    $dbo->{current}     =
        $dbo->{collection}->[0] if defined $dbo->{collection}->[0];
    
    return $dbo;
}

=head2 count

    The count method returns the number of items in the resultset of the
    object it's called on.
    
    my $count = $s->dbo->table->read->count;
    my $count = $s->dbo->table->count;

=cut

sub count {
    my $dbo     = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    return int(@{$dbo->{collection}});
};

=head2 create

    Caveat 1: The create method will remove the primary key if the column
    is marked as auto-incremented ...
    
    # see declaration in the table's yaml data profile
    table: 
      columns: 
        [column]: 
          auto: 1 
    
    ... this will need to be changed manually if your database doesn't
    support the auto-increment declaration, i.e. SQLite
    
    The create method creates a new entry in the datastore.
    Takes 1 arg.
    
    arg 1: hashref (SQL::Abstract fields parameter)
    
    $s->dbo->table->create({
        'column_a' => 'value_a',
    });
    
    # example of a quick copy an existing record
    my $user = $s->dbo->users->read;
    $user->first;
    $user->full_name('Copy of ' . $user->full_name);
    $user->user_name('new');
    $user->create($user->current);

    # new account id
    $user->return->id;
    # or
    $user->return;
    print $user->id;
    print $user->full_name;
=cut

sub create {
    my $dbo     = shift;
    my $input   = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    my @columns = keys %{$dbo->{configuration}->{table}->{columns}};
    my %input   = %{$input} if ref($input) eq "HASH";
    
    $dbo->clear;
    
    # process direct input
    if (%input) {
        foreach my $i (keys %input) {
            if (defined $dbo->{configuration}->{table}->{columns}->{$i}) {
                $dbo->{current}->{$i} = $input{$i};
            }
        }
    }
    else {
        die
        "Attempting to create an entry in table $table without any input.";
    }
    
    # remove primary key if auto-incremented
    my $key = $dbo->{configuration}->{table}->{columns}->{$dbo->key};
    if ($key->{auto} == 1 && $key->{required} == 0) {
        if (defined $dbo->{current}->{$dbo->key}) {
            delete $dbo->{current}->{$dbo->key};
        }
    }
    
    # insert
    $s->data->insert($table, $dbo->{current});
    
    # polish input data
    # constrain where to actual existing columns
    if ($input) {
        foreach my $i (keys %{$input}) {
            unless (defined $dbo->{current}->{$i}) {
                delete $input->{$i};
            }
        }
    }
    
    $dbo->{where} = $input;
    $dbo->{order} =
        ($key->{auto} == 1 && $key->{required} == 0) ? [$dbo->key . " desc"] : [];
    
    return $dbo;
};

=head2 read

    The read method fetches records from the datastore.
    Takes 2 arg.
    
    arg 1: hashref (SQL::Abstract where parameter) or scalar
    arg 2: arrayref (SQL::Abstract order parameter) - optional
    
    $s->dbo->table->read({
        'column_a' => 'value_a',
    });
    
    or
    
    $s->dbo->table->read(1);

=cut

sub read {
    my $dbo     = shift;
    my $where   = shift || {};
    my $order   = shift || [];
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    my @columns = keys %{$dbo->{configuration}->{table}->{columns}};
    
    # process where clause
    if ($where && ref($where) ne "HASH") {
        $where = {
            $dbo->key => $where
        };
    }
    else {
        # constrain where to actual existing columns
        if ($where) {
            foreach my $i (keys %{$where}) {
                my $table = $dbo->{configuration}->{table};
                unless (defined $table->{columns}->{$i}) {
                    delete $where->{$i};
                }
            }
        }
    }
    
    $dbo->{collection}  =
        $s->data->select($table, \@columns, $where, $order)->hashes;
    $dbo->{cursor}      = 0;
    $dbo->{current}     =
        $dbo->{collection}->[0] || {};
    
    return $dbo;
};

=head2 update

    The update method alters an existing record in the datastore.
    Takes 2 arg.
    
    arg 1: hashref (SQL::Abstract fields parameter)
    arg 2: arrayref (SQL::Abstract where parameter) or scalar - optional
    
    $s->dbo->table->update({
        'column_a' => 'value_a',
    },{
        'column_a' => '...'
    });
    
    or
    
    $s->dbo->table->update({
        'column_a' => 'value_a',
    }, 1);

=cut

sub update {
    my $dbo     = shift;
    my $input   = shift || {};
    my $where   = shift || {};
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    my @columns = keys %{$dbo->{configuration}->{table}->{columns}};
    
    $dbo->clear;
    
    # process direct input
    unless (keys %{$input}) {
        die
        "Attempting to create an entry in table $table without any input.";
    }
    
    # constrain where to actual existing columns
    if ($input) {
        foreach my $i (keys %{$input}) {
            my $table = $dbo->{configuration}->{table};
            unless (defined $table->{columns}->{$i}) {
                delete $input->{$i};
            }
        }
    }
    
    # process where clause
    if ($where && ref($where) ne "HASH") {
        $where = {
            $dbo->key => $where
        };
    }
    else {
        # constrain where to actual existing columns
        if ($where) {
            foreach my $i (keys %{$where}) {
                my $table = $dbo->{configuration}->{table};
                unless (defined $table->{columns}->{$i}) {
                    delete $where->{$i};
                }
            }
        }
    }
    
    $s->data->update($table, $input, $where);
    
    $dbo->{where} = $input;
    $dbo->{order} = [];
    
    return $dbo;
};

=head2 delete

    Takes 1 arg.
    
    arg 1: hashref (SQL::Abstract where parameter) or scalar
    
    $s->dbo->table->delete({
        'column_a' => 'value_a',
    });
    
    or
    
    $s->dbo->table->delete(1);

=cut

sub delete {
    my $dbo     = shift;
    my $where   = shift;
    my $self    = $dbo->{base};
    my $table   = $dbo->{table};
    my $s       = $self->{base};
    
    # process where clause
    if ($where && ref($where) ne "HASH") {
        $where = {
            $dbo->key => $where
        };
    }
    else {
        # constrain where to actual existing columns
        if ($where) {
            foreach my $i (keys %{$where}) {
                my $table = $dbo->{configuration}->{table};
                unless (defined $table->{columns}->{$i}) {
                    delete $where->{$i};
                }
            }
        }
    }
    
    $s->data->delete($table, $where);
    
    return $dbo;
};

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Orm
