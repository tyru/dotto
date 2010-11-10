package App::Dotto;
use strict;
use warnings;
use utf8;
use Carp;
use Getopt::SubCommand;
use File::Basename qw/basename/;

our $VERSION = eval '0.001';
my $ARGPARSER;


sub run {
    $ARGPARSER ||= Getopt::SubCommand->new(
        usage_name => 'dotto',
        usage_version => $VERSION,
        commands => {
            delete => {
                sub => \&command_delete,
                options => {
                    username => {
                        name => [qw/u username/],
                        attribute => '=s',
                    },
                    force => {
                        name => [qw/f force/],
                        usage => 'Do delete (if not given, "delete" does not do anything).',
                        required => 1,
                    },
                },
                usage => 'Delete dotfiles.',
            },
        },
    );
    $ARGPARSER->invoke({fallback => 'help'});
}

sub command_delete {
    my ($global_opts, $command_opts, $command_args) = @_;
    # TODO
}




1;
__END__

=head1 NAME

    App::Dotto - NO DESCRIPTION YET.


=head1 SYNOPSIS


=head1 OPTIONS

