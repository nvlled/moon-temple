#!/bin/bash

mkdir -p temp
mkdir -p temp/.lua
cp -rv ../src/*.lua temp/.lua
cp redbean-init.lua temp/.init.lua
cp redbean-args temp/.args
rm -f moon-temple.com
cp redbean.com moon-temple.com

cd temp
zip -r ../moon-temple.com .
cd ..
rm -rf temp
