use strict;
use warnings;
use inc::Module::Install;
  
# Define metadata
name           'SweetPea-Application';
all_from       'lib/SweetPea/Application.pm';

# Specific dependencies
requires       'SweetPea'               => '2.35';
requires       'Config::Any'            => '0';
requires       'YAML::Syck'             => '0';
requires       'Template'               => '0';
requires       'SQL::Translator'        => '0';
requires       'File::Find'             => '0';
requires       'File::ShareDir'         => '0';
requires       'File::Util'             => '0';
requires       'Exception::Handler'     => '0';
requires       'DBIx::Simple'           => '0';
requires       'SQL::Abstract'          => '0';
requires       'SQL::Interp'            => '0';
requires       'Email::Stuff'           => '0';
requires       'Data::FormValidator'    => '0';
test_requires  'Test::More'             => '0.42';

install_script 'script/sweetpea-app';
install_share  'script/sweetpea-app-templates';

WriteAll;