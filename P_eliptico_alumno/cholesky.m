%Calcula la descomposici�n de Cholesky "A = L�L'", donde "A(nxn)" es sim�trica
%definida positiva, y "L" es triangular inferior con elementos diagonales
%positivos.
function L = cholesky(A)

n = size(A,1);%Dimensi�n de "A" (cuadrada)
L = zeros(n,n);%Reservamos espacio para la matriz factor


%Versi�n vectorial (La m�s r�pida)
for i = 1 : n %Para cada columna
    L(i,i) = sqrt(A(i,i) - L(i,1:i-1)*L(i,1:i-1)' );%Elementos diagonales
    L(i+1:n,i) = (A(i+1:n,i) - L(i+1:n,1:i-1) * L(i,1:i-1)' )./L(i,i);%El resto de los elementos de la columna "i"
end


%Versi�n recursiva (Segunda m�s r�pida con tama�os medios (n <= 400)).
%Impracticable para grandes dimensiones (>500)
% L(1,1) = sqrt(A(1,1));%Primer elemento del factor "L"
% L(2:n,1) = A(2:n,1) .* (1/sqrt(A(1,1)));%Calculamos la primera columna de "L" ( "L21 = A21 / L(1,1)" )
% 
% if n == 1%Hemos terminado
%    return;
% else
%    L(2:n,2:n) = cholesky(A(2:n,2:n) - L(2:n,1)*L(2:n,1)');%Llamada recursiva "L22 = cholesky (A22-L21*L21')"
% end


%Versi�n semi-vectorial (Velocidad moderada) 
% for i = 1 : n
%    L(i,i) = sqrt(A(i,i) - L(i,1:i-1)*L(i,1:i-1)' );%Elementos diagonales, de cada fila
%    for k = i + 1 : n
%       L(k,i) = (A(k,i) - L(i,1:i-1)*L(k,1:i-1)')./L(i,i);
%    end    
% end


%Versi�n con bucles (La m�s lenta)
% for i = 1 : n%Para cada columna
%    sum = 0;
%    for j = 1 : i-1
%        sum = sum + L(i,j).* L(i,j);
%    end
%    L(i,i) = sqrt(A(i,i) - sum);%Expresi�n del t�rmino diagonal
%    
%    for k = i + 1 : n%Para cada elemento por debajo de la diagonal en cada columna "i"
%        prod = 0;
%        for j = 1 : i-1
%            prod = prod + L(i,j) .* L(k,j);
%        end
%        L(k,i) = (A(k,i) - prod)/L(i,i);%Expresi�n del t�rmino L(k,i)
%    end
% end