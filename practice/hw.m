format bank
h=-500:500:10000;
p=29.921*(1-6.8753*(10^-6*h));
tb=49.161*log(p)+44.932;
t=[h' tb'];
disp('       Alt(ft)    Boiling Temp(°F)')
disp(t)