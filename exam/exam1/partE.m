x=input('Enter the first score: ');
y=input('Enter the second score: ');
z=input('Enter the third score: ');
p=[x;y;z];
point_avg=mean(p);
highest_point=max(p);
fprintf('The average and highest scores are %-2.2f and %-2.2f\n',point_avg,highest_point)