function [ x,y ] = angle( s,a,d )
%calculate the distance
x=s*cosd(a)*d;
y=s*sind(a)*d+0.5*(-10)*d^2;
end