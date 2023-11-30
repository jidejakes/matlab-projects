%Olujide Jacobs
%Homework 3
%Yun Lin
%2/1/2012

%Problem 1a&b
format bank
%define variables
x = -3;
y = ((x-(pi))*((x^(2/3))+45))/x^3;
%open file from source
fid = fopen('value.txt','w');
%print file
fprintf(fid,'When x = -3, y is %-12.6f\n',y);

%define variables
x = 10;
y = ((x-(pi))*((x^(2/3))+45))/x^3;
%print file
fprintf(fid,'When x = 10, y is %-12.6f\n',y);

%Problem 1c
%define variables
x = -3:1:5;
y = ((x-(pi)).*((x.^(2./3))+45))./x.^3;
r = [x;y];
%print file
fprintf(fid,'When x = %i, y is %-12.6f\n',r);

%Problem 1d
%define variable
z = [x',y'];
%display file and create table
disp('             x             y')
disp(z);
fclose(fid);