#!/bin/bash

iverilog $1 -o test_file

vvp test_file

rm test_file


