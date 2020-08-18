#!/bin/bash

release=1b2
release_dir="sptools-r$release"
base="$release_dir/sptools"

mkdir -p $base
mkdir -p $base/resources
mkdir -p $base/src

cp ChangeLog $base
cp LICENSE $base
cp README.md $base
cp spflow.bas $base
cp sptest.bas $base
cp sptrans.bas $base
cp -R resources/* $base/resources
cp -R src/* $base/src
cp docs/sptools.pdf $base

cd $release_dir
zip -r ../$release_dir.zip sptools
cd .
