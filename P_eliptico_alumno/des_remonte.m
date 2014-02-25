function x=des_remonte(L,L1,L2,b)
%Resuelvo el sistema L*L'x=b
m=length(L1)-1; %numero de nodos

y=zeros(1,m);
x=zeros(1,m);

%Descenso Ly=b
for k=1:m
    i=L1(k)+1:L1(k+1)-1;
    y(k)=(b(k)-dot(y(L2(i)),L(i)))/L(L1(k+1));
end

%Remonte L'x=y
%Cada vez que calculo un x(k) actualizo el vector b: Le resto la multiplicacion de x(k) por
%la columna k de L' (que es la fila k de L).
for k=m:-1:1
    x(k)=y(k)/(L(L1(k+1)));
    for i=L1(k)+1:L1(k+1)-1
        y(L2(i))=y(L2(i))-L(i)*x(k);
    end
end