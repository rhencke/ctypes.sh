#!/bin/bash
#
# simple sqlite3 interface for bash
# lovingly modelled after https://www.sqlite.org/tclsqlite.html
#

source ctypes.sh

dlopen libsqlite3.so

declare -A _connections

trap __sqlite3_cleanup EXIT

sqlite3() {
    if [[ $# -ne 2 || ! "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ || -z "$2" ]]; then
        echo usage: "$0" dbcmd database-name >&2
        exit 1
    fi
    # TODO add db to connections
    local id="$1" name="$2"
    eval "$id() { __sqlite3_entry $id \"\$@\" ;}"
}

__sqlite3_cleanup() {
    : # TODO
}

__sqlite3_entry() {
    local id="$1" method="_sqlite3_$2" opts=("${@:3}")
    if ! declare -f "$method" >/dev/null; then
        echo "command not defined" # TODO better
        echo "usage: $id <command> [args]" >&2
        exit 1
    fi
    $method $id "${opts[@]}"
}

_sqlite3_eval() {
    local id="$1" sql="$2" fn="$3"
    if ! test -z "$fn"; then
        eval "$fn() { echo bla bla; unset -f $fn; false; }"
    fi
}

# Example:
set -e

sqlite3 mydb :memory:
mydb eval "CREATE TABLE t1(a int, b text)"
mydb eval "INSERT INTO t1 VALUES(3,'howdy!')"
mydb eval "INSERT INTO t1 VALUES(2,'goodbye')"
mydb eval "INSERT INTO t1 VALUES(1,'hello')"
mydb eval "SELECT * FROM t1 ORDER BY a" _; while _; do
    echo "a=$a" "b=$b"
done