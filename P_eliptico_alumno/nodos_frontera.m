function [p_dirichlet,p_neumann,p_robin,p_naturales]=nodos_frontera(e,P,f_dirichlet,f_neumann,f_robin)
%f_dirichlet indica el numero de la frontera creada por matlab que tiene cond. dirichlet
%f_neumann indica el numero de la frontera creada por matlab que tiene cond. neumann
%f_robin indica el numero de la frontera creada por matlab que tiene cond. robin

%Señalamos cuáles tienen condiciones neumann,robin y dirichlet.
%El resto serán nodos centrales.


v=length(e(:,1)); %Si v=3 elementos lineales. Si v=4 elementos cuadráticos.

%condicion dirichlet
%p_dirichlet(1:2,:) fila 1:indica el numero de la frontera y 2:es el numero del nodo
if isempty(f_dirichlet)
   p_dirichlet=[];%Si no hay fronteras de tipo Dirichlet, lo ponemos
else
   p_dirichlet=[0;0];%Si hay, iniciamos el vector
end
d=1;%Contador de posiciones (columnas) para Dirichlet
for i=f_dirichlet%Bucle en "i" con los valores de "f_dirichlet" (nº de frontera)
    j=find(e(1,:)==i);%Hallamos las posiciones en "e" que tienen nº de frontera "i". Será un vector, en general.
    %Algoritmo de extracción de todos los nodos diferentes de
    %las columnas indicadas por "j": tomar los primeros nodos
    %de cada columna y en la última, añadir el segundo también. Para evitar
    %nodos repetidos (comunes a dos fronteras contiguas), debemos comprobar
    %que se satisfacen las siguientes condiciones cuanda añadamos un nodo:
    %   1)Al comenzar una nueva columna, el primer nodo de esa columna no
    %   debe estar ya en "p_dirichlet".
    %   2)En la última columna de la frontera numerada por "i", el segundo
    %   nodo no ha de encontrarse en "p_dirichlet".
    for j=j%Bucle en "j" con cada valor individual de la posición en el vector "e"
        if isempty(find(e(2,j)==p_dirichlet(2,:)));%Comprobamos que nuestro vector "p_dirichlet" no tiene ya el nodo que vamos a introducir (el primero de cada columna de "e")
           p_dirichlet(1:2,d)=e([1,2],j);%Si no lo tiene, lo añadimos junto con el nº de la frontera
           d=d+1;%Siguiente posición en "p_dirichlet" (siguiente columna)
        end
        if v==4%Caso con elementos cuadráticos
           p_dirichlet(1:2,d)=e([1,4],j);%
           d=d+1;
        end
    end%Terminamos el bucle en los lados que pertenecen a la frontera número "i"
    
    if isempty(find(e(3,j)==p_dirichlet(2,:)));%Comprobamos que el segundo nodo de la última columna de "e" que pertenece a la frontera "i" no está ya en nuestro "p_dirichlet"
        p_dirichlet(1:2,d)=e([1,3],j);%Si no está, lo añadimos
        d=d+1;
    end
end
    

%condicion neumann
%p_neumann(1:3 o 4,:) fila 1:indica el numero de la frontera y 2,3,4: es el numero de los nodos 
%en el que la fila 4 es el punto intermedio entre 2 y 3 si trato con elementos cuadraticos.
p_neumann=[];
n=1;%Contador de posiciones para Neumann
for i=f_neumann%Para cada frontera Neumann
    j=find(e(1,:)==i);%Extraemos los índices de "e" con frontera igual a "i"
    m=length(j);%Nº de columnas en "e" con frontera "i"
    p_neumann(:,n:n+m-1)=e(:,j);%Nos quedamos con todas esas columnas ("m" columnas)
    n=n+m;%Avanzamos "m" posiciones
end

%condicion robin
%p_robin(1:3 o 4,:) fila 1:indica el numero de la frontera y 2,3,4: es el numero de los nodos 
%en el que la fila 4 es el punto intermedio entre 2 y 3 si trato con elementos cuadraticos.
p_robin=[];
r=1;%Contador de posiciones para Robin
for i=f_robin%Para cada frontera Robin
    j=find(e(1,:)==i);%Extraemos los índices de "e" con frontera igual a "i"
    m=length(j);%Nº de columnas en "e" con frontera "i"
    p_robin(:,r:r+m-1)=e(:,j);%Nos quedamos con todas esas columnas ("m" columnas)
    r=r+m;%Avanzamos "m" posiciones
end

%Creamos el vector de nodos naturales (nodos centrales + neumann + robin)
%== "p_totales - p_dirichlet"
p_naturales=[1:size(P,1)];%[1:size(P,1)] es un vector con todos los nodos del sistema (están ordenados)
if ~isempty(p_dirichlet)%Si hay elementos "p_dirichlet"
    p_naturales(p_dirichlet(2,:))=[];%Quitamos todos esos nodos del vector anterior
end

