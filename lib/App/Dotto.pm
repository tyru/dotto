package App::Dotto;
use strict;
use warnings;
use utf8;
use Carp;
use Getopt::SubCommand;
use File::Basename qw/basename/;
use Perl6::Say;

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
            version => {
                sub => \&command_version,
                usage => 'Show version',
            },
        },
    );
    $ARGPARSER->invoke_command(fallback => 'help');
}

sub command_delete {
    my ($global_opts, $command_opts, $command_args) = @_;
    # TODO
}

sub command_version {
    say "v$VERSION";
}



1;
__END__

=head1 NAME

    App::Dotto - dotfiles utilities


=head1 SYNOPSIS

    $ dotto copy          # Copy dotfiles to specified directory in config file.
    $ dotto copy    -f    # Same as above but overwrite if the file exists.
                          # (PLEASE CAREFULLY DO THIS!)
    $ dotto copy -s       # Copy dotfiles' symlinks.
    $ dotto copy -s -f    # Same as above but overwrite if the file exists.
                          # (PLEASE CAREFULLY DO THIS!)
    $ dotto install       # Install dotfiles to $HOME directory.
    $ dotto install    -f # Same as above but overwrite if the file exists.
                          # (PLEASE CAREFULLY DO THIS!)
    $ dotto install -s    # Install dotfiles' symlinks to $HOME directory.
    $ dotto install -s -f # Same as above but overwrite if the file exists.
                          # (PLEASE CAREFULLY DO THIS!)
    $ dotto delete -f     # Delete all dotfiles (PLEASE CAREFULLY DO THIS!).
    $ dotto help          # Show this help text.
    $ dotto help copy     # Show the help text of "copy".

=head1 GLOBAL OPTIONS

=over

=item -h, --help

=item -v, --version

=item -c, --config-file {file}

=item -C attr=value

Modify misc. values from arguments, not from config file.

=back

=head1 COMMANDS

=over

=item install [-s|--symbolic] [-f|--force]

Copy dotfiles to .
if -s option was given, install symlinks.
If -f option was given, overwrite if file exists.

=item delete [-f|--force]

Delete all dotfiles in home directory.
You must specify -f option for safety.

=item help [-v|--verbose]

Show the summary of dotto.
It means showing this help text as you see.

=item help [-v|--verbose] COMMAND

Show the help text of specified command.

=item version

Show the version of dotto.

=back
