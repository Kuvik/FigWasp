function TV=T_vecinos(T)
TV(1:length(T(:,1)),1:3)=0;
for k=1:length(T(:,1))-1
    m=T(k,:); %almacena todos los vertices del triangulo k
    for i=k+1:length(T(:,1)) %Mira en los triangulos siguientes
        if isempty(find(TV(k,:)==0))
           break
        end
        a=find(T(i,:)==m(1));
        b=find(T(i,:)==m(2));
        c=find(T(i,:)==m(3));
        M=[1,2,3];
        N=M;
        M([a,b,c])=[];
        if length(M)==1
           if isempty(a) TV(k,1)=i;
           elseif isempty(b) TV(k,2)=i;
           elseif isempty(c) TV(k,3)=i;
           end
           TV(i,M)=k;
        end
    end
end
