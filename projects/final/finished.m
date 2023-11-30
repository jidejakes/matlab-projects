%I fixed out of bounds issue and made the random placement window bigger.

% Project 3
% Yun Lin
% 4/22/2012
 
clear
clc
 
disp('                     Bunker Buster    ')
disp('    ')
disp(' Objective: Destroy other player before he destroys you!')
disp('     ')
disp('    Players must input power of cannon (1 to 600)')
disp('    ')
disp('    Players must input angle of cannon (0 to 90)')
disp('    ')
disp('  To exit game at any time, enter 0 for power input')
disp('      ')
disp('      ')
 
 
close all hidden
format bank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                        %
%                         Create Terrain                                 %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%CREATE TERRAIN
Ty = randperm(5); % Picks (n) random numbers to make plot. Can be 
N = length(Ty);% changed for different effects. n*L gives length of field.
hold on
 
L = 40;
M = N*L;
xi = 0:M-1;
yi = interpft(Ty,M); % Terrain 'Function'
 
%--------------------------------------------------------------------------
%                      PLACE AND DRAW 'TANKS'            
%--------------------------------------------------------------------------
%Create Tank 1
p=randi(40); ...Max distance of tanks from border. 
              
p2=p+2;
yi(p:p2)=min(yi(p:p2)); ...Flatten Spot on for Tank 1 (modifies yi)
B=length(yi(p:p2)); % Width of Flat Spot
c=min(yi(p:p2));     % Min Value of 'yi'
 
%Create Tank 2
P=198-p; %Random placement of tank 2
P2=P+2;
yi(P:P2)=min(yi(P:P2)); %Flatten Spot for Tank 2
 
B2=length(yi(P:P2));
c2=min(yi(P:P2));
 
%Plot Tanks
tank1=rectangle('Position',[p,c,B/2,B*.09]);
tank2=rectangle('Position',[P,c2,B2/2,B2*.09]);
%Plot Terrain
hT=area(yi);   
colormap summer
a=max(yi)*2;
plot(tank1)
plot(tank2)
axis([min(yi) M 0 a])  %axis([min(yi) 100 0 a])
xlabel('Player 1                                                                                                Player 2')
title(' Bunker Buster ') 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                       %
%                      Trajectory                                       %
%                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%-----------Tank Int. Pos-------------------
x_0 = (p+(B/4)); % initial x-position Tank 1 
y_0 = c+(B*.09); % initial y-position Tank 1
 
x2_0=(P+(B2/4)); % initial x-position Tank 2
y2_0=c2+(B*.09); % initial y-position Tank 2
%-------------------------------------------
 
Player2_Health=100;
Player1_Health=100;
remaining_health2=100;
remaining_health1=100;
 
while remaining_health2>0 && remaining_health1>0
power=input('Player 1 Shoots\n  Power:  ');
if power==0;
   close all hidden 
    break
end
v0=power/10;
theta= input(' Degree:  ');
 
v0x=v0*cos(theta*pi/180);
v0y=v0*sin(theta*pi/180);
 
g = 9.8; % gravity
thmax=v0y/g;
hmax=v0y^2/(2*g);
ttot=2.5*thmax;
dmax=v0x*ttot;
tplot=linspace(0,ttot,200);
x=x_0+ v0x*tplot;
y=y_0+ v0y*tplot-0.5*g*tplot.^2; 
 
% Find Ground Contact
s = yi - y;
ix = find(s > -.5 & s < .5);
x_sol = x(ix); %y1_sol = y(ix)...%y2_sol = yi(ix)
d=round(max(x_sol)); % Intersection of yi
 
r=1; %r is the radius of the circle
ang=0:0.01:2*pi; %0.01 is the angle step
xp=r*4*cos(ang);
yp=.5*r*sin(ang);
 
if x_sol<=200 && yi(d)<=200
blast=plot(max(x_sol) + xp,yi(d) + yp,'r');
 
%-Distance Blast To Tank2------------------------------------------------
 
dist2=sqrt(((x2_0-d)^2)-((y2_0-yi(d))^2)); % Distance from blast to tank
damage2=((1/dist2)*175);
 
% Player 2 Health--------------------------------------------------------
 
for i=1:1
    if dist2<=10
       Player2_Health= Player2_Health(i)-damage2;
       
    elseif dist2<1
        disp('DIRECT HIT')
    end
end
remaining_health2=min(Player2_Health);
if remaining_health2<=0
    disp('Player 1 Wins Booyaah!!!')
    break
end
 
%--Plot and Delete Hit----------------------------------------------------
 
h=plot(x,y,'r');
area(yi); %covers trajectory below grade
disp('Hit Any Key To Continue')
pause
delete(h)
delete(blast)
clc
else disp('out of bounds ')
end
%------------------------------------------------------------------------%
%            SWITCH PLAYERS
%------------------------------------------------------------------------%
 
power2=input('Player 2 Shoots\n  Power:  ');
if power2==0;
   close all hidden 
    break
end
 
%-Trajectory Player 2-----------------------------------------------------
 
v20=power2/10;
Player2_angle= input(' Degree:  ');
theta2=180-Player2_angle;
v0x=v20*cos(theta2*pi/180);
v0y=v20*sin(theta2*pi/180);
 
thmax=v0y/g;
hmax=v0y^2/(2*g);
ttot=2.5*thmax;
dmax=v0x*ttot;
tplot=linspace(0,ttot,200);
x2=x2_0+ v0x*tplot;
y2=y2_0+ v0y*tplot-0.5*g*tplot.^2;
 
%-Find Ground Contact----------------------------------------------------
s = yi - y2;
ix = find(s > -.5 & s < .5);
x_sol2 = x2(ix); %y1_sol = y(ix)...y2_sol = yi(ix)
d2=round(min(x_sol2)); % Intersection of yi
 
%---Plot Blast 2---------------------------------------------------------
r=1; %r is the radius of the circle
ang=0:0.01:2*pi; %0.01 is the angle step
xp=r*4*cos(ang);
yp=.5*r*sin(ang);
 
if x_sol2>=0 && yi(d2)>=0
blast=plot(min(x_sol2)+xp,yi(d2)+yp,'r');
 
%-Distance Blast To Tank1-------------------------------------------------
 
dist1=sqrt(((x_0-d2)^2)-((y_0-yi(d2))^2)); % Distance from blast to tank
damage1=((1/dist1)*175);
 
% Player 1 Health----------------------------------------------------
 
for i=1:1
    if dist1<=10
       Player1_Health = Player1_Health(i)-damage1;
    elseif damage1 <=0
        disp('DIRECT HIT')
    end
end
remaining_health1=min(Player1_Health);
if remaining_health1<=1
    disp('Player 2 Wins Booyaah!!!')
    break
end
 
% Plot and Delete Hit-----------------------------------------------------
 
h2=plot(x2,y2,'r');
area(yi); %covers trajectory below grade
 
disp('Hit Any Key To Continue')
pause
delete(h2)
delete(blast)
clc
else disp('out of bounds ')
end
 
end
hold off