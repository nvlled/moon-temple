#!/bin/bash
dir=`pwd`
cd `dirname $0`
./make.sh 
mv -fv `pwd`/moon-temple.com $dir
cd $dir
./moon-temple.com $@
