%3.1

R = [0.9 1.5 1.3 1.3];
d = [1 1.25 3.8 4.0];
V=zeros();

for a=1:length(R)
    if d(a) < R(a)
        V(a)=1/3*pi*R(a)^2*R(a);
        fprintf('Volume is %.2f \n',V(a))
    elseif d(a) > R(a)
        V(a)=(1/3*pi*R(a)^2*R(a))+(pi*R(a)^2*(d(a)-R(a)));
        fprintf('Volume is %.2f \n',V(a))
    elseif d(a) > 3*R(a)
        disp('Overtop')
    end
end


%3.12

%vectorized code
tstart = 0;
tend = 20;
ni = 8;
t1 = tstart;
y1 = 12 + 6*cos(2*pi*t(1)/(tend-tstart));
i = 2:1:ni+1;
t = t + (tend-tstart)/ni;
y = 10 + 5*cos(2*pi*t);


%3.15

x = input('x: ');
n = input('n: ');
round_value = rounder(x,n);
disp(round_value)
