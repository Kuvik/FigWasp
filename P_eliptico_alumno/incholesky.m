function L=incholesky(A,L1,L2)
%Realiza el Cholesky incompleto de la matriz A
%siendo A=L*L' 

m=length(L1)-1; %numero de nodos
L=zeros(1,L1(m+1));

for k=1:m
    %Calculo el elemento de la diagonal k
    L(L1(k+1))=sqrt(A(L1(k+1))-sum(L(L1(k)+1:L1(k+1)-1).^2));
    
    %Calculo todos los elementos de la columna k
    a=L2(L1(k)+1:L1(k+1)-1); %Columnas que posee la fila k
    for i=k+1:m
        %buscar si la fila i tiene elemento en la columna k
        s=find(L2(L1(i)+1:L1(i+1)-1)==k);
        if isempty(s)==0 %esto me indica que la fila i tiene columna k
           b=L2(L1(i)+1:L1(i)+s-1); %Columnas que posee la fila i hasta la columna k sin incluirla 
           ni=1; nk=1; c=0;
           %comparo si existen columnas iguales en la fila k y en la fila i
           %para eso recorrere el vector a comparandolo con el b si
           %a(nk)<=b(ni) voy variando indices en nk si a(nk)>b(ni) vario indice ni
           while nk<=length(a) & ni<=length(b)
               while nk<=length(a) & a(nk)<=b(ni) 
                   if a(nk)==b(ni)
                       c=c+L(L1(k)+nk)*L(L1(i)+ni);
                   end
                   nk=nk+1;
               end
               ni=ni+1;
           end
           L(L1(i)+s)=(A(L1(i)+s)-c)/L(L1(k+1));
       end
    end
end           