function x=m_diagonal(A,L1,b) 
%Resuelve el sistema Qx=b siendo Q la matriz formada por la diagonal de A

for i=1:length(L1)-1 %numero de nodos
    x(i)=b(i)/A(L1(i+1));
end
