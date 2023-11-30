clear
clc

knot = input('Enter Knot Speed: ');
ft_s = ktsTOfps(knot);
fprintf('The speed of %i knot is %i ft/s\n', knot,ft_s);