function [P,T,e]=dividir_malla(P,T,e)
%Esta funcion sirve para pasar de una malla de elementos triangulares cuadraticos
%a una malla con 4 veces mas triangulos lineales utilizando los lados medios 

%El vector e pierde la ultima fila para ir aumentando el numero de columnas
M=length(e);
for i=1:M
    e1(1:3,2*i-1)=e([1,2,4],i);
    e1(1:3,2*i)=e([1,4,3],i);
end
e=e1;

%Recorro todos los triangulos y los divido en cuatro
L=length(T);
for k=1:length(T)
    T(L+1,1:3)=[T(k,4),T(k,2),T(k,5)];
    T(L+2,1:3)=[T(k,5),T(k,3),T(k,6)];
    T(L+3,1:3)=[T(k,6),T(k,4),T(k,5)];
    T(k,1:3)=[T(k,1),T(k,4),T(k,6)];
    L=L+3;
end
T=T(:,1:3);
