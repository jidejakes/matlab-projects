%Olujide Jacobs
%Homework 7
%Yun Lin
%3/7/2012

clear
clc
format bank

%Problem 1
%define variables
m=input('Enter either 20 or 600 as your value for m: ');
sum_ax=0;
%calculation
for n=0:m
    ax=((-1)^n)*(1/(2*n+1)); %sumation
    sum_ax=sum_ax+ax;   
end
%output
fprintf('When m is %i, the value is %-2.15f\n',m,sum_ax)
%comparison
x=pi/4;
fprintf('pi/4 is equal to %-2.15f and the value when m is %i is %-2.15f\n',x,m,sum_ax) %compared the value of m to pi/4
fprintf('\n')

%Problem 2
%define variables
k=zeros(4,7);
for j=1:7
    for i=1:4
        if rem(i,2)==0 || rem(j,2)==0  %if i and j are even
        k(i,j)=(i+j)^2;
        else k(i,j)=sqrt(i+j); %if not
        end
    end
end
disp(k)
fprintf('\n')

%Problem 3
%define variables
at=[];
vt=[];
i=1;
for t=0:47
    at(i)=-0.12*t^4+12*t^3-380*t^2+4100*t+220;
    vt(i)=-0.48*t^3+36*t^2-760*t+4100;
    if at(i)<1000
      disp('Error: The balloon has fallen below radar') %error message when ballonn falls below radar. condition
    end
    i=i+1;
    
end
%table
  x=[at' vt'];
  disp('      Altitude      Velocity')
  disp(x)