source_code: contains all matlab file
	TransitionMatrixGenerator.m
		Usage: obj = TransitionMatrixGenerator('modelName/upstreamMachine', 'modelName/downstreamMachine', bufferCapacity);
		Usage Example: obj = TransitionMatrixGenerator('merginglines/Upstream','merginglines/Downstream',5);

		Need to open the merginglines stateflow and place the slx file into the same folder
		The return value "obj" contains any information you want, you can see comments on line 320-355 
		For example,  if you have a "obj.Tf = @(p1,p2,q1,q2)reshape([-p1...)"
		you can run "obj.Tf(0.1,0.2,0.3,0.4)" to get the transition matrix with "p1=0.1 p2=0.2 q1=0.3 q2=0.4" 
		(the sequence your input values should match the sequence of parameters)

		Getting the numeric matrix directly
			If you want to calculate a specfic buffer without generate obj.Tf (the matlab function for the result matrix), 
			you can put a breakpoint on line 530,
			and run "obj = obj.generateTransitionMatrixbyNum()" directly, the program will generate a numeric transition matrix in obj.T.
			The speed of getting a numeric matrix is faster, but if the buffer changes you need to run the program again.
			Generally, if you have over 5 different buffers, I encourage generate the obj.Tf directly and run on generated matlab function
		
		Choosing which parameter to optimize
			If you want to "fix" some parameters and only try to optimize the remaining parameters, you have two options
				1. Just "fix" them manually by inputting the same parameter every time, obj.Tf will still recoginize them as "varaibles",
				it will only be a little slower because most time are used in generate the matrix

				2. Call "obj = obj.generateNewOptimals(obj, varaibles)" (put a breakpoint anywhere before it starts to calculate)
				the detailed explanation of the meaning of parameters can be seen from line 796-803. 
				For example, if you have (p1,p2,q1,q2) as parameters, and you call "obj = obj.generateNewOptimals(-1,0.1,-1,0.2)"
				this input represents fix p2=0.1 and q2=0.2, and treat only p1 and q1 as varaibles, 
				the generated obj.Tf will only contain two varaibles like: "obj.Tf = @(p1,q1)reshape(...)"
				it will only be a little faster
		

	Generate_Buffers.m
		Usage: Just run it directly
		This file is a simple "script" to run the TransitionMatrixGenerator with the same slx file but different buffers
		You can change the range for i to generater different number of buffers and change the machine names directly

	Other files:
		InitGUI, inputGUI, InputParaGUI are just GUI files, you don't need to care about them
		If you want to input all data with these GUIs manually instead of reading from the stateflow,
		you can set DEBUG=0 on line 321 of TransitionMatrixGenerator to show all of the GUIs
		You can also set DEBUG=1 if you want to skip the GUIs


stateflow contains all slx file
	4-Behavior_State_Machine, 5-Behavior_State_Machine, 6-Behavior_State_Machine are correct.
	merginglines still have some problems not fixed



All of other redundunt, useless or testing code are deleted.


