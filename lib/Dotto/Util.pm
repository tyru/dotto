#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use YAML ();
use File::Path qw(mkpath);
use File::Basename qw(dirname);
use File::Spec::Functions qw(canonpath);
use File::Copy::Recursive qw(rcopy);
use File::Find qw();

use base qw(Exporter);
our @EXPORT_OK = qw(
    chown_user
    determine_user
    determine_home
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
    if (-e $dest) {
        die "install(): destination path must not exists.";
    }

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
        die "install_symlink(): Your platform does not support symbolic link.";
    }
    if (_same_file($src, $dest)) {
        warn "Skip same file: $src, $dest\n";
        return;
    }
    if (not -e $src) {
        die "$src must exists.";
    }
    if (-e $dest) {
        die "$dest must not exists.";
    }

    symlink $src, $dest;
    chown_user($dest, $user);
}

sub chown_user {
    my ($path, $username) = @_;

    return if $^O eq 'MSWin32';
    return unless -e $path;

    my ($uid, $gid) = (getpwnam $username)[2,3];
    die "$username not in passwd file" unless defined $uid;

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
    die "$config_file:$!" unless -f $config_file;
    YAML::LoadFile($config_file);
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
        *determine_user = sub {
            unless (exists $ENV{USERNAME}) {
                die "error: environment variable 'HOME' is not set.";
            }
            $ENV{USERNAME};
        };
        *determine_home = sub {
            unless (exists $ENV{HOME}) {
                die "error: environment variable 'HOME' is not set.";
            }
            $ENV{HOME};
        };
        *get_home_from_user = sub {
            unless (exists $ENV{HOME}) {
                die "error: environment variable 'HOME' is not set.";
            }
            return $ENV{HOME};
        };
        *get_user_from_home = sub {
            my ($home) = @_;

            die "get_user_from_home(): not implemented on your platform.";
        };
    }
    else {
        *determine_user = sub {
            unless (exists $ENV{USER}) {
                die "error: environment variable 'USER' is not set.";
            }
            $ENV{USER};
        };
        *determine_home = sub {
            my $user = determine_user();

            my $home;
            if ($user eq 'root') {
                $home = "/root";
            }
            else {
                $home = catfile("/home", $user);
            }
            die "$home:$!" unless -d $home;

            $home;
        };
        *get_home_from_user = sub {
            my ($username) = @_;

            if ($username eq 'root') {
                return "/root";
            }
            else {
                return catfile("/home", $username);
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

sub determine_user_and_home {
    (determine_user(), determine_home());
}


__END__

=head1 NAME

    Util.pm - NO DESCRIPTION YET.


=head1 SYNOPSIS


=head1 OPTIONS


=head1 AUTHOR

tyru <tyru.exe@gmail.com>
