//#include <cuda_runtime.h>
#include <ctime>
#include "caffe/caffe.hpp"
#include <math.h>
#include <iostream>

using std::vector;
using std::max;
using std::abs;
using boost::shared_ptr;
using namespace caffe;

float f_x(float t) {
  return 0.5*sin(2*t) - 0.05*cos(17*t + 0.8) 
      + 0.05*sin(25*t+10) - 0.02*cos(45*t + 0.3);
}

void parseInput(int TotalLength, Blob<float> &sequence, Blob<float> &label_sequence, const char *filepath)
{
  FILE *fp = fopen(filepath, "r");
  int i = 0;
  while (!feof(fp)) {
    long int timestamp;
    float accel_x, accel_y, accel_z;
    int clip;
    float label;
    if (fscanf(fp, "%ld,%f,%f,%f,%d,%f", &timestamp, &accel_x, &accel_y, &accel_z, &clip, &label) == EOF) {
      break;
    }
    // printf("%ld  %lf %lf %lf  %d %d\n", timestamp, accel_x, accel_y, accel_z, clip, label);
    sequence.mutable_cpu_data()[i] = accel_x;
    // sequence.mutable_cpu_data()[i*3+0] = accel_x;
    // sequence.mutable_cpu_data()[i*3+1] = accel_y;
    // sequence.mutable_cpu_data()[i*3+2] = accel_z;
    // label_sequence.mutable_cpu_data()[i] = label;
    label_sequence.mutable_cpu_data()[i] = (float) label;
    if (i < 10){
      printf("%ld  %f %f %f  %d %f\n", timestamp, accel_x, accel_y, accel_z, clip, label);
      printf("LABEL %d / %d %f\n", label, label_sequence.mutable_cpu_data()[i], label_sequence.mutable_cpu_data()[i]);
    }

    i++;
  }

  fclose(fp);
}

int main(int argc, char** argv)
{
  if (argc < 4) {  
    LOG(ERROR) << "lstm_sequence solver_proto(1) result_path(2) sequence_length(3)";
    return 0;
  }

  // Converting input parameters
  const char* net_solver(argv[1]);
  const char* result_path(argv[2]);
  const int TotalLength = atoi(argv[3]);
  // const int dataDimension = atoi(argv[4]);

  caffe::SolverParameter solver_param;
  caffe::ReadProtoFromTextFileOrDie(net_solver, &solver_param);

  // Set device id and mode
  if (solver_param.solver_mode() == caffe::SolverParameter_SolverMode_GPU) {
    LOG(INFO) << "Use GPU with device ID " << solver_param.device_id();
    Caffe::SetDevice(solver_param.device_id());
    Caffe::set_mode(Caffe::GPU);
  } else {
    LOG(INFO) << "Use CPU.";
    Caffe::set_mode(Caffe::CPU);
  }

  shared_ptr<Solver<float> > solver;
  solver.reset(GetSolver<float>(solver_param));
  shared_ptr<Net<float> > train_net(solver->net());
  shared_ptr<Net<float> > test_net(new Net<float> (solver_param.net(), TEST));
  CHECK(train_net->has_blob("data"));
  CHECK(train_net->has_blob("clip"));
  CHECK(train_net->has_blob("label"));
  CHECK(test_net->has_blob("data"));
  CHECK(test_net->has_blob("clip"));
  shared_ptr<Blob<float> > train_data_blob = train_net->blob_by_name("data");
  shared_ptr<Blob<float> > train_label_blob = train_net->blob_by_name("label");
  shared_ptr<Blob<float> > train_clip_blob = train_net->blob_by_name("clip");
  shared_ptr<Blob<float> > test_data_blob = test_net->blob_by_name("data");
  shared_ptr<Blob<float> > test_clip_blob = test_net->blob_by_name("clip");
  
  const int seq_length = train_data_blob->shape(0);
  CHECK_EQ(TotalLength % seq_length, 0);
  CHECK_EQ(seq_length, 200);

  // Initialize bias for the forget gate to 5 as described in the clockwork RNN paper
  const vector<shared_ptr<Layer<float> > >& layers = train_net->layers();
  for (int i = 0; i < layers.size(); ++i) {
    if (strcmp(layers[i]->type(), "Lstm") != 0) {
      continue;
    }
    const int h = layers[i]->layer_param().lstm_param().num_output();
    shared_ptr<Blob<float> > bias = layers[i]->blobs()[2];
    caffe_set(h, 5.0f, bias->mutable_cpu_data() + h);
  }

  vector<int> sequence_shape(1, TotalLength);
  vector<int> label_sequence_shape(1, TotalLength);
  Blob<float> sequence(sequence_shape);
  Blob<float> label_sequence(label_sequence_shape);

  // Construct data 
  parseInput(TotalLength, sequence, label_sequence, "data/gait_data.csv");

  // Training
  printf("SEQUENCE LENGTH : %d\n", seq_length);
  caffe_set(seq_length, 1.0f, train_clip_blob->mutable_cpu_data());
  int iter = 0;
  while(iter < solver_param.max_iter()) {
    int seq_idx = iter % (TotalLength / seq_length);
    train_clip_blob->mutable_cpu_data()[0] = 0; //seq_idx > 0;
    if (Caffe::mode() == Caffe::CPU) {
      caffe_copy(seq_length, label_sequence.mutable_cpu_data() + label_sequence.offset(seq_idx * seq_length), train_label_blob->mutable_cpu_data());
      caffe_copy(seq_length, sequence.mutable_cpu_data() + sequence.offset(seq_idx * seq_length), train_data_blob->mutable_cpu_data());
    }
    else {
      caffe_copy(seq_length, sequence.mutable_gpu_data() + sequence.offset(seq_idx * seq_length), train_label_blob->mutable_gpu_data());
    }
    for (int i = 0 ; i < 200 ;i++){
      printf("label : %d %f\n", train_label_blob->mutable_cpu_data()[i], train_label_blob->mutable_cpu_data()[i]);
    }
    solver->Step(1);
    iter++;
  }

  // Output Test
  std::ofstream log_file;
  log_file.open(result_path, std::fstream::out);
  test_net->ShareTrainedLayersWith(train_net.get());
  vector<Blob<float>* > bottom;
  vector<int> shape(2, 1);
  test_data_blob->Reshape(shape);
  test_clip_blob->Reshape(shape);
  test_net->Reshape();
  for (int i = 0; i < TotalLength; ++i) { 
    test_clip_blob->mutable_cpu_data()[0] = i > 0;
    const vector<Blob<float>* >& pred = test_net->ForwardPrefilled();
    CHECK_EQ(pred.size(), 1);
    CHECK_EQ(pred[0]->count(), 1);
    log_file << sequence.cpu_data()[i] << " " << *pred[0]->cpu_data() << std::endl;
  }
  
  log_file.close();
}
