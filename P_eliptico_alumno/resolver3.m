function [U,k]=resolver3(A,b,L1,L2,xo)
%Resuelve AU=b mediante gradiente conjugado precondicionado con Cholesky incompleto
%todos los vectores son filas
%k es el numero de iteraciones que da hasta encontrar la solución

e=1e-10;
f=1e-10;
m=length(b);

%Calculamos el cholesky incompleto de A
L=incholesky(A,L1,L2);

x=xo;
r=b-producto(A,xo,L1,L2);
R=des_remonte(L,L1,L2,r);
d=R;
c=dot(R,r);
for k=1:m
    if dot(d,d)<f break
    end
    z=producto(A,d,L1,L2);
    a=c/dot(d,z);
    x=x+a*d;
    r=r-a*z;
    R=des_remonte(L,L1,L2,r);
    p=dot(R,r);
    if dot(r,r)<e break
    end
    d=R+(p/c)*d;
    c=p;
end
U=x;