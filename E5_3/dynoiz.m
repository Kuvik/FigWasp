function [ot,rt,KeyCode]=dynoiz(varargin)  

error(nargchk(4,6,nargin,'struct'))
ti=varargin{1};
wp=varargin{2};
p=varargin{3};    
I=varargin{4};     
if nargin==6
    KeyCode=varargin{5};
    keys=varargin{6};
end
with_mogl=1; % 0|1

% Wait LoopPeriod ms before looping to fix flip rate and prevent overload ?
LoopPeriod=0.01; %0.01

%scrfli=Screen('GetFlipInterval',wp);
I=double(I);
imsiz=size(I);%scrsiz=get(0,'ScreenSize');

i=0;
tov=[];

if ~with_mogl  % with Matlab matrix addition
    % Make first flip outside loop
    DN = abs(randn(imsiz)) * p.noamcl;
    noitex = Screen(wp, 'MakeTexture', DN + I);
    Screen(noitex,'TextColor',p.wflu*p.mgv*[1 1 1]);
    Screen(noitex,'TextFont',p.fontname); Screen(noitex,'TextSize',p.chsiz);
    bourec=Screen('TextBounds',noitex,'+');
    Screen(noitex,'DrawText','+',(imsiz(2)-bourec(3))/2,.5*imsiz(1));
    Screen(wp, 'DrawTexture', noitex);
    Screen('Close',noitex);
    [~,ot]=Screen(wp,'Flip');
    while GetSecs < ot + ti
        i=i+1;% Increment framecounter:
        wlo=GetSecs;
        if nargin==6
            % poll for a response: subjects can respond before stimulus terminates
            if (KeyCode(KbName(keys{1}))==1 || KeyCode(KbName(keys{2}))==1)
                break;
            end
            [~,rt,KeyCode]=KbCheck;
        end
        % preparing noisy image 
        noitex = Screen(wp, 'MakeTexture', DN + I);
        Screen(noitex,'TextColor',p.wflu*p.mgv*[1 1 1]);
        Screen(noitex,'TextFont',p.fontname); Screen(noitex,'TextSize',p.chsiz);
        bourec=Screen('TextBounds',noitex,'+');
        Screen(noitex,'DrawText','+',(imsiz(2)-bourec(3))/2,.5*imsiz(1));
        Screen(wp, 'DrawTexture', noitex);
        Screen('Close',noitex);
        % Tell PTB that all drawing commands are done now. This allows the 
        % graphics hardware to perform all drawing and image processing in 
        % parallel while we execute Matlab code for non-graphics related stuff, 
        % in our case random noise creation
        Screen('DrawingFinished', wp);
        % Matrix of random noise with mean gcl for use in the next iteration
        DN = abs(randn(imsiz)) * p.noamcl;
        tov(i)=Screen(wp,'Flip'); % request stimulus onset
        % Wait LoopPeriod ms before looping to fix flip rate and to prevent overload
        WaitSecs('UntilTime',wlo + LoopPeriod);
    end
    
elseif with_mogl % with Matlab OpenGL
    
    AssertOpenGL;
    % For Psychtoolbox imaging pipeline and high precision framebuffers
    % Hardware requirements: ATI Radeon X1000 or later, NVidia Geforce 6000 
    % or later. Recommended Radeon HD2000/3000/... or Geforce-8000/9000/...
    % hardware for maximum fun

    % Make first flip outside loop
    DN = abs(randn(imsiz)) * p.noamcl;
    fshtex=Screen(wp,'MakeTexture',I);
    noitex=Screen(wp,'MakeTexture',DN);
    
    % Initialize OpenGL, but only for 2D drawing. We need this to be able
    % to use the low-level OpenGL command glBlendFunc():
    InitializeMatlabOpenGL([],[],1);
    
    % Enable standard additive blending:
    glBlendEquation(GL.FUNC_ADD);
    
    % Now for the compositing of the noise texture into our onscreen window 
    % backbuffer: draw image I in additive mode -- adding flash pixels to 
    % the noise texture:
    Screen(noitex, 'Blendfunction', GL_ONE, GL_ONE);
    % The extra zero at the end forcefully disables bilinear filtering. 
    % This is not strictly neccessary on correctly working hardware, 
    % but an extra precaution to make sure that the noise values are 
    % blitted one-to-one into the offscreen window:
    Screen(noitex, 'DrawTexture', fshtex, [], [], [], 0);

    Screen(noitex,'TextColor',p.wflu*p.mgv*[1 1 1]);
    Screen(noitex,'TextFont',p.fontname); Screen(noitex,'TextSize',p.chsiz);
    bourec=Screen('TextBounds',noitex,'+');
    Screen(noitex,'DrawText','+',(imsiz(2)-bourec(3))/2,.5*imsiz(1));
    Screen(wp, 'DrawTexture', noitex);
    Screen('Close',noitex);
    [~,ot]=Screen(wp,'Flip');
    %keyboard
    
    while GetSecs < ot + ti
        i=i+1;% Increment framecounter:
        wlo=GetSecs;
        if nargin==6
            % poll for a response: subjects can respond before stimulus terminates
            if (KeyCode(KbName(keys{1}))==1 || KeyCode(KbName(keys{2}))==1)
                break;
            end
            [~,rt,KeyCode]=KbCheck;
        end
        % preparing noisy image 
        noitex=Screen(wp,'MakeTexture',DN);
        glBlendEquation(GL.FUNC_ADD);
        Screen(noitex, 'Blendfunction', GL_ONE, GL_ONE);
        Screen(noitex, 'DrawTexture', fshtex, [], [], [], 0);
        Screen(noitex,'TextColor',p.wflu*p.mgv*[1 1 1]);
        Screen(noitex,'TextFont',p.fontname); Screen(noitex,'TextSize',p.chsiz);
        bourec=Screen('TextBounds',noitex,'+');
        Screen(noitex,'DrawText','+',(imsiz(2)-bourec(3))/2,.5*imsiz(1));
        Screen(wp, 'DrawTexture', noitex);
        Screen('Close',noitex);
        % Tell PTB that all drawing commands are done now. This allows the 
        % graphics hardware to perform all drawing and image processing in 
        % parallel while we execute Matlab code for non-graphics related stuff, 
        % in our case random noise creation
        Screen('DrawingFinished', wp);
        % Matrix of random noise with mean gcl for use in the next iteration
        DN = abs(randn(imsiz)) * p.noamcl;
        tov(i)=Screen(wp,'Flip'); % request stimulus onset
        % Wait LoopPeriod ms before looping to fix flip rate and to prevent overload 
        WaitSecs('UntilTime',wlo+LoopPeriod);
        
    end
end

% Compute avg. computation time for redraw:
AvgRedrawTime = mean(diff(tov)) * 1000
%plot(diff(tov));

return


function B = GPUAvail
try
    d = gpuDevice;
    B = d.SupportsDouble;
catch
    B = false;
end

