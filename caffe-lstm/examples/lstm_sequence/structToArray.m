function [ out ] = structToArray( in )
%STRUCTTOARRAY Summary of this function goes here
%   Detailed explanation goes here

out = [[in.timestamp]' reshape([in.accel]', [3 length(in)])' [in.clip]' [in.label]'];

end

