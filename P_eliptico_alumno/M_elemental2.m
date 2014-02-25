function [R,M,B]=M_elemental2(P,T)
%Creo las matrices de rigidez R de las que saldrán las aij
%Creo las matrices de masas M
%Creo las matrices B de las que saldran los bi
%Utiliza elementos finitos de orden 2

%Construyo los vectores de caracter general
%gL(1:2,1:6,i) guarda la expresion de los gradientes de las 6 funciones elmentales evaluadas en los 7 puntos caracteristicos del triangulo elemental
%L(1:6,1:7) guarda la expresion de las 6 funciones elmentales evaluadas en los 7 puntos del triangulo elemental
%Vm Vector de puntos caracteristicos del triangulo elemental
%Los puntos de gauss y sus pesos en el triangulo elemental son:
a=(6+sqrt(15))/21;
b=4/7-a;
A=(155+sqrt(15))/2400;
B=31/240-A;
Vm(1,:)=[1/3,1/3,9/80];
Vm(2,:)=[a,a,A];
Vm(3,:)=[1-2*a,a,A];
Vm(4,:)=[a,1-2*a,A];
Vm(5,:)=[b,b,B];
Vm(6,:)=[1-2*b,b,B];
Vm(7,:)=[b,1-2*b,B];

%Vm(1,:)=[0,0,1/40];
%Vm(2,:)=[1,0,1/40];
%Vm(3,:)=[0,1,1/40];
%Vm(4,:)=[1/2,0,1/15];
%Vm(5,:)=[1/2,1/2,1/15];
%Vm(6,:)=[0,1/2,1/15];
%Vm(7,:)=[1/3,1/3,9/40];

ng=length(Vm(:,1));

for i=1:ng %puntos de evaluacion de las integrales de los gradientes base
    gL(:,1,i)=[4*Vm(i,1)+4*Vm(i,2)-3;4*Vm(i,1)+4*Vm(i,2)-3];
    gL(:,2,i)=[4*Vm(i,1)-1;0];
    gL(:,3,i)=[0;4*Vm(i,2)-1];
    gL(:,4,i)=4*[1-2*Vm(i,1)-Vm(i,2);-Vm(i,1)];
    gL(:,5,i)=4*[Vm(i,2);Vm(i,1)];
    gL(:,6,i)=4*[-Vm(i,2);1-Vm(i,1)-2*Vm(i,2)];
end
 
for i=1:ng %puntos de evaluacion de las integrales para las funciones base
    L(1,i)=-(1-Vm(i,1)-Vm(i,2))*(1-2*(1-Vm(i,1)-Vm(i,2)));
    L(2,i)=-Vm(i,1)*(1-2*Vm(i,1));
    L(3,i)=-Vm(i,2)*(1-2*Vm(i,2));
    L(4,i)=4*(1-Vm(i,1)-Vm(i,2))*Vm(i,1);
    L(5,i)=4*Vm(i,1)*Vm(i,2);
    L(6,i)=4*(1-Vm(i,1)-Vm(i,2))*Vm(i,2);
end
   
    
    
%Ahora empiezo a crear las matrices elementales
NE=length(T(:,1)); %nº de triangulos que existen en el mallado
for k=1:NE
         
   A=P(T(k,:),:); %vertices y lados del triangulo en coordenadas reales (x,y)
  
   P_gauss=zeros(ng,2);
   for i=1:6
        P_gauss(:,1)=P_gauss(:,1)+A(i,1)*L(i,:)'; %Puntos de Gauss reales en el triangulo
        P_gauss(:,2)=P_gauss(:,2)+A(i,2)*L(i,:)';
   end                                                            
   
   %Resuelvo la integral de los aij con una aproximación de 2ºorden Matriz de Rigidez
   for i=1:ng %puntos de evaluacion de las integrales
       Jo(:,:,i)=[dot(A(1:6,2),gL(2,1:6,i)),-dot(A(1:6,2),gL(1,1:6,i));-dot(A(1:6,1),gL(2,1:6,i)),dot(A(1:6,1),gL(1,1:6,i))];
       dJ(i)=abs(det(Jo(:,:,i)));
   end
   
   %Crea la matriz elemental M(1:3,1:3,1:NE)
   R(1:6,1:6,k)=0;
   for p=1:6
       for q=p:6
           for i=1:ng
               R(p,q,k)=R(p,q,k)+Vm(i,3)/dJ(i)*fun_c(P_gauss(i,:))*(gL(:,p,i)'*Jo(:,:,i)')*(Jo(:,:,i)*gL(:,q,i));
           end
       end
   end
   for p=1:6
       for q=(p+1):6
           R(q,p,k)=R(p,q,k);
       end
   end
      
   %Crea la matriz elemental de Masas M(1:6,1:6,1:NE) con una aproximacion de 3er orden
   M(1:6,1:6,k)=0;
   for p=1:6
       for q=p:6
           for i=1:ng
               M(p,q,k)=M(p,q,k)+Vm(i,3)*fun_a(P_gauss(i,:))*dJ(i)*L(p,i)*L(q,i);
           end
       end
   end
   for p=1:6
       for q=(p+1):6
           M(q,p,k)=M(p,q,k);
       end
   end
  
   
   %Resuelvo la integral de los bi con una aproximación de 3er orden
   for i=1:6 %Funciones base ntos de evaluación de las integrales
      B(i,k)=0;
      for j=1:ng
       B(i,k)=B(i,k)+Vm(j,3)*dJ(j)*L(i,j)*fun(P_gauss(j,:));
      end
   end
end
