% colormap summer
% mapwidth=0.1:0.01:10;
% mapheight=1000;
% plot(mapwidth,mapheight)
%page 247 for projectile

%tank1
s=input('Enter the speed: ');
a=input('Enter the angle: ');
hold on
for d=1:0.01:10
    [x,y]=angle(s,a,d);
    comet(x,y)
    if y<=0 %0 is the ground level
        break;
    end
end
xlabel('Distance')
ylabel('Height')
hold off