function [nuevo_A,nuevo_b,nuevo_L1,nuevo_L2]=contorno(A,b,L1,L2,P,p_dirichlet)
%Imponemos las condiciones de frontera de dirichlet del problema (c. esenciales)
%y eliminamos filas y columnas de la matriz A correspondientes a los nodos dirichlet
%pasando esos datos al vector b. 
%Queda un sistema en el que solo son incógnitas los nodos naturales

m=length(L1)-1;%Número de nodos de la malla

U=zeros(1,m);%Vector término independiente sólo Dirichlet
ref=zeros(1,m);%Vector con tantas componentes como nodos 1-dirichlet 0-natural 
n_vecinosD=zeros(1,length(L1));%Vector en el que almacenamos el nº de vecinos que son de tipo Dirichlet para cada nodo "i"
vecinosD=zeros(1,length(L2));%Vector en el que marcamos con 1 las componentes a quitar de L2 y A

ref(p_dirichlet(2,:))=1;%Marcamos con "1" todos los nodos con condiciones Dirichlet

%Calculamos el nuevo término independiente
if ~isempty(p_dirichlet)%Si hay frontera Dirichlet
    for i=1:length(p_dirichlet(1,:))%Para cada nodo Dirichlet
        n=p_dirichlet(:,i);
        U(n(2))=fun_dirichlet(P(n(2),:),n(1));%Imponemos en ese nodo el valor indicado por las CC Dirichlet
    end
    c=producto(A,U,L1,L2);
    b=b-c;%"A · u_nat = A · (u - u_D) = b - c" . Término independiente para la solución sólo en los nodos naturales.
end

nuevo_b=b(ref==0);%Nos quedamos con las componentes del término independiente correspondientes a nodos naturales

%Creacion de los vectores "nuevo_L1", "nuevo_L2"; uso de los vectores
%auxiliares "n_vecinosD","vecinosD".
for i=1:m%Para cada nodo de la malla ("para cada fila de la matriz A")    
    if ref(i)==1%Si es un nodo Dirichlet ("si esa fila pertenece a un nodo Dirichlet")
       n_vecinosD(i+1)=(L1(i+1)-L1(i));%Guardamos el nº de vecinos que tiene, todos ellos a eliminar
       vecinosD(L1(i)+1:L1(i+1))=1;%Marcamos esos nodos vecinos con "1", para eliminarlos ("marcamos esa fila para eliminar")
    else%Si no lo es ("Si la fila es de un nodo natural")
        for j=L1(i)+1:L1(i+1)-1 %Para todos los vecinos del nodo i a excepción de sí mismo 
            if ref(L2(j))==1%Si es nodo Dirichlet
                n_vecinosD(i+1)=n_vecinosD(i+1)+1;%Añadimos uno al contador de componentes a eliminar
                vecinosD(j)=1;%Marcamos esa posición para eliminar ("quitamos esa columna correspondiente a un nodo Dirichlet, de la fila "i")
            end
        end
    end
end

nuevo_L1=L1-cumsum(n_vecinosD);%La "cumsum(n_vecinosD)" crea un vector con la suma acumulada de todos los vecinos de tipo Dirichlet.
%Esto es, son componentes a quitar de la matriz "A" (y por tanto, de "L2").
%El "nuevo_L1" guarda el nº acumulado de vecinos NATURALES +1 hasta el nodo
%"i". Así, "nuevo_L1(i+1)-nuevo_L1(i)" es el nº de vecinos naturales del
%nodo "i". "length(nuevo_L1)-1" es el nº de nodos naturales de la malla

nuevo_L1(p_dirichlet+1)=[];%Del vector "nuevo_L1", eliminamos las componentes correspondientes a los nodos Dirichlet.
%El vector actualizado ahora tiene ahora "length(p_dirichlet)" componentes
%menos, por lo que la componente "i" no se corresponde ahora con el nodo
%"i", sino con el "i-ésimo" nodo natural de la malla

nuevo_L2=L2(find(vecinosD==0));%Nos quedamos con todas las componentes no marcadas de "A". En este punto, el vector "nuevo_L2" tiene 
%el nº correcto de componentes, pero hace referencia a nodos que ahora
%están situados en otras posiciones. Debemos adaptar la numeracion.

a=cumsum(ref);%Adaptamos los indices de "A" al nuevo nº de componentes."a(i)" guarda el nº acumulado de filas (= componentes de la solución) que hemos quitado

for i=1:length(nuevo_L2)%Para todos los nodos naturales de la malla
    nuevo_L2(i)=nuevo_L2(i)-a(nuevo_L2(i));%Convertimos la referencia del nodo antiguo a la nueva, descontando los "a(nuevo_L2(i))" nodos que se han quitado hasta ese nodo "nuevo_L2(i)"
end
%En este punto, "nuevo_L2" hace referencia sólo a nodos naturales, con la
%notación modificada dada por "nuevo_L1"

%Nueva matriz
nuevo_A=A(vecinosD==0);%La matriz "nuevo_A" contiene sólo las componentes no marcadas: filas y columnas eliminadas de los nodos Dirichlet