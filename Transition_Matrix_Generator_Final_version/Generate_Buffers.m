for i=5:5
   %temp=TransitionMatrixGenerator('figure11/Upstream','figure11/Downstream',i);
   %temp=TransitionMatrixGenerator('figure11with6states/Upstream','figure11with6states/Downstream',i);
   %temp=TransitionMatrixGenerator('example/Upstream','example/Downstream',i);
   temp=TransitionMatrixGenerator('example/Upstream','example/Downstream',i);
    %res{i}=temp.Tf;
    save("buffer"+num2str(i)+".mat","temp");
end