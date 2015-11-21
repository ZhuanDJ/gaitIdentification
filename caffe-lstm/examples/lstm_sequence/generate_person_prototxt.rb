#/usr/bin/env ruby

for person in 1..23
prototxt_template = %{name: "LSTM"
layer {
  name: "gait"
  type: "HDF5Data"
  top: "data"
  top: "clip"
  top: "label"
  include {
    phase: TRAIN
  }
  hdf5_data_param {
    source: "/home/jmlee/workspace/gaitIdentification/caffe-lstm/examples/lstm_sequence/gait-dataset/gait_train_#{person}.txt"
    batch_size: 200
  }
}
layer {
  name: "Silence"
  type: "Silence"
  bottom: "label"
  include: { phase: TEST }
}
layer {
  name: "lstm1"
  type: "Lstm"
  bottom: "data"
  bottom: "clip"
  top: "lstm1"

  lstm_param {
    num_output: 100
    clipping_threshold: 0.1
    weight_filler {
      type: "gaussian"
      std: 0.1
    }
    bias_filler {
      type: "constant"
    }
  }
}
layer {
  name: "ip1"
  type: "InnerProduct"
  bottom: "lstm1"
  top: "ip1"

  inner_product_param {
    num_output: 2
    weight_filler {
      type: "gaussian"
      std: 0.1
    }
    bias_filler {
      type: "constant"
    }
  }
}
layer {
  name: "loss"
  type: "SoftmaxWithLoss"
  bottom: "ip1"
  bottom: "label"
  top: "loss"
  include: { phase: TRAIN }
}
}
solver_template = %{net: "prototxt/lstm_gait_#{person}.prototxt"
base_lr: 0.01
momentum: 0.95
lr_policy: "step"
gamma: 0.5 # drop the learning rate
stepsize: 10000 # drop the learning rate every 10k iterations
#weight_decay: 0.004
display: 1000
max_iter: 1000000
solver_mode: CPU
average_loss: 200
debug_info: false

#test_iter: 1000
#test_interval: 50000

snapshot: 10000
snapshot_prefix: "snapshot/gait_#{person}"
}

h5_txt_template = %{/home/jmlee/workspace/gaitIdentification/caffe-lstm/examples/lstm_sequence/gait-dataset/gait_train_#{person}.h5}

# write files...
file = File.new("prototxt/lstm_gait_#{person}.prototxt", "w")
file.write(prototxt_template)
file.close

file = File.new("prototxt/lstm_gait_#{person}_solver.prototxt", "w")
file.write(solver_template)
file.close

file = File.new("gait-dataset/gait_train_#{person}.txt", "w")
file.write(h5_txt_template)
file.close
  
end
