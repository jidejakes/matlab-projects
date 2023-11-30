clear
clc
%Create Terrain
s=input('Enter the speed: ');
an=input('Enter the angle: ');
hold on
y = randperm(5); 
N = length(y);
L = 10;
M = N*L;
x = 0:L:L*N-1;
xi = 0:M-1;
yi = interpft(y,M);
%Create Tank 1
p=randi(8); ...Random placement of tank 1
p2=p+2;
yi(p:p2)=min(yi(p:p2)); ...Flatten Spot for Tank 1
B=length(yi(p:p2));
c=min(yi(p:p2));
tank1=rectangle('Position',[p,c,B/2,B*.09]);
%Create Tank 2
P=50-p; %Random placement of tank 2
P2=P+2;
yi(P:P2)=max((P:P2)); %Flatten Spot for Tank 2
B2=length(yi(P:P2));
c2=min(yi(P:P2));
tank2=rectangle('Position',[P,c2,B2/2,B2*.09]);
%Plot Terrain
area(yi);   
colormap summer
a=max(yi)*1.5;
plot(tank1)
plot(tank2)
axis([min(yi) 50 0 a])
for d=1:0.01:10
    [x,y]=angle(s,an,d);
    comet(x,y)
    if y<=0 %0 is the ground level
        break;
    end
end
xlabel('Distance')
ylabel('Height')