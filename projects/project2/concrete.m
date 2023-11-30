%Olujide Jacobs & Eric Peterson
%Project 2
%Yun Lin
%3/13/2012

clear
clc
%import excel file and create columns
hd=xlsread('Heat_data.xlsx');
%define variables and plot graphs of temperature and time then heat flux
%and time
t=hd(:,1);%separate columns
T=hd(:,2);
hf=hd(:,3);
m=6;%weight of concrete
c=0.8;%specific heat
plot(t,T,'--b')
title('Graph of temperature against time')
grid on
xlabel('Time(hrs)')
ylabel('Temperature(C)')
hold off
figure
%plot heat flux and time
plot(t,hf,'--r')
title('Graph of heat flux against time')
grid on
xlabel('Time(hrs)')
ylabel('Heat Flux(KJ)')
hold off
figure
%calculate heat loss, plot graph of adiabatic temperature and time
%we have to use loops to calculate every step
heat=0;
for i=1:length(hf)
    heat=heat+hf(i);
    adt(i)=T(i)+heat/(m*c);
end
plot(t,adt,'--b')
title('Graph of adiabatic temperature against time')
grid on
xlabel('Time(hrs)')
ylabel('Adiabatic temperature(C)')
hold off
figure
%plot graph of adiabatic temperature rise and time by taking minimmum adiabatic
%temperature from original adiabatic temperature
adtr=adt-min(adt);
plot(t,adtr,'--r')
title('Graph of adiabatic temperature rise against time')
grid on
xlabel('Time(hrs)')
ylabel('Adiabatic temperature rise(C)')
hold off