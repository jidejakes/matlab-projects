%Olujide Jacobs
%Homework 5
%Yun Lin
%2/22/2012
clear
clc
format bank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Problem 13%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%define variables
m=input('Enter 5, 10 or 20 as a value for m: ');
%calculation
sum_ax=0;
for n=0:m
    ax=sqrt(12)*((-1/3)^n)/(2*n+1);
    sum_ax=sum_ax+ax;
end
%output
disp(sum_ax)
fprintf('When m is %i, the value is %-.3f\n',m,sum_ax)
%comparison
if sum_ax==pi
        disp(pi)
        fprintf('when m is %i, it equals pi(%-.3f)\n',m,sum_ax)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Problem 18%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%define variable
an=input('Enter a value: ');
%calculation
x=an*pi/180;
s(1)=0;
E=1;
n=0;
while E>=0.000001
        s(n+2)=s(n+1) + (((-1)^n)/factorial(2*n+1))*((x)^(2*n+1)); 
        E=abs((s(n+2)-(s(n+1)))/s(n+1));
        n=n+1;
end
angle=sind(45);
fprintf('When x is %-.2f, sin(%-.2f) is %-.4f\n',an,an,s(n+1))
fprintf('The value of sin(45) with a calculator is %3.6f\n',angle)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Problem 22%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
W=input('Please enter your weight in pounds: ');
H=input('Please enter your height in inches: ');
BMI=703*(W/(H^2));
if BMI<18.5;
   fprintf('Your BMI value is %.1f which classifies you as Underweight\n',BMI)
elseif BMI>=18.5 && BMI<24.9
   fprintf('Your BMI value is %.1f which classifies you as Normal\n',BMI)
elseif BMI>=25.0 && BMI<29.9
   fprintf('Your BMI value is %.1f which classifies you as Overweight\n',BMI)
elseif BMI>=30
   fprintf('Your BMI value is %.1f which classifies you as Obese\n',BMI)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%extra%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
B=input('Enter % of body fat: ');
WE=input('Enter weight in pounds: ');
PF=(B/100)*WE;
fprintf('You have %.1f pounds of fat and you have to lose %.1f pounds for your BMI to be Normal\n',PF,PF)