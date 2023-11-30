%Olujide Jacobs
%Project 1
%Yun Lin
%2/14/2012

close all
clear all
clc

%Problem a
%Import excel file
x=xlsread('Data.xls');
%define variables and create table
time=x(:,1);
dose1=x(:,2);
dose2=x(:,3);
dose3=x(:,4);
%table=[time dose1 dose2 dose3];
%disp('    time      dose1     dose2     dose3');
%disp(table);
%plot graph of concentration against time
plot(time,dose1)
xlabel('time (hrs)')
ylabel('concentration (ug/dL)')
hold on
plot(time,dose2,'--red')
hold on
plot(time,dose3,'--green')
hold on
%I'm going to proceed with Dose 2

%Problem b
%define variables for half life
max1=max(dose1);
max2=(max1)/2;
t=find(dose1==max1);
%calculate the half life
%the loop function was used to calculate the half life of each dose
for i=t:600;
    if dose1(i)<=(max2);
        t2=i;
        break;
    end
end
half_life=t2-t;
fprintf('The halflife of dose 1 is %-6.3f\n',half_life)

%Problem c
max3=max(dose2);
max3_2=(max3)/2;
t3=find(dose2==max3);
for i=t3:600;
    if dose2(i)<=(max3_2);
        t4=i;
        break;
    end
end
half_life2=t4-t;
max5=max(dose3);
max3_3=(max5)/2;
t5=find(dose3==max5);
for i=t5:600;
    if dose3(i)<=(max3_3);
        t6=i;
        break;
    end
end
half_life3=t6-t5;
fprintf('The halflife of dose 2 is %-6.3f\nThe halflife of dose 3 is %-6.3f\n' ,half_life2,half_life3)
p=100;
d1=dose2';
d2=zeros(1,p);
d2((p+1):(600))=d1(1:500);
d3=zeros(1,(2*p));
d3((2*p)+1:600)=d1(1:400);
d4=zeros(1,(3*p));
d4((3*p)+1:600)=d1(1:300);
overall=d1+d2+d3+d4;
plot(time,overall)
xlabel('time (hrs)')
ylabel('overall (ug/dL)')
hold off
px=600/4;
fprintf('The pill should be taken every %-3.2f hours\n',px)