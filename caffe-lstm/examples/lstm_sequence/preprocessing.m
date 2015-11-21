function [ processedData ] = preprocessing( sensorData, windowSize )
%PREPROCESSING Summary of this function goes here
%   Detailed explanation goes here

X = sensorData;
n = size(X, 1);

data = struct('timestamp', {}, 'accel', {}, 'clip', {});

% csv specification
accel_col = 2;

for i=1:n
    timestamp = X(i, 1);
    accel = [X(i, accel_col) X(i, accel_col+1) X(i, accel_col+2)];

    data(i).timestamp = timestamp;
    data(i).accel = accel;
    data(i).clip = 1;
end


averageWindowSize = 50;
accels = [];
for i=1:n
    if i <= averageWindowSize
        accels = [ accels ; data(i).accel ];
    else
        accels = [ accels(2:end, :); data(i).accel ];
    end
    data(i).averageAccel = mean(accels, 1);
    data(i).maxAccel = max(accels, [], 1);
end

threshold = 3;
% Choose apropriate axis
best_axis = -1;
clip_count = 0;
for axis=1:3
    for i=2:n
        data(i).clip = 1;
    end
    for i=2:n
        % downward point
        if data(i).accel(axis) < data(i).averageAccel(axis) + threshold && ...
                data(i-1).accel(axis) > data(i).averageAccel(axis) + threshold
            data(i).clip = 0;
        end
    end
    if length(find([data.clip] == 0)) > clip_count
        clip_count = length(find([data.clip] == 0));
        best_axis = axis;
    end
    for idx = find([data.clip] == 0)
        data(idx).clip = 1;
    end
end
if best_axis >= 0
    for i=2:n
        % downward point
        if data(i).accel(best_axis) < data(i).averageAccel(best_axis) + threshold && ...
                data(i-1).accel(best_axis) > data(i).averageAccel(best_axis) + threshold
            data(i).clip = 0;
        end
    end
end

% Generate final result
processed_idx = 1;
processed_data = struct('timestamp', {}, 'accel', {}, 'clip', {}, 'averageAccel', {}, 'maxAccel', {});
clipIdx = find([data.clip]' == 0);
i = 0;
while i < length(clipIdx) - 1;
    i = i + 1;
    if clipIdx(i+1) - clipIdx(i) > 25
        continue;
    end
    from = clipIdx(i);
    to = -1;
    j = i;
    while j < length(clipIdx)
        j = j+1;
        if clipIdx(j) - clipIdx(j-1) > 25
            break;
        end
        if data(clipIdx(j)).timestamp - data(clipIdx(i)).timestamp > (windowSize * 40)
            to = clipIdx(j);
            break;
        end
    end
    
    if to ~= -1
%         fprintf('%d %d\n', from, to);
        for k=from:to
            elem = data(k);
            if k == from
                elem.clip = 0;
            else
                elem.clip = 1;
            end
            processed_data(processed_idx, :) = elem;
            processed_idx = processed_idx + 1;
        end
    end

    i = j;
end




% File write!
final_timestamp = [processed_data.timestamp]';
final_accel = reshape([processed_data.accel]', [ 3, length(processed_data)])';
final_clip = [processed_data.clip]';

final = [final_timestamp final_accel final_clip];

finalSize = size(final, 1);
if finalSize > windowSize
    final = final((finalSize - windowSize + 1):finalSize, :);
    final(1, 3) = 0;
end


processedData = final;
% range = 1:windowSize;

% if size(processedData, 1) == windowSize
%     plot(range, processedData(range, 2), 'r-', range, processedData(range, 3), 'g-', range, processedData(range, 4), 'b-');
% end

end
