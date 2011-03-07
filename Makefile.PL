use strict;
use warnings;
use inc::Module::Install;

name 'App-Dotto';
license 'perl';
perl_version '5.8.1';
author 'tyru <tyru.exe@gmail.com>';
version '0.01';

test_requires 'Test::More';
test_requires 'Test::Pod';
requires 'Perl6::Say';
requires 'Perl6::Slurp';
requires 'File::Copy::Recursive';
requires 'File::HomeDir';
requires 'YAML';

WriteAll;
