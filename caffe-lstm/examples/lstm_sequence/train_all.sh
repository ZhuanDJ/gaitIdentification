#!/usr/bin/env sh

TOOLS=../../build/tools

$TOOLS/caffe train --solver="prototxt/lstm_gait_solver.prototxt" #--weights=_iter_177549.caffemodel"
