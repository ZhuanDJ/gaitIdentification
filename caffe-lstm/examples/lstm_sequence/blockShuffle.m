function [ result ] = blockShuffle( data, blockSize )

n = size(data, 1);
numSequence = n / blockSize;
permIdx = reshape(repmat(randperm(numSequence) - 1, blockSize, 1), n, 1) .* blockSize;
offset = repmat((1:blockSize)', numSequence, 1);
permIdx = permIdx + offset;
data = data(permIdx, :);

result = data;

end

