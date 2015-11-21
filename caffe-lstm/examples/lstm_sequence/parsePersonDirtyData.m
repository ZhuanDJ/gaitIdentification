function [ data, final ] = parsePersonDirtyData( person, day )
%LOADDATA Summary of this function goes here
%   parseDate(person, day)

filepath = sprintf('gait-dataset/w%03dday%d-raw.csv', person, day);
X = csvread(filepath, 1, 0);
n = size(X, 1);

nSeqLength = 200;
nSamples = floor(n / nSeqLength);

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

windowSize = 50;
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

% Generate final result
startIndices = randperm(n-(nSeqLength-1), nSamples)';

processed_idx = 1;
processed_data = struct('timestamp', {}, 'accel', {}, 'linear_accel', {}, 'accel_mag', {}, 'orientation', {}, 'clip', {}, 'label', {}, 'averageAccel', {}, 'maxAccel', {});

i=0;
while i < length(startIndices) - 1;
    i = i + 1;
    from = startIndices(i, 1);
    to = from + (nSeqLength-1);
        
    fprintf('%d %d\n', from, to);
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

% File write!
write_filepath = sprintf('gait-dataset/w%03dday%d-dirty.csv', person, day);
fprintf('Writing %s...\n', write_filepath);
final_timestamp = [processed_data.timestamp]';
final_accel = reshape([processed_data.accel]', [ 3, length(processed_data)])';
final_clip = [processed_data.clip]';
label = ones(length(final_clip), 1) * person;
final = [final_timestamp final_accel final_clip label];
dlmwrite(write_filepath, final, 'delimiter', ',', 'precision', 14);

end

