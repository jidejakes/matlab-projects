clear
clc

density = input('Enter Density: ');
specific_weight = DenToSw(density);
fprintf('The specific weight of %i kg/m3 is %i lb/in3\n', density,specific_weight);