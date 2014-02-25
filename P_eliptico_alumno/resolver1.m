function [U,k]=resolver1(A,b,L1,L2,xo)
%Resuelve AU=b mediante gradiente conjugado simple
%todos los vectores son filas
%k es el numero de iteraciones que da hasta encontrar la solución

e=1e-10;
f=1e-10;
m=length(b);

x=xo;
r=b-producto(A,xo,L1,L2);
d=r;
c=dot(r,r);
for k=1:m
    if dot(d,d)<f
        break;
    end
    z=producto(A,d,L1,L2);
    a=c/dot(d,z);
    x=x+a*d;
    rprev = r;%Para la version optimizada de Polak
    r=r-a*z;
    %p=dot(r,r);%Algoritmo original de Fletcher-Reeves
    p=dot(r,r-rprev);%Versión de Polak (mejora de un 2%, aprox.)
    if p<e
        break;
    end
    d=r+(p/c)*d;
    c=p;
end
U=x;