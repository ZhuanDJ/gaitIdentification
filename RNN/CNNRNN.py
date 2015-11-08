"""

Vanilla Recurrent Neural Network
Code provided by Mohammad Pezeshki - Nov. 2014 - Universite de Montreal
This code is distributed without any warranty, express or implied. 
Thanks to Razvan Pascanu and Graham Taylor for their codes available at:
https://github.com/pascanur/trainingRNNs
https://github.com/gwtaylor/theano-rnn

"""

import numpy as np
import theano
import theano.tensor as T
import time
import os
import datetime
import struct
import matplotlib
import operator
import cPickle
from theano.tensor.signal import downsample
from theano.tensor.nnet import conv
# Force matplotlib to not use any Xwindows backend.
matplotlib.use('Agg')
import matplotlib.pyplot as plt
plt.ion()

mode = theano.Mode(linker='cvm') #the runtime algo to execute the code is in c


"""
What we have in this class:

    Model structure parameters:
        n_u : length of input layer vector in each time-step
        n_h : length of hidden layer vector in each time-step
        n_y : length of output layer vector in each time-step
        activation : type of activation function used for hidden layer
        output_type : type of output which could be `real`, `binary`, or `softmax`

    Parameters to be learned:
        W_uh : weight matrix from input to hidden layer
        W_hh : recurrent weight matrix from hidden to hidden layer
        W_hy : weight matrix from hidden to output layer
        b_h : biases vector of hidden layer
        b_y : biases vector of output layer
        h0 : initial values for the hidden layer

    Learning hyper-parameters:
        learning_rate : learning rate which is not constant
        learning_rate_decay : learning rate decay :)
        L1_reg : L1 regularization term coefficient
        L2_reg : L2 regularization term coefficient
        initial_momentum : momentum value which we start with
        final_momentum : final value of momentum
        momentum_switchover : on which `epoch` should we switch from
                              initial value to final value of momentum
        n_epochs : number of iterations

    Inner class variables:
        self.x : symbolic input vector
        self.y : target output
        self.y_pred : raw output of the model
        self.p_y_given_x : output after applying sigmoid (binary output case)
        self.y_out : round (0,1) for binary and argmax (0,1,...,k) for softmax
        self.loss : loss function (MSE or CrossEntropy)
        self.predict : a function returns predictions which is type is related to output type
        self.predict_proba : a function returns predictions probabilities (binary and softmax)
    
    build_train function:
        train_set_x : input of network
        train_set_y : target of network
        index : index over each ...............................
        lr : learning rate
        mom : momentum
        cost : cost function value
        compute_train_error : a function compute error on training
        gparams : Gradients of model parameters
        updates : updates which should be applied to parameters
        train_model : a function that returns the cost, but 
                      in the same time updates the parameter
                      of the model based on the rules defined
                      in `updates`.
        
"""
class CNNRNN(object):
    def __init__(self, image_shape, filter_shapes, nkerns, pool_sizes, 
                 n_h, n_y, activation, output_type,
                 learning_rate, learning_rate_decay, L1_reg, L2_reg,
                 initial_momentum, final_momentum, momentum_switchover,
                 n_epochs, params = None):

        self.n_cnnlayers = len(nkerns)
        self.nkerns = nkerns;
        self.pool_sizes = pool_sizes;
        self.image_shapes = [(1, 1, image_shape[0], image_shape[1])]
        self.filter_shapes = []
        for i in xrange(self.n_cnnlayers):
          cur_shape = (self.image_shapes[i][2], self.image_shapes[i][3])
          self.image_shapes.append(( 1,
            nkerns[i],
            (cur_shape[0] - filter_shapes[i][0] + 1) / pool_sizes[i][0], 
            (cur_shape[1] - filter_shapes[i][1] + 1) / pool_sizes[i][1]
          ))

          if i == 0:
            prev_kern = 1
          else:
            prev_kern = nkerns[i-1]
          self.filter_shapes.append((
            nkerns[i],
            prev_kern,
            filter_shapes[i][0],
            filter_shapes[i][1]
          ))

        print self.image_shapes
        self.n_u = int(np.prod(self.image_shapes[-1]))
        n_u = self.n_u
        self.n_h = int(n_h)
        self.n_y = int(n_y)

        self.activation_str = activation

        if activation == 'tanh':
            self.activation = T.tanh
        elif activation == 'sigmoid':
            self.activation = T.nnet.sigmoid
        elif activation == 'relu':
            self.activation = lambda x: x * (x > 0) # T.maximum(x, 0)
        else:
            raise NotImplementedError   

        self.output_type = output_type
        self.learning_rate = float(learning_rate)
        self.learning_rate_decay = float(learning_rate_decay)
        self.L1_reg = float(L1_reg)
        self.L2_reg = float(L2_reg)
        self.initial_momentum = float(initial_momentum)
        self.final_momentum = float(final_momentum)
        self.momentum_switchover = int(momentum_switchover)
        self.n_epochs = int(n_epochs)

        rng = np.random.RandomState()

        # input which is `x`
        self.x = T.matrix()

        self.cnnW = [];
        self.cnnb = [];

        if(params == None):
          for i in xrange(self.n_cnnlayers):
            fan_in = np.prod(self.filter_shapes[i][1:])
            fan_out = (self.filter_shapes[i][0] * np.prod(self.filter_shapes[i][2:]) / np.prod(self.pool_sizes[i]))
            W_bound = np.sqrt(6. / (fan_in + fan_out))
            initial_W = np.asarray(
              rng.uniform(
                low =  -W_bound,
                high = W_bound,
                size = self.filter_shapes[i]
              ),  
              dtype = theano.config.floatX  
            )

            W = theano.shared(
              value = initial_W, 
              name = 'W', 
              borrow = True
            )
            self.cnnW.append(W)

            b = theano.shared(
              value = np.zeros(
                (self.filter_shapes[i][0],),
                dtype = theano.config.floatX
              ),
              name = 'b',
              borrow = True
            )
            self.cnnb.append(b)

          # weights are initialized from an uniform distribution
          self.W_uh = theano.shared(value = np.asarray(
                                                np.random.uniform(
                                                    size = (n_u, n_h),
                                                    low = -.01, high = .01),
                                                dtype = theano.config.floatX),
                                    name = 'W_uh')

          self.W_hh = theano.shared(value = np.asarray(
                                                np.random.uniform(
                                                    size = (n_h, n_h),
                                                    low = -.01, high = .01),
                                                dtype = theano.config.floatX),
                                    name = 'W_hh')

          self.W_hy = theano.shared(value = np.asarray(
                                                np.random.uniform(
                                                    size = (n_h, n_y),
                                                    low = -.01, high = .01),
                                                dtype = theano.config.floatX),
                                    name = 'W_hy')

          # initial value of hidden layer units are set to zero
          self.h0 = theano.shared(value = np.zeros(
                                              (n_h, ),
                                              dtype = theano.config.floatX),
                                  name = 'h0')

          # biases are initialized to zeros
          self.b_h = theano.shared(value = np.zeros(
                                               (n_h, ),
                                               dtype = theano.config.floatX),
                                   name = 'b_h')

          self.b_y = theano.shared(value = np.zeros(
                                               (n_y, ),
                                               dtype = theano.config.floatX),
                                   name = 'b_y')
        else:
          self.cnnW = params[:self.n_cnnlayers]
          self.cnnb = params[self.n_cnnlayers:2*self.n_cnnlayers]
          cur_idx = 2*self.n_cnnlayers

          self.W_uh = params[cur_idx]
          cur_idx += 1
          self.W_hh = params[cur_idx]
          cur_idx += 1
          self.W_hy = params[cur_idx]
          cur_idx += 1
          self.h0 = params[cur_idx]
          cur_idx += 1
          self.b_h = params[cur_idx]
          cur_idx += 1
          self.b_y = params[cur_idx]

        self.params = []
        self.params.extend(self.cnnW)
        self.params.extend(self.cnnb)
        self.params.extend([self.W_uh, self.W_hh, self.W_hy, self.h0,
                       self.b_h, self.b_y])

        # Initial value for updates is zero matrix.
        self.updates = {}
        for param in self.params:
            self.updates[param] = theano.shared(
                                      value = np.zeros(
                                                  param.get_value(
                                                      borrow = True).shape,
                                                      dtype = theano.config.floatX),
                                      name = 'updates')

        # h_t = g(W_uh * u_t + W_hh * h_tm1 + b_h)
        # y_t = W_yh * h_t + b_y
        def cnn_fn(cnn_idx, input):
          conv_out = conv.conv2d(
            input = input,
            filters = self.cnnW[cnn_idx],
            filter_shape = self.filter_shapes[cnn_idx],
            image_shape = self.image_shapes[cnn_idx],
            border_mode = 'valid'
          )
          if(self.pool_sizes[cnn_idx][0] > 1 and self.pool_sizes[cnn_idx][1] > 1):
            pooled_out = downsample.max_pool_2d(
              input = conv_out,
              ds = self.pool_sizes[cnn_idx],
              ignore_border = True
            )
          else:
            pooled_out = conv_out
          return self.activation(pooled_out + self.cnnb[cnn_idx].dimshuffle('x', 0, 'x', 'x'))

        def recurrent_fn(u_t, h_tm1):
            cur_input = u_t.reshape((1, 1, image_shape[0], image_shape[1]))
            for i in xrange(self.n_cnnlayers):
              cur_input = cnn_fn(i, cur_input)
            h_t = self.activation(T.dot(cur_input.flatten(1), self.W_uh) + \
                                  T.dot(h_tm1, self.W_hh) + \
                                  self.b_h)
            y_t = T.dot(h_t, self.W_hy) + self.b_y
            return h_t, y_t

        
          # self.cnnlayers.append(cur_input)

        # Iteration over the first dimension of a tensor which is TIME in our case
        # recurrent_fn doesn't use y in the computations, so we do not need y0 (None)
        # scan returns updates too which we do not need. (_)
        [self.h, self.y_pred], _ = theano.scan(recurrent_fn,
                                               sequences = self.x,
                                               outputs_info = [self.h0, None])

        # L1 norm
        self.L1 = abs(self.W_uh.sum()) + \
                  abs(self.W_hh.sum()) + \
                  abs(self.W_hy.sum())

        # square of L2 norm
        self.L2_sqr = (self.W_uh ** 2).sum() + \
                      (self.W_hh ** 2).sum() + \
                      (self.W_hy ** 2).sum()

        # Loss function is different for different output types
        # defining function in place is so easy! : lambda input: expresion
        if self.output_type == 'real':
            self.y = T.matrix(name = 'y', dtype = theano.config.floatX)
            self.loss = lambda y: self.mse(y) # y is input and self.mse(y) is output
            self.predict = theano.function(inputs = [self.x, ],
                                           outputs = self.y_pred,
                                           mode = mode)

        elif self.output_type == 'binary':
            self.y = T.matrix(name = 'y', dtype = 'int32')
            self.p_y_given_x = T.nnet.sigmoid(self.y_pred)
            self.y_out = T.round(self.p_y_given_x)  # round to {0,1}
            self.loss = lambda y: self.nll_binary(y)
            self.predict_proba = theano.function(inputs = [self.x, ],
                                                 outputs = self.p_y_given_x,
                                                 mode = mode)
            self.predict = theano.function(inputs = [self.x, ],
                                           outputs = T.round(self.p_y_given_x),
                                           mode = mode)
        
        elif self.output_type == 'softmax':
            self.y = T.vector(name = 'y', dtype = 'int32')
            self.p_y_given_x = T.nnet.softmax(self.y_pred)
            self.y_out = T.argmax(self.p_y_given_x, axis = -1)
            self.loss = lambda y: self.nll_multiclass(y)
            self.predict_proba = theano.function(inputs = [self.x, ],
                                                 outputs = self.p_y_given_x,
                                                 mode = mode)
            self.predict = theano.function(inputs = [self.x, ],
                                           outputs = self.y_out, # y-out is calculated by applying argmax
                                           mode = mode)
        else:
            raise NotImplementedError

        # Just for tracking training error for Graph 3
        self.errors = []

    def save(self, f):
      filter_shapes = []
      for i in xrange(self.n_cnnlayers):
        filter_shapes.append((self.filter_shapes[i][2], self.filter_shapes[i][2]))
      data = [
        (self.image_shapes[0][2], self.image_shapes[0][3]),
        filter_shapes,
        self.nkerns,
        self.pool_sizes,
        self.n_h,
        self.n_y,
        self.activation_str,
        self.output_type,
        self.learning_rate,
        self.learning_rate_decay,
        self.L1_reg,
        self.L2_reg,
        self.initial_momentum,
        self.final_momentum,
        self.momentum_switchover,
        self.n_epochs,
        self.params
      ]
      cPickle.dump(data, f)

    def mse(self, y):
        # mean is because of minibatch
        return T.mean((self.y_pred - y) ** 2)

    def nll_binary(self, y):
        # negative log likelihood here is cross entropy
        return T.mean(T.nnet.binary_crossentropy(self.p_y_given_x, y))

    def nll_multiclass(self, y):
        # notice to [  T.arange(y.shape[0])  ,  y  ]
        return -T.mean(T.log(self.p_y_given_x)[T.arange(y.shape[0]), y])

    # X_train, Y_train, X_test, and Y_test are numpy arrays
    def build_trian(self, X_train, Y_train, X_test = None, Y_test = None):
        train_set_x = theano.tensor._shared(np.asarray(X_train, dtype=theano.config.floatX), borrow=True)
        train_set_y = theano.tensor._shared(np.asarray(Y_train, dtype=theano.config.floatX), borrow=True)
        if self.output_type in ('binary', 'softmax'):
            train_set_y = T.cast(train_set_y, 'int32')

        ######################
        # BUILD ACTUAL MODEL #
        ######################
        print 'Buiding model ...'

        index = T.lscalar('index')    # index to a case
        # learning rate (may change)
        lr = T.scalar('lr', dtype = theano.config.floatX)
        mom = T.scalar('mom', dtype = theano.config.floatX)  # momentum


        # Note that we use cost for training
        # But, compute_train_error for just watching
        cost = self.loss(self.y)

        # We don't want to pass whole dataset every time we use this function.
        # So, the solution is to put the dataset in the GPU as `givens`.
        # And just pass index to the function each time as input.
        compute_train_error = theano.function(inputs = [index, ],
                                              outputs = self.loss(self.y),
                                              givens = {
                                                  self.x: train_set_x[index],
                                                  self.y: train_set_y[index]},
                                              mode = mode)

        # Gradients of cost wrt. [self.W, self.W_in, self.W_out,
        # self.h0, self.b_h, self.b_y] using BPTT.
        gparams = []
        for param in self.params:
            gparams.append(T.grad(cost, param))

        # zip just concatenate two lists
        
        updates = []
        for param, gparam in zip(self.params, gparams):
            weight_update = self.updates[param]
            upd = mom * weight_update - lr * gparam
            updates.append((weight_update, upd))
            updates.append((param, param + upd))

        # compiling a Theano function `train_model` that returns the
        # cost, but in the same time updates the parameter of the
        # model based on the rules defined in `updates`
        train_model = theano.function(inputs = [index, lr, mom],
                                      outputs = cost,
                                      updates = updates,
                                      givens = {
                                          self.x: train_set_x[index], # [:, batch_start:batch_stop]
                                          self.y: train_set_y[index]},
                                      mode = mode)

        ###############
        # TRAIN MODEL #
        ###############
        print 'Training model ...'
        epoch = 0
        n_train = train_set_x.get_value(borrow = True).shape[0]
        prev_loss = 9999999.9;
        while (epoch < self.n_epochs):
            epoch = epoch + 1
            for idx in xrange(n_train):
                effective_momentum = self.final_momentum \
                                     if epoch > self.momentum_switchover \
                                     else self.initial_momentum
                example_cost = train_model(idx,
                                           self.learning_rate,
                                           effective_momentum)

            # compute loss on training set
            train_losses = [compute_train_error(i)
                            for i in xrange(n_train)]
            this_train_loss = np.mean(train_losses)
            self.errors.append(this_train_loss)

            print('epoch %i, train loss %f ''lr: %f' % \
                  (epoch, this_train_loss, self.learning_rate))
            if(prev_loss > this_train_loss):
                self.learning_rate *= self.learning_rate_decay
            else:
                self.learning_rate *= 0.8
            prev_loss = this_train_loss

def load_RNNparam(f):
  data = cPickle.load(f)
  model = CNNRNN(*data)
  return model

def load_traindata(filename):
    f = open(filename)
    line = f.readline()

    input_seq = []
    while line:
        input_data = map(int, line.split('\t'))
        input_seq.append(np.asarray(input_data, dtype=theano.config.floatX))
        line = f.readline()

    f.close()

    input_seqs = []
    input_seqs.append(np.asarray(input_seq, dtype=theano.config.floatX))
    
    for i in range(2, 102):
        new_input_seq = map(operator.add, input_seq, np.random.standard_normal(len(input_seq)))
        input_seqs.append(np.asarray(new_input_seq, dtype=theano.config.floatX))
    

    return input_seqs

def load_image_traindata(filename):
    img_size = 160*120

    f = open(filename,'rb')
    imgdata = f.read(8)
    seq_len, step_len = struct.unpack('<II', imgdata)
    print 'Sequnce count: ' + str(seq_len) + ' / step length: ' + str(step_len)
    imgdata = f.read(img_size)

    input_seq = []
    input_seqs = []
    read_pos = 1
    read_len = int(seq_len/10.)
    print 'Start to reading image data...'
    for j in range(seq_len):
      for i in range(step_len):
        input_seq.append(np.asarray([ord(x) for x in list(imgdata)], dtype=theano.config.floatX) / 255.)
        imgdata = f.read(img_size)
      if j > read_pos * read_len:
        print 'Reading ' + str(read_pos) + '0% pos...'
        read_pos = read_pos + 1
      input_seqs.append(np.asarray(input_seq, dtype=theano.config.floatX))
      input_seq = []
    f.close()
    if(len(input_seq) > 0):
      input_seqs.append(np.asarray(input_seq, dtype=theano.config.floatX))
    return input_seqs
    
def get_targets(input_seqs):
    n_seqs = len(input_seqs)
    target_seqs = []
    for input_seq in input_seqs:  
        n_seq = len(input_seq)
        count = 1;
        target_seq = []
        for input_data in input_seq:
            if count > 1 and count <= n_seq:
                target_seq.append(np.asarray(input_data, dtype=theano.config.floatX))
            count = count + 1 
        target_seq.append(np.asarray(input_data, dtype=theano.config.floatX))  
        target_seqs.append(np.asarray(target_seq, theano.config.floatX))


    return target_seqs

def load_target_data(filename):
    f = open(filename, 'r')

    input_seq = []
    input_seqs = []
    for raw_line in f:
      line = raw_line.strip()
      if(len(line) == 0):
        input_seqs.append(np.asarray(input_seq, dtype=theano.config.floatX))
        input_seq = []
      else:
        input_seq.append(np.asarray(map(int, line.split(' ')), dtype=theano.config.floatX))

    f.close()
    if(len(input_seq) > 0):
      input_seqs.append(np.asarray(input_seq, dtype=theano.config.floatX))
      print input_seqs[-1].shape
    return input_seqs



"""
Here we define some testing functions.
For more details see Graham Taylor model:
https://github.com/gwtaylor/theano-rnn
"""
"""
Here we test the RNN with real output.
We randomly generate `n_seq` sequences of length `time_steps`.
Then we make a delay to get the targets. (+ adding some noise)
Resulting graphs are saved under the name of `real.png`.
"""
def test_real():
    print '==== Testing model with real outputs ===='
    print '** Load training data **'
    input_seqs = load_image_traindata('fixed_objects_modified_imageSeqsFile.txt')
    target_seqs = load_target_data('fixed_objects_modified_headSeqsFile.txt')
    
    #input_seqs.pop()
    #target_seqs.pop()

    n_h = 200 # hidden vector size
    n_y = 2 # output vector size
    time_steps = 66 # number of time-steps in time
    n_seq = 5 # number of sequences for training

    seq = np.asarray(input_seqs)
    targets = np.asarray(target_seqs)


    # generating random sequences
    #seq = np.random.randn(n_seq, time_steps, n_u)
    #targets = np.zeros((n_seq, time_steps, n_y))

    print seq.shape
    print targets.shape
    #print seq
    #print targets

    #targets[:, 1:, 0] = seq[:, :-1, 0] # 1 time-step delay between input and output
    #targets[:, 2:, 1] = seq[:, :-2, 1] # 2 time-step delay
    #targets[:, 3:, 2] = seq[:, :-3, 2] # 3 time-step delay

    #print targets
    #targets += 0.01 * np.random.standard_normal(targets.shape)

    #print targets

    load_file = None
    #load_file = 'param.prm'
    if load_file == None:
      model = CNNRNN(
                  image_shape=(160,120), filter_shapes=[(11, 11), (7, 7), (3, 3)], 
                  nkerns=[20, 30, 80], pool_sizes=[(5, 5), (2, 2), (2, 2)],
                  n_h = n_h, n_y = n_y,
                  activation = 'tanh', output_type = 'real',
                  learning_rate = 0.0001, learning_rate_decay = 0.999,
                  L1_reg = 0, L2_reg = 0, 
                  initial_momentum = 0.5, final_momentum = 0.9,
                  momentum_switchover = 5,
                  n_epochs = 400)
    else:
      f = file(load_file, 'rb')
      model = load_RNNparam(f)
      f.close()

    model.build_trian(seq, targets)


    # We just plot one of the sequences
    plt.close('all')
    fig = plt.figure()

    # Graph 1
    ax1 = plt.subplot(311) # numrows, numcols, fignum
    plt.plot(seq[0])
    plt.grid()
    ax1.set_title('Input sequence')

    # Graph 2
    ax2 = plt.subplot(312)
    true_targets = plt.plot(targets[0])

    guess = model.predict(seq[0])
    guessed_targets = plt.plot(guess, linestyle='--')
    plt.grid()
    for i, x in enumerate(guessed_targets):
        x.set_color(true_targets[i].get_color())
    ax2.set_title('solid: true output, dashed: model output')

    # Graph 3
    ax3 = plt.subplot(313)
    plt.plot(model.errors)
    plt.grid()
    ax1.set_title('Training error')

    # Save as a file
    plt.savefig('real.png')

    f = file('param.prm', 'wb')
    model.save(f)
    f.close()

"""
Here we test the RNN with binary output.
We randomly generate `n_seq` sequences of length `time_steps`.
Then we make a delay and make binary number which are obtained 
using comparison to get the targets. (+ adding some noise)
Resulting graphs are saved under the name of `binary.png`.
"""
def test_binary():
    print 'Testing model with binary outputs'
    n_u = 2
    n_h = 5
    n_y = 1
    time_steps = 20
    n_seq = 100

    np.random.seed(0)

    seq = np.random.randn(n_seq, time_steps, n_u)
    targets = np.zeros((n_seq, time_steps, n_y))

    # whether `dim 3` is greater than `dim 0`
    targets[:, 2:, 0] = np.cast[np.int](seq[:, 1:-1, 1] > seq[:, :-2, 0])

    model = RNN(n_u = n_u, n_h = n_h, n_y = n_y,
                activation = 'tanh', output_type = 'binary',
                learning_rate = 0.001, learning_rate_decay = 0.999,
                L1_reg = 0, L2_reg = 0, 
                initial_momentum = 0.5, final_momentum = 0.9,
                momentum_switchover = 5,
                n_epochs = 700)

    model.build_trian(seq, targets)

    plt.close('all')
    fig = plt.figure()
    ax1 = plt.subplot(311)
    plt.plot(seq[1])
    plt.grid()
    ax1.set_title('input')
    ax2 = plt.subplot(312)
    guess = model.predict_proba(seq[1])
    # put target and model output beside each other
    plt.imshow(np.hstack((targets[1], guess)).T, interpolation = 'nearest', cmap = 'gray')

    plt.grid()
    ax2.set_title('first row: true output, second row: model output')

    ax3 = plt.subplot(313)
    plt.plot(model.errors)
    plt.grid()
    ax3.set_title('Training error')

    plt.savefig('binary.png')

"""
Here we test the RNN with softmax output.
We randomly generate `n_seq` sequences of length `time_steps`.
Then we make a delay and make classed which are obtained 
using comparison to get the targets.
Resulting graphs are saved under the name of `softmax.png`.
"""
def test_softmax():
    print 'Testing model with softmax outputs'
    n_u = 2
    n_h = 6
    n_y = 3 # equal to the number of calsses
    time_steps = 10
    n_seq = 100

    np.random.seed(0)

    seq = np.random.randn(n_seq, time_steps, n_u)
    # Note that is this case `targets` is a 2d array
    targets = np.zeros((n_seq, time_steps), dtype=np.int)

    thresh = 0.5
    # Comparisons to assing a class label in output
    targets[:, 2:][seq[:, 1:-1, 1] > seq[:, :-2, 0] + thresh] = 1
    targets[:, 2:][seq[:, 1:-1, 1] < seq[:, :-2, 0] - thresh] = 2
    # otherwise class is 0

    model = CNNRNN(
                image_shape=(320,240), filter_shapes=[(11, 11), (7, 7), (3, 3)], 
                nkerns=[30, 50, 70], pool_sizes=[(5, 5), (4, 4), (2, 2)],
                n_u = n_u, n_h = n_h, n_y = n_y,
                activation = 'tanh', output_type = 'softmax',
                learning_rate = 0.001, learning_rate_decay = 0.999,
                L1_reg = 0, L2_reg = 0, 
                initial_momentum = 0.5, final_momentum = 0.9,
                momentum_switchover = 5,
                n_epochs = 500)

    model.build_trian(seq, targets)

    plt.close('all')
    fig = plt.figure()
    ax1 = plt.subplot(311)
    plt.plot(seq[1])
    plt.grid()
    ax1.set_title('input')
    ax2 = plt.subplot(312)

    plt.scatter(xrange(time_steps), targets[1], marker = 'o', c = 'b')
    plt.grid()

    guess = model.predict_proba(seq[1])
    guessed_probs = plt.imshow(guess.T, interpolation = 'nearest', cmap = 'gray')
    ax2.set_title('blue points: true class, grayscale: model output (white mean class)')

    ax3 = plt.subplot(313)
    plt.plot(model.errors)
    plt.grid()
    ax3.set_title('Training error')
    plt.savefig('softmax.png')


if __name__ == "__main__":
    t0 = time.time()
    test_real()
    #test_binary()
    #test_softmax()
    print "Elapsed time: %f" % (time.time() - t0)

