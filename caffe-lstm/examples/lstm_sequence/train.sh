#!/usr/bin/env sh

TOOLS=../../build/tools

if [ -z "$*" ]; then 
  echo "No args";
  exit
fi

$TOOLS/caffe train --solver="prototxt/lstm_gait_$1_solver.prototxt" #--weights=_iter_177549.caffemodel"

