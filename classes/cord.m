function [ x,y ] = cord( v,a,t )
%calculate the horizontal distance
x=v*cosd(a)*t;
y=v*sind(a)*t+0.5*(-9.8)*t^2;
end