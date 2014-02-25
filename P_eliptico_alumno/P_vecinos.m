function [L1,L2]=P_vecinos(T);
%Crea los vectores L1 y L2 que van a servir para movernos por la matriz de coeficientes:
%L1 es un vector que indica el numero de vecinos de cada nodo de forma acumulada.
%empezando por el cero L1=(0,1,3,....). L1(i+1)-L1(i) es el n�mero de
%vecinos del nodo i. Tiene longitud "m+1",donde "m" es el n� de nodos del
%sistema.
%El vector L2 anota qu� numeros tienen esos vecinos L2(L1(i)+1:L1(i+1)), en
%formato "global". S�lo anota los vecinos que son menores o iguales que el indicado, 
%toda vez que "A" es simetrica
%Todo nodo es vecino de s� mismo, y lo colocamos al final

m=max(max(T)); %numero de nodos
NE=length(T(:,1)); %numero de elementos

L1=zeros(1,m+1);%Creamos el vector L1
L2(1)=0;

N_vecinos(1:m)=1; %Es un vector que indica en la posicion i cu�ntos vecinos tiene el nodo i,menores o iguales que s� mismo
Vecinos(1:m,1)=(1:m)'; %Es una matriz que en la fila "i" guarda el numero (global) de los nodos vecinos del "i" 

v=length(T(1,:)); %El numero de nodos de un triangulo (3 1er orden y 6 2�orden)

for k=1:NE%Para cada elemento (tri�ngulo)
    for i=1:v%Para cada nodo "i" del elemento
        n=T(k,i);%Extraemos "n" = n�mero del nodo del elemento "k" en la posici�n (columna) "i"
            for j=1:v%Hacemos otro bucle que barra todos los nodos del elemento compar�ndolos con el "n"
                if isempty(find(Vecinos(n,:)==T(k,j))) & T(k,j)<=n%Comprobamos si el nodo actual "T(k,j)" no est� en la matriz "Vecinos"; y si es menor o igual que el que estamos contrastando "n"
                N_vecinos(n)=N_vecinos(n)+1;%Contador de columnas de Vecinos(n). Se incrementa cada vez que a�adimos un nodo al "Vecinos(n,:)"
                Vecinos(n,N_vecinos(n))=T(k,j);%A�adimos el nodo "T(k,j)" a la matriz Vecinos(n), en la columna "N_vecinos(n)"
            end
        end
    end
end   
%Al acabar, Vecinos es una matriz de "m" filas en la que aparecen, en cada fila, los nodos
%que comparten elemento con el nodo de la primera columna y que son menores o iguales que �l
%N_vecinos es un vector columna de "m" componentes que contiene el n� de columnas
%de la fila Vecinos(m,:); esto es, el n� de nodos menores o iguales que el "i"
%y que comparten elemento (n� de "vecinos" <= i)

%Creacion de los vectores L1 y L2
for i=1:m
    L1(i+1)=L1(i)+N_vecinos(i);%Por construcci�n, la primera componente de "L" es "0". El resto, es igual al vector "N_vecinos" en suma acumulada (la componente "i-�sima" es la suma de las componentes anteriores hasta la "i-1")
    %Esto es, el n� de nodos vecinos acumulados hasta la componente "i"
    L2(L1(i)+1:L1(i+1))=sort(Vecinos(i,1:N_vecinos(i)));%Vamos concatenando los vecinos ordenados de cada nodo en L2, seg�n los proporciona "Vecinos" cuando se ordena cada fila
end

%Para ver cuantos vecinos tiene el nodo i
%L1(i+1)-L(i) numero de vecinos
%El numero de los vecinos L2(L1(i)+1:L1(i+1)) siendo el ultimo el de la diagonal