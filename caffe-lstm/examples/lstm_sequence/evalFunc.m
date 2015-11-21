function [ result ] = evalFunc( caffeModel, sensorData )



clip = ones(size(sensorData,1),1); clip(1) = 0;
caffeModel.blobs('data').set_data(sensorData(:, 2:4)');
caffeModel.blobs('clip').set_data(clip');
caffeModel.forward_prefilled;

predict_result = caffeModel.blobs('prob').get_data;
avr = mean(predict_result, 2);

[~, class] = max(sum(log(predict_result), 2));
for i=1:size(predict_result, 2)
    fprintf('%.2f ', predict_result(2, i));
end
fprintf('\n%f\n', avr(2));

result = class - 1;
% fprintf('%f\n', result);
% threshold = 0.95;
% if avr < threshold
%     result = 0;
% else
%     result = double(class == 2);
% end

end
