function f=fun_robin(M,n,i)
% M son las coordenadas del punto
% n es la frontera a la que pertenece
if i==1
   f=5; %Representa la "h" de las condiciones de robin 
end
if i==2
    f=0; %Representa la "g_R" de las condiciones de robin
end