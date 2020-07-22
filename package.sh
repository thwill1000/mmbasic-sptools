#!/bin/bash

release=1b1
release_dir="mbt-r$release"
base="$release_dir/mbt"

mkdir -p $base
mkdir -p $base/resources
mkdir -p $base/src

cp ChangeLog $base
cp LICENSE $base
cp README.md $base
cp mbt.bas $base
cp -R resources/* $base/resources
cp -R src/* $base/src
cp docs/mbt.pdf $base

cd $release_dir
zip -r ../$release_dir.zip mbt
cd .
