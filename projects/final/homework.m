%Olujide Jacobs
%Homework 9
%Yun Lin
%18th april 2012

clear
clc
format bank
x=input('Please enter the height of the water in the tank: ');
v=vol(x);
fprintf('When the water height is %-1.0f, the volume is %-1.0f.\n',x,v)
t=0:1:x;
l=(1000*t)+x;
plot(t,l)
xlabel('Time (min)')
ylabel('Water Inlet (m^3)')
grid on
title('Time history of water level')

