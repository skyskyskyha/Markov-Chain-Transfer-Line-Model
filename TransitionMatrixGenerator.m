classdef TransitionMatrixGenerator
    %TRANSITIONMATRIXGENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function result = sortstates(states)
            if length(states) < 2
                result = states;
                return;
            end
            result = [];

            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if states(i).Name < min
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
        end
        
        function m = getProbabilityMatrix(stateFlowChart)
            % Get a list of states with names in alphanumeric order, then
            % create m such that m(row, col) represents probability of
            % moving from col to row
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
                    
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if states(i).Name < min
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            N = length(states);
            m = zeros(N);
            m = sym(m);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    prob = t.LabelString;
                    disp(prob)
                    prob = prob(find(prob=='[')+1:find(prob==']')-1);
                    m(i, j) = str2sym(prob);
                end
            end
        end
        
        function b = getBufferMatrix(stateFlowChart)
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if states(i).Name < min
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            
            N = length(states);
            b = zeros(N);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    change=t.LabelString;
                    change=change(find(change=='{')+1:find(change=='}')-1);
                    change=str2double(change);
                    b(i, j) = change;
                end
            end
        end
        
        function c = getConditionMatrix(stateFlowChart)
            
            % Add logic for arbitrary buffer condition in the future.
            
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if states(i).Name < min
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            
            N = length(states);
            c = zeros(N);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    change=t.LabelString;
                    change=change(find(change=='(')+1:find(change==')')-1);
                    if (strlength(change) == 1)
                        change=str2double(change);
                        c(i, j) = change;
                    else
                        temp = char(change);
                        c(i,j) = temp(2)-'0';
                    end
                end
            end
        end
        
       function sub = getSpecialBoundary(stateFlowChart)
            
            % Add logic for arbitrary buffer condition in the future.
            
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if states(i).Name < min
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            
            N = length(states);
            sub = zeros(N);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    change=t.LabelString;
                    change=change(find(change=='(')+1:find(change==')')-1);
                    if (strlength(change) == 1)
                        sub(i,j)=i;
                    else
                        temp = char(change);
                        sub(i,j) = temp(1)-'A'+1;
                    end
                end
            end
        end
    end
    

    
    properties
        m1;
        m2;
        num1;
        num2;
        m1_to_num1;
        m2_to_num2;
        b1;
        b2;
        c1; % Conditional connection matrices
        c2;
        op1; % Whether state is operable
        op2;
        sub1;
        sub2;
        bufCap;
        svm;
        T;      % Symbolic result
        Tf;     % Function for evaluation
        Tn; % Numeric Matrix after substitution into Tf
        groups;
    end
    
    methods
        function obj = TransitionMatrixGenerator(m1StateFlow,...
                       m2StateFlow,bufCap)
            %TRANSITIONMATRIXGENERATOR Construct an instance of this class
            %   Detailed explanation goes here
            rt = sfroot;
            m1StateFlow = find(rt, '-isa', 'Stateflow.Chart',...
                'Path', m1StateFlow);
            m2StateFlow = find(rt, '-isa', 'Stateflow.Chart',...
                'Path', m2StateFlow);
            
            obj.m1 = obj.getProbabilityMatrix(m1StateFlow);
            obj.m2 = obj.getProbabilityMatrix(m2StateFlow);
            obj.b1 = obj.getBufferMatrix(m1StateFlow);
            obj.b2 = obj.getBufferMatrix(m2StateFlow);
            obj.bufCap = bufCap;
            obj.c1 = obj.getConditionMatrix(m1StateFlow);
            obj.c2 = obj.getConditionMatrix(m2StateFlow);
            obj.c1(isnan(obj.c1)) = 0;
            obj.c2(isnan(obj.c2)) = 0;
            obj.op1 = zeros(length(obj.c1),1);
            for i=1:length(obj.c1)
                sum=0;
                for j=1:length(obj.c1)
                    sum=sum+obj.c1(j,i);
                end
                if (sum==1)
                    % 1 means operable state, which can't fail while starve
                    % or block
                    obj.op1(i)=1;
                else
                    obj.op1(i)=0;
                end
            end
            obj.op2 = zeros(length(obj.c2),1);
            for i=1:length(obj.c2)
                sum=0;
                for j=1:length(obj.c2)
                    sum=sum+obj.c2(j,i);
                end
                if (sum==1)
                    % 1 means operable state, which can't fail while starve
                    % or block
                    obj.op2(i)=1;
                else
                    obj.op2(i)=0;
                end
            end
            obj.sub1 = obj.getSpecialBoundary(m1StateFlow);
            obj.sub2 = obj.getSpecialBoundary(m2StateFlow);
            obj.T = [];
        end
        
        function obj = myFunc(obj, N, varargin)
            obj = obj.setBufferNumbers(N);
            obj = obj.substituteValuesDirectly_m1(cell2mat(varargin(1)));
            obj = obj.substituteValuesDirectly_m2(cell2mat(varargin(2)));
            obj = obj.generateTransitionMatrixbyNum();
        end
        
        function obj = setBufferNumbers(obj, bufCap)
            obj.bufCap = bufCap;
        end
        
        function obj = substituteValuesDirectly_m1(obj, varargin)
            in = num2cell(cat(2, varargin{:}));
            obj.m1_to_num1 = matlabFunction(obj.m1);
            obj.num1 = obj.m1_to_num1(in{:});
        end
                
        function obj = substituteValuesDirectly_m2(obj, varargin)
            in = num2cell(cat(2, varargin{:}));
            obj.m2_to_num2 = matlabFunction(obj.m2);
            obj.num2 = obj.m2_to_num2(in{:});
        end
        
        function state = findFinalState(obj,buf,m1,m2)
            state = -1;
            for i=1:length(obj.svm)
                if (buf==obj.svm(i,1) && m1==obj.svm(i,2) && m2==obj.svm(i,3))
                    state=i;
                    break;
                end
            end
        end
        
        function obj = generateTransitionMatrixbyNum(obj)
            MAX = obj.bufCap;
            obj.svm = obj.genStateVecMatrix();
            obj = obj.genGroups();
            obj = obj.pruneSVM_tarjan();
            dim = length(obj.svm);
            obj.T = zeros(dim);
            disp ("Generating numeric transition matrix directly" )
            for i=1:dim
                for j=1:dim
                    target = j;
                    bufStart = obj.svm(i, 1);
                    bufStop  = obj.svm(j, 1);
                    m1Start  = obj.svm(i, 2);
                    m1Stop   = obj.svm(j, 2);
                    m2Start  = obj.svm(i, 3);
                    m2Stop   = obj.svm(j, 3);
                    
                    t1 = obj.b1(m1Stop, m1Start);
                    t2 = obj.b2(m2Stop, m2Start);
                    p1 = obj.num1(m1Stop, m1Start);
                    p2 = obj.num2(m2Stop, m2Start);

                   % check whether we are going to another state
                    if bufStart == 0 && obj.sub2(m2Stop, m2Start) ~= m2Stop && obj.c2(m2Start, m2Stop)
                        target = obj.findFinalState(bufStop, m1Stop, obj.sub2(m2Stop, m2Start));
                    end
                    % if the machine2 is starved, we need to check whether
                    % it can reach the state
                    if bufStart == 0 && m2Start == m2Stop && obj.op2(m2Start) == 1
                        t2 = 0;
                        p2 = 1;
                    else
                        if bufStart == 0 && m2Start~=m2Stop && obj.op2(m2Start) == 1
                            p2 = 0;
                        end
                    end
                    
                   % check whether we are going to another state
                    if bufStart == MAX && obj.sub1(m1Stop, m1Start) ~= m1Stop && obj.c1(m1Start, m1Stop)
                        target = obj.findFinalState(bufStop, obj.sub1(m1Stop, m1Start), m2Stop);
                    end
                    % if the machine1 is blocked, we need to check whether
                    % it can reach the state
                    if bufStart == MAX && m1Start == m1Stop
                        t1 = 0;
                        p1 = 1;
                    else
                        if bufStart == MAX
                            p1 = 0;
                        end
                    end
                    
                    if (bufStop-bufStart) ~= t1+t2
                        continue;
                    end
                    if (target == -1)
                        obj.T(j, i) = p1*p2;
                    else 
                        obj.T(target, i) = p1*p2;
                    end
                end
            end
      end
      
      function obj = generateTransitionMatrix(obj, bufCap)
            obj.bufCap = bufCap;
            MAX = obj.bufCap;
            obj.svm = obj.genStateVecMatrix();
            obj = obj.genGroups();
            obj = obj.pruneSVM_tarjan();
            dim = length(obj.svm);
            obj.T = zeros(dim);
            obj.T = sym(obj.T);
            disp ( "Generating symbolic transition matrix" )
            for i=1:dim
                for j=1:dim
                    bufStart = obj.svm(i, 1);
                    bufStop  = obj.svm(j, 1);
                    m1Start  = obj.svm(i, 2);
                    m1Stop   = obj.svm(j, 2);
                    m2Start  = obj.svm(i, 3);
                    m2Stop   = obj.svm(j, 3);
                    
                    t1 = obj.b1(m1Stop, m1Start);
                    t2 = obj.b2(m2Stop, m2Start);
                    p1 = obj.m1(m1Stop, m1Start);
                    p2 = obj.m2(m2Stop, m2Start);

                    % if the machine2 is starved, we need to check whether
                    % it can reach the state
                    if bufStart == 0 && obj.c2(m2Stop, m2Start) == 1
                        t2 = 0;
                        p2 = 1;
                    else
                        if bufStart == 0
                            p2 = 0;
                        end
                    end
                    
                    % if the machine1 is blocked, we need to check whether
                    % it can reach the state
                    if bufStart == MAX && obj.c1(m1Stop, m1Start) == 1
                        t1 = 0;
                        p1 = 1;
                    else
                        if bufStart == MAX
                            p1 = 0;
                        end
                    end
                    
                    if (bufStop-bufStart) ~= t1+t2
                        continue;
                    end
                    
                    obj.T(j, i) = p1*p2;
                end
            end
            disp( "Generating matlabFunction from T" )
            obj.Tf = matlabFunction(obj.T);
        end
        
        function svm = genStateVecMatrix(obj)
           m1Dim = length( obj.m1 );
           m2Dim = length( obj.m2 );
           
           svm = zeros((obj.bufCap+1)*m1Dim*m2Dim, 3);
           ind = 1;
           for i = 1:(obj.bufCap+1)
               for j = 1:m1Dim
                   for k = 1:m2Dim
                       svm(ind, 1) = i-1;
                       svm(ind, 2) = j;
                       svm(ind, 3) = k;
                       ind = ind + 1;
                   end
               end
           end
        end
        
        function obj=pruneSVM_tarjan(obj)
            tic
            obj.svm = obj.genStateVecMatrix();
            m1Dim = length(obj.m1);
            m2Dim = length(obj.m2);
            oneLine = m1Dim*m2Dim;
            twoLines = m1Dim*m2Dim*2;
            threeLines = m1Dim*m2Dim*3;
            
            % prune lower boundary equations
            matlabQueue = zeros(threeLines,1);
            vectorMatrix = zeros(threeLines, 5);
            for i=1:threeLines
                vectorMatrix(i,1)=i;
                vectorMatrix(i,2)=obj.svm(i,1);
                vectorMatrix(i,3)=obj.svm(i,2);
                vectorMatrix(i,4)=obj.svm(i,3);
                % 0 means unused,1 means used
                vectorMatrix(i,5)=0;
            end
            queueHead=1;
            queueTail=1;
            for i=twoLines+1:threeLines
               matlabQueue(queueTail)=i;
               % set this as visited
               vectorMatrix(i,5)=1;
               queueTail = queueTail+1;
            end
            
            while (queueHead<queueTail)
                curIndex=matlabQueue(queueHead);
                curState=vectorMatrix(curIndex:curIndex,2:4);
                curBuffer=curState(1);
                lowerBuffer=0;
                upperBuffer=2;
                if (curBuffer==0)
                    % search for buffer is 0 or 1
                    lowerBuffer=0;
                    upperBuffer=1;
                else
                    if (curBuffer==1)
                        % search for buffer 0 or 1
                        lowerBuffer=0;
                        upperBuffer=1;
                    else
                        if (curBuffer==2)
                            lowerBuffer=1;
                            upperBuffer=1;
                        end
                    end
                end
                for desiredBuffer=lowerBuffer:upperBuffer
                    for m1State=1:m1Dim
                        for m2State=1:m2Dim
                            indexVector=desiredBuffer*m1Dim*m2Dim+(m1State-1)*m2Dim+m2State;
                            if (vectorMatrix(indexVector,5)==1)
                                continue;
                            end
                            desiredState=vectorMatrix(indexVector:indexVector,2:4);
                            bufChange=desiredBuffer-curBuffer;
                            if (obj.isAdjacent(bufChange,curState,desiredState))
                                matlabQueue(queueTail)=indexVector;
                                queueTail=queueTail+1;
                                vectorMatrix(indexVector,5)=1;
                            end
                        end
                    end
                end
                queueHead=queueHead+1;
            end
            
            prunedSVM=zeros(size(obj.svm,1),3);
            index=0;
            for i=1:size(vectorMatrix,1)
                if (vectorMatrix(i,5)==1&&vectorMatrix(i,2)~=2)
                    index=index+1;
                    prunedSVM(index,1:3)=vectorMatrix(i:i,2:4);
                end
            end
            % copy internal states from 2 to N-2
            internalStatesSize=(obj.bufCap-3)*m1Dim*m2Dim;
            prunedSVM(index+1:index+internalStatesSize,1:3)=obj.svm(twoLines+1:(obj.bufCap-1)*oneLine,1:3);
            index=index+internalStatesSize;
            % prune upper boundary equations
            matlabQueue = zeros(threeLines,1);
            vectorMatrix = zeros(threeLines, 5);
            start=(obj.bufCap-2)*m1Dim*m2Dim;
            for i=1:threeLines
                vectorMatrix(i,1)=start+i;
                vectorMatrix(i,2)=obj.svm(start+i,1);
                vectorMatrix(i,3)=obj.svm(start+i,2);
                vectorMatrix(i,4)=obj.svm(start+i,3);
                % 0 means unused,1 means used
                vectorMatrix(i,5)=0;
            end
            queueHead=1;
            queueTail=1;
            for i=1:oneLine
               matlabQueue(queueTail)=i;
               % set this as visited
               vectorMatrix(i,5)=1;
               queueTail = queueTail+1;
            end
            
            while (queueHead<queueTail)
                curIndex=matlabQueue(queueHead);
                curState=vectorMatrix(curIndex:curIndex,2:4);
                curBuffer=curState(1);
                lowerBuffer=obj.bufCap-2;
                upperBuffer=obj.bufCap;
                if (curBuffer==obj.bufCap-2)
                    % search for buffer is bufCap-1
                    lowerBuffer=obj.bufCap-1;
                    upperBuffer=obj.bufCap-1;
                else
                    if (curBuffer==obj.bufCap-1)
                        % search for buffer bufCap-1 or bufCap
                        lowerBuffer=obj.bufCap-1;
                        upperBuffer=obj.bufCap;
                    else
                        if (curBuffer==obj.bufCap)
                            lowerBuffer=obj.bufCap-1;
                            upperBuffer=obj.bufCap-1;
                        end
                    end
                end
                for desiredBuffer=lowerBuffer:upperBuffer
                    for m1State=1:m1Dim
                        for m2State=1:m2Dim
                            indexVector=(desiredBuffer+2-obj.bufCap)*m1Dim*m2Dim+(m1State-1)*m2Dim+m2State;
                            if (vectorMatrix(indexVector,5)==1)
                                continue;
                            end
                            desiredState=vectorMatrix(indexVector:indexVector,2:4);
                            bufChange=desiredBuffer-curBuffer;
                            if (obj.isAdjacent(bufChange,curState,desiredState))
                                matlabQueue(queueTail)=indexVector;
                                queueTail=queueTail+1;
                                vectorMatrix(indexVector,5)=1;
                            end
                        end
                    end
                end
                queueHead=queueHead+1;
            end
            
            for i=1:size(vectorMatrix,1)
                if (vectorMatrix(i,5)==1&&vectorMatrix(i,2)~=obj.bufCap-2)
                    index=index+1;
                    prunedSVM(index,1:3)=vectorMatrix(i,2:4);
                end
            end
            obj.svm=prunedSVM(1:index,1:3);
        end
        
        function obj=pruneSVM(obj)
            obj.svm = obj.genStateVecMatrix();
            m1Dim = length(obj.m1);
            m2Dim = length(obj.m2);
            
            maxes = obj.svm(obj.bufCap*m1Dim*m2Dim+1:(obj.bufCap+1)*m1Dim*m2Dim, :);
            maxesLessOne = obj.svm((obj.bufCap-1)*m1Dim*m2Dim+1:(obj.bufCap)*m1Dim*m2Dim, :);
            maxesLessTwo = obj.svm((obj.bufCap-2)*m1Dim*m2Dim+1:(obj.bufCap-1)*m1Dim*m2Dim, :);
            newMaxesLessOne = obj.pruneFrom(1, maxesLessOne, maxesLessTwo);
            
            newMaxesLessOne = obj.expand(0, newMaxesLessOne, maxesLessOne);
            newMaxes = obj.pruneFrom(1, maxes, newMaxesLessOne);
            
            change = true;
            while change
                change   = false;
                oldLO = newMaxesLessOne;
                oldM = newMaxes;
                newMaxesLessOne = obj.expand(0, newMaxesLessOne, maxesLessOne);
                newMaxes = obj.pruneFrom(1, maxes, newMaxesLessOne);
                newMaxesLessOne  = [newMaxesLessOne; obj.expand(1, newMaxes, maxesLessOne)];
                newMaxesLessOne(newMaxesLessOne(:, 1) == obj.bufCap, :) = [];
                newMaxesLessOne = unique(newMaxesLessOne, 'rows');
                
                if ~isequal(oldLO, newMaxesLessOne) || ~isequal(oldM, newMaxes)
                    change = true;
                end
            end
            
            obj.svm((obj.bufCap-1)*m1Dim*m2Dim+1:(obj.bufCap+1)*m1Dim*m2Dim, :) = [];
            obj.svm = [obj.svm; newMaxesLessOne; newMaxes];
            
            zeros = obj.svm(1:m1Dim*m2Dim, :);
            ones  = obj.svm(m1Dim*m2Dim+1:2*m1Dim*m2Dim, :);
            twos  = obj.svm(2*m1Dim*m2Dim+1:3*m1Dim*m2Dim, :);
            
            newOnes = obj.pruneFrom(-1, ones, twos);
            newZeros = obj.pruneFrom(-1, zeros, newOnes);
            
            change = true;
            while change
                change   = false;
                oldO = newOnes;
                oldZ = newZeros;
                newOnes  = obj.expand(0, newOnes, ones);
                newZeros = obj.pruneFrom(-1, zeros, newOnes);
                newOnes  = [newOnes; obj.expand(1, newZeros, ones)];
                newOnes(newOnes(:, 1) == 0, :) = [];
                newOnes = unique(newOnes, 'rows');
                
                if ~isequal(oldO, newOnes) || ~isequal(oldZ, newZeros)
                    change = true;
                end
            end
            
            obj.svm(1:2*m1Dim*m2Dim, :) = [];
            obj.svm = [newZeros; newOnes; obj.svm];
            
            obj.svm = unique(obj.svm, 'rows');
        end
        
        
        function mat = substituteValues(obj, varargin)
            % REQUIRES: Vectors input must be in alphanumeric order,
            % grouped by the first letter of each variable, for example
            % substituteValues([p1, p2, ..., pn], [q1, q2, ..., qm], ...)
            % is acceptable input.
            % MODIFIES: obj
            % EFFECTS: Calls genTransitionMatrix after substituting the
            % values provided in the vectors. Produces the transition
            % matrix of these respective values.
            
            
            % Error checking comes first. This can go wrong in some ways,
            % so let's make a list.
            % 1. Not enough input arguments
            % 2. Provided arrays aren't of respective sizes
            
            % So we need to have some expectation of what our input looks
            % like. Let's create a function for that.
            
            % Check number of arguments is correct
%             if (nargin-1) ~= length(keys(obj.groups))
%                 disp("Error: incorrect number of input arguments")
%                 return;
%             end
%             
%             % Check each vector has the correct number of keys
%             k = keys(obj.groups);
%             for i=1:length(k)
%                 if length(obj.groups(k{i})) ~= length(varargin{i})
%                     disp("Error: incorrect length of vector " + i)
%                     return;
%                 end
%             end
%             
            % substitute arguments into anonymous function handle
            tic
            disp(varargin)
            in = num2cell(cat(2, varargin{:}));
            mat = obj.Tf(in{:});
            toc
        end
        
        function obj=genGroups(obj)
            obj.groups = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for i=1:numel(obj.m1)
                if obj.m1(i) == 0
                    continue
                end
                var = obj.m1(i);
                symbols = symvar(var);
                for j=1:length(symbols)
                    c = string(symbols(j));
                    c = convertStringsToChars(c);
                    c = c(1);
                    if ~isKey(obj.groups, c)
                        obj.groups(c) = symbols(j);
                    else
                        obj.groups(c) = [obj.groups(c); symbols(j)];
                    end
                end
            end
            
            for i=1:numel(obj.m2)
                if obj.m2(i) == 0
                    continue
                end
                var = obj.m2(i);
                symbols = symvar(var);
                for j=1:length(symbols)
                    c = string(symbols(j));
                    c = convertStringsToChars(c);
                    c = c(1);
                    if ~isKey(obj.groups, c)
                        obj.groups(c) = symbols(j);
                    else
                        obj.groups(c) = [obj.groups(c); symbols(j)];
                    end
                end
            end
            
            % sort the syms in alphanumeric order
            k = keys(obj.groups);
            for i=1:length(k)
                obj.groups(k{i}) = unique(obj.groups(k{i}));
            end
        end
        
        function pruned=pruneFrom(obj, bufChange, ...
                                  statesToPrune, internalStates)
           % prunes statesToPrune from internalStates with respect to
           % bufChange
           toKeep   = [];
           toRemove = [];
           
           for i=1:size(internalStates,1)
               for j=1:size(statesToPrune,1)
                   if ( obj.isAdjacent(bufChange, internalStates(i, :), statesToPrune(j, :) ))
                       toKeep   = [toKeep; statesToPrune(j, :)];
                       toRemove = [toRemove; j];
                   end
               end
               if (~isempty(toRemove))
                   for j=length(toRemove):-1:1
                       statesToPrune(toRemove(j), :) = [];
                   end
                   toRemove = [];
               end
           end
           pruned = toKeep;
        end
        
        function expanded=expand(obj, bufChange, toExpand, expansionDomain)
             expanded = toExpand; 
             toAdd    = [];
             toRemove = [];
             change   = true;
             while change
                change = false;
                for i=1:size(expanded,1)
                    for j=1:size(expansionDomain,1)
                        if isequal(expanded(i, :), expansionDomain(j, :))
                            continue
                        end
                        if ( obj.isAdjacent(bufChange, expanded(i, :), expansionDomain(j, :)) )
                            toAdd = [toAdd; expansionDomain(j, :)];
                            toRemove = [toRemove; j];
                        end
                    end
                    if ~isempty(toRemove)
                        for j=length(toRemove):-1:1
                            expansionDomain(toRemove(j), :) = [];
                        end
                        toRemove = [];
                    end
                end
                if ~isempty(toAdd)
                    change = true;
                    expanded = [expanded; toAdd];
                    toAdd = [];
                end
             end
        end
        
        function val=isAdjacent(obj, bufChange, state1, state2)
            change1 = obj.b1(state2(2), state1(2));
            change2 = obj.b2(state2(3), state1(3));

            val = false;
            
            % bufChange does not match
            if change1 + change2 ~= bufChange
                return
            end
            
            % if m2 is starved and it should go to another state instead of
            % the state it arrows to, we should mark it
            specialLowerBoundary = false;
            if state1(1) == 0
                for i = 1:length(obj.sub2)
                    if obj.sub2(i,state1(3)) == state2(3) && obj.sub2(i,state1(3)) ~= i
                        specialLowerBoundary = true;
                        break;
                    end
                end
            end
            
            % if m2 is starved and it this change can't happen
            if state1(1) == 0 && obj.c2(state2(3), state1(3)) == 0 && specialLowerBoundary == false
                return
            end
            
            % if m2 is starved and it should not go to this state, instead
            % it should go to another state (like C->B instead of C->D)
            if state1(1) == 0 && obj.sub2(state2(3), state1(3)) ~= state2(3)
                return 
            end
            
            % if m2 is starved and the buffer is still 0 but m1 produces(in
            % this situation buffer should be 1 instead because of
            % Gershwin's hypothesis)
            if state1(1) == 0 && state2(1) == 0 && change1 ~= 0
                return
            end
            
            % if m1 is blockd and it should go to another state instead of
            % the state it arrows to, we should mark it
            specialUpperBoundary = false;
            if state1(1) == obj.bufCap
                for i = 1:length(obj.sub1)
                    if obj.sub1(i,state1(2)) == state2(2) && obj.sub1(i,state1(2)) ~= i
                        specialUpperBoundary = true;
                        break;
                    end
                end
            end
            
            % if m1 is blockd and it this change can't happen
            if state1(1) == obj.bufCap && obj.c1(state2(2), state1(2)) == 0 && specialUpperBoundary == false
                return 
            end
            
            % if m1 is blockd and it should not go to this state, instead
            % it should go to another state (like C->B instead of C->D)
            if state1(1) == obj.bufCap && obj.sub1(state2(2), state1(2)) ~= state2(2)
                return 
            end
            
            % if m1 is blockd and the buffer is still N but m2 subtracts(in
            % this situation buffer should be N-1 instead because of
            % Gershwin's hypothesis)
            if state1(1) == obj.bufCap && state2(1) == obj.bufCap && change1~=0
                return 
            end
            
        
            m1Connected = ( obj.m1(state2(2), state1(2)) ~= 0 || specialUpperBoundary);
            m2Connected = ( obj.m2(state2(3), state1(3)) ~= 0 || specialLowerBoundary);
            
            val = m1Connected && m2Connected;
            
        end
    end
end

