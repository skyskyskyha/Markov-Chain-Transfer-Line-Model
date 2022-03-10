%The probability for machine 1 from up to down(fail)
p1 = 0.4;
%The probability for machine 1 from down to up(repair)
r1 = 0.6;
%The probability for machine 2 from up to down(fail)
p2 = 0.7;
%The probability for machine 2 from down to up(repair)
r2 = 0.3;
%state s = (n,a1,a2) n is the number of buffer, a1 and a2 represents two
%machines, 0 is down and 1 is up 
TransitionMatrix = zeros(8);
%from (0,0,0) to (0,0,0)
TransitionMatrix(1,1) = (1-r1)*(1-r2);
%from (0,0,0) to (0,0,1)
TransitionMatrix(1,2) = (1-r1)*r2;
%from (0,0,0) to (0,1,0)
TransitionMatrix(1,3) = 0;
%from (0,0,0) to (0,1,1)
TransitionMatrix(1,4) = r1*r2;
%from (0,0,0) to (1,0,0)
TransitionMatrix(1,5) = 0;
%from (0,0,0) to (1,0,1)
TransitionMatrix(1,6) = 0;
%from (0,0,0) to (1,1,0)
TransitionMatrix(1,7) = r1*(1-r2);
%from (0,0,0) to (1,1,1)
TransitionMatrix(1,8) = 0;

%from (0,0,1) to (0,0,0)
TransitionMatrix(2,1) = (1-r1)*p2;
%from (0,0,1) to (0,0,1)
TransitionMatrix(2,2) = (1-r1)*(1-p2);
%from (0,0,1) to (0,1,0)
TransitionMatrix(2,3) = 0;
%from (0,0,1) to (0,1,1)
TransitionMatrix(2,4) = r1*(1-p2);
%from (0,0,1) to (1,0,0)
TransitionMatrix(2,5) = 0;
%from (0,0,1) to (1,0,1)
TransitionMatrix(2,6) = 0;
%from (0,0,1) to (1,1,0)
TransitionMatrix(2,7) = r1*p2;
%from (0,0,1) to (1,1,1)
TransitionMatrix(2,8) = 0;

%from (0,1,0) to (0,0,0)
TransitionMatrix(3,1) = p1*(1-r2);
%from (0,1,0) to (0,0,1)
TransitionMatrix(3,2) = p1*r2;
%from (0,1,0) to (0,1,0)
TransitionMatrix(3,3) = 0;
%from (0,1,0) to (0,1,1)
TransitionMatrix(3,4) = (1-p1)*r2;
%from (0,1,0) to (1,0,0)
TransitionMatrix(3,5) = 0;
%from (0,1,0) to (1,0,1)
TransitionMatrix(3,6) = 0;
%from (0,1,0) to (1,1,0)
TransitionMatrix(3,7) = (1-p1)*(1-p2);
%from (0,1,0) to (1,1,1)
TransitionMatrix(3,8) = 0;

%from (0,1,1) to (0,0,0)
TransitionMatrix(4,1) = p1*p2;
%from (0,1,1) to (0,0,1)
TransitionMatrix(4,2) = p1*(1-p2);
%from (0,1,1) to (0,1,0)
TransitionMatrix(4,3) = 0;
%from (0,1,1) to (0,1,1)
TransitionMatrix(4,4) = (1-p1)*(1-p2);
%from (0,1,1) to (1,0,0)
TransitionMatrix(4,5) = 0;
%from (0,1,1) to (1,0,1)
TransitionMatrix(4,6) = 0;
%from (0,1,1) to (1,1,0)
TransitionMatrix(4,7) = (1-p1)*p2;
%from (0,1,1) to (1,1,1)
TransitionMatrix(4,8) = 0;

%from (1,0,0) to (0,0,0)
TransitionMatrix(5,1) = 0;
%from (1,0,0) to (0,0,1)
TransitionMatrix(5,2) = (1-r1)*r2;
%from (1,0,0) to (0,1,0)
TransitionMatrix(5,3) = 0;
%from (1,0,0) to (0,1,1)
TransitionMatrix(5,4) = 0;
%from (1,0,0) to (1,0,0)
TransitionMatrix(5,5) = (1-r1)*(1-r2);
%from (1,0,0) to (1,0,1)
TransitionMatrix(5,6) = 0;
%from (1,0,0) to (1,1,0)
TransitionMatrix(5,7) = r1*(1-r2);
%from (1,0,0) to (1,1,1)
TransitionMatrix(5,8) = r1*r2;

%from (1,0,1) to (0,0,0)
TransitionMatrix(6,1) = 0;
%from (1,0,1) to (0,0,1)
TransitionMatrix(6,2) = (1-r1)*(1-p2);
%from (1,0,1) to (0,1,0)
TransitionMatrix(6,3) = 0;
%from (1,0,1) to (0,1,1)
TransitionMatrix(6,4) = 0;
%from (1,0,1) to (1,0,0)
TransitionMatrix(6,5) = (1-r1)*p2;
%from (1,0,1) to (1,0,1)
TransitionMatrix(6,6) = 0;
%from (1,0,1) to (1,1,0)
TransitionMatrix(6,7) = r1*p2;
%from (1,0,1) to (1,1,1)
TransitionMatrix(6,8) = r1*(1-p2);

%from (1,1,0) to (0,0,0)
TransitionMatrix(7,1) = 0;
%from (1,1,0) to (0,0,1)
TransitionMatrix(7,2) = p1*r2;
%from (1,1,0) to (0,1,0)
TransitionMatrix(7,3) = 0;
%from (1,1,0) to (0,1,1)
TransitionMatrix(7,4) = 0;
%from (1,1,0) to (1,0,0)
TransitionMatrix(7,5) = p1*(1-r2);
%from (1,1,0) to (1,0,1)
TransitionMatrix(7,6) = 0;
%from (1,1,0) to (1,1,0)
TransitionMatrix(7,7) = (1-p1)*(1-r2);
%from (1,1,0) to (1,1,1)
TransitionMatrix(7,8) = (1-p1)*r2;

%from (1,1,1) to (0,0,0)
TransitionMatrix(8,1) = 0;
%from (1,1,1) to (0,0,1)
TransitionMatrix(8,2) = p1*(1-p2);
%from (1,1,1) to (0,1,0)
TransitionMatrix(8,3) = 0;
%from (1,1,1) to (0,1,1)
TransitionMatrix(8,4) = 0;
%from (1,1,1) to (1,0,0)
TransitionMatrix(8,5) = p1*p2;
%from (1,1,1) to (1,0,1)
TransitionMatrix(8,6) = 0;
%from (1,1,1) to (1,1,0)
TransitionMatrix(8,7) = (1-p1)*p2;
%from (1,1,1) to (1,1,1)
TransitionMatrix(8,8) = (1-p1)*(1-p2);

TransitionMatrix

