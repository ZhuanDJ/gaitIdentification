function [ output_args ] = mergeAllTrainData(  )
% generate train, test data 
ResultIdx = 1;
Result = [];

% merge person data
nPersonSequences = 130;

nSamples = 200;
nSeqLength = 200;
clip = ones(nSeqLength, 1);
clip(1, 1) = 0;

for person=13:23
    fprintf('merging... person %d\n', person);
    personResultIdx = 1;
    personResult = [];
    for day=1:2
        filepath = sprintf('gait-dataset/w%03dday%d-raw.csv', person, day);
        X = csvread(filepath, 1, 0);
        
        startIndices = randperm(size(X, 1)-(nSeqLength-1), nSamples)';
        i = 0;
        while i < length(startIndices) - 1;
            i = i + 1;
            from = startIndices(i, 1);
            to = from + (nSeqLength-1);

            data200 = X(from:to, :);
            label = ones(nSeqLength, 1) * person;
            data200 = [data200(:, 1:4), clip, label];
            personResult(personResultIdx:personResultIdx+199, :) = data200;
            personResultIdx = personResultIdx + nSeqLength;
        end
    end
    % Select 'nPersonSequences' sequences randomly
    personResult = blockShuffle(personResult, nSeqLength);
    personResult = personResult(1:nPersonSequences*nSeqLength, :);

    personResultSize = size(personResult, 1);
    Result(ResultIdx:ResultIdx+(personResultSize-1), :) = personResult;
    ResultIdx = ResultIdx + personResultSize;
end

% merge trash data
% nTrashSequences = 50;
% trashLabel = 100;
% for trash=1:10
%     fprintf('merging... trash %d\n', trash);
%     trashResultIdx = 1;
%     trashResult = [];
%     filepath = sprintf('gait-dataset/trash%03d-raw.csv', trash);      
% 
%     X = csvread(filepath, 1, 0);
%     startIndices = randperm(size(X, 1)-(nSeqLength-1), nSamples)';
%     i = 0;
%     while i < length(startIndices) - 1;
%         i = i + 1;
%         from = startIndices(i, 1);
%         to = from + (nSeqLength-1);
% 
%         data200 = X(from:to, :);
%         label = ones(nSeqLength, 1) * trashLabel;
%         data200 = [data200(:, 1:4), clip, label];
%         trashResult(trashResultIdx:trashResultIdx+(nSeqLength-1), :) = data200;
%         trashResultIdx = trashResultIdx + nSeqLength;
%     end
%     
%     Select 'nTrashSequences' sequences randomly
%     trashResult = blockShuffle(trashResult, nSeqLength);
%     trashResult = trashResult(1:nTrashSequences*nSeqLength, :);
% 
%     trashResultSize = size(trashResult, 1);
%     Result(ResultIdx:ResultIdx+(trashResultSize-1), :) = trashResult;
%     ResultIdx = ResultIdx + trashResultSize;
% end
Result(:, 6) = Result(:, 6) - min(Result(:, 6));

% Randomly shuffle data
fprintf('shuffle...\n');
Result = blockShuffle(Result, nSeqLength);

% write out test data
trainSize = size(Result, 1);
fprintf('writing train data csv... (%d samples)\n', trainSize / nSeqLength);
trainFilePath = 'gait-dataset/gait_all_train.csv';

dlmwrite(trainFilePath, Result(1:trainSize, :), 'delimiter', ',', 'precision', 14);

generateH5('gait_all_train');

end

