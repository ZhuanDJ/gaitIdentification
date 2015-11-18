function [ data, processed_data ] = parseData( person, day )
%LOADDATA Summary of this function goes here
%   parseDate(person, day)

filepath = sprintf('gait-dataset/w%03dday%d-raw.csv', person, day);
X = csvread(filepath, 1, 0);
n = size(X, 1);

data = struct('timestamp', {}, 'accel', {}, 'linear_accel', {}, 'accel_mag', {}, 'orientation', {}, 'clip', {});

% csv specification
accel_col = 2;
accel_mag_col = 5;
orientation_col = 10;

for i=1:n
    timestamp = X(i, 1);
    accel = [X(i, accel_col) X(i, accel_col+1) X(i, accel_col+2)];
    accel_mag = X(i, accel_mag_col);
    orientation = [X(i, orientation_col) X(i, orientation_col+1) X(i, orientation_col+2)];

    data(i).timestamp = timestamp;
    data(i).accel = accel;
    data(i).accel_mag = accel_mag;
    data(i).orientation = orientation;
    data(i).label = person;
    data(i).clip = 1;
end

windowSize = 10;
accels = [];
for i=1:n
    if i <= windowSize
        accels = [ accels ; data(i).accel ];
    else
        accels = [ accels(2:end, :); data(i).accel ];
    end
    data(i).averageAccel = mean(accels, 1);
    data(i).maxAccel = max(accels, [], 1);
end

threshold = 5;
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
end
for i=2:n
    % downward point
    if data(i).accel(best_axis) < data(i).averageAccel(best_axis) + threshold && ...
            data(i-1).accel(best_axis) > data(i).averageAccel(best_axis) + threshold
        data(i).clip = 0;
    end
end

% Generate final result
processed_data = [];
clipIdx = find([data.clip]' == 0);
i = 0;
while i < length(clipIdx) - 1;
    i = i + 1;
    if clipIdx(i+1) - clipIdx(i) > 50
        continue;
    end
    from = clipIdx(i);
    to = -1;
    j = i;
    while j < length(clipIdx)
        j = j+1;
        if clipIdx(j) - clipIdx(j-1) > 50
            break;
        end
        if data(clipIdx(j)).timestamp - data(clipIdx(i)).timestamp > 10000
            to = clipIdx(j);
            break;
        end
    end
    
    if to ~= -1
        fprintf('%d %d\n', from, to);
        for k=from:to
            elem = data(k);
            if k == from
                elem.clip = 0;
            else
                elem.clip = 1;
            end
            processed_data = [processed_data ; elem];
        end
    end

    i = j;
end

% File write!
write_filepath = sprintf('gait-dataset/w%03dday%d.csv', person, day);
fprintf('Writing %s...\n', write_filepath);
final_timestamp = [processed_data.timestamp]';
final_accel = reshape([processed_data.accel]', [ 3, length(processed_data)])';
final_clip = [processed_data.clip]';
label = ones(length(final_clip), 1) * person;
dlmwrite(write_filepath, [final_timestamp final_accel final_clip label], 'delimiter', ',', 'precision', 14);

end

