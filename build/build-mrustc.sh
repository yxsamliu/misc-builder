#!/bin/bash

## $1 : version, like v0.9 (tag) or master (branch)
## $2 : destination: a directory or S3 path (eg. s3://...)

set -exu

ROOT=$PWD
VERSION=$1

FULLNAME=mrustc-${VERSION}-$(date +%Y%m%d)

OUTPUT=${ROOT}/${FULLNAME}.tar.xz
S3OUTPUT=
if [[ $2 =~ ^s3:// ]]; then
    S3OUTPUT=$2
else
    if [[ -d "${2}" ]]; then
        OUTPUT=$2/${FULLNAME}.tar.xz
    else
        OUTPUT=${2-$OUTPUT}
    fi
fi

OUTPUT=$(realpath "${OUTPUT}")

git clone --depth 1 --single-branch -b "${VERSION}" https://github.com/thepowersgang/mrustc.git
cd mrustc

# build mrustc
make RUSTCSRC

# build needed libs
make -f minicargo.mk LIBS

# don't need debug symbols, intermediate c or txt
rm -f bin/*.debug
find output/ \( -name '*_dbg.txt' -or -name '*.c' -or -name '*.txt' \) -exec rm {} \;

# Don't try to compress the binaries as they don't like it

export XZ_DEFAULTS="-T 0"
tar Jcf "${OUTPUT}" ./bin/ ./output/

if [[ -n "${S3OUTPUT}" ]]; then
    s3cmd put --rr "${OUTPUT}" "${S3OUTPUT}"
fi
