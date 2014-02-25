function [I,imsiz,c,sigma,N]=E5flash2(varargin)
% E5: flash patch  

error(nargchk(5,6,nargin,'struct'))
if nargin==6
    flshmd=varargin{1};
    bglu=varargin{2};
    stlu=varargin{3};
    n=varargin{4};     % half height
    s=varargin{5};     % 0 or 1: left or right
    noam=varargin{6};
elseif nargin==5
    flshmd=varargin{1};
    bglu=varargin{2};
    stlu=varargin{3};    
    n=varargin{4};
    s=varargin{5};
    noam=0;
end 
showim=1;
% Defining parameters 
gsb=8;          % grayscale shades bits 
mgv=2^gsb-1;    % maximum gun value: number of shades of gray 
if or(strcmpi(n,'FullScreen'),strcmpi(n,'FS')) 
    scrsiz=get(0,'ScreenSize');
    w=scrsiz(3);
    h=scrsiz(4);
    n=h/2;
else
    h=2*n; %+1                    % flash frame edge length, height
    w=round(h*4/3);               % image width: if h=512, w=640
end
if mod(w,2)==1, w=w+1; end
%if flshmd==1, w=h; end
imsiz=[h w];
c=[1+w/2,1+n];         % coordinates origin
nsd=2;          % image height in sds
% spatial sigma: trims brim with gaussian envelope
sigma=n/nsd;  % 2D gaussian blob sd in pixels: depends on n and nsd


% Coordinate matrices for flash frame
boxedge=(-n+1:n)/n;
[x,y]=meshgrid(boxedge);
% Square matrix for flash frame
S=bglu*ones(h);
% Gaussian blob
sn=sigma/h;         % sn~0.5/nsd, blob width as fraction of image height
B = exp(-(x.^2+y.^2)./(2*sn^2));           % range=[0 1]   
% B(B<trim)=0;              % trim around edges (for 8-bit colour displays)

% Clipping patch with a circular stencil
%stimrad=n;                 % circular stimulus radius
%ch=CircularStencil(h,h,c,c,stimrad);
%S(find(ch==0))=bglu;

% Multiplying
G=S+stlu*B;

if flshmd==1      % Placing on the center
    I=bglu*ones(h,w);
    I(:,c(1)-n:c(1)+n-1)=G;
elseif flshmd==2  % Placing on one side
    exc=round((w-1)*3/8); % excentricity:50%:(w-1)/2*(1/2);75%:(w-1)/2*(3/4)=n+1
    I=bglu*ones(h,w);
    if s==0  % left
        if exc <= (w-h)/2
            I(:,c(1)-n-exc:c(1)+n-1-exc)=G;
        elseif exc > (w-h)/2
            I(:,1:c(1)+n-1-exc)=G(:,1+exc-(w-h)/2:end);
        end
        %I=[G, bglu*ones(h,w-h)];
    elseif s==1  % right
        if exc <= (w-h)/2
            I(:,c(1)-n+exc:c(1)+n-1+exc)=G;
        elseif exc > (w-h)/2
            I(:,c(1)-n+exc:end)=G(:,1:end-exc+(w-h)/2);
        end
    else
        error('KuvikException:InvalidInputArgument',...
            'Valid inputs for arg5 are 0(left) or 1(right).')
    end
else
    error('KuvikException:InvalidInputArgument',...
        'Valid inputs for arg1 are 1 or 2.')
end

% Adding white noise
% gaussian noise(na is nvar): the mean and variance parameters are 
% specified as if the image were of class double in the range [0,1]. If the
% input is of class uint8/uint16, imnoise converts the image to double, 
% adds noise according to the specified type and parameters, and then 
% converts the noisy image back to the input class
%nome=0; nvar=na; P8=uint8(Pd); P8n=imnoise(P8,'gaussian',nome,nvar); 
%nome=0; nvar=na; P8n=uint8(Pd+255*sqrt(nvar)*randn(h)); 

% Gaussian noise code
N=noam*randn(h,w);  % here, noam is noise pdf sd
% IMPORTANT:for dynamic noise, do not add I+N
I=I; %I+N; 

% Uniform noise function code
%I=I+noam*(2*rand(h,w)-1); 


% Displaying image
if showim
    %imshow(uint(S))      
    imshow(I+N,'DisplayRange',[0 1]); %imagesc(S,[0 1]);colormap gray(mgv) 
    %axis image, colorbar     
    %title(sprintf('Grayscale uint%d values: 0-%d',gsb,mgv))
    %xlabel(sprintf('Screen depth: %d-bit       Image size: %dx%d pixels',get(0,'ScreenDepth'),w,h))
end


