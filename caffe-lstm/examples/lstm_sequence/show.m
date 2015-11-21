function [ ] = show( result, person )
%SHOW Summary of this function goes here
%   Detailed explanation goes here

if person == -1
    personResult = result;
else
    personResult = result(result(:, 6) == person, :);
end

len = min(200, size(result, 1));

personResult = blockShuffle(personResult, len);

plot(1:len, personResult(1:len, 2), 'r-', 1:len, personResult(1:len, 3), 'g-', 1:len, personResult(1:len, 4), 'b-');

if size(personResult, 2) >= 6
    label = personResult(1, 6);
    title(sprintf('label %d', label));
end

end

