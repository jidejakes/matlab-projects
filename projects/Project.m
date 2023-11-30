%Project

clear
clc
format bank

DA = [349 1800 1.25 12; 598 852 1.25 12; 2199 9600 1 19; 700 12720 1 19; 2070 1411 7.5 14; 3259 725 7.5 14; 709 1000 0.5 8; 599 1500 0.5 8; 349 1800 0.75 12; 855 600 0.75 12; 449 5280 1.5 14; 899 7200 1.5 14];

% Total_Cost = Initial_Price(dollars) + ((0.0907444*Power/1000)/24(kW/d) * Time(day) * Life(day))

time_dishwasher = linspace(0,DA(1,4)*365,10);
Dishwasher1 = DA(1,1) + (0.0907444*((DA(1,2)/1000) * DA(1,3))) * time_dishwasher;
Dishwasher2 = DA(2,1) + (0.0907444*((DA(2,2)/1000) * DA(2,3))) * time_dishwasher;
figure
plot(time_dishwasher,Dishwasher1,time_dishwasher,Dishwasher2,'-r')
title('Dishwasher cost vs Time')
xlabel('Time (days)')
ylabel('Cost (dollars)')
legend('Dishwasher 1', 'Dishwasher 2')

time_oven = linspace(0,DA(3,4)*365,10);
Oven1 = DA(3,1) + (0.0907444*((DA(3,2)/1000) * DA(3,3))) * time_oven;
Oven2 = DA(4,1) + (0.0907444*((DA(4,2)/1000) * DA(4,3))) * time_oven;
figure
plot(time_oven,Oven1,time_oven,Oven2,'-r')
title('Oven cost vs Time')
xlabel('Time (days)')
ylabel('Cost (dollars)')
legend('Oven 1', 'Oven 2')

time_refrigerator = linspace(0,DA(5,4)*365,10);
Refrigerator1 = DA(5,1) + (0.0907444*((DA(5,2)/1000) * DA(5,3))) * time_refrigerator;
Refrigerator2 = DA(6,1) + (0.0907444*((DA(6,2)/1000) * DA(6,3))) * time_refrigerator;
figure
plot(time_refrigerator,Refrigerator1,time_refrigerator,Refrigerator2,'-r')
title('Refrigerator cost vs Time')
xlabel('Time (days)')
ylabel('Cost (dollars)')
legend('Refrigerator 1', 'Refrigerator 2')

time_microwave = linspace(0,DA(7,4)*365,10);
Microwave1 = DA(7,1) + (0.0907444*((DA(7,2)/1000) * DA(7,3))) * time_microwave;
Microwave2 = DA(8,1) + (0.0907444*((DA(8,2)/1000) * DA(8,3))) * time_microwave;
figure
plot(time_microwave,Microwave1,time_microwave,Microwave2,'-r')
title('Microwave cost vs Time')
xlabel('Time (days)')
ylabel('Cost (dollars)')
legend('Microwave 1', 'Microwave 2')

time_washer = linspace(0,DA(9,4)*365,10);
Washer1 = DA(9,1) + (0.0907444*((DA(9,2)/1000) * DA(9,3))) * time_washer;
Washer2 = DA(10,1) + (0.0907444*((DA(10,2)/1000) * DA(10,3))) * time_washer;
figure
plot(time_washer,Washer1,time_washer,Washer2,'-r')
title('Washer cost vs Time')
xlabel('Time (days)')
ylabel('Cost (dollars)')
legend('Washer 1', 'Washer 2')

time_dryer = linspace(0,DA(11,4)*365,10);
Dryer1 = DA(11,1) + (0.0907444*((DA(11,2)/1000) * DA(11,3))) * time_dryer;
Dryer2 = DA(12,1) + (0.0907444*((DA(12,2)/1000) * DA(12,3))) * time_dryer;
figure
plot(time_dryer,Dryer1,time_dryer,Dryer2,'-r')
title('Dryer cost vs Time')
xlabel('Time (days)')
ylabel('Cost (dollars)')
legend('Dryer 1', 'Dryer 2')

disp('From the graph, the most cost effective option does not change over its lifespan, it is constant.')
disp('         ')

%cost after using for 5 years
Dishwasher1cost = DA(1,1) + (0.0907444*((DA(1,2)/1000) * DA(1,3))) * 5*365;
Dishwasher2cost = DA(2,1) + (0.0907444*((DA(2,2)/1000) * DA(2,3))) * 5*365;
Oven1cost = DA(3,1) + (0.0907444*((DA(3,2)/1000) * DA(3,3))) * 5*365;
Oven2cost = DA(4,1) + (0.0907444*((DA(4,2)/1000) * DA(4,3))) * 5*365;
Refrigerator1cost = DA(5,1) + (0.0907444*((DA(5,2)/1000) * DA(5,3))) * 5*365;
Refrigerator2cost = DA(6,1) + (0.0907444*((DA(6,2)/1000) * DA(6,3))) * 5*365;
Microwave1cost = DA(7,1) + (0.0907444*((DA(7,2)/1000) * DA(7,3))) * 5*365;
Microwave2cost = DA(8,1) + (0.0907444*((DA(8,2)/1000) * DA(8,3))) * 5*365;
Washer1cost = DA(9,1) + (0.0907444*((DA(9,2)/1000) * DA(9,3))) * 5*365;
Washer2cost = DA(10,1) + (0.0907444*((DA(10,2)/1000) * DA(10,3))) * 5*365;
Dryer1cost = DA(11,1) + (0.0907444*((DA(11,2)/1000) * DA(11,3))) * 5*365;
Dryer2cost = DA(12,1) + (0.0907444*((DA(12,2)/1000) * DA(12,3))) * 5*365;

disp('    Appliance Options and Costs for 5 year Timeframe')
disp('  --------------------------------------------------------------')
disp('      App   Opt1 Price   Energy Cost   Opt2 Price   Energy Cost')
a = [{'Dish'} DA(1,1)' Dishwasher1cost' DA(2,1)' Dishwasher2cost'];
b = [{'Oven'} DA(3,1)' Oven1cost' DA(4,1)' Oven2cost'];
c = [{'Refr'} DA(5,1)' Refrigerator1cost' DA(6,1)' Refrigerator2cost'];
d = [{'Mcrv'} DA(7,1)' Microwave1cost' DA(8,1)' Microwave2cost'];
e = [{'Wshr'} DA(9,1)' Washer1cost' DA(10,1)' Washer2cost'];
f = [{'Dryr'} DA(11,1)' Dryer1cost' DA(12,1)' Dryer2cost'];
disp(a)
disp(b)
disp(c)
disp(d)
disp(e)
disp(f)

%cost after using for 10 years
Dishwashers1cost = DA(1,1) + (0.0907444*((DA(1,2)/1000) * DA(1,3))) * 10*365;
Dishwashers2cost = DA(2,1) + (0.0907444*((DA(2,2)/1000) * DA(2,3))) * 10*365;
Ovens1cost = DA(3,1) + (0.0907444*((DA(3,2)/1000) * DA(3,3))) * 10*365;
Ovens2cost = DA(4,1) + (0.0907444*((DA(4,2)/1000) * DA(4,3))) * 10*365;
Refrigerators1cost = DA(5,1) + (0.0907444*((DA(5,2)/1000) * DA(5,3))) * 10*365;
Refrigerators2cost = DA(6,1) + (0.0907444*((DA(6,2)/1000) * DA(6,3))) * 10*365;
Microwaves1cost = DA(7,1) + (0.0907444*((DA(7,2)/1000) * DA(7,3))) * 10*365;
Microwaves2cost = DA(8,1) + (0.0907444*((DA(8,2)/1000) * DA(8,3))) * 10*365;
Washers1cost = DA(9,1) + (0.0907444*((DA(9,2)/1000) * DA(9,3))) * 10*365;
Washers2cost = DA(10,1) + (0.0907444*((DA(10,2)/1000) * DA(10,3))) * 10*365;
Dryers1cost = DA(11,1) + (0.0907444*((DA(11,2)/1000) * DA(11,3))) * 10*365;
Dryers2cost = DA(12,1) + (0.0907444*((DA(12,2)/1000) * DA(12,3))) * 1*365;

disp('    Appliance Options and Costs for 10 year Timeframe')
disp('  --------------------------------------------------------------')
disp('      App   Opt1 Price   Energy Cost   Opt2 Price   Energy Cost')
as = [{'Dish'} DA(1,1)' Dishwashers1cost' DA(2,1)' Dishwashers2cost'];
bs = [{'Oven'} DA(3,1)' Ovens1cost' DA(4,1)' Ovens2cost'];
cs = [{'Refr'} DA(5,1)' Refrigerators1cost' DA(6,1)' Refrigerators2cost'];
ds = [{'Mcrv'} DA(7,1)' Microwaves1cost' DA(8,1)' Microwaves2cost'];
es = [{'Wshr'} DA(9,1)' Washers1cost' DA(10,1)' Washers2cost'];
fs = [{'Dryr'} DA(11,1)' Dryers1cost' DA(12,1)' Dryers2cost'];
disp(as)
disp(bs)
disp(cs)
disp(ds)
disp(es)
disp(fs)

DB = [1.5 5.25 14 8000 33.95 12 2500; 5 4.95 14 8000 39.95 11 30000; 0.5 3.99 7 10000 19.95 3.5 25000];

%cost of usage for 5 years

%Cost = Price + (Power*Time(Watthour) + 43800/8000(replace times))*5(yrs)

Bulb1costcfl = DB(1,2) + (DB(1,3)*DB(1,1) + 43800/DB(1,4))*5;
Bulb2costcfl = DB(1,5) + (DB(1,6)*DB(1,1) + 43800/DB(1,7))*5;
Bulb3costcfl = DB(2,2) + (DB(2,3)*DB(2,1) + 43800/DB(2,4))*5;
Bulb4costled = DB(2,5) + (DB(2,6)*DB(2,1) + 43800/DB(2,7))*5;
Bulb5costled = DB(3,2) + (DB(3,3)*DB(3,1) + 43800/DB(3,4))*5;
Bulb6costled = DB(3,5) + (DB(3,6)*DB(3,1) + 43800/DB(3,7))*5;

disp('  Cost of bulbs for 5 year Timeframe')
disp('        ----------------------')
disp('          Bulb         Cost')
ba = [1' Bulb1costcfl'];
bb = [2' Bulb2costcfl'];
bc = [3' Bulb3costcfl'];
bd = [4' Bulb4costled'];
be = [5' Bulb5costled'];
bf = [6' Bulb6costled'];
disp(ba)
disp(bb)
disp(bc)
disp(bd)
disp(be)
disp(bf)

%cost of usage for 10 years
Bulbs1costcfl = DB(1,2) + (DB(1,3)*DB(1,1) + 87600/DB(1,4))*10;
Bulbs2costcfl = DB(1,5) + (DB(1,6)*DB(1,1) + 87600/DB(1,7))*10;
Bulbs3costcfl = DB(2,2) + (DB(2,3)*DB(2,1) + 87600/DB(2,4))*10;
Bulbs4costled = DB(2,5) + (DB(2,6)*DB(2,1) + 87600/DB(2,7))*10;
Bulbs5costled = DB(3,2) + (DB(3,3)*DB(3,1) + 87600/DB(3,4))*10;
Bulbs6costled = DB(3,5) + (DB(3,6)*DB(3,1) + 43800/DB(3,7))*10;

disp('  Cost of bulbs for 10 year Timeframe')
disp('        ----------------------')
disp('          Bulb         Cost')
ca = [1' Bulbs1costcfl'];
cb = [2' Bulbs2costcfl'];
cc = [3' Bulbs3costcfl'];
cd = [4' Bulbs4costled'];
ce = [5' Bulbs5costled'];
cf = [6' Bulbs6costled'];
disp(ca)
disp(cb)
disp(cc)
disp(cd)
disp(ce)
disp(cf)