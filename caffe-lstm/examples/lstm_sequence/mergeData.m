resultIdx = 1;
result = [];

for person=1:23
    fprintf('merging... person %d\n', person);
    personResultIdx = 1;
    personResult = [];
    for day=1:2
        X = csvread(sprintf('gait-dataset/w%03dday%d.csv', person, day));
        clipIdx = find(X(:, 5) == 0)';
        for endIdx=clipIdx(2:end)
            % get 200-length data
            data200 = X((endIdx-200):endIdx-1, :);
            data200(:, 5) = 1;
            data200(1, 5) = 0;
            personResult(personResultIdx:personResultIdx+199, :) = data200;
            personResultIdx = personResultIdx + 200;
        end
    end
    % Select 130 sequences randomly
    personResult = blockShuffle(personResult, 200);
    personResult = personResult(1:130*200, :);
    
    personResultSize = size(personResult, 1);
    result(resultIdx:resultIdx+(personResultSize-1), :) = personResult;
    resultIdx = resultIdx + personResultSize;
end
result(:, 6) = result(:, 6) - min(result(:, 6));

% Randomly shuffle data
fprintf('shuffle...\n');
result = blockShuffle(result, 200);

% write out
trainingSize = 500000;
fprintf('writing csv...\n');
dlmwrite('gait-dataset/gait_train.csv', result(1:trainingSize, :), 'delimiter', ',', 'precision', 14);
dlmwrite('gait-dataset/gait_test.csv', result((trainingSize+1):end, :), 'delimiter', ',', 'precision', 14);

% generate H5
generateH5('gait_train');