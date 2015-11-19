a = caffe.Net('lstm_gait_matlab.prototxt', 'snapshot/gait_iter_40000.caffemodel', 'test');
X = csvread('gait-dataset/gait_test.csv');

n = size(X, 1);
m = n / 200;

positive_count = 0;
negative_count = 0;

for i=1:m
    fprintf('%d\n', i);
    x = X((i*200-199):i*200, :);
    true_class = x(:, 6)';

    a.blobs('data').set_data(x(:, 2:4)');
    a.blobs('clip').set_data(x(:, 5)');
    a.forward_prefilled;

    [~, class] = max(a.blobs('prob').get_data);
    class = mod(class + 19, 20);
    if class == 0
        class = class + 1;
    end
    
    correct = sum(true_class == class) > 100;
    
    if correct
        positive_count = positive_count + 1;
    else
        negative_count = negative_count + 1;
    end
end

fprintf('accuracy : %f\n', positive_count / (positive_count + negative_count));