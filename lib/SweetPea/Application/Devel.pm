package SweetPea::Application::Devel;

use warnings;
use strict;

use Cwd;
use DBI;
use SweetPea 2.34;
use SweetPea::Application::Config;
use Exception::Handler;
use File::ShareDir ':ALL';
use File::Util;
use SQL::Translator;
use SQL::Translator::Schema::Field;
use Template;

=head1 NAME

SweetPea::Application::Devel - Development routines for SweetPea-Application.

=cut

=head1 SYNOPSIS

    ... from inside SweetPea::Application or a Controller;
    $s->devel->create_db('dbi:mysql:database', 'root');

=head1 METHODS

=head2 new
=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->{file} = File::Util->new();
    $self->{base} = SweetPea->new;
    $self->{base}->{store}->{application}->{path} = getcwd;
    $self->{conf} = SweetPea::Application::Config->new($self->{base});
    $self->{temp} = Template->new(
        EVAL_PERL => 1,
        ABSOLUTE  => 1,
        ANYCASE   => 1
    );
    $self->{dbit} = {
        'db2'     => 'DB2',
        'mysql'   => 'MySQL',
        'oracle'  => 'Oracle',
        'pg'      => 'PostgrSQL',
        'odbc'    => 'SQLServer',
        'sqlite'  => 'SQLite',
        'sybase'  => 'Sybase'
    };
    $self->{error}= Exception::Handler->new;
    return $self;
}

sub _translate_database_type {
    my $self = shift;
    my $dsn  = shift;
    my $s    = $self->{base};
       $dsn  =~ s/dbi\:([a-zA-Z0-9\-\_]+)\:/dbi\:$1\:/ if $dsn =~ /\:/;
    return $self->{dbit}->{lc($dsn)};
}

=head2 create_database
=cut

sub create_database {
    my $self             = shift;
    my @dsn              = @_;
    my $s                = $self->{base};
    my ($scheme, $driver, @trash) = DBI->parse_dsn($dsn[0]);
    my $translator       = SQL::Translator->new(
     debug               => 0,
     add_drop_table      => 0,
     quote_table_names   => 1,
     quote_field_names   => 1,
     validate            => 1,
     no_comments         => 1,
     producer            => $self->_translate_database_type($driver)
    );

    my $schema     =  $translator->schema(
          name     => $scheme,
      );
    
    my $table      = $schema->add_table( name => 'users' );
    $table->add_field(
         name      => 'id',
         data_type => 'integer',
         size      => 11,
         table     => $table,
         
         is_auto_increment => 1,
         is_primary_key    => 1
    );
    $table->add_field(
         name      => 'name',
         data_type => 'varchar',
         size      => 255,
         table     => $table,
         
         is_nullable       => 0
    );
    $table->add_field(
         name      => 'email',
         data_type => 'varchar',
         size      => 255,
         table     => $table,
         
         is_nullable       => 0
    );
    $table->add_field(
         name      => 'login',
         data_type => 'varchar',
         size      => 255,
         table     => $table,
         is_unique => 1,
         
         is_nullable       => 0
    );
    $table->add_field(
         name      => 'password',
         data_type => 'varchar',
         size      => 255,
         table     => $table,
         
         is_nullable       => 0
    );
    $table->add_field(
         name      => 'status',
         data_type => 'integer',
         size      => 1,
         table     => $table,
         
         is_nullable       => 0
    );
    $table->primary_key('id');
    
    $table         = $schema->add_table( name => 'permissions' );
    $table->add_field(
         name      => 'id',
         data_type => 'integer',
         size      => 11,
         table     => $table,
         
         is_auto_increment => 1,
         is_primary_key    => 1
    );
    $table->add_field(
         name      => 'user',
         data_type => 'integer',
         size      => 11,
         table     => $table,
         
         is_nullable       => 0
    );
    $table->add_field(
         name      => 'role',
         data_type => 'varchar',
         size      => 255,
         table     => $table,
         
         is_nullable       => 1
    );
    $table->add_field(
         name      => 'permission',
         data_type => 'varchar',
         size      => 255,
         table     => $table,
         
         is_nullable       => 1
    );
    $table->add_field(
         name      => 'operation',
         data_type => 'varchar',
         size      => 255,
         table     => $table,
         
         is_nullable       => 1
    );
    $table->primary_key('id');
    my  $db = DBI->connect(@dsn) or exit print "\n", $self->{error}->trace(($@));
    if ($db) {
        # hack
        my ($scheme, $driver, @trash)
                         = DBI->parse_dsn($dsn[0]);
        
        for ($translator->translate(
                to => $self->_translate_database_type($driver))) {
            $db->do($_) or exit print "\n", $self->{error}->trace(($@));
        }
    }
    
    # auto-update
    $self->update_database(@dsn);
}

=head2 update_database
=cut

sub update_database {
    my $self             = shift;
    my @dsn              = @_;
    my $s                = $self->{base};
    
    my ($scheme, $driver, @trash)
                         = DBI->parse_dsn($dsn[0]);
    
    my  $db              = DBI->connect(@dsn)
        or exit print "\n", $self->{error}->trace(($@));
    
    my $translator       = SQL::Translator->new(
             parser      => 'DBI',
             parser_args => {
             dsn         => $dsn[0],
             db_user     => $dsn[1],
             db_password => $dsn[2],
             },
             producer    => $self->_translate_database_type($driver)
    ); $translator->translate;

    my $schema           =  $translator->schema;
    
    my @tables           = $schema->get_tables
        or exit print "\n", $self->{error}->trace(($translator->error));
        
    # update datastore config
    my $datastore = $self->{conf}->get('/datastores');
    
    $datastore->{datastores}->{development} = {
        dsn      => $dsn[0],
        username => $dsn[1],
        password => $dsn[2]
    };
    
    $self->{conf}->set('/datastores');
    
    my $table_configuration_template = {
        table     => {
            'name'    => '',
            'columns' => {}
        },
        form      => {
            'name'          => '',
            'fields'        => {},
            'validation'    => {}
        },
        grid      => {
            'name'    => '',
            'columns' => {}
        }
    };
    
    # remove placeholders
    unlink "sweet/configuration/datastores/development/empty";
    unlink "sweet/configuration/datastores/production/empty";
    
    foreach my $table (@tables) {
        my ($production, $development);
        
        my $name = $table->name;
        # get base table configuration data
        if (-e "sweet/configuration/datastores/development/table/$name.yml") {
            $development =
            $self->{conf}->get("/datastores/development/table/$name");
        }
        else {
            $development = $table_configuration_template;
            $self->{conf}->set(
                "/datastores/development/table/$name",
                $development
            );
        }
        if (-e "sweet/configuration/datastores/production/table/$name.yml") {
            $production =
            $self->{conf}->get("/datastores/production/table/$name");
        }
        else {
            $production = $table_configuration_template;
            $self->{conf}->set(
                "/datastores/production/table/$name",
                $production
            );
        }
        $development->{table}->{name} = $name;
        $development->{form}->{name}  = $name . "_form"
            if $development->{form}->{name} eq '';
        $development->{grid}->{name}  = $name . "_grid"
            if $development->{grid}->{name} eq '';
            
        $production->{table}->{name}  = $name;
        $production->{form}->{name}   = $name . "_form"
            if $production->{form}->{name} eq '';
        $production->{grid}->{name}   = $name . "_grid"
            if $production->{grid}->{name} eq '';
        
        $development->{table}->{columns}    = {}
            unless defined $development->{table}->{columns};
        $development->{grid}->{columns}     = {}
            unless defined $development->{grid}->{columns};
        $development->{form}->{fields}      = {}
            unless defined $development->{form}->{fields};
        $development->{form}->{validation}  = {}
            unless defined $development->{form}->{validation};
        $development->{form}->{validation}->{optional}  = []
            unless defined $development->{form}->{validation}->{optional};
        $development->{form}->{validation}->{required}  = []
            unless defined $development->{form}->{validation}->{required};
        $production->{table}->{columns}     = {}
            unless defined $production->{table}->{columns};
        $production->{grid}->{columns}      = {}
            unless defined $production->{grid}->{columns};
        $production->{form}->{fields}       = {}
            unless defined $production->{form}->{fields};
        $production->{form}->{validation}   = {}
            unless defined $production->{form}->{validation};
        $production->{form}->{validation}->{optional}   = []
            unless defined $production->{form}->{validation}->{optional};
        $production->{form}->{validation}->{required}   = []
            unless defined $production->{form}->{validation}->{required};
        
        # update table configuration data
        my @fields = $table->get_fields;
        foreach my $field (@fields) {
            my $name = $field->name;
            if ($name) {
                my $field_label     = ucfirst $name;
                    $field_label    =
                    join(" ", map {ucfirst $_} split /_/, $field_label);
                    
                # build validation hash
                unless (defined $development->{form}->{validation} && keys %{$development->{form}->{validation}} > 0) {
                    if ($field->is_nullable) {
                        push @{$development->{form}->{validation}->{optional}},
                            $name unless grep { $_ eq $name} @{$development->{form}->{validation}->{optional}};
                        push @{$production->{form}->{validation}->{optional}},
                            $name unless grep { $_ eq $name} @{$production->{form}->{validation}->{optional}};
                    }
                    else {
                        push @{$development->{form}->{validation}->{required}},
                            $name unless grep { $_ eq $name} @{$development->{form}->{validation}->{required}};
                        push @{$production->{form}->{validation}->{required}},
                            $name unless grep { $_ eq $name} @{$production->{form}->{validation}->{required}};
                    }
                }
                
                $development->{table}->{columns}->{$name} = {
                    'type'      => $field->data_type,
                    'size'      => $field->size,
                    'value'     => ( lc($field->default_value) eq 'null' ?
                                    '' : $field->default_value ),
                    'required'  => $field->is_nullable,
                    'key'       => $field->is_primary_key,
                    'auto'      => $field->is_auto_increment,
                    'unique'    => $field->is_unique
                };
                $development->{form}->{fields}->{$name} = {
                    name        => $name,
                    length      => $field->size,
                    value       => $field->default_value,
                    maps_to     => $name,
                    label       => $field_label,
                    type        => 'text',
                    input_via   => 'post',
                    attributes  => {
                        class   => 'form_field'
                    }
                } unless defined $development->{form}->{fields}->{$name};
                $development->{grid}->{columns}->{$name} = {
                    attributes  => {
                        class   => 'grid_column'
                    },
                    maps_to     => $name,
                    value       => $field->default_value,
                    name        => $name,
                    label       => $field_label
                } unless defined $development->{grid}->{columns}->{$name};
                
                $production->{table}->{columns}->{$name} = {
                    'type'      => $field->data_type,
                    'size'      => $field->size,
                    'value'     => ( lc($field->default_value) eq 'null' ?
                                    '' : $field->default_value ),
                    'required'  => $field->is_nullable,
                    'key'       => $field->is_primary_key,
                    'auto'      => $field->is_auto_increment,
                    'unique'    => $field->is_unique
                };
                $production->{form}->{fields}->{$name} = {
                    name        => $name,
                    length      => $field->size,
                    value       => $field->default_value,
                    maps_to     => $name,
                    label       => $field_label,
                    type        => 'text',
                    input_via   => 'post',
                    attributes  => {
                        class   => 'form_field'
                    }
                } unless defined $production->{form}->{fields}->{$name};
                $production->{grid}->{columns}->{$name} = {
                    attributes  => {
                        class   => 'grid_column'
                    },
                    maps_to     => $name,
                    value       => $field->default_value,
                    name        => $name,
                    label       => $field_label
                } unless defined $production->{grid}->{columns}->{$name};
            }
        }
        
        $development->{form}->{validation}->{constraint_methods}    = {}
            unless defined $development->{form}->{validation}->{constraint_methods};
        $production->{form}->{validation}->{constraint_methods}     = {}
            unless defined $production->{form}->{validation}->{constraint_methods};
        
        # save new configuration data
        $self->{conf}->set(
            "/datastores/development/table/$name",
            $development
        );
        $self->{conf}->set(
            "/datastores/production/table/$name",
            $production
        );
    }
}

=head2 create_models
=cut

sub create_models {
    my $self = shift;
    my $s    = $self->{base};

}

=head2 update_models
=cut

sub update_models {
    my $self = shift;
    my $s    = $self->{base};

}

=head2 process_template
=cut

sub process_template {
    my ($self, $file, $vars) = @_;
    my $s    = $self->{base};
    my $t    = $self->{temp};
    my $content;
       $file = dist_file('SweetPea-Application', $file);
       $t->process($file, $vars, \$content);
    return $content;
}

=head2 file_content
=cut

sub file_content {
    my ($self, $file) = @_;
    my $s    = $self->{base};
    my $t    = $self->{temp};
       $file = dist_file('SweetPea-Application', $file);
    my $content = $s->file('<', $file);
    return $content;
}

=head2 make_file
=cut

sub make_file {
    my $self = shift;
    my @data = @_;
    my $s    = $self->{base};
    $self->{file}->write_file(@data) unless -e $data[1];
}

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=cut

1; # End of SweetPea::Application::Devel
