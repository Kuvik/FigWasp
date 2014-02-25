function [P,T,e]=malla_cuadratica(P,T,e,TV)
%A partir de una malla simple, esta funcion coge los puntos medios de cada
%triangulo y crea los vectores T, P, e, para poder utilizar elementos finitos cuadraticos

L=length(P);
M=length(e);
T(:,4:6)=0;

%Lo primero que hago es añadirle al vector e una fila mas.
for i=1:M
    e(4,i)=L+i;
    P(L+i,:)=(P(e(2,i),:)+P(e(3,i),:))/2;
end

%Voy triangulo por triangulo rellenando el vector T y P
a=[5,6,4];         %a(i) es el nodo mitad opuesto al nodo i
b=[2,3,1,2];       %El nodo i es el nodo opuesto al lado formado por b(i)--b(i+1)
A=[e(2,:),e(3,:)]; %vectores creados para localizar los nodos de la frontera 
B=[e(3,:),e(2,:)];
C=e(4,:);
L=length(P);
for k=1:length(T)
    for i=1:3
        if T(k,a(i))==0
            if TV(k,i)==0 %si el lado opuesto al nodo a(i) pertenece a la frontera
               M=length(A)/2;
               j=find(A==T(k,b(i)) & B==T(k,b(i+1)));
               if j>M
                  j=j-M;
               end
               T(k,a(i))=C(j);
               A([j,j+M])=[];
               B([j,j+M])=[];
               C(j)=[];
            else
               P(L+1,:)=(P(T(k,b(i)),:)+P(T(k,b(i+1)),:))/2;
               T(k,a(i))=L+1;
               h=TV(k,i); %triangulo vecino del k en esa frontera
               i=find(TV(h,:)==k);
               T(h,a(i))=L+1;
               L=L+1;
            end
        end
    end
end
