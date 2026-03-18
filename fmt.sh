#!/bin/bash
# V code formatter script

echo "Formatting V source files..."

v fmt picview.v
v fmt main.v

echo "Done!"
