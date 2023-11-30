clear
clc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                        %
%                   Create Terrain                                       %
%                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create Terrain
hold on
v0=input('power:  ');%user defines power
theta= input('degree:  ');%user defines angle
Ty = randperm(5); 
N = length(Ty);
hold on 
L = 20;
M = N*L;
Tx = 0:L:L*N-1;
xi = 0:M-1;
yi = interpft(Ty,M);
%Create Tank 1
p=randi(8); ...Random placement of tank 1
%p=TANK_p;
p2=p+2;
yi(p:p2)=min(yi(p:p2)); ...Flatten Spot for Tank 1
B=length(yi(p:p2));
c=min(yi(p:p2));
tank1=rectangle('Position',[p,c,B/1.1,B*.15]);
%Create Tank 2
P=98-p; %Random placement of tank 2
P2=P+2;
yi(P:P2)=min(yi(P:P2)); %Flatten Spot for Tank 2
B2=length(yi(P:P2));
c2=min(yi(P:P2));
tank2=rectangle('Position',[P,c2,B2/1.1,B2*.15]); 
%Plot Terrain
h=area(yi);   
colormap summer
a=max(yi)*1.5;
plot(tank1)
plot(tank2)
axis([min(yi) 100 0 a])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                       %
%                      Trajectory                                       %
%                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TESTLP=randi(100);
TESTLP2=randi(100);
for TESTLP=TESTLP2
%g=9.81;
v0x=v0*cos(theta*pi/180);
v0y=v0*sin(theta*pi/180);
%thmax=v0y/g;
%hmax=v0y^2/(2*g);
%ttot=2*thmax;
%dmax=v0x*ttot;
%tplot=linspace(0,ttot,100);
sft=(p+(B2/8));
%xt=v0x*tplot +sft;
%yt=v0y*tplot-0.5*g*tplot.^2+c ;
%comet(xt,yt)
%[h d]=trajectory(25,39)
%hold off 
%%  Work in SI units.   
%%  My catapult launches from a height of 3/4 meters (see y_0 below). 
%%  Remember that 10 m/s is about 20 miles per hour. 
%%  One tenth second time steps is most likely too large. 
x_0 = sft; %  1) the initial x-position,  
y_0 = c; %  2) the initial y-position,  
v_x_0 = v0x; %  3) the initial x-velocity, you have to estimate 
v_y_0 = v0y; %  4) the initial y-velocity, you have to estimate 
dt = 0.1; %  5) the time interval between calculation steps 
mass = 5;  %  6) the mass of the projectile. Found online for 
%racquetball. 
Area = 1.02e-2; %  a) the projectile?s cross sectional area, A, 
rho = 1.2; %  b) the density of air 
C_drag = 0.5; %  c) the projectile?s drag/aerodynamic coefficient, Cdrag, 
g = 9.8; % 8) gravity, 
%%  How many iterations will you run? 
N_steps = 10000; %  Make large enough for projectile to strike ground. 
%%  Now define arrays that will hold data. 
x = zeros(1,N_steps + 1); %  1) x-position,  
x(1) = x_0; %  Make sure initial value is correct. 
y = zeros(1,N_steps + 1); %  2) y-position,  
y(1) = y_0; %  Make sure initial value is correct. 
v_x = zeros(1,N_steps + 1); %  3) x-velocity,  
v_x(1) = v_x_0; % Make sure initial value is correct. 
v_y = zeros(1,N_steps + 1); %  4) y-velocity,  
v_y(1) = v_y_0; % Make sure initial value is correct. 
%%  Use formulas for acceleration later, just define as 0 for now. 
a_x = 0; %  5) x-acceleration, 
a_y = 0; %  6) y-acceleration.   
angle = tan(v_y_0 / v_x_0);  %  Defining the trajectory angle will save on 
%thinking. 
%{   
Note that a_drag has x and y components, and that a_drag is given by 
a_drag_x = -C_drag*.5*rho*Area*(v_x^2 + v_y^2)/mass*cos(angle) and 
a_drag_y = -C_drag*.5*rho*Area*(v_x^2 + v_y^2)/mass*sin(angle). 
%} 
%%  Now make loop to calculate the data based upon the forces. 
i_loop = 1; 
n_loop = 1; 
while i_loop < N_steps, %  Skip the initial values. 
      angle = tan(v_y(i_loop) / v_x(i_loop)); 
      a_x = -C_drag*.5*rho*Area*(v_x(i_loop)^2 + ...
      v_y(i_loop)^2)/mass*cos(angle); 
      v_x(i_loop+1) = v_x(i_loop) + a_x*dt; %  Remember: v = v_o + a*t  
      x(i_loop + 1) = x(i_loop) + v_x(i_loop)*dt + .5*a_x*dt^2; % Rem: 
%x=p+v_y*t+.5*g*t^2 
     a_y = -g - C_drag*.5*rho*Area*(v_x(i_loop)^2 +...
v_y(i_loop)^2)/mass*sin(angle); 
    v_y(i_loop +1) = v_y(i_loop) + a_y*dt; %  Remember: v = v_o + a*t  
    y(i_loop + 1) = y(i_loop) + v_y(i_loop)*dt + .5*a_y*dt^2; % Rem: 
%y=c+v_o*t+.5*a*t^2 
    %%  If the projectile passes below the ground, we want to stop.   
    if y(i_loop+1) < 0, 
        i_loop = N_steps; 
        n_loop = n_loop+1; 
    else 
        i_loop = i_loop+1; 
        n_loop = n_loop+1; 
    end; 
end;
%{ 
%If we leave the loop early because the ball is lower than the ground, 
%we want to delete the extra data that is still stored as zeros. 
%} 
% if n_loop < N_steps, 
%     x(n_loop:end) = [ ]; % Empties out rest of array. 
%     y(n_loop:end) = [ ];
    comet(x,y)
end