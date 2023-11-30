%Olujide Jacobs
%Homework 9
%Yun Lin
%4/18/2012

clear
clc
format bank
x=input('Please enter the height of the water in the tank: '); %user defines water level
if x<=50 %conditional statement is used to evaluate the volume in each case
v=vol(x);
fprintf('When the water height is %-1.0f, the volume is %-1.0f.\n',x,v)
tf=v/1000;
t=0:1:tf;
l=(1000*t)+x;
plot(t,l)
xlabel('Time (min)')
ylabel('Water Inlet (m^3)')
grid on
title('Time history of water level')
else
fprintf('The height has been exceeded.\n')%if the condition isn't satisfied, an error message is displayed
end