clear
clc
close all hidden
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                        %
%                         Create Terrain                                 %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%CREATE TERRAIN
% Picks (n) random numbers to make plot. Can be changed for different
% effects. n*L gives length of field.
power=input('power:  ');
theta= input('degree:  ');
Ty = randperm(5); 
N = length(Ty);
hold on

L = 20;
M = N*L;
Tx = 0:L:L*N-1;
xi = 0:M-1;
yi = interpft(Ty,M); % Terrain 'Function'

%--------------------------------------------------------------------------
%                      PLACE AND DRAW 'TANKS'            
%--------------------------------------------------------------------------
%Create Tank 1
p=randi(8); ...Max distance of tanks from border. 
              
p2=p+2;
yi(p:p2)=min(yi(p:p2)); ...Flatten Spot on for Tank 1 (modifies yi)

B=length(yi(p:p2)); % Width of Flat Spot
c=min(yi(p:p2));     % Min Value of 'yi'


%Create Tank 2
P=98-p; %Random placement of tank 2
P2=P+2;
yi(P:P2)=min(yi(P:P2)); %Flatten Spot for Tank 2


B2=length(yi(P:P2));
c2=min(yi(P:P2));
sft=(p+(B2/8)); %Center of Tank

%Plot Tanks
tank1=rectangle('Position',[p,c,B/2,B*.09]);
tank2=rectangle('Position',[P,c2,B2/2,B2*.09]);


%Plot Terrain
h=area(yi);   

colormap summer
a=max(yi)*1.5;
plot(tank1)
plot(tank2)
axis([min(yi) M 0 a])  %axis([min(yi) 100 0 a])




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                       %
%                      Trajectory. USE SI UNITS!!                       %
%                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


TESTLP=rand(100); % This to be replaced by 'shot/ground contact' 
TESTLP2=rand(100);% Here to keep loop running

wind=randi(50)-randi(50); % Make this better!

while TESTLP~=TESTLP2


if power==0;
    break;
end
v0=power/10;


v0x=v0*cos(theta*pi/180);
v0y=v0*sin(theta*pi/180);

%!!!!!!!!Remember, SI units!!!!!!!!!!!!!!!!!!!!! 

x_0 = sft; % initial x-position Tank 1 
y_0 = c; % initial y-position  Tank 1
mass = 43.88;  % the mass of the projectile(M107 155mm)
Area = 1.55; % projectiles cross sectional area
rho = 1.2; % density of air
C_drag = 0.5; % projectiles drag/aerodynamic coefficient 
% g = 9.8; % gravity




g=9.81;
v0x=v0*cos(theta*pi/180);
v0y=v0*sin(theta*pi/180);
thmax=v0y/g;
hmax=v0y^2/(2*g);
ttot=2*thmax;
dmax=v0x*ttot;
tplot=linspace(0,ttot,200);
x=v0x*tplot+p;
y=v0y*tplot-0.5*g*tplot.^2 +c;
comet(x,y)




%shot=plot(xvar , yvar);
%disp('Hit Any Key To Continue')
%pause
%delete(shot)
end
