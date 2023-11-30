v=15;
a=45;
hold on
for i=0.001:0.001:3
    [x,y]=cord(v,a,i);
    plot(x,y)
    if y<=0
        break
    end
end
hold off