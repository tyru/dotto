#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use YAML ();
use File::Path qw(rmtree mkpath);
use File::Basename qw(dirname);
use File::Spec::Functions qw(canonpath);
use File::Copy::Recursive qw(rcopy);
use File::Find qw();

use base qw(Exporter);
our @EXPORT_OK = qw(
    chown_user
    determine_user_and_home
    get_home_from_user
    get_user_from_home
    install
    install_symlink
    load_config
);



sub install {
    # install $src to $dest as $user.
    my ($src, $dest, $user) = @_;

    if (_same_file($src, $dest)) {
        warn "Skip same file: $src, $dest\n";
        return;
    }

    unless (-e $src) {
        warn "$src:$!\n";
        return;
    }
    # Delete destination
    # TODO: Use rsync?
    rmtree($dest);

    unless (-d (my $dir = dirname($dest))) {
        mkpath $dir or die "$dir: $!";
    }
    # rcopy() preserves attributes (permission,mtime,symlink,etc.).
    rcopy($src, $dest);
    chown_user($dest, $user);
}

sub install_symlink {
    my ($src, $dest, $user) = @_;

    if ($^O =~ /\A(MSWin32|msys|cygwin)\Z/) {
        die "install_symlink(): Your platform does not support symbolic link.\n";
    }
    if (_same_file($src, $dest)) {
        warn "Skip same file: $src, $dest\n";
        return;
    }
    if (-e $dest) {
        die "$dest must not exists.\n";
    }

    symlink $src, $dest;
    chown_user($dest, $user);
}

sub chown_user {
    my ($path, $username) = @_;

    my ($uid, $gid) = (getpwnam $username)[2,3];
    die "$username not in passwd file\n" unless defined $uid;

    if (-f $path) {
        chown $uid, $gid, $path;
    }
    else {
        # chown recursively.
        File::Find::find({
            wanted => sub {
                chown $uid, $gid, $_;
            },
        }, $path);
    }
}

sub _same_file {
    my ($f1, $f2) = @_;
    # TODO: broken symlinks
    for ($f1, $f2) {
        $_ = readlink while -l;
    }
    canonpath($f1) eq canonpath($f2);
}

sub load_config {
    my ($config_file) = @_;
    die "$config_file:$!\n" unless -f $config_file;
    my $c = YAML::LoadFile($config_file);
    $c->{directory} = $ENV{DOTTO_DIRECTORY} if !exists $c->{directory} && exists $ENV{DOTTO_DIRECTORY};
    _validate_prereq_config($c);
    $c;
}

sub _validate_prereq_config {
    my ($c) = @_;

    unless (exists $c->{directory}) {
        die "'directory' is not in config.\n";
    }
}

sub convert_filename {
    my ($c, $filename) = @_;
    if (exists $c->{os_files}{$^O}{$filename}) {
        return $c->{os_files}{$^O}{$filename}
    }
    else {
        $filename;
    }
}

BEGIN {
    if ($^O eq 'MSWin32') {
        *determine_user_and_home = sub {
            my ($user, $home);

            unless (exists $ENV{HOME}) {
                die "Please set environment variable 'HOME'.";
            }
            unless (-d $ENV{HOME}) {
                die "%HOME% ($ENV{HOME}) is not accessible.";
            }
            $home = $ENV{HOME};
            $user = $ENV{USERNAME};

            unless (-d $home) {
                die "$home:$!"
            }

            ($user, $home);
        };
        *get_home_from_user = sub {
            unless (exists $ENV{HOME}) {
                die "Please set environment variable 'HOME'.";
            }
            return $ENV{HOME};
        };
        *get_user_from_home = sub {
            my ($home) = @_;

            die "get_user_from_home(): not implemented on your platform.";
        };
    }
    else {
        *determine_user_and_home = sub {
            my ($user, $home);

            unless (exists $ENV{USER}) {
                die "Please set environment variable 'USER'.";
            }
            $user = $ENV{USER};

            if ($user eq 'root') {
                $home = "/root";
            }
            else {
                $home = "/home/$user";
            }

            unless (-d $home) {
                die "$home:$!"
            }

            ($user, $home);
        };
        *get_home_from_user = sub {
            my ($username) = @_;

            if ($username eq 'root') {
                return "/root";
            }
            else {
                return "/home/$username";
            }
        };
        *get_user_from_home = sub {
            my ($home) = @_;

            if (canonpath($home) eq canonpath('/root')) {
                return "root";
            }
            elsif (dirname($home) eq '/home') {
                return basename $home;
            }
            else {
                die "invalid home directory '$home'.";
            }

        };
    }
}


__END__

=head1 NAME

    Util.pm - NO DESCRIPTION YET.


=head1 SYNOPSIS


=head1 OPTIONS


=head1 AUTHOR

tyru <tyru.exe@gmail.com>
