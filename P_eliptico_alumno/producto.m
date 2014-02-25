function C=producto(A,U,L1,L2)
%realiza el producto AU=C
C(1:length(U))=0;
for i=1:length(L1)-1 %para cada nodo
    for j=L1(i)+1:L1(i+1)-1
        C(i)=C(i)+A(j)*U(L2(j)); %Multiplico hasta la diagonal asi
        C(L2(j))=C(L2(j))+A(j)*U(i); %Multiplico de la diagonal para delante asi
    end
    C(i)=C(i)+A(L1(i+1))*U(i); %Multiplicacion con los elementos de la diagonal para no contarla 2 veces
end  