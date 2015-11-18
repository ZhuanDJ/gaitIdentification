result = [];

for person=1:20
    fprintf('merging... person %d\n', person);
    for day=1:2
        X = csvread(sprintf('gait-dataset/w%03dday%d.csv', person, day));
        clipIdx = find(X(:, 5) == 0)';
        for endIdx=clipIdx(2:end)
            % get 200-length data
            data200 = X((endIdx-200):endIdx-1, :);
            data200(:, 5) = 1;
            data200(1, 5) = 0;
            result = [result ; data200];
        end
    end
end

% Randomly shuffle data
fprintf('shuffle...\n');
n = size(result, 1);
numSequence = n / 200;
permIdx = reshape(repmat(randperm(numSequence) - 1, 200, 1), n, 1) .* 200;
offset = repmat((1:200)', numSequence, 1);
permIdx = permIdx + offset;
result = result(permIdx, :);

% write out
fprintf('writing csv...\n');
dlmwrite('gait-dataset/gait_data.csv', result, 'delimiter', ',', 'precision', 14);
dlmwrite('gait-dataset/gait_train.csv', result(1:554000, :), 'delimiter', ',', 'precision', 14);
dlmwrite('gait-dataset/gait_test.csv', result(554001:end, :), 'delimiter', ',', 'precision', 14);

% generate H5
generateH5('gait_data');
generateH5('gait_train');
generateH5('gait_test');