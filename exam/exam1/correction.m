%Olujide Jacobs
clear
clc

V=459;56700;4590000;62400000;
E=input('Enter any value for the emmisive power from the four given values: ');
if E==459
    T=nthroot((E)/((5.67)*(10^-8)),4);
    fprintf('The temperature is %-1.3f which classifies it as "Normal".\n',T)
elseif E==56700
    T=nthroot((E)/((5.67)*(10^-8)),4);
    fprintf('The temperature is %-1.3f which classifies it as "Red Hot".\n',T)
elseif E==4590000
    T=nthroot((E)/((5.67)*(10^-8)),4);
    fprintf('The temperature is %-1.3f which classifies it as "Bright Light".\n',T)
elseif E==62400000
    T=nthroot((E)/((5.67)*(10^-8)),4);
    fprintf('The temperature is %-1.3f which classifies it as "Bright as sun".\n',T)
elseif E~=V
    disp('Invalid number. Please enter a value from the given ones')
end