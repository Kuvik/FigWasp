function f=fun_dirichlet(M,n)
% M son las coordenadas del punto
% n es la frontera a la que pertenece
%if n==2 | n==6
if n==1 | n==5
   f=2*(M(1)^2+2*M(1)+2);
end
%if n==3 | n==5
if n==2 | n==4
   f=2*(M(1)^2-2*M(1)+2);
end
if n==7 | n==8 | n==9 | n==10
   f=1/4;
end