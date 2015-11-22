caffe.reset_all;
caffenet = caffe.Net('prototxt/lstm_gait_matlab.prototxt', 'snapshot/gait_iter_20000.caffemodel', 'test');
X = csvread('gait-dataset/gait_all_train.csv');

n = size(X, 1);
m = n / 200;

positive_count = 0;
negative_count = 0;

for i=1:m
    if mod(i, 100) == 0
        fprintf('* iter %d\n', i);
    end
    x = X((i*200-199):(i*200), :);
%     x = X((i*200-49):(i*200), :);
    true_class = x(1, 6)' + 1;

    clip = ones(size(x,1),1); clip(1) = 0;
    caffenet.blobs('data').set_data(x(:, 2:4)');
    caffenet.blobs('clip').set_data(clip');
    caffenet.forward_prefilled;

    [~, class] = max(sum(log(caffenet.blobs('prob').get_data), 2));

%     class = class -1;
%     zeroIdx = find(class == 0);
%     class(zeroIdx) = 20;

%     correct = sum(true_class == class) > 100;
    correct = (true_class == class);
    
    if correct
        positive_count = positive_count + 1;
    else
        fprintf('%d %d\n', mode(class), mode(true_class));
        negative_count = negative_count + 1;
    end
end
fprintf('\n');

fprintf('accuracy : %f\n', positive_count / (positive_count + negative_count));