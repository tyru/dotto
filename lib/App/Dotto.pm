package App::Dotto;

use 5.008_001;
use strict;
use warnings;
use utf8;
use Carp;
use Getopt::SubCommand;
use File::Basename qw/dirname basename/;
use Perl6::Say;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile rel2abs);

use App::Dotto::Util qw/get_user_from_home get_home_from_user determine_user_and_home load_config convert_filename install_symlink supported_symlink install hashize_arg_config/;

our $VERSION = eval '0.001';
my $ARGPARSER;


sub run {
    $ARGPARSER ||= Getopt::SubCommand->new(
        usage_name => 'dotto',
        usage_version => $VERSION,
        global_opts => {
            username => {
                name => [qw/u username/],
                attribute => '=s',
            },
            config_file => {
                name => [qw/c config-file/],
                attribute => '=s',
            },
            verbose => {
                name => [qw/v verbose/],
            },
            arg_config => {
                name => 'C',
                attribute => '=s@',
            },
        },
        commands => {
            delete => {
                sub => \&command_delete,
                options => {
                    force => {
                        name => [qw/f force/],
                        usage => 'Do delete (if not given, "delete" does not do anything).',
                        required => 1,
                    },
                    convert_filename => {
                        name => [qw/O os-files/],
                    },
                },
                usage => 'Delete dotfiles.',
                auto_help_opt => 1,
            },
            install => {
                sub => \&command_install,
                options => {
                    force => {
                        name => [qw/f force/],
                    },
                    extract => {
                        name => [qw/x extract/],
                    },
                    dry_run => {
                        name => 'dry-run',
                    },
                    dereference => {
                        name => [qw/L dereference/],
                    },
                    symbolic => {
                        name => [qw/s symbolic/],
                    },
                    directory => {
                        name => [qw/d directory/],
                        attribute => '=s',
                    },
                },
                usage => 'Copy dotfiles from directory to directory.',
                auto_help_opt => 1,
            },
            version => {
                sub => \&command_version,
                usage => 'Show dotto version.',
                auto_help_opt => 1,
            },
        },
    );

    my $command = $ARGPARSER->get_command;
    if ($ARGPARSER->can_invoke_command($command)) {
        $ARGPARSER->invoke_command($command);
    }
    else {
        if (defined $command) {
            warn "Unknown command: $command\n\n";
            sleep 1;
        }
        $ARGPARSER->invoke_command('help');
    }
}

sub command_delete {
    my ($global_opts, $command_opts, $command_args) = @_;

    my $username = $global_opts->{username};
    my $config_file = $global_opts->{config_file};
    my $verbose = $global_opts->{verbose};
    my $arg_config = $global_opts->{arg_config};

    my $home = $command_opts->{home};
    my $convert_filename = $command_opts->{convert_filename};

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

sub command_install {
    my ($global_opts, $command_opts, $command_args) = @_;

    if ($command_opts->{symbolic}) {
        command_install_symlinks(@_);
    }
    else {
        command_install_files(@_);
    }
}
sub command_install_files {
    my ($global_opts, $command_opts, $command_args) = @_;

    my $home = $command_opts->{home};
    my $username = $command_opts->{username};
    my $config_file = $command_opts->{config_file};
    my $verbose = $command_opts->{verbose};
    my $force = $command_opts->{force};
    my $extract = $command_opts->{extract};
    my $dry_run = $command_opts->{dry_run};
    my $dereference = $command_opts->{dereference};
    my $directory = $command_opts->{directory};
    my $arg_config = $command_opts->{arg_config};

    if (defined $home) {
        $username = get_user_from_home $home;
        unless (defined $username) {
            die "error: can't determine username "
                . "from home directory on your platform.";
        }
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

    if (!defined $directory && exists $c->{directory}) {
        $directory = $c->{directory};
    }
    unless (defined $directory) {
        warn "error: directory is undefined: please specify with -d {directory}\n";
        sleep 1;
        $ARGPARSER->show_command_usage();
        exit 1;    # this will be never reached.
    }

    # Install dotfiles to $home.
    for my $file (@files) {
        my ($src, $dest);
        if ($extract) {
            $src  = catfile($directory, $file);
            $dest = catfile($home, convert_filename $c, $file);
        }
        else {
            $src  = catfile($home, $file);
            $dest = catfile($directory, $file);
        }

        if ($dry_run || $verbose) {
            say "Copy $src -> $dest";
            next if $dry_run;
        }

        if (-e $dest) {
            unless ($force) {
                warn "warning: sync-dotfiles: File exists '$dest'.\n";
                next;
            }
            rmtree($dest);
        }

        install($src, $dest, $username, {dereference => $dereference});
    }

    unless ($extract) {
        for my $file (@{$c->{ignore_files}}) {
            my $dest = catfile($directory, convert_filename $c, $file);
            if (-e $dest) {
                rmtree($dest);
            }
        }
    }
}
sub command_install_symlinks {
    my ($global_opts, $command_opts, $command_args) = @_;

    my $username = $global_opts->{username};
    my $config_file = $global_opts->{config_file};
    my $verbose = $global_opts->{verbose};
    my $arg_config = $global_opts->{arg_config};

    my $home = $command_opts->{home};
    my $directory = $command_opts->{directory};
    my $force = $command_opts->{force};

    unless (supported_symlink()) {
        die "error: your platform does not support symbolic link.\n";
    }

    if (defined $home) {
        $username = get_user_from_home $home;
        unless (defined $username) {
            die "error: can't determine username "
                . "from home directory on your platform.";
        }
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
    my @files = map { convert_filename $c, $_ } @{$c->{files}};

    if (!defined $directory && exists $c->{directory}) {
        $directory = $c->{directory};
    }
    unless (defined $directory) {
        warn "error: directory is undefined: please specify with -d {directory}\n";
        sleep 1;
        $ARGPARSER->show_command_usage();
        exit 1;    # this will be never reached.
    }

    # Install symbolic links.
    for my $file (@files) {
        my $src  = rel2abs(catfile($directory, $file));
        my $dest = catfile($home, $file);

        if (-e $dest) {
            unless ($force) {
                warn "warning: install-symlinks: File exists '$dest'.\n";
                next;
            }
            rmtree($dest);
        }

        say("$src -> $dest") if $verbose;
        install_symlink $src, $dest, $username;
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
