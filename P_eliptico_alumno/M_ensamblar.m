function [A,C,b]=M_ensamblar(P,T,L1,L2,R,M,B,p_neumann,p_robin)
%Ensamblado de la matriz total partiendo de las matrices elementales M,B. 
%En A solamente nos quedamos con la parte triangular inferior, por ser simetrica
%La matriz A se almacenará en forma de vector, quedándonos sólo con
%aquellos elementos que sean no nulos
%La matriz A es la matriz de Rigidez en coordenadas globales
%La matriz C es la matriz de Masas y todo lo dicho para A vale para C
%L1(1:m+1) indica L1(i)+1 en qué columna empieza la fila de los "aij" correspondiente al nodo i 
%en los vectores L0, C y A
%L2(1:nº de elementos de A) indica la columna dentro de la matriz que le corresponde a los elementos de A

m=length(P(:,1)); %número de nodos en la malla
NE=length(T);  %número de elementos triangulares en la malla
n=L1(m+1); %numero de elementos de la matriz A y del vector IJ;
A=zeros(1,n);%Matriz general de Rigidez
C=zeros(1,n);%Matriz general de Masas
b=zeros(1,m);%Vector de términos independientes

v=length(T(1,:)); %El numero de nodos de un triangulo (3 1er orden y 6 2ºorden)

%Creo las matrices A, C y el vector b
for k=1:NE%Para cada uno de los elementos del sistema
    for i=1:v%Para cada índice local de los nodos de cada elemento
       n=T(k,i);%Tomamos el número de nodo en coordenadas globales
       b(n)=b(n)+B(i,k);%Añadimos al término independiente en la posición "n" (coordenada global) la contribución del elemento en la componente local "i"
       for j=1:v%Para cada índice local "j"
           if T(k,j)<=n%Nos quedamos sólo con los nodos en coordenadas globales "T(k,j)" que son menores o iguales que el de contraste "n"
              s=find(L2(L1(n)+1:L1(n+1))==T(k,j));%De entre todos los nodos vecinos en todos los elementos que tiene "n", hallamos la posición "s" que en ese vector ocupa el nodo "T(k,j)"
              A(L1(n)+s)=A(L1(n)+s)+R(i,j,k);%Añadimos a "A" en la posición "L1(n)+s" el valor de la matriz en coordenadas locales "R(i,j,k)"
              C(L1(n)+s)=C(L1(n)+s)+M(i,j,k);%Añadimos a "C" en la posición "L1(n)+s" el valor de la matriz en coordenadas locales "M(i,j,k)"
          end
       end
    end
end

if v==3 %Elementos lineales
% Sobre el vector b escribo las integrales del linea debido a la c.neumann
% en el contorno con la aproximacion de simpson
    if ~isempty(p_neumann)
        for i=1:size(p_neumann,2)
            n=p_neumann(1,i);%Número de frontera
            L=p_neumann(2,i);%Nodo inicial de la frontera "i" 
            M=p_neumann(3,i);%Nodo final de la frontera "i"            
            b(L)=b(L)+norm(P(L,:)-P(M,:))/6*(fun_neumann(P(L,:),n)+4/2*fun_neumann((P(L,:)+P(M,:))/2,n));%Fórmula de Simpson considerando que "fi_i(j)=delta_ij"; "fi_i((i+j)/2) = 1/2"
            b(M)=b(M)+norm(P(L,:)-P(M,:))/6*(fun_neumann(P(M,:),n)+4/2*fun_neumann((P(L,:)+P(M,:))/2,n));
        end
    end

    % Sobre el vector b y la matriz A escribo las integrales del linea 
    % debido a la c.robin en el contorno con aproximacion de simpson
    % fun_robin(x,n,1)=h coeficiente que acompaña a T en las condiciones de Robin
    % fun_robin(x,n,2)=FR coeficiente independiente que multiplica a la funcion base
    if ~isempty(p_robin)
        for i=1:length(p_robin(1,:))
            L=p_robin(2,i);
            M=p_robin(3,i);
            n=p_robin(1,i); %el numero de frontera
            h=fun_robin((P(L,:)+P(M,:))/2,n,1);
            b(L)=b(L)+norm(P(L,:)-P(M,:))/6*(fun_robin(P(L,:),n,2)+4/2*fun_robin((P(L,:)+P(M,:))/2,n,2));
            b(M)=b(M)+norm(P(L,:)-P(M,:))/6*(fun_robin(P(M,:),n,2)+4/2*fun_robin((P(L,:)+P(M,:))/2,n,2));
            A(L1(M+1))=A(L1(M+1))+h*norm(P(L,:)-P(M,:))/6*(1+4/4);
            A(L1(L+1))=A(L1(L+1))+h*norm(P(L,:)-P(M,:))/6*(1+4/4);
            if L>M
               a=L;
               L=M;
               M=a;
            end
            s=find(L2(L1(M)+1:L1(M+1))==L);
            A(L1(M)+s)=A(L1(M)+s)+h*norm(P(L,:)-P(M,:))/6*(4/4);
       end
   end
   
elseif v==6 %Elementos cuadraticos
    % Sobre el vector b escribo las integrales del linea debido a la c.neumann
    % en el contorno con la aproximacion de simpson
    r=[0,1/4,1/2,3/4,1]; %Puntos de evaluacion de las integrales de las funciones base
    %Calculamos las funciones base evaluadas en los puntos, incluyendo los pesos(1,4,2,4,1) de simpson
    L(1,:)=2.*(r-1/2).*(r-1);
    L(2,:)=-4*r.*(r-1);
    L(3,:)=2*r.*(r-1/2);
   
    Lp=L;
    Lp(:,2)=L(:,2)*4;
    Lp(:,3)=L(:,3)*2;
    Lp(:,4)=L(:,4)*4;
    
    if ~isempty(p_neumann)
        for i=1:length(p_neumann(1,:))
            M=[p_neumann(2,i),p_neumann(4,i),p_neumann(3,i)]; %Vector numeros de vertices del lado
            n=p_neumann(1,i); %el numero de frontera
            f=[fun_neumann(P(M(1),:),n),fun_neumann((P(M(1),:)+P(M(2),:))/2,n),fun_neumann(P(M(2),:),n),fun_neumann((P(M(2),:)+P(M(3),:))/2,n),fun_neumann(P(M(3),:),n)];
            for j=1:3
                b(M(j))=b(M(j))+norm(P(M(1),:)-P(M(2),:))/6*dot(f,Lp(j,:));
            end
        end
    end

    % Sobre el vector b y la matriz A escribo las integrales del linea 
    % debido a la c.robin en el contorno con aproximacion de simpson
    % h es el coeficiente que acompaña a T en las condiciones de Robin
    if ~isempty(p_robin)
        for i=1:length(p_robin(1,:))
            M=[p_robin(2,i),p_robin(4,i),p_robin(3,i)]; %Vector numeros de vertices del lado
            n=p_robin(1,i); %el numero de frontera
            f=[fun_robin(P(M(1),:),n,2),fun_robin((P(M(1),:)+P(M(2),:))/2,n,2),fun_robin(P(M(2),:),n,2),fun_robin((P(M(2),:)+P(M(3),:))/2,n,2),fun_robin(P(M(3),:),n,2)];
            h=fun_robin(P(M(2),:),n,1);
            for j=1:3
                b(M(j))=b(M(j))+norm(P(M(1),:)-P(M(2),:))/6*dot(f,Lp(j,:));
                A(L1(M(j)+1))=A(L1(M(j)+1))+h*norm(P(M(1),:)-P(M(2),:))/6*dot(L(j,:),Lp(j,:));
            end
            %Ahora los terminos cruzados que son 3. a12 a13 a23 por simetria
            [M,j]=sort(M); %ordena de menor a mayor, el mayor del todo es el nodo de la mitad del lado;
            s=find(L2(L1(M(3))+1:L1(M(3)+1))==M(2));
            A(L1(M(3))+s)=A(L1(M(3))+s)+h*norm(P(M(1),:)-P(M(2),:))/12*dot(L(j(3),:),Lp(j(2),:));
            s=find(L2(L1(M(3))+1:L1(M(3)+1))==M(1)); 
            A(L1(M(3))+s)=A(L1(M(3))+s)+h*norm(P(M(1),:)-P(M(2),:))/12*dot(L(j(3),:),Lp(j(1),:));
            s=find(L2(L1(M(2))+1:L1(M(2)+1))==M(1));   
            A(L1(M(2))+s)=A(L1(M(2))+s)+h*norm(P(M(1),:)-P(M(2),:))/12*dot(L(j(2),:),Lp(j(1),:));
       end
   end
end
