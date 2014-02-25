function [P,T,e]=acondicionar_malla(p,t,e)
%Acondiciona el vector P(vector nodes) T(vector de triangulos) e(vector de condiciones en la frontera)
P=p';
T=t(1:3,:)';
e=e([5,1,2],:);

%"P" vector de nodos. Cada fila representa un nodo, con coordenadas (x,y) en las columnas
%"T" vector de elementos. Cada fila representa un elemento, con nodos componentes en las tres columnas, 
%ordenados en sentido antihorario
%"e" vector de segmentos frontera. Cada columna representa un segmento; las
%tres filas se corresponden con lo siguiente:
%Primera fila: numero de frontera, según orden de Matlab
%Segunda fila: primer nodo del segmento, según orden de Matlab
%Tercera fila: segundo nodo del segmento, según orden de Matlab
%En la cuarta fila introduciremos los puntos medios si utilizamos elementos cuadráticos