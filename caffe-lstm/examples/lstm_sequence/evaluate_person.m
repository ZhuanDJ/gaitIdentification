person = 23;
iteration = 150000;
threshold = 0;

caffe.reset_all;
caffenet = caffe.Net('prototxt/lstm_gait_person_matlab.prototxt', sprintf('snapshot/gait_%d_iter_%d.caffemodel', person, iteration), 'test');
X = csvread('gait-dataset/gait_test.csv');

n = size(X, 1);
m = n / 200;

positive_count = 0;
negative_count = 0;

fp_data = [];
fn_data = [];

tp = 0; tn = 0;
fp = 0; fn = 0;
for i=1:m
    if mod(i, 100) == 0
        fprintf('* iter %d\n', i);
    end
    x = X((i*200-199):(i*200), :);
%     x = X((i*200-49):(i*200), :);
    if x(1,6) + 1 == person
        true_class = 2;
    else
        true_class = 1;
    end
%     true_class = double((x(1, 6)' + 1) == person) + 1;

    clip = ones(size(x,1),1); clip(1) = 0;
    caffenet.blobs('data').set_data(x(:, 2:4)');
    caffenet.blobs('clip').set_data(clip');
    caffenet.forward_prefilled;

%     [~, class] = max(a.blobs('prob').get_data);
    predict_result = caffenet.blobs('prob').get_data;
    [~, class] = max(sum(log(predict_result), 2));
    avr2 = exp(sum(log(predict_result(2, :))) / size(predict_result, 2));

    if avr2 < threshold && class == 2
        fprintf('threshold! %f < %f\n', avr2, threshold);
        class = 1;
    end

%     class = class -1;
%     zeroIdx = find(class == 0);
%     class(zeroIdx) = 20;

%     correct = sum(true_class == class) > 100;

    if class == 2 && true_class == 2
        tp = tp + 1;
    elseif class == 2 && true_class == 1
        fp_data(size(fp_data,1)+1:size(fp_data,1)+200, :) = x;
        fp = fp + 1;
        fprintf('%d %d\n', mode(class), mode(true_class));
    elseif class == 1 && true_class == 1
        tn = tn + 1;
    elseif class == 1 && true_class == 2
        fn_data(size(fn_data,1)+1:size(fn_data,1)+200, :) = x;
        fn = fn + 1;
        fprintf('%d %d\n', mode(class), mode(true_class));
    else
        error('error occured!');
    end

end
fprintf('\n');

fprintf('accuracy : %f\n', (tp + tn) / (tp + fp + tn + fn));
fprintf('precision : %f\n', tp / (tp + fp));
fprintf('recall : %f\n', tp / (tp + fn));
fprintf('true positive : %f\n', tp);
fprintf('true negative : %f\n', tn);
fprintf('false positive : %f\n', fp);
fprintf('false negative : %f\n', fn);