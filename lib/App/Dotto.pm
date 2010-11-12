package App::Dotto;
use strict;
use warnings;
use utf8;
use Carp;
use Getopt::SubCommand;
use File::Basename qw/basename/;
use Perl6::Say;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile);

use App::Dotto::Util qw/get_home_from_user determine_user_and_home load_config convert_filename hashize_arg_config/;

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
                    config_file => {
                        name => [qw/c config-file/],
                        attribute => '=s',
                    },
                    verbose => {
                        name => [qw/v verbose/],
                    },
                    convert_filename => {
                        name => [qw/O os-files/],
                    },
                    arg_config => {
                        name => 'C',
                        attribute => '=s@',
                    },
                },
                usage => 'Delete dotfiles.',
                auto_help_opt => 1,
            },
            version => {
                sub => \&command_version,
                usage => 'Show version',
                auto_help_opt => 1,
            },
        },
    );
    $ARGPARSER->invoke_command(fallback => 'help');
}

sub command_delete {
    my ($global_opts, $command_opts, $command_args) = @_;

    my $home = $command_opts->{home};
    my $username = $command_opts->{username};
    my $config_file = $command_opts->{config_file};
    my $verbose = $command_opts->{verbose};
    my $convert_filename = $command_opts->{convert_filename};
    my $arg_config = $command_opts->{arg_config};

    if (defined $home) {
        # nop
    }
    elsif (defined $username) {
        $home = get_home_from_user $username;
    }
    else {
        ($username, $home) = determine_user_and_home;
    }

    if (!defined $config_file && exists $ENV{DOTTORC}) {
        $config_file = $ENV{DOTTORC};
    }
    unless (defined $config_file) {
        die "error: specify config file with -c option.\n";
    }
    my $c = load_config($config_file);
    if (ref $arg_config eq 'ARRAY' && @$arg_config) {
        %$c = (%$c, %{hashize_arg_config @$arg_config});
    }

    my @files = @{$c->{files}};
    if ($convert_filename) {
        @files = map { convert_filename $c, $_ } @files;
    }
    for my $file (@files) {
        $file  = catfile($home, $file);
        print "Deleting $file..." if $verbose;
        rmtree($file);
        print "done.\n" if $verbose;
    }
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
