disp('Please read each line carefully!')
x=input('Please input the number 1\n');
y=input('Please input the number 5\n')
z=0;
fid=fopen('T:\Class102:\Sample.txt','w');
fprintf(fid,'The value of y is %f',y)
disp('The z value is:')
disp(z)
fclose(fid)
disp('Dont submit your exam before you check all your answers twice.')