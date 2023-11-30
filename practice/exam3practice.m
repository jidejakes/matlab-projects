format bank
x=0;
v=1:20;
for i=1:length(v)
    x=x+v(i)+1;
end
disp(x)

%2
%chapter 6 number 13
m=input('Enter either 5, 10 or 20: ');
sum_a=0;
for n=0:m
    ax=sqrt(12)*((-1/3)^n)/(2*n+1);
    sum_a=sum_a+ax;
end
fprintf('When m is %i, the value is %-1.4f.\n',m,sum_a)