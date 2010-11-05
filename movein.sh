#!/bin/sh
# Original script is from oreilly book "Linuxサーバ Hacks" (Linux Server Hacks)


# Fill in for default value.
server=''
movein_dir=''

die () {
    echo "$*" >&2
    exit 1
}

usage () {
    die "Usage: `basename $0` {hostname} [{dir}]"
}


case $# in
    1)
        server="$1"
        ;;
    2)
        server="$1"
        movein_dir="$2"
        ;;
    *) usage
        ;;
esac

if [ -z "$server" -o -z "$movein_dir" ]; then
    usage
fi
cd "$movein_dir" && tar zhcf - . | ssh "$server" "tar zpvxf -"
