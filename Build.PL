use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bundle::Dotto',
    license             => 'perl',
    dist_author         => 'tyru <tyru.exe@gmail.com>',
    dist_version        => '0.01',
    requires => {
        'Test::More' => 0,
        'Test::Pod' => 0,
        'Perl6::Say' => 0,
        'Perl6::Slurp' => 0,
        'File::Copy::Recursive' => 0,
        'File::HomeDir' => 0,
        'YAML' => 0,
    },
);

$builder->create_build_script;

