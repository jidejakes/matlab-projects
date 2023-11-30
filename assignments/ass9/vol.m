function[v]=vol(x)
if x>0 && x<20
    a=20/x;
    b=80/a;
    v=60*1/2*(60+b)*x;
elseif x==20
    v=60*1/2*((60+20)*20);
elseif x>20 && x<=50
    v=(60*(1/2*(60+20)*20)+((x-20)*20*20)); %volume of the tank in each case
elseif x>50
    v=60000;
    fprintf('The water level cannot exceed 50m. The maximum water level is %-1.0f \n',v);
elseif x==0
    disp('No water exists in the tank.');
    v=0;
end
