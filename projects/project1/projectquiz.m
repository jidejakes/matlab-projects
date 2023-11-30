x=1:5;
for x=1:3;
    f1=x^2
end
for x=2:4;
    f2=(5*x)-10
end
for x=3:5;
    f3=((x)-(2*x-5))/x
end
f=[f1;f2;f3]
plot(x,f)