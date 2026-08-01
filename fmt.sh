#!/bin/bash
# V code formatter script

echo "Formatting V source files..."

v fmt -w picview.v
v fmt -w picview_test.v
v fmt -w main.v

echo "Done!"
