function c=fun_c(V)
%Coeficiente "c" de la ecuación "-div(c·grad(u)) + a·u = f", según Matlab
%"V" es un nodo de la malla, con dos componentes (x,y)
c=2+V(1)*V(2);