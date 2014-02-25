function [R,M,B]=M_elemental1(P,T)
%Creo las matrices de rigidez R de las que saldrán las aij
%Creo las matrices de masas M
%Creo las matrices B de las que saldran los bi
%Utilizo elementos finitos de orden 1.

NE=length(T(:,1)); %nº de triangulos que existen en el mallado

Vm(1,:)=[0,0];
Vm(2,:)=[1,0];
Vm(3,:)=[0,1];
Vm(4,:)=[1/2,0];
Vm(5,:)=[1/2,1/2];
Vm(6,:)=[0,1/2];
Vm(7,:)=[1/3,1/3];

%Gradientes de las funciones base constantes
gL(:,1)=[-1;-1];
gL(:,2)=[1;0];
gL(:,3)=[0;1];

for i=1:7 %Puntos de evaluacion de las integrales para las funciones base
    L(1,i)=1-Vm(i,1)-Vm(i,2);
    L(2,i)=Vm(i,1);
    L(3,i)=Vm(i,2);
end

for k=1:NE
   V(1,:)=P(T(k,1),:); %vertice 1 del triangulo en coordenadas reales (x,y)
   V(2,:)=P(T(k,2),:); %vertice 2 del triangulo en coordenadas reales (x,y)
   V(3,:)=P(T(k,3),:); %vertice 3 del triangulo en coordenadas reales (x,y)
   V(4,:)=(V(1,:)+V(2,:))/2;
   V(5,:)=(V(2,:)+V(3,:))/2;
   V(6,:)=(V(3,:)+V(1,:))/2;   
   
   
   %Matriz jacobiana J: Jo=detJ*inv(J)' que sale en el cambio de variable
   Jo=[(V(3,2)-V(1,2)),-(V(2,2)-V(1,2));-(V(3,1)-V(1,1)),(V(2,1)-V(1,1))]; 
   dJ=abs(det(Jo));
   
   %Crea la matriz elemental de Rigidez(1:3,1:3,1:NE) con aproximacion de 2ºorden
   for i=1:3
       for j=i:3
           R(i,j,k)=1/(6*dJ)*(fun_c(V(4,:))+fun_c(V(5,:))+fun_c(V(6,:)))*(gL(:,i)'*Jo')*(Jo*gL(:,j));
       end
   end
   R(2,1,k)=R(1,2,k);
   R(3,1,k)=R(1,3,k);
   R(3,2,k)=R(2,3,k);   
   
   %Crea la matriz elemental de Masas M(1:3,1:3,1:NE)con aproximacion de 2ºorden
   for i=1:3
       for j=i:3
           M(i,j,k)=dJ/6*(fun_a(V(4,:))*L(i,4)*L(j,4)+fun_a(V(5,:))*L(i,5)*L(j,5)+fun_a(V(6,:))*L(i,6)*L(j,6));
       end
   end
   M(2,1,k)=M(1,2,k);
   M(3,1,k)=M(1,3,k);
   M(3,2,k)=M(2,3,k);
   
   %Crea la matriz elemental del vector indepenciente b(1:3,1:NE)
   %mediante una formula de cuadratura de 2º orden
   B(1,k)=(fun(V(4,:))*1/2+fun(V(5,:))*0+fun(V(6,:))*1/2)*(dJ/6);
   B(2,k)=(fun(V(4,:))*1/2+fun(V(5,:))*1/2+fun(V(6,:))*0)*(dJ/6);
   B(3,k)=(fun(V(4,:))*0+fun(V(5,:))*1/2+fun(V(6,:))*1/2)*(dJ/6);
end