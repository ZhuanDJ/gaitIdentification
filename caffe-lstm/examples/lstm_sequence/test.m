% X = csvread('gait-dataset/w021day1-raw.csv', 1, 0);
% X2 = csvread('gait-dataset/w022day1-raw.csv', 1, 0);

% [~,a] = parseData(1,1);
% [~,b] = parseData(2,1);
% [~,c] = parseData(21,1);
% [~,d] = parseData(23,1);
X = {};
X{1} = csvread('gait-dataset/w008day1.csv');
X{2} = csvread('gait-dataset/w022day1.csv');
X{3} = csvread('gait-dataset/w021day1.csv');
X{4} = csvread('gait-dataset/w023day1.csv');

figure;

n = 20000;
interval = 200;

t = 1;
while t < n
    
    for x=1:2
        for y=1:2
            plotIdx = (x-1)*2 + y;
            %             plotIdx = x;
            subplot(2,2,plotIdx);
            accel = zeros(interval, 3);
            for i=0:(interval-1)
                accel(i+1, :) = X{plotIdx}(t+i, 2:4);
            end
            plot(...
                1:interval, accel(:, 1), 'r-', ...
                1:interval, accel(:, 2), 'g-', ...
                1:interval, accel(:, 3), 'b-');
            if plotIdx == 1
                title('Person 1');
            elseif plotIdx == 2
                title('Bowon');
            elseif plotIdx == 3
                title('Jongmin');
            else
                title('Daehyun');
            end
            ylim([-20 20]);
            
        end
    end
    
    t = t + 1;
    pause(0.001);
end


