function [hmax,dmax]=trajectory(~,~)
% max height and distance
%inputs
%v0=int vel (m/s)
%theta=angle in deg
%outputs:
%hmax=max height(m)
%dmax=max dist(m)
v0=input('Enter Velocity: ');
theta=input('Enter Angle: ');
%Create Terrain
y = randperm(5); 
N = length(y);
L = 10;
M = N*L;
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
yi(P:P2)=min((P:P2)); %Flatten Spot for Tank 2
B2=length(yi(P:P2));
c2=min(yi(P:P2));
tank2=rectangle('Position',[P,c2,B2/2,B2*.09]);
%Plot Terrain
area(yi);   
colormap summer
a=max(yi)*1.5;
hold on
plot(tank1)
plot(tank2)
axis([min(yi) 50 0 a])
g=9.81;
v0x=v0*cosd(theta*pi/180);
v0y=v0*sind(theta*pi/180);
thmax=v0y/g;
hmax=v0y^2/(2*g);
ttot=2*thmax;
dmax=v0x*ttot;
tplot=linspace(0,ttot,200);
x=v0x*tplot;
y=v0y*tplot-0.5*g*tplot.^2;
comet(x,y)