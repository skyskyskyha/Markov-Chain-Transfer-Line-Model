function T=MP3SState(x,N)
% x is a vector of optimization variables x=[ps,pb,psu,pbd]
% N is the buffer capacity from 4 to 25

ps=x(1);
pb=x(2);
psu=x(3);
pbd=x(4);

%call subrountine that returns the transition matrix for the inputs that
%you have previously saved into separate files
switch N
    case 4
        T=MP3StateMatrixN4(ps,pb,psu,pbd); % N=4
    case 5
        T=MP3StateMatrixN5(ps,pb,psu,pbd); % N=5
    case 6
        T=MP3StateMatrixN6(ps,pb,psu,pbd); % N=6
        
        % on so on
        
    case 25
        T=MP3StateMatrixN25(ps,pb,psu,pbd); % N=25
    otherwise
        display('This buffer capacity not supported')
        T=[];
        return;
end

