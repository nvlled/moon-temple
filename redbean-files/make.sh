#!/bin/bash

prev_dir=`pwd`
output_filename="${1:-moon-temple.com}"
cd `dirname $0`

mkdir -p temp
mkdir -p temp/.lua
cp ../src/*.lua temp/.lua
cp redbean-init.lua temp/.init.lua
cp redbean-args temp/.args
cp bin/redbean.com $output_filename

cd temp
zip -d ../$output_filename help.txt
zip -r ../$output_filename .
cd ..
rm -rf temp

if [ x"`ls -A include|head -n1`" != "x" ]; then
    cd include
    zip -r ../$output_filename .
    cd ..
fi


chmod +x $output_filename
if [ `pwd` != $prev_dir ]; then
    mv -f $output_filename $prev_dir
    cd $prev_dir
fi

echo "created file: $output_filename"