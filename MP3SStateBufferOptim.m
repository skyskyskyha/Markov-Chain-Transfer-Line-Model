function T=MP3SStateBufferOptim(x,mttf,mttr)
% x is a vector of optimization variables x=[ps,pb,psu,pbd]
% N is the buffer capacity from 4 to 25

ps=x(1);
pb=x(2);
psu=x(3);
pbd=x(4);
N=round(x(5));

%call subrountine that returns the transition matrix for the inputs that
%you have previously saved into separate files
switch N
    case 4
        T=MP3StateMatrixOptimN4(ps,pb,psu,pbd,mttf,mttr); % N=4
    case 5
        T=MP3StateMatrixOptimN5(ps,pb,psu,pbd,mttf,mttr); % N=5
    case 6
        T=MP3StateMatrixOptimN6(ps,pb,psu,pbd,mttf,mttr); % N=6
        
        % on so on
        
    case 25
        T=MP3StateMatrixOptimN25(ps,pb,psu,pbd,mttf,mttr); % N=25
    otherwise
        display('This buffer capacity not supported')
        T=[];
        return;
end

