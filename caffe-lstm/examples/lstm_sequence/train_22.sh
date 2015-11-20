#!/usr/bin/env sh

TOOLS=../../build/tools

$TOOLS/caffe train \
      --solver=lstm_gait_22_solver.prototxt #--weights=_iter_177549.caffemodel

