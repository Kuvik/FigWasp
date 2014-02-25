function [u,P1,T1,e1]=fem2(p,t,e,f_dirichlet,f_neumann,f_robin)

%Adaptar la malla que proporciona Matlab a la estructura de datos
%Funciones elementales cuadráticas
[P,T,e]=acondicionar_malla(p,t,e);%Adaptamos la malla de matlab a la estructura de datos.
TV=T_vecinos(T);
[P,T,e]=malla_cuadratica(P,T,e,TV);%Malla original adaptada para utilizar elementos cuadraticos
[P1,T1,e1]=dividir_malla(P,T,e);%Malla el doble de fina que la original de elementos lineales
[p_dirichlet,p_neumann,p_robin,p_naturales]=nodos_frontera(e,P,f_dirichlet,f_neumann,f_robin);


%Creamos los vectores L2 y L2 que ayudaran a almacenar la matriz A
[L1,L2]=P_vecinos(T);

%Creamos la matrices elementales para cada triangulo
[R,M,b]=M_elemental2(P,T);
[R,M,b]=M_ensamblar(P,T,L1,L2,R,M,b,p_neumann,p_robin);
A=R+M;

%Aplicamos las condiciones de dirichlet(esenciales) y reducimos el sistema
[nuevo_A,nuevo_b,nuevo_L1,nuevo_L2]=contorno(A,b,L1,L2,P,p_dirichlet);


%Resolvemos el sistema por el gradiente conjugado precondicionado
xo(1:length(nuevo_b))=0;

[U,k]=resolver1(nuevo_A,nuevo_b,nuevo_L1,nuevo_L2,xo);
%[U,k]=resolver2(nuevo_A,nuevo_b,nuevo_L1,nuevo_L2,xo);
%[U,k]=resolver3(nuevo_A,nuevo_b,nuevo_L1,nuevo_L2,xo);

%Dibujamos las graficas
u=pintar(P1,e1,T1,U,p_dirichlet,p_naturales);%Para cuadráticos