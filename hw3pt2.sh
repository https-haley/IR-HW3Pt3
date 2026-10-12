#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: ./hw3p2.sh <indir> <outdir>"
    exit 1
fi

flex multiplefiles.lex
if [ $? -ne 0 ]; then
    echo "Flex compilation failed."
    exit 1
fi

g++ -o multiplefiles lex.yy.c hashtable.cpp -lfl
if [ $? -ne 0 ]; then
    echo "C++ compilation failed."
    exit 1
fi

./multiplefiles "$1" "$2"