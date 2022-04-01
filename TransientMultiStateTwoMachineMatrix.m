function [K,ImportantStates,stateVecMatrix,m]=TransientMultiStateTwoMachineMatrix(pIdle,N,puFinish,puContinue,pdFinish,pdContinue,pRecovery)
% Transient multi-op transition matrix formulation
%
% Input Variables
%   pIdle           [upstream,downstream] machine state change probability 'halt' (starvation,blockage) i -> s+1, i=1,...,s, j -> t+1, j=1,...,t
%   N               maximum buffer capacity >=4
%   puFinish        upstream machine state change probability 'completion' i -> 1, i=2,...,s
%   puContinue      upstream machine state change probability 'operational' i -> i+1, i=1,...,s-1
%   pdFinish        downstream machine state change probability 'operational' j -> j+1, j=1,...,t-1
%   pdContinue      downstream machine state change probability 'completion' j -> 1, j=2,...,t
%   pRecovery       [upstream,downstream] probability of upstream and downstream machines recovering from starvation/blockage
%
% Ouput Variables
%   K               m x m Transition Matrix
%   ImportantStates structure of important states (vectors)
%   stateVecMatrix  m x 3 matrix [BufferContent M1State M2State] of states
%   m               transition matrix size

%% % For Debug
% clear variables;
N=20; 
pIdle=[0.1,0.1];
puContinue=[0.9 0.2679];
puFinish=[0.6664 1];
% pou=[1/11 1/13 0]; 
% pcu=[1-pou(1) 1/7 1/5]; 
% phu=[1/23 1/27 1/39]; 

pdContinue=[0.9 0.2679];
pdFinish=[0.6664 1];
% pod=[1/9 1/17 0]; 
% pcd=[1-pod(1) 1/100 1/3]; 
% phd=[1/37 1/31 1/29];

pRecovery=[0.9 0.9];

%% Assign Variable Values

% Upstream
s=length(puFinish)+1; %number of upstream machine operational states, s+1 is upstream starved state, s+2 is a recovery state
pou=[puContinue 0];
pcu=[1-pou(1) puFinish];
%phu=pIdle(1:s);
phu=repmat(pIdle(1),1,s);
% Downstream
t=length(pdFinish)+1; %number of downstream machine operational states, t+1 is downstream blocked state, t+2 is a recovery state
pod=[pdContinue 0];
pcd=[1-pod(1) pdFinish];
%phd=pIdle(s+1:s+t);
phd=repmat(pIdle(2),1,t);

%% %Calculated State Change Probabilities
pwu=1-pcu-pou; %upstream machine state change probability 'wait in same operational state' i -> i  i=2,...,s (1 - p(i,1) - p(i,i+1))
pwu(1)=0; %(1-pou(1))*(1-phu(1)); %state 1 -> 1 (1-p(1,2))*(1-p(1,s+1)) (WILL REQUIRE REVISION FOR SEPARATE MATRIX FORMULATION)
pwu(end)=1-pcu(end); %state s -> 1

pwd=1-pcd-pod; %downstream machine state change probability 'wait in same operational state' j -> j  j=2,...,t (1 - p(j,1) - p(j,j+1))
pwd(1)=0; %(1-pod(1))*(1-phd(1)); %state 1 -> 1 (1-p(1,2))*(1-p(1,t+1)) (WILL REQUIRE REVISION FOR SEPARATE MATRIX FORMULATION)
pwd(end)=1-pcd(end); %state t -> 1

pru=pRecovery(1);
prd=pRecovery(2);

%% Determine valid states
StateDimVec=[N+1,s+2,t+2];
stateVecMatrix=fullfact(StateDimVec);
stateVecMatrix(:,1)=stateVecMatrix(:,1)-1;
stateVecMatrix=sortrows(stateVecMatrix,2);
stateVecMatrix=sortrows(stateVecMatrix,1);

% n=0 - remove transient states (can include some empty transient states)
for i=1:s+2
    for j=1:t+2
        if (i>1 && j==1) || (i>1 && j==t+1)
            continue
        else
            stateVecMatrix((stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j),:)=[];
        end
    end
end

%% n=1 - remove transient states
for i=1:s+2
    for j=1:t+2
        if (i==1 && j~=1 && j~=t+1) %|| (i~=1 && i~=s+1 && i~=2)
            stateVecMatrix((stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j),:)=[];
        else
            continue
        end
    end
end

%% N=N-1 - remove transient states
for i=1:s+2
    for j=1:t+2
        if (i~=1 && i~=s+1 && j==1)
            stateVecMatrix((stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j),:)=[];
        else
            continue
        end
    end
end

%% N=N - remove transient states (can include some full transient states)
for i=1:s+2
    for j=1:t+2
        if (i==1 && j>1) || (i==s+1 && j>1)
            continue
        else
            stateVecMatrix((stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j),:)=[];
        end
    end
end

% %% Important States for Metrics
ImportantStates.MPStarve=(stateVecMatrix(:,1)==0);
ImportantStates.MPBlock=(stateVecMatrix(:,1)==N);
ImportantStates.UpStreamProd=(stateVecMatrix(:,1)<N & stateVecMatrix(:,2)==1);
ImportantStates.DnStreamProd=(stateVecMatrix(:,1)>0 & stateVecMatrix(:,3)==1);
ImportantStates.UpStreamOperational=(stateVecMatrix(:,2)>1 & stateVecMatrix(:,2)<s+1);
ImportantStates.DnStreamOperational=(stateVecMatrix(:,3)>1 & stateVecMatrix(:,3)<t+1);
ImportantStates.UpIdle=(stateVecMatrix(:,2)==s+1);
ImportantStates.DnIdle=(stateVecMatrix(:,3)==t+1);
ImportantStates.UpRecover=(stateVecMatrix(:,2)==s+2);
ImportantStates.DnRecover=(stateVecMatrix(:,3)==t+2);
ImportantStates.Inventory=stateVecMatrix(:,1);

%ImportantStates.UpStateList=stateVecMatrix(:,2);
%ImportantStates.DnStateList=stateVecMatrix(:,3);
ImportantStates.UpStateList=stateVecMatrix(:,2).*(stateVecMatrix(:,1)==0);
ImportantStates.DnStateList=stateVecMatrix(:,3).*(stateVecMatrix(:,1)==N);

% ImportantStates.UpStreamProducing=(stateVecMatrix(:,2)==1 | stateVecMatrix(:,2)==s+1);
% ImportantStates.DnStreamProducing=(stateVecMatrix(:,3)==1 | stateVecMatrix(:,3)==t+1);
% ImportantStates.MPEmptyUp=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,3)==1);
% %ImportantStates.MPEmptyUp=(stateVecMatrix(:,1)==0 & (stateVecMatrix(:,3)==1 | stateVecMatrix(:,3)==t+1));
% %ImportantStates.MPEmptyUp=(stateVecMatrix(:,1)==0 & (stateVecMatrix(:,3)==1 | stateVecMatrix(:,3)==t+2));
% ImportantStates.StarveUp=(stateVecMatrix(:,1)<N & stateVecMatrix(:,2)==s+1);
% ImportantStates.MPFullDn=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1);
% %ImportantStates.MPFullDn=(stateVecMatrix(:,1)==N & (stateVecMatrix(:,2)==1 | stateVecMatrix(:,2)==s+1));
% %ImportantStates.MPFullDn=(stateVecMatrix(:,1)==N & (stateVecMatrix(:,2)==1 | stateVecMatrix(:,2)==s+2));
% ImportantStates.BlockDn=(stateVecMatrix(:,1)>0 & stateVecMatrix(:,3)==t+1);
% ImportantStates.MPEmpFulUp=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,3)==t+1);
% ImportantStates.MPEmpFulDn=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1);

ImportantStates.MPEmptyUp=(stateVecMatrix(:,1)==0);
ImportantStates.StarveUp=(stateVecMatrix(:,2)==t+1);
ImportantStates.BlockDn=(stateVecMatrix(:,3)==s+1);
ImportantStates.MPFullDn=(stateVecMatrix(:,1)==N);

ImportantStates.ReadyStvUpI=(stateVecMatrix(:,3)==t+1);
ImportantStates.NowStvUpJ=(stateVecMatrix(:,3)==t+1);
ImportantStates.ReadyStvDnI=(stateVecMatrix(:,1)==N);
ImportantStates.NowStvDnJ=(stateVecMatrix(:,1)==N);
% %
ImportantStates.ReadyStvUpK=(stateVecMatrix(:,1)==0);
ImportantStates.NowStvUpL=(stateVecMatrix(:,1)==0);
ImportantStates.ReadyStvDnK=(stateVecMatrix(:,2)==s+1);
ImportantStates.NowStvDnL=(stateVecMatrix(:,2)==s+1);

%% Initialize transition matrix
m=size(stateVecMatrix,1);
K=zeros(m);

%%
%%%%%%% Populate Transition Matrix with mu & md transition probabilities
%%% INTERNAL EQUATIONS
for k=1:m
    n=stateVecMatrix(k,1);
    if (n>1 && n<N-1)
        %% entering p(n,1,1)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(1-phd(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(1-phd(1));
            for j=2:t
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(1-phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(i))*(1-phu(i))*(pcd(j))*(1-phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(1-phd(j));
            end
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
        
        %% entering p(n,1,t+1)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(phd(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(phd(1));
            for j=2:t
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(i))*(1-phu(i))*(pcd(j))*(phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(phd(j));
            end
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
        
        %% entering p(n,s+1,1)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(1-phd(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(1-phd(1));
            for j=2:t
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(1-phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(i))*(phu(i))*(pcd(j))*(1-phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(1-phd(j));
            end
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
        
        %% entering p(n,s+1,t+1)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(phd(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(phd(1));
            for j=2:t
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(i))*(phu(i))*(pcd(j))*(phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(phd(j));
            end
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
        
        %% entering p(n-1,2,1)
        x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
        for j=2:t
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pou(1))*(pcd(j))*(1-phd(j));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
            K(x,y)=(pwu(2))*(pcd(j))*(1-phd(j));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
            K(x,y)=(pou(1))*(pcd(j))*(1-phd(j));
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pwu(2))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pwu(2))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
               
        %% entering p(n-1,i,1)
        for i=3:s
            x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
            K(x,y)=(pou(i-1))*(pcd(1))*(1-phd(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pou(i-1))*(pcd(1))*(1-phd(1));
            for j=2:t
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
                K(x,y)=(pou(i-1))*(pcd(j))*(1-phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pwu(i))*(pcd(j))*(1-phd(j));
            end
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pwu(i))*(pcd(1))*(1-phd(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pwu(i))*(pcd(1))*(1-phd(1));
        end
        %% entering p(n-1,s,1)
        x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pou(s-1))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pou(s-1))*(pcd(1))*(1-phd(1));
        for j=2:t
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==j); %%????
            K(x,y)=(pou(s-1))*(pcd(j))*(1-phd(j));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==j);
            K(x,y)=(pwu(s))*(pcd(j))*(1-phd(j));
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==1);
        K(x,y)=(pwu(s))*(pcd(1))*(1-phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pwu(s))*(pcd(1))*(1-phd(1));
        %% entering p(n-1,s+1,1)
        x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
        K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));
        for j=2:t
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
            K(x,y)=(1-pru)*(pcd(j))*(1-phd(j));
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));
        
        %% entering p(n-1,s+2,1)
        x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pru)*(pcd(1))*(1-phd(1));
        for j=2:t
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pru)*(pcd(j))*(1-phd(j));
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pru)*(pcd(1))*(1-phd(1));
        
        %% entering p(n-1,2,t+1)
        x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pou(1))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pou(1))*(pcd(1))*(phd(1));
        for j=2:t
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pou(1))*(pcd(j))*(phd(j));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
            K(x,y)=(pwu(2))*(pcd(j))*(phd(j));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j); %%Error Before Here?
            K(x,y)=(pou(1))*(pcd(j))*(phd(j));
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pwu(2))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pwu(2))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pou(1))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pou(1))*(pcd(1))*(phd(1));
        
        %% entering p(n-1,i,t+1)
        for i=3:s
            x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
            K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
            for j=2:t
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
                K(x,y)=(pou(i-1))*(pcd(j))*(phd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pwu(i))*(pcd(j))*(phd(j));
            end
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
        end
        
        %% entering p(n-1,s,t+1)
        x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pou(s-1))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pou(s-1))*(pcd(1))*(phd(1));
        for j=2:t
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pou(s-1))*(pcd(j))*(phd(j));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==j);
            K(x,y)=(pwu(s))*(pcd(j))*(phd(j));
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==1);
        K(x,y)=(pwu(s))*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pwu(s))*(pcd(1))*(phd(1));
        
        %% entering p(n-1,s+1,t+1)
        x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
        K(x,y)=(1-pru)*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(1-pru)*(pcd(1))*(phd(1));
        for j=2:t
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
            K(x,y)=(1-pru)*(pcd(j))*(phd(j));
        end
        
        %% entering p(n-1,s+2,t+1)
        x=(stateVecMatrix(:,1)==n-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pru)*(pcd(1))*(phd(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pru)*(pcd(1))*(phd(1));
        for j=2:t
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pru)*(pcd(j))*(phd(j));
        end
        
        %% entering p(n+1,1,2)
        x=(stateVecMatrix(:,1)==n+1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
        K(x,y)=(pcu(1))*(1-phu(1))*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pcu(i))*(1-phu(i))*(pod(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
            K(x,y)=(pcu(i))*(1-phu(i))*(pwd(2));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pcu(i))*(1-phu(i))*(pod(1));
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
        K(x,y)=(pcu(1))*(1-phu(1))*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
        
        %% entering p(n+1,1,j)
        for j=3:t
            x=(stateVecMatrix(:,1)==n+1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(pcu(1))*(1-phu(1))*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pcu(1))*(1-phu(1))*(pwd(j));
            for i=2:s
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
                K(x,y)=(pcu(i))*(1-phu(i))*(pod(j-1));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(i))*(1-phu(i))*(pwd(j));
            end
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(pcu(1))*(1-phu(1))*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
            K(x,y)=(pcu(1))*(1-phu(1))*(pwd(j));
        end
        
        %% entering p(n+1,1,t+1)
        x=(stateVecMatrix(:,1)==n+1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pcu(1))*(1-phu(1))*(1-prd);
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
            K(x,y)=(pcu(i))*(1-phu(i))*(1-prd);
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pcu(1))*(1-phu(1))*(1-prd);
        
        %% entering p(n+1,1,t+2)
        x=(stateVecMatrix(:,1)==n+1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pcu(1))*(1-phu(1))*(prd);
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
            K(x,y)=(pcu(i))*(1-phu(i))*(prd);
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pcu(1))*(1-phu(1))*(prd);
       
        %% entering p(n+1,s+1,2)
        x=(stateVecMatrix(:,1)==n+1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(phu(1))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
        K(x,y)=(pcu(1))*(phu(1))*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(phu(1))*(pod(1));
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pcu(i))*(phu(i))*(pod(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
            K(x,y)=(pcu(i))*(phu(i))*(pwd(2));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pcu(i))*(phu(i))*(pod(1));
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pcu(1))*(phu(1))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
        K(x,y)=(pcu(1))*(phu(1))*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pcu(1))*(phu(1))*(pod(1));
        
        %% entering p(n+1,s+1,j)
        for j=3:t
            x=(stateVecMatrix(:,1)==n+1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(pcu(1))*(phu(1))*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pcu(1))*(phu(1))*(pwd(j));
            for i=2:s
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
                K(x,y)=(pcu(i))*(phu(i))*(pod(j-1));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pcu(i))*(phu(i))*(pwd(j));
            end
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(pcu(1))*(phu(1))*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
            K(x,y)=(pcu(1))*(phu(1))*(pwd(j));
        end
        
        %% entering p(n+1,s+1,t+1)
        x=(stateVecMatrix(:,1)==n+1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pcu(1))*(phu(1))*(1-prd);
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
            K(x,y)=(pcu(i))*(phu(i))*(1-prd);
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pcu(1))*(phu(1))*(1-prd);
        
        %% entering p(n+1,s+1,t+2)
        x=(stateVecMatrix(:,1)==n+1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pcu(1))*(phu(1))*(prd);
        for i=2:s
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
            K(x,y)=(pcu(i))*(phu(i))*(prd);
        end
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pcu(1))*(phu(1))*(prd);
        
        %% entering p(n,2,2)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pou(1))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
        K(x,y)=(pou(1))*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pou(1))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pwu(2))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==2);
        K(x,y)=(pwu(2))*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pwu(2))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
        K(x,y)=(pou(1))*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
        K(x,y)=(pou(1))*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pou(1))*(pod(1));
        
        %% entering p(n,2,j)
        for j=3:t
            x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(pou(1))*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pou(1))*(pwd(j));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(pwu(2))*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
            K(x,y)=(pwu(2))*(pwd(j));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(pou(1))*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
            K(x,y)=(pou(1))*(pwd(j));
        end
        
        %% entering p(n,2,t+1)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pou(1))*(1-prd);
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pwu(2))*(1-prd);
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pou(1))*(1-prd);
        
        %% entering p(n,2,t+2)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pou(1))*(prd);
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pwu(2))*(prd);
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pou(1))*(prd);
        
        %% entering p(n,i,2)
        for i=3:s
            x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
            K(x,y)=(pou(i-1))*(pod(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==2);
            K(x,y)=(pou(i-1))*(pwd(2));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pou(i-1))*(pod(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
            K(x,y)=(pwu(i))*(pod(1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
            K(x,y)=(pwu(i))*(pwd(2));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            K(x,y)=(pwu(i))*(pod(1));
        end
       
        %% entering p(n,i,j)
        for i=3:s
            for j=3:t
                x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j-1);
                K(x,y)=(pou(i-1))*(pod(j-1));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
                K(x,y)=(pou(i-1))*(pwd(j));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
                K(x,y)=(pwu(i))*(pod(j-1));
                y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
                K(x,y)=(pwu(i))*(pwd(j));
            end
        end
        
        %% entering p(n,i,t+1)
        for i=3:s
            x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+1);
            K(x,y)=(pou(i-1))*(1-prd);
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
            K(x,y)=(pwu(i))*(1-prd);
        end
       
        %% entering p(n,i,t+2)
        for i=3:s
            x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+1);
            K(x,y)=(pou(i-1))*(prd);
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
            K(x,y)=(pwu(i))*(prd);
        end
        
        %% entering p(n,s+1,2)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
        K(x,y)=(1-pru)*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
        K(x,y)=(1-pru)*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(1-pru)*(pod(1));
        
        %% entering p(n,s+1,j)
        for j=3:t
            x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(1-pru)*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
            K(x,y)=(1-pru)*(pwd(j));
        end
        
        %% entering p(n,s+1,t+1)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(1-pru)*(1-prd);
        
        %% entering p(n,s+1,t+2)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(1-pru)*(prd);
        
        %% entering p(n,s+2,2)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
        K(x,y)=(pru)*(pod(1));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
        K(x,y)=(pru)*(pwd(2));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
        K(x,y)=(pru)*(pod(1));
        
        %% entering p(n,s+2,j)
        for j=3:t
            x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
            
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j-1);
            K(x,y)=(pru)*(pod(j-1));
            y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
            K(x,y)=(pru)*(pwd(j));
        end
        
        %% entering p(n,s+2,t+1)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pru)*(1-prd);
        
        %% entering p(n,s+2,t+2)
        x=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
        
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
        K(x,y)=(pru)*(prd);
        
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LOWER BOUNDARY EQUATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Entering p(0,2,1)
x=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(2));
y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pwu(2))*(prd);
y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1));
y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(2))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(2))*(pcd(j))*(1-phd(j));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(2))*(pcd(1))*(1-phd(1)); 
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1)); 

%% entering p(0,2,t+1)
x=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pwu(2))*(1-prd);
y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(1-prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(2))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(phd(j));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(2))*(pcd(j))*(phd(j));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(2))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));

%% entering p(0,i,1)
for i=3:s
    x=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
    K(x,y)=(pou(i-1));
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pou(i-1))*(prd);
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pwu(i));
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pwu(i))*(prd);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
    K(x,y)=(pou(i-1))*(pcd(1))*(1-phd(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1); %<- check
    K(x,y)=(pwu(i))*(pcd(1))*(1-phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pou(i-1))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pwu(i))*(pcd(j))*(1-phd(j));
    end
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pcd(1))*(1-phd(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pcd(1))*(1-phd(1));
end

%% entering p(0,i,t+1)
for i=3:s
    x=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pou(i-1))*(1-prd);
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pwu(i))*(1-prd);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
    K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1); %<- Check
    K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pou(i-1))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pwu(i))*(pcd(j))*(phd(j));
    end
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
end

%% entering p(0,s+1,1)
x=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru);
y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-pru)*(prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));

%% entering p(0,s+1,t+1)
x=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-pru)*(1-prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru)*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pcd(1))*(phd(1));

%% entering p(0,s+2,1)
x=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru);
y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pru)*(prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru)*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pcd(1))*(1-phd(1));

%% entering p(0,s+2,t+1)
x=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pru)*(1-prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru)*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pcd(1))*(phd(1));

%% entering p(1,1,1)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1));
y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
for i=2:s
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(1-phu(i));
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(1-phu(i))*(prd);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(1-phd(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(1-phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j); %<- Check
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(1-phu(i))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(1-phd(j));
    end
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));

%% entering p(1,1,t+1)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(1-prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
for i=2:s
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(1-phu(i))*(1-prd);
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(phd(1));
    for j=2:t
        %                 y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
        %                 K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(1-phu(i))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(phd(j));
    end
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));

%% entering p(1,2,1)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(1-phd(j));
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(2))*(pcd(j))*(1-phd(j));
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(2))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(2))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));

%% entering p(1,2,2)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(2))*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==2);
K(x,y)=(pwu(2))*(pwd(2));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(2))*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
K(x,y)=(pou(1))*(pwd(2));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pod(1));

%% entering p(1,2,j)
for j=3:t
    x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pwu(2))*(pod(j-1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(2))*(pwd(j));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pou(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pwd(j));
end

%% entering p(1,2,t+1)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(1-prd);
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pwu(2))*(1-prd);
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(1-prd);

y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(phd(j));
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(2))*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(2))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(2))*(pcd(1))*(phd(1));

%% entering p(1,2,t+2)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(prd);
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pwu(2))*(prd);
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(prd);

%% entering p(1,i,1)
for i=3:s
    x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
    K(x,y)=(pou(i-1))*(pcd(1))*(1-phd(1));
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pcd(1))*(1-phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pou(i-1))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==n & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pwu(i))*(pcd(j))*(1-phd(j));
    end
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pwu(i))*(pcd(1))*(1-phd(1));
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pcd(1))*(1-phd(1));
end

%% entering p(1,i,2)
for i=3:s
    x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
    K(x,y)=(pou(i-1))*(pod(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1); %<- Check
    K(x,y)=(pwu(i))*(pod(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==2);
    K(x,y)=(pou(i-1))*(pwd(2));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pod(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    K(x,y)=(pwu(i))*(pwd(2));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pod(1));
end

%% entering p(1,i,j)
for i=3:s
    for j=3:t
        x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pou(i-1))*(pod(j-1));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pou(i-1))*(pwd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pwu(i))*(pod(j-1));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pwu(i))*(pwd(j));
    end
end

%% entering p(1,i,t+1)
for i=3:s
    x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pou(i-1))*(1-prd);
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pwu(i))*(1-prd);
    
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
    K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pou(i-1))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pwu(i))*(pcd(j))*(phd(j));
    end
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
end

%% entering p(1,i,t+2)
for i=3:s
    x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pou(i-1))*(prd);
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pwu(i))*(prd);
end
        

%% entering p(1,s+1,1)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1));
y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
for i=2:s
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(phu(i));
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(phu(i))*(prd);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(1-phd(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(1-phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(phu(i))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
        K(x,y)=(1-pru)*(pcd(j))*(1-phd(j));
    end
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));

y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));



%% entering p(1,s+1,2)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru)*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
K(x,y)=(1-pru)*(pwd(2));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pod(1));

%% entering p(1,s+1,j)
for j=3:t
    x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(1-pru)*(pod(j-1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pwd(j));
end

%% entering p(1,s+1,t+1)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(1-prd);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-pru)*(1-prd);

y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru)*(pcd(1))*(phd(1));
for i=2:s
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==0 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(phu(i))*(1-prd);
    for j=2:t
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(phu(i))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
        K(x,y)=(1-pru)*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(phd(j));
    end
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(phd(1));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pcd(1))*(phd(1));

%% entering p(1,s+1,t+2)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-pru)*(prd);

%% entering p(1,s+2,1)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru)*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pcd(1))*(1-phd(1));

%% entering p(1,s+2,2)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru)*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
K(x,y)=(pru)*(pwd(2));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pod(1));

%% entering p(1,s+2,j)
for j=3:t
    x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pru)*(pod(j-1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pwd(j));
end

%% entering p(1,s+2,t+1)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pru)*(1-prd);

y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru)*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pcd(1))*(phd(1));

%% entering p(1,s+2,t+2)
x=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pru)*(prd);

%% entering p(2,1,2)
x=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==2); %% <- make more general?
K(x,y)=(pcu(2))*(1-phu(2))*(pwd(2));
for i=2:s
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(1-phu(i))*(pod(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pwd(2));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pod(1));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(1-phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));

%% entering p(2,1,j)
for j=3:t
    x=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1); %?
    K(x,y)=(pcu(1))*(1-phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j); %?
    K(x,y)=(pcu(1))*(1-phu(1))*(pwd(j));
    for i=2:s
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pcu(i))*(1-phu(i))*(pod(j-1));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(1-phu(i))*(pwd(j));
    end
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(1-phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(1-phu(1))*(pwd(j));
end

%% entering p(2,1,t+1)
x=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(1-prd);
for i=2:s
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(1-phu(i))*(1-prd);
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(1-prd);

%% entering p(2,1,t+2)
x=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(prd);
for i=2:s
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(1-phu(i))*(prd);
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(prd);

%% entering p(2,s+1,2)
x=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));
for i=2:s
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(phu(i))*(pod(1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    K(x,y)=(pcu(i))*(phu(i))*(pwd(2));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(phu(i))*(pod(1));
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));

%% entering p(2,s+1,j)
for j=3:t
    x=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    
    for i=2:s
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pcu(i))*(phu(i))*(pod(j-1));
        y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(phu(i))*(pwd(j));
    end
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(phu(1))*(pwd(j));
end

%% entering p(2,s+1,t+1)
x=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(1-prd);
for i=2:s
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(phu(i))*(1-prd);
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(1-prd);

%% entering p(2,s+1,t+2)
x=(stateVecMatrix(:,1)==2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(prd);
for i=2:s
    y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(phu(i))*(prd);
end
y=(stateVecMatrix(:,1)==1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(prd);
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% UPPER BOUNDARY EQUATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Entering p(N,1,2)
x=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(1-phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pwd(2));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pod(1));
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(1-phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));

y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pwd(2));
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pod(1));
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
K(x,y)=(pru)*(pwd(2));
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pod(1));

%% Entering p(N,1,j)
for j=3:t
    x=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(1-phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(1-phu(1))*(pwd(j));
    for i=2:s
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pcu(i))*(1-phu(i))*(pod(j-1));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(1-phu(i))*(pwd(j));
    end
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(1-phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(1-phu(1))*(pwd(j));
    
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pod(j-1));
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwd(j));
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pru)*(pod(j-1));
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pwd(j));
end

%% Entering p(N,1,t+1)
x=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(1-prd);
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(1-phu(i))*(1-prd);
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(1-prd);

y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-prd);
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pru)*(1-prd);

%% Entering p(N,1,t+2)
x=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(prd);
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(1-phu(i))*(prd);
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(prd);

y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(prd);
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pru)*(prd);

%% entering p(N,s+1,2)
x=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    K(x,y)=(pcu(i))*(phu(i))*(pwd(2));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(phu(i))*(pod(1));
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));
        
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
K(x,y)=(1-pru)*(pwd(2));
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pod(1));

%% entering p(N,s+1,j)
for j=3:t
    x=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(phu(1))*(pwd(j));
    for i=2:s
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pcu(i))*(phu(i))*(pod(j-1));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(phu(i))*(pwd(j));
    end
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(phu(1))*(pwd(j));
    
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(1-pru)*(pod(j-1));
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pwd(j));
end

%% entering p(N,s+1,t+1)
x=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(1-prd);
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(phu(i))*(1-prd);
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(1-prd);

y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-pru)*(1-prd);

%% entering p(N,s+1,t+2)
x=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(prd);
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(phu(i))*(prd);
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(prd);

y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-pru)*(prd);

%% entering p(N-1,1,1)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(1-phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(1-phu(i))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(1-phd(j));
    end
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(1-phd(1));

y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pcd(2))*(1-phd(2));
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcd(j))*(1-phd(j));
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pru)*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
K(x,y)=(pru)*(pcd(2))*(1-phd(2));
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pcd(1))*(1-phd(1));

%% entering p(N-1,1,2)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(1-phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
for i=2:s
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(1-phu(i))*(pod(1));
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pwd(2));
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pod(1));
end
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(1-phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pod(1));

%% entering p(N-1,1,j)
for j=3:t
    x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(1-phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(1-phu(1))*(pwd(j));
    for i=2:s
        y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pcu(i))*(1-phu(i))*(pod(j-1));
        y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(1-phu(i))*(pwd(j));
    end
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(1-phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(1-phu(1))*(pwd(j));
end

%% entering p(N-1,1,t+1)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(1-phu(i))*(pcd(1))*(phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(1-phu(i))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(1-phu(1))*(pcd(j))*(phd(j));
    end
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(1-phu(1))*(pcd(1))*(phd(1));

y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pcd(2))*(phd(2));
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcd(j))*(phd(j));
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pcd(1))*(phd(1));

%% entering p(N-1,1,t+2)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(prd);
for i=2:s
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(1-phu(i))*(prd);
end
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(1-phu(1))*(prd);
        
%% entering p(N-1,2,2)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pod(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pou(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pod(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==2);
K(x,y)=(pwu(2))*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(2))*(pod(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
K(x,y)=(pou(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pod(1));

%% entering p(N-1,2,j)
for j=3:t
    x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pou(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pwd(j));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pwu(2))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(2))*(pwd(j));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pou(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pwd(j));
end

%% entering p(N-1,2,t+1)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(1-prd);
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pwu(2))*(1-prd);
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(1-prd);

%% entering p(N-1,2,t+2)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(prd);
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pwu(2))*(prd);
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pou(1))*(prd);

%% entering p(N-1,i,2)
for i=3:s
    x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==2);
    K(x,y)=(pou(i-1))*(pwd(2));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pod(1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    K(x,y)=(pwu(i))*(pwd(2));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pod(1));
end

%% entering p(N-1,i,j)
for i=3:s
    for j=3:t
        x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pou(i-1))*(pod(j-1));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pou(i-1))*(pwd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pwu(i))*(pod(j-1));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pwu(i))*(pwd(j));
    end
end

%% entering p(N-1,i,t+1)
for i=3:s
    x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pou(i-1))*(1-prd);
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pwu(i))*(1-prd);
end

%% entering p(N-1,i,t+2)
for i=3:s
    x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pou(i-1))*(prd);
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pwu(i))*(prd);
end

%% entering p(N-1,s+1,1)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(phu(1))*(pcd(2))*(1-phd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(1-phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(phu(i))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(1-phd(j));
    end
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(1-phd(1));

y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
K(x,y)=(1-pru)*(pcd(2))*(1-phd(2));
for j=2:t
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));

%% entering p(N-1,s+1,2)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));
for i=2:s
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pcu(i))*(phu(i))*(pod(1));
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==2);
    K(x,y)=(pcu(i))*(phu(i))*(pwd(2));
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(phu(i))*(pod(1));
end
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);
K(x,y)=(pcu(1))*(phu(1))*(pwd(2));
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pod(1));

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru)*(pod(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
K(x,y)=(1-pru)*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pod(1));

%% entering p(N-1,s+1,j)
for j=3:t
    x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(phu(1))*(pwd(j));
    for i=2:s
        y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j-1);
        K(x,y)=(pcu(i))*(phu(i))*(pod(j-1));
        y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(phu(i))*(pwd(j));
    end
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pcu(1))*(phu(1))*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pcu(1))*(phu(1))*(pwd(j));
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(1-pru)*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pwd(j));
end

%% entering p(N-1,s+1,t+1)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));
for i=2:s
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pcu(i))*(phu(i))*(pcd(1))*(phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(i))*(phu(i))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
        K(x,y)=(pcu(1))*(phu(1))*(pcd(j))*(phd(j));
    end
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-pru)*(1-prd);
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pcu(1))*(phu(1))*(pcd(1))*(phd(1));

for j=2:t
    y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==N & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pcd(1))*(phd(1));

%% entering p(N-1,s+1,t+2)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(prd);
for i=2:s
    y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    K(x,y)=(pcu(i))*(phu(i))*(prd);
end
y=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pcu(1))*(phu(1))*(prd);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(1-pru)*(prd);

%% entering p(N-1,s+2,2)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==2);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru)*(pod(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==2);
K(x,y)=(pru)*(pwd(2));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pod(1));

%% entering p(N-1,s+2,j)
for j=3:t
    x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j-1);
    K(x,y)=(pru)*(pod(j-1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pwd(j));
end

%% entering p(N-1,s+2,t+1)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pru)*(1-prd);

%% entering p(N-1,s+2,t+2)
x=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);
K(x,y)=(pru)*(prd);

%% entering p(N-2,2,1)
x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(1-phd(j));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(2))*(pcd(j))*(1-phd(j));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(2))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(2))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(1-phd(1));
        
%% entering p(N-2,i,1)
for i=3:s
    x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
    K(x,y)=(pou(i-1))*(pcd(1))*(1-phd(1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pcd(1))*(1-phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pou(i-1))*(pcd(j))*(1-phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pwu(i))*(pcd(j))*(1-phd(j));
    end
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pwu(i))*(pcd(1))*(1-phd(1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pcd(1))*(1-phd(1));
end
%% entering p(n-1,s,1)
x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(s-1))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(s-1))*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==j); %%????
    K(x,y)=(pou(s-1))*(pcd(j))*(1-phd(j));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(s))*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(s))*(pcd(1))*(1-phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(s))*(pcd(1))*(1-phd(1));
%% entering p(n-1,s+1,1)
x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pcd(1))*(1-phd(1));

%% entering p(n-1,s+2,1)
x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru)*(pcd(1))*(1-phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pcd(j))*(1-phd(j));
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pcd(1))*(1-phd(1));

%% entering p(n-1,2,t+1)
x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(1))*(pcd(j))*(phd(j));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(2))*(pcd(j))*(phd(j));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==j); %%Error Before Here?
    K(x,y)=(pou(1))*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(2))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(2))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(1))*(pcd(1))*(phd(1));

%% entering p(n-1,i,t+1)
for i=3:s
    x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+1);
    
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==1);
    K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pou(i-1))*(pcd(1))*(phd(1));
    for j=2:t
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i-1 & stateVecMatrix(:,3)==j);
        K(x,y)=(pou(i-1))*(pcd(j))*(phd(j));
        y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==j);
        K(x,y)=(pwu(i))*(pcd(j))*(phd(j));
    end
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==1);
    K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==i & stateVecMatrix(:,3)==t+2);
    K(x,y)=(pwu(i))*(pcd(1))*(phd(1));
end

%% entering p(n-1,s,t+1)
x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==1);
K(x,y)=(pou(s-1))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pou(s-1))*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s-1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pou(s-1))*(pcd(j))*(phd(j));
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==j);
    K(x,y)=(pwu(s))*(pcd(j))*(phd(j));
end
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==1);
K(x,y)=(pwu(s))*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s & stateVecMatrix(:,3)==t+2);
K(x,y)=(pwu(s))*(pcd(1))*(phd(1));

%% entering p(n-1,s+1,t+1)
x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(1-pru)*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(1-pru)*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(1-pru)*(pcd(j))*(phd(j));
end

%% entering p(n-1,s+2,t+1)
x=(stateVecMatrix(:,1)==N-2 & stateVecMatrix(:,2)==s+2 & stateVecMatrix(:,3)==t+1);

y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==1);
K(x,y)=(pru)*(pcd(1))*(phd(1));
y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==t+2);
K(x,y)=(pru)*(pcd(1))*(phd(1));
for j=2:t
    y=(stateVecMatrix(:,1)==N-1 & stateVecMatrix(:,2)==s+1 & stateVecMatrix(:,3)==j);
    K(x,y)=(pru)*(pcd(j))*(phd(j));
end

% %% For Debug
% q=zeros(size(K,1),1);
% %q(9)=1; % Start State [1 1 1]
% %q(109)=1; % Start State [5 4 4]
% q(101)=1; % Start State [4 5 4]
% 
% for i=0:100
%     currentState=(K^i)*q;
%     AvgInventory(i+1)=currentState'*ImportantStates.Inventory;
%     ProbStarve(i+1)=currentState'*ImportantStates.MPStarve;
%     ProbBlock(i+1)=currentState'*ImportantStates.MPBlock;
%     ProbUpProd(i+1)=currentState'*ImportantStates.UpStreamProd;
%     ProbDnProd(i+1)=currentState'*ImportantStates.DnStreamProd;
%     ProbUpOps(i+1)=currentState'*ImportantStates.UpStreamOperational;
%     ProbDnOps(i+1)=currentState'*ImportantStates.DnStreamOperational;
%     ProbUpIdle(i+1)=currentState'*ImportantStates.UpIdle;
%     ProbDnIdle(i+1)=currentState'*ImportantStates.DnIdle;
%     ProbUpRecover(i+1)=currentState'*ImportantStates.UpRecover;
%     ProbDnRecover(i+1)=currentState'*ImportantStates.DnRecover;
% end
% 
% figure(1)
% plot([0:100],AvgInventory);
% title('Expected Inventory');
% figure(2)
% plot([0:100],ProbStarve,'r-o');
% hold on
% plot([0:100],ProbBlock,'k-+');
% hold off
% title('Probability of Starvation and Blockage');
% legend('Starvation','Blockage','Location','best');
% figure(3)
% plot([0:100],ProbUpProd,'r-o');
% hold on
% plot([0:100],ProbDnProd,'k-+');
% hold off
% title('Probability of Productive State');
% legend('Upstream Machine','Downstream Machine','Location','best');
% figure(4)
% plot([0:100],ProbUpOps,'r-o');
% hold on
% plot([0:100],ProbDnOps,'k-+');
% hold off
% title('Probability of In Operation');
% legend('Upstream Machine','Downstream Machine','Location','best');
% figure(5)
% plot([0:100],ProbUpIdle,'r-o');
% hold on
% plot([0:100],ProbDnIdle,'k-+');
% hold off
% title('Probability of Idle due to Starvation or Blockage');
% legend('Upstream Machine','Downstream Machine','Location','best');
% figure(6)
% plot([0:100],ProbUpRecover,'r-o');
% hold on
% plot([0:100],ProbDnRecover,'k-+');
% hold off
% title('Probability of Recovery State');
% legend('Upstream Machine','Downstream Machine','Location','best');
% 
% temp=[stateVecMatrix,sum(K)'];
% disp('temp stop');

