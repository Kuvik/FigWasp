function f=fun_neumann(M,n)
% M son las coordenadas del punto
% n es la frontera a la que pertenece
if (n == 3 || n == 6)
    f=2*(2+M(1)*M(2));
end