function [sol] = fit_ball(data)
%This is a solution based on linearizing the sphere equation.
%The solution is not least-squares in its truest form, however this result
%is good enough for most purposes. This can be an input for the initual
%guess while using the Gauss-Newton or the Levenberg-Marquardt algorithm 
%
% The data has to be in 3 columns and at least 4 rows, first column with Xs, 
% 2nd column with Ys and 3rd columns with Zs of the sphere data. 
% The output is a structure with the following fields
% r = radius
% center = [a;b;c]
%           a = X coordinate of the center
%           b = Y coordinate of the center
%           c = Z coordinate of teh center
%
%
% usage: fit_ball(data) % where data is a mx3 data and m>=4
% Updated by Ding Zhang Dec 31, 2019.
% Renamed and updated by Gabriel Antoniak (gjantoni@umich.edu) 6/17/24 to
% create a structure for the output rather than 2 seperate variables

xx = data(:,1);
yy = data(:,2);
zz = data(:,3);
AA = [-2*xx, -2*yy , -2*zz , ones(size(xx))];
BB = [-(xx.^2+yy.^2+zz.^2)];
YY = mldivide(AA,BB); %Trying to solve AA*YY = BB
a = YY(1);
b = YY(2);
c = YY(3);
D = YY(4); % D^2 = a^2 + b^2 + c^2 -r^2(where a,b,c are centers)

sol = struct;
sol.center = [a; b; c];
sol.r      = sqrt((a^2+b^2+c^2)-D);
end

