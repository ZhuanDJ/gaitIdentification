function [ ] = generateH5( filename )
%GENERATEH5 Summary of this function goes here
%   Detailed explanation goes here
fprintf('generate H5... %s\n', filename);

X = csvread(sprintf('gait-dataset/%s.csv', filename));

accel = single(X(:, 2:4))';
label = single(X(:, 6))';
clip = single(X(:,5))';

out_filepath = sprintf('gait-dataset/%s.h5', filename);

delete(out_filepath);

h5create(out_filepath, '/data', size(accel));
h5create(out_filepath, '/clip', size(clip));
h5create(out_filepath, '/label', size(label));

h5write(out_filepath, '/data', accel);
h5write(out_filepath, '/clip', clip);
h5write(out_filepath, '/label', label);

end

