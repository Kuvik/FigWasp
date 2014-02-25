function f=fun(V)
%Termino independiente de la ec de Poisson
%"V" es un nodo de la malla, con dos componentes (x,y)
f=-8*(1+V(1)*V(2));