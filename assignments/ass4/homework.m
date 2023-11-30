%Olujide Jacobs
%Homework 4
%Yun Lin
%2/8/2012

%Problem 1a
5+3>32/4;
%5+3 is equal to 8
%32/4 is equal t 8
%so 8 can't be greater than 8, therefore the answer is false

%Problem 1b
y = 2*3>(10/5)+1>2^2;
%2*3 is equal to 6
%(10/5)+1 is equal to 3
%2^2 is equal to 4
%6 > 3 is true but 3 > 4 is false, so the overall expression is false

%Problem 1c
y = 2*(3>10/5)+(1>2)^2;
%3>(10/5 = 2) is true
%(1>2)^2 is true
%therefore 2*true is true, so the expression is true

%Problem 1d
5*3-4*4<=~2*4-2+~0;
%5*3-4*4 is equal to -1
%2*4-2+~0 is equal to 7
%so -1 is less than or not equal to 7, therefore the expression is true

%Problem 3
v = [4 -2 -1 5 0 1 -3 8 2];
u = [0 2 1 -1 0 -2 4 3 2];

%1a
~(~v);
%the expression is true

%1b
u==v;
%the expression is false because most of the elements are not the same
%apart from 0 and 2

%1c
u-v<u;
%the expression is true, most of the elements are true

%1d
u-(v<u);
%the expression is false

%Problem 6
TCH = [75 79 86 86 79 81 73 89 91 86 81 82 86 88 89 90 82 84 81 79 73 69 73 79 82 72 66 71 69 66 66];
TSF = [69 68 70 73 72 71 69 76 85 87 74 84 76 68 79 75 68 68 73 72 79 68 68 69 71 70 89 95 90 66 69];

%1a
tch_ave = mean(TCH);
tsf_ave = mean(TSF);
fprintf('The average temperature in Chicago and San Fransisco are %-1.4f and %-1.4f.\n',tch_ave,tsf_ave)

%1b
TCH>tch_ave;
%the temperature in chicago was above the average in 16 different days
TSF>tsf_ave;
%the temperature in chicago was above the average in 11 different days
x=length(find(TCH>tch_ave));
y=length(find(TSF>tsf_ave));
fprintf('The temperature in chicago was above average in %i days.\n',x)

%1c
%the temperature in san fransisco was lower than the temperature in chicago
%in 23 different days(1-9th,11th,13-20th,22-26th)
w=length(find(TSF<TCH));
fprintf('The temperature in San fransisco was lower than that in Chicago in %i different days.\n',w)
%1d
%the temperature in both cities was the same just on one day(29th)
v=length(find(TSF==TCH));
fprintf('The temperature in San fransisco and Chicago were same in %i different days.\n',v)