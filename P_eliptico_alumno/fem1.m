function u=fem1(p,t,e,f_dirichlet,f_neumann,f_robin)

%Adaptar la malla que proporciona Matlab, a la estructura de datos
%requerida.
%Funciones elementales lineales: 
[P,T,e]=acondicionar_malla(p,t,e);   
[p_dirichlet,p_neumann,p_robin,p_naturales]=nodos_frontera(e,P,f_dirichlet,f_neumann,f_robin);


%Crear los vectores L1,L2 que ayudan a almacenar la matriz A
[L1,L2]=P_vecinos(T);

%Crear la matrices elementales para cada triangulo
[R,M,b]=M_elemental1(P,T);
[R,M,b]=M_ensamblar(P,T,L1,L2,R,M,b,p_neumann,p_robin);
A=R+M;

%Aplicar las condiciones de dirichlet(esenciales) y reducir el sistema
[nuevo_A,nuevo_b,nuevo_L1,nuevo_L2]=contorno(A,b,L1,L2,P,p_dirichlet);


%Resolver el sistema por el gradiente conjugado
xo(1:length(nuevo_b))=0;

%[U,k]=resolver1(nuevo_A,nuevo_b,nuevo_L1,nuevo_L2,xo);
[U,k]=resolver2(nuevo_A,nuevo_b,nuevo_L1,nuevo_L2,xo);
%[U,k]=resolver3(nuevo_A,nuevo_b,nuevo_L1,nuevo_L2,xo);

%Dibujar las graficas
u=pintar(P,e,T,U,p_dirichlet,p_naturales); %Para lineales