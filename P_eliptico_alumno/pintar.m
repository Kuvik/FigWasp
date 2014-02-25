function V=pintar(P,e,T,U,p_dirichlet,p_naturales)
%Representa gráficamente la solución encontrada
if isempty(p_dirichlet)
else
    for i=1:length(p_dirichlet(1,:))
        n=p_dirichlet(:,i);
        V(n(2))=fun_dirichlet(P(n(2),:),n(1));
    end
end
i=sort(p_naturales);
V(i)=U;

%dibujo las graficas

[Vx,Vy]=pdegrad(P',T',-V');
subplot(1,2,1); pdeplot(P',e(2:3,:),T','xydata',V','zdata',V','colormap','jet','colorbar','off','mesh','on')
%axis([0,1,-0.5,1,0,8]);
subplot(1,2,2); pdeplot(P',e(2:3,:),T','xydata',V','flowdata',[Vx',Vy'],'colormap','jet','mesh','on')
%axis([0,1,-.5,1]);
%colorbar;


%Funciones utilizadas para pintar
%pdemesh(P',e(2:3,:),T',V');
%hold on
%pdesurf(P',T',V');
%colormap(jet);
%caxis([0,.6]);

%Tambien para pintar se puede usar
%tri2grid(P',T',U,x,y) corte en los vectores x e y. Ej: x=0; y=-1:0.1:1;
%trisurf(T',P(:,1),P(:,2),U);