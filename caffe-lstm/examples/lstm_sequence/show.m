function [ ] = show( result, person )
%SHOW Summary of this function goes here
%   Detailed explanation goes here

personResult = result(result(:, 6) == person, :);
personResult = blockShuffle(personResult, 200);

plot(1:200, personResult(1:200, 2), 'r-', 1:200, personResult(1:200, 3), 'g-', 1:200, personResult(1:200, 4), 'b-');

end

