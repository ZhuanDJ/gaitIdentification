function [ output_args ] = mergeAllTrainData( )
% generate train, test data for 'targetPerson'
ResultIdx = 1;
Result = [];


% merge person data
nPersonSequences = 130;

nSamples = 200;
nSeqLength = 200;
clip = ones(nSeqLength, 1);
clip(1, 1) = 0;

for person=1:11
    fprintf('merging... person %d\n', person);
    personResultIdx = 1;
    personResult = [];
    for day=1:2
        filepath = sprintf('gait-dataset/w%03dday%d.csv', person, day);

        X = csvread(filepath);
        clipIdx = find(X(:, 5) == 0)';
        for endIdx=clipIdx(2:end)
            % get 200-length data
            data200 = X((endIdx-nSeqLength):endIdx-1, :);
            data200(:, 5) = 1;
            data200(1, 5) = 0;
            personResult(personResultIdx:personResultIdx+(nSeqLength-1), :) = data200;
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
% nTrashSequences = 100;
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
%     % Select 'nTrashSequences' sequences randomly
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

% write out train data
% trainingSize = 500000;
trainingSize = size(Result, 1);
fprintf('writing train data csv ... (%d samples) \n', trainingSize / nSeqLength);
trainFileName = 'gait_all_train.csv';
trainFilePath = sprintf('gait-dataset/%s', trainFileName);

dlmwrite(trainFilePath, Result(1:trainingSize, :), 'delimiter', ',', 'precision', 14);

% generate H5
generateH5('gait_all_train');

%dlmwrite('gait-dataset/gait_test.csv', Result((trainingSize+1):end, :), 'delimiter', ',', 'precision', 14);


end

