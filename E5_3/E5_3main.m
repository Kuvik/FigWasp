function E5_3main(flshmd,withDynNoise,pThreshold,lang,trigkey,logludt,isMain,resume)
%
% Methods: Adaptive Bayesian method to adjust performance at 50% of present
%          4-point scales will be used for subjective reports
%          fMRI
%
% if flshmd==1, E5_3: main task with one central stimulus
% #trials: nk * nc * nr = nt
%          02 * 06 * 40 = 480
% Randomize blocks of event-related trials 
% randomize csi(ni), but not task type(nk), within blocks
% nt  = nk * ntpb * nbpk * ns  
% 480 = 02 * 24   * 4/2  * 05 
% 5sessions of 4blocks of 24trials (with 6 conditions)
% 5sessions of 12min approximately, so around 60min
%
% if flshmd==2, E5_3: main task with lateral stimuli
% #trials: nk * nc * nr = nt
%          03 * 06 * 40 = 720
% Randomize blocks of event-related trials 
% randomize csi(ni), but not task type(nk), within blocks
% nt  = nk * ntpb * nbpk * ns  
% 720 = 03 * 24   * 6/3  * 05 
% 5sessions of 6blocks of 24trials (with 6 conditions)
% 5sessions of 18min approximately, so around 90min
%
% Additionally, there is a habituation&calibration block with fixed csi at 
% the beginning for main task(nb=30), although not for training(nb in 3:6)
% nht = ntpb. It is intended to habituate the subjects to the CSI.


KbName('UnifyKeyNames');
% detection: flshmd=1
d1keys{1}='1'; % Y in flshmd=1
d1keys{2}='2'; % N in flshmd=1
% detection: flshmd=2
d1keys{3}='1'; % Y left in flshmd=2
d1keys{4}='2'; % N in flshmd=2
d1keys{5}='3'; % Y right in flshmd=2
% normal cr (4 points)

chlrkeys{1}='1'; % choose left (only if given freedom to choose side)
chlrkeys{2}='2'; % choose right (only if given freedom to choose side)
% perception under imagery question: flshmd=1
ikeys{1}='1'; % only imaged, analysis target
ikeys{2}='2'; % imaged and seen 
%ikeys{3}='3#'; % imagery failed, only stimulus, just in case 
% perception under imagery question: flshmd=2
ikeys{4}='1'; % only imaged, analysis target
ikeys{5}='2'; % imaged and seen in the same side, analysis target
ikeys{6}='3'; % imaged and seen in the opposite side, just control for analysis
%ikeys{7}='4$'; % imagery failed, stimulus in same side, just in case 
%ikeys{8}='5%'; % imagery failed, stimulus in opposite side, just in case 
% if imagery is 1 or 2, cr on onlyimaged/imagedandseen dichotomy in same side (4 points)
% if imagery is 3, usual cr (4 points)

% if imagery is 2, additionally temporal order and relative brightness
itkeys{1}='1'; % imaged before
itkeys{2}='2'; % coincident
itkeys{3}='3'; % imaged after
ibkeys{1}='1'; % imaged less bright
ibkeys{2}='2'; % imaged same
ibkeys{3}='3'; % imaged brighter

crkeys{1}='1!'; 
crkeys{2}='2@'; 
crkeys{3}='3#'; 
crkeys{4}='4$'; 

contkey='c'; % press this to continue

RestrictKeysForKbCheck([KbName(d1keys{1}) KbName(d1keys{2})...
    KbName(d1keys{3}) KbName(d1keys{4}) KbName(d1keys{5}) ...
    KbName(chlrkeys{1}) KbName(chlrkeys{2}) ...
    KbName(ikeys{1}) KbName(ikeys{2}) KbName(ikeys{3}) ...
    KbName(itkeys{1}) KbName(itkeys{2}) KbName(itkeys{3}) ...
    KbName(ibkeys{1}) KbName(ibkeys{2}) KbName(ibkeys{3}) ...
    KbName(crkeys{1}) KbName(crkeys{2}) KbName(crkeys{3}) KbName(crkeys{4}) ...
    KbName(contkey) KbName(trigkey) KbName('F10') KbName('F11')]);
oldvdl=Screen('Preference','VisualDebugLevel',1);
LoadGammaTable='';  % '', 'Acer715', 'TamagawaMonitor', not too necessary
debugmode=2;
allowquit=1;

viswon=0;
if viswon % 14-bit high luminance resolution mode with VideoSwitcher
    PsychVideoSwitcher('SwitchMode',0,viswon,0); 
end



%%%%%%%%%%%%%%%%%
% initialization
%%%%%%%%%%%%%%%%%

%%% Defining paremeters: layout %%%
if viswon
    p.gsb=14;         % grayscale shades bits
    p.btrr=126.3;
else
    p.gsb=8;
end
p.mgv=2^p.gsb-1;    % maximum gun value: number of shades of gray 
p.instexlu=0.5;                     % text luminance
p.reptexlu=0.5;
% Defining paremeters: stimuli
  p.bglu=0; p.bglucl=p.bglu*p.mgv;     % background luminance
p.wflu=0.9; p.wflucl=p.wflu*p.mgv;   % white fixation point luminance
p.gflu=(p.wflu+p.bglu)/3;         % grey fixation luminance
p.bgsiz='FS';
[~,~,p.scrcen,p.sigma]=E5flash2(flshmd,p.bglu,0,p.bgsiz,0); 
p.scrsiz=get(0,'ScreenSize');  % 1 1 1024 768; 1 1 1280 800
p.icr=p.scrsiz(4)/2;         % 511, incircle radius
p.noam=0.35;%0.3   % gaussian noise sd: pdf clamped if noam>1/3
p.noamcl=p.noam*p.mgv; 
% Empty matrix 
BM64=p.bglu*ones(p.scrsiz(4),p.scrsiz(3));    
if viswon, BM=PsychVideoSwitcher('MapLuminanceToRGB',BM64,p.btrr);
else BM=uint8(BM64*p.mgv); end
% Defining paremeters: sound
p.ppa.deviceid=-1; p.ppa.reqlatencyclass=2; p.ppa.freq=44100;
p.ppa.buffersize=0; p.ppa.suggestedLatencySecs=[]; p.ppa.latbias=0;
p.beepv=0.5; p.beepf=400; p.beepd=0.1;
p.beep(1,:)=p.beepv*MakeBeep(p.beepf,p.beepd,p.ppa.freq);% Generate some beep sound
p.beep(2,:)=p.beep(1,:); 
%p.sbeep=sin(1:0.5:100);
% Defining paremeters: trial sequence
if flshmd==1
    p.nk=2;                    % number of different tasks
elseif flshmd==2
    p.nk=3;
end
p.ni=5;                    % number of different intervals
p.nc=p.ni+1;             %#conditions,i.e., ni and the catch trial
p.cpt=(p.nc-p.ni)/p.nc; %proportion of catch trials: 5/6=16.67% 
if ~isMain  %training out of the scanner
    p.nb=3;  
    p.ns=1;                    
    p.nr=1;
elseif isMain % actual experiment
    if flshmd==1                  % #blocks
        p.nb=20;  
    elseif flshmd==2
        p.nb=30;  % 30 for main, 3 for training 
    end
    p.ns=5;                    % #sessions 
    p.nr=40;                   % number of trials per condition
end
p.nbps=round(p.nb/p.ns);      % #blockspersession
p.nt=p.nk*p.nc*p.nr; % total number of trials 
p.ntpb=round(p.nt/p.nb);      % #trialsperblock 
p.nht=p.ntpb;%*2                  % #habituation trials
p.nqd=2;                  % number of questions per trial in detection task   
if flshmd==1
    p.nqi1=2;
    p.nqi2=4;
elseif flshmd==2
    p.nqi1=2; % number of questions per trial in imagery task  
    p.nqi2=4;
    p.nqi3=2;
end
p.prebk=4;      % first waiting interval
p.lrdi=0.5;  % arrow indicating side disp interval
p.csi_grain=0.15;
p.presti=1.5;  % interval for getting prepared to image or detect
p.presi0=0.8;             % prestimulus fixed interval
p.presi1=p.csi_grain*[-2 -1 0 1 2];  % prestimulus variable interval
p.csi=p.presi0+p.presi1;         % varying CSI                 
p.sdi=0.2;                   % stimulus display time in ms 
p.posti=0.5;                     % poststimulus interval
p.postr=1;                   % trial end interval
p.iti=p.presti+p.postr;       % ITI
p.respwid1=5;                   % response window for detection
p.respwid2=5; 
p.respwii0=5;
p.respwii11=5;                   % response window for imagery
p.respwii12=5; 
p.respwii21=5; 
p.respwii22=5; 
p.respwii23=5; 
%ITI=csi+sdi+posti+respwi

% figure(1);pause(3);E5flash(0,.1,256,0);tic;pause(0.01);E5flash(0,.00,256,0);tc=toc;


% Definition of PF intensity: lwc=log10(stlu/bglu)
%logarithm of Weber contrast of Gaussian peak amplitude 
p.ludt=10^logludt;

% Provide our prior knowledge to QuestCreate, and receive the data struct q
tGuess=logludt;  
tGuessSd=3;
%pThreshold=0.75;          % threshold criterion expressed as P(response)==1           
beta=3.5;delta=0.01;
gamma=0.5;                         % because it is a Y/N task, gamma=0.5
grain=0.01;range=4;                % intensity as logarithm of contrast
p.lurgmax=0.2;
q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range);
q.normalizePdf=1;% This adds a few ms per call to QuestUpdate, but 
                 % otherwise the pdf will underflow after about 1000 trials

%%% Shuffling algorithm: creating a random sequence of p.nc categories %%%
trm_rps=zeros(p.nb,p.ntpb);
for i=1:p.nb           % csi values sequence random permutation  
    trm_rps(i,:)=randperm(p.ntpb);
    trm_rps(i,:)=mod(trm_rps(i,:),p.nc)+1;  % shuffle instead of randomize (j=ceil(no*rand)) 
end
p.trm_rps=trm_rps; % 1-5 are p.csi(1-5); 6 is for zero luminance
if resume.ing
    fromBlockNum=resume.from;
else
    fromBlockNum=1;
end


%%% Image sequence presentation and control flow statements %%%

%%% Instructions text
if strcmp(lang,'EN')
    instr{1}='Detection';
    instr{2}='Perception under imagery';
    instr{3}='Please look always at the fixation cross in the center of the screen.';
    if flshmd==1
        instr{4}='A fixed time interval after a beep sound, a flashing stimulus will appear at the center of the screen in some trials.';
        instr{5}='By pressing the corresponding keys, you will have to report:';
        instr{6}='Detection';
        instr{7}='[R1] seen   [R2] not seen';
        instr{8}='Confidence in your decision in ''Detection'' question';
        instr{9}='[L1] not at all  [L2] a little  [L3] quite  [L4] absolutely';
        instr{10}='Perception under imagery';
        instr{11}='Imagine the flash at the same time as it appears (beep-stimulus interval is fixed)';
        instr{12}='Number of stimuli (S:screen stimulus, I:imagery stimulus)';
        instr{13}='R1: only I   R2: I & S';
        instr{14}='Rate the stimulus procedence belief in ''Perception under imagery'' question (it varies depending on your answer)';
        instr{15}='L1: not at all    L2: a little   L3: quite   L4: absolutely';
    elseif flshmd==2
        instr{4}='A fixed time interval after a beep sound, a flashing stimulus will appear at one side of the screen in some trials.';
        instr{5}='By pressing the corresponding keys, you will have to report:';
        instr{6}='Detection';
        instr{7}='R1: seen left   R2: not seen   R3: seen right';
        instr{8}='Confidence in your decision in ''Detection'' question';
        instr{9}='L1: not at all    L2: a little   L3: quite   L4: absolutely';
        instr{10}='Imagine the flash in the indicated side (left or right),';
        instr{11}='and at the same time as it appears in the screen (beep-stimulus interval is fixed)';
        instr{12}='Number and position of stimuli (S:screen stimulus, I:imagery stimulus)';
        instr{13}='R1: only I   R2: I & S in same side   R3: I & S in opposite sides';
        instr{14}='Confidence in your decision in ''Peception under imagery'' question (it varies depending on your answer)';
        instr{15}='L1: not at all    L2: a little   L3: quite   L4: absolutely';
    end
    instr{16}='Rating of imagery-stimulus superposition for ''I & S in same side'' in ''Perception under imagery''';
    instr{17}='R1: miss, t(I) < t(S)   R2: hit, t(I) = t(S)   R3: miss, t(I) > t(S)';
    instr{18}='Rating of the relative brightness for ''I & S in same side'' in ''Peception under imagery''';
    instr{19}='R1: B(I) < B(S)   R2: B(I) = B(S)   R3: B(I) > B(S)';
    instr{20}='IMPORTANT: try to use all the confidence {1 2 3 4} scale as exhaustively as possible.';
    instr{21}='answer only when a response prompt appears';
    %instr{22}='You will receive your performance score later';
    instr{23}='Wait for a sign to continue';
    instr{24}='Detection\nR1: seen left   R2: not seen   R3: seen right';
    instr{25}='Confidence\nL1: not at all   L2: a little   L3: quite   L4: absolutely';
    if flshmd==1
        instr{26}='Perception under imagery\nR1: I   R2: I & S'; % R3 would be just in case they fail to imagine
    elseif flshmd==2
        instr{27}='Perception under imagery\nR1: I   R2: I & S, same   R3: I & S, opposite'; % 4and 5 would be just in case they fail to imagine
    end
    instr{31}='Temporal order\nR1: t(I) < t(S)   R2: t(I) = t(S)   R3: t(I) > t(S)';
    instr{32}='Relative brightness\nR1: B(I) < B(S)   R2: B(I) = B(S)   R3: B(I) > B(S)';
    instr{33}=hex2dec('2190');%'<'; %'Imagine the flash in the LEFT side'; 
    instr{34}=hex2dec('2192');%'>'; %'Imagine the flash in the RIGHT side';
    instr{35}=hex2dec('2194'); %'◇';
    instr{36}='+';
    switch OSName
        case 'Linux', p.fontname='-misc-fixed-medium-r-normal--18-120-100-100-c-90-iso8859-15';
        case 'Windows', p.fontname='Courier New';
        otherwise, p.fontname='Helvetica';
    end
elseif strcmp(lang,'JP')
    instr{1}=' ';
    instr{2}=' ';
    instr=cellfun(@double,instr,'uniformOutput',False);
    p.fontname='TakaoExGothic';
    if IsLinux, p.fontname='-:lang=ja'; end
end
p.instr=instr;
p.fontsize=18;
p.chsiz=28;

% Getting parameters
p.oldfontname=Screen('Preference','DefaultFontName',p.fontname);
p.oldfontsize=Screen('Preference', 'DefaultFontSize',p.fontsize);
[p.dispsiz(1) p.dispsiz(2)]=Screen('DisplaySize',0);
load EDevices; % Visual angle subtended by the screen pixels
p.monsiz=Tamagawa_fMRI.display_size; %like p.dispsiz should be %mm
p.vdist=Tamagawa_fMRI.visual_distance; %mm
[p.visang,p.pixperdeg, p.degperpix]=VisAng(p);
p.scrnum=Screen('Screens'); % 0 is the main screen
oldgt=Screen('ReadNormalizedGammaTable',0);
if LoadGammaTable
    load(LoadGammaTable); graygammatable=gammaTable1;
    Screen('LoadNormalizedGammaTable',0, graygammatable*[1 1 1]);
end
[p.gammatable,p.dacbits,p.reallutsize]=Screen('ReadNormalizedGammaTable',0);
p.wcl=WhiteIndex(0); p.bcl=BlackIndex(0); %CLUT index at the current screen depth
p.gcl=p.bglu*(p.wcl+p.bcl);
p.scrppi=get(0,'ScreenPixelsPerInch'); % 96
[p.winsiz(1) p.winsiz(2)]=Screen('WindowSize', 0);
assert(p.scrsiz(3)==p.winsiz(1) && p.scrsiz(4)==p.winsiz(2)); 
switch debugmode
    case 0, winsiz=[];
    case 1, winsiz=[+10 +10 p.scrsiz(3)/2-10 p.scrsiz(4)/2-10];
    case 2, PsychDebugWindowConfiguration([],.8), winsiz=[];
end
p.timeseg(1,:)=datevec(now);

try
    % Dummy calls to make sure these functions are loaded and ready when we 
    % need them - without delays in the wrong moment:
    KbCheck;
    WaitSecs(0.1);
    GetSecs;
    
    % initialize KbCheck and variables to make sure they're properly 
    % allocated by Matlab - this to avoid time delays in the critical 
    % reaction time measurement part of the script
    [KeyIsDown,rt1,KeyCode1]=KbCheck;
    [KeyIsDown,rt2,KeyCode2]=KbCheck;
    [KeyIsDown,rt3,KeyCode3]=KbCheck;
    [KeyIsDown,rt4,KeyCode4]=KbCheck;
    
    %%% Initialize audio device %%%
    InitializePsychSound;
    PAhandle=PsychPortAudio('Open',-1,[],2,44100,2,0);
    PsychPortAudio('FillBuffer', PAhandle, p.beep); % Fill buffer with beep
    
    %%% Initializing data structures %%%
    wip=zeros(1,6+max([p.nqd p.nqi1 p.nqi2]));
    try    
        % Open onscreen window: We request a 32 bit per color component
        % floating point framebuffer if it supports alpha-blendig. Otherwise
        % the system shall fall back to a 16 bit per color component
        % framebuffer:
        PsychImaging('PrepareConfiguration');
        PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
        wip(1)=PsychImaging('OpenWindow',0,[],winsiz);%w(1)=0;
    catch ME
        wip(1)=Screen(0,'OpenWindow',[],winsiz);%w(1)=0;
        warning('KuvikWarning:ObsoleteHardware',...
            ['Floating 32-bit framebuffer unavailable. Falling back to 16-bit.'...
            '\nMException message: ' ME.message]);
    end
    p.scrdep=get(0,'ScreenDepth'); % up to 32; %pixdeps=Screen('PixelSizes',0);
    [p.scrfli p.nrValidSamples p.stddev]=Screen('GetFlipInterval',wip(1));
    Screen(wip(1),'FillRect',p.gcl);
    KbName('UnifyKeyNames'); 
    dateISO8601=datestr(now,30);
    p.filename30=['E5_3D',dateISO8601];
    p.filename29=['E5_3D',datestr(now,29)];
    h.csi=[];
    h.side=[];
    h.tint=[];
    h.kbi=[];
    h.d1=[];
    h.d2=[];
    h.i1=[];
    h.i2=[];
    h.i3=[];
    h.i4=[];
    h.timelog=[];
    h.kbih=[];
    h.sideh=[];
    h.tinth=[];
    h.d1h=[];
    h.d2h=[];
    h.timelogh=[];
    
    %%% Stacking frames in offscreen buffers %%% 
    
    % Detection instructions
    wip(15)=Screen(0,'OpenOffscreenWindow',p.gcl);
    Screen(wip(15),'TextColor',p.instexlu*p.mgv*[1 1 1]);
    Screen(wip(15),'TextSize',36); bourec=Screen('TextBounds', wip(15),instr{1});
    Screen(wip(15),'DrawText',instr{1},(p.scrsiz(3)-bourec(3))/2,.1*p.scrsiz(4));
    Screen(wip(15),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(15),instr{3});
    Screen(wip(15),'DrawText',instr{3},(p.scrsiz(3)-bourec(3))/2,.25*p.scrsiz(4));
    bourec=Screen('TextBounds', wip(15),instr{4});
    Screen(wip(15),'DrawText',instr{4},(p.scrsiz(3)-bourec(3))/2,.3*p.scrsiz(4));
    bourec=Screen('TextBounds', wip(15),instr{5});
    Screen(wip(15),'DrawText',instr{5},(p.scrsiz(3)-bourec(3))/2,.35*p.scrsiz(4));
    Screen(wip(15),'TextSize',20); bourec=Screen('TextBounds', wip(15),instr{6});
    Screen(wip(15),'DrawText',instr{6},(p.scrsiz(3)-bourec(3))/2,.5*p.scrsiz(4));
    Screen(wip(15),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(15),instr{7});
    Screen(wip(15),'DrawText',instr{7},(p.scrsiz(3)-bourec(3))/2,.55*p.scrsiz(4));
    Screen(wip(15),'TextSize',20); bourec=Screen('TextBounds', wip(15),instr{8});
    Screen(wip(15),'DrawText',instr{8},(p.scrsiz(3)-bourec(3))/2,.65*p.scrsiz(4));
    Screen(wip(15),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(15),instr{9});
    Screen(wip(15),'DrawText',instr{9},(p.scrsiz(3)-bourec(3))/2,.7*p.scrsiz(4));
    Screen(wip(15),'TextSize',20); bourec=Screen('TextBounds', wip(15),instr{20});
    Screen(wip(15),'DrawText',instr{20},(p.scrsiz(3)-bourec(3))/2,.8*p.scrsiz(4));
    bourec=Screen('TextBounds', wip(15),instr{21});
    Screen(wip(15),'DrawText',instr{21},(p.scrsiz(3)-bourec(3))/2,.85*p.scrsiz(4));
    Screen(wip(15),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(15),instr{23});
    Screen(wip(15),'DrawText',instr{23},(p.scrsiz(3)-bourec(3))/2,.9*p.scrsiz(4));

    % Perception under imagery instructions
    wip(16)=Screen(0,'OpenOffscreenWindow',p.gcl);
    Screen(wip(16),'TextColor',p.instexlu*p.mgv*[1 1 1]);
    Screen(wip(16),'TextSize',36); bourec=Screen('TextBounds', wip(16),instr{2});
    Screen(wip(16),'DrawText',instr{2},(p.scrsiz(3)-bourec(3))/2,.1*p.scrsiz(4));
    Screen(wip(16),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(16),instr{3});
    Screen(wip(16),'DrawText',instr{3},(p.scrsiz(3)-bourec(3))/2,.25*p.scrsiz(4));
    bourec=Screen('TextBounds', wip(15),instr{10});
    Screen(wip(16),'DrawText',instr{10},(p.scrsiz(3)-bourec(3))/2,.3*p.scrsiz(4));
    bourec=Screen('TextBounds', wip(16),instr{11});
    Screen(wip(16),'DrawText',instr{11},(p.scrsiz(3)-bourec(3))/2,.33*p.scrsiz(4));
    Screen(wip(16),'TextSize',20); bourec=Screen('TextBounds', wip(16),instr{12});
    Screen(wip(16),'DrawText',instr{12},(p.scrsiz(3)-bourec(3))/2,.4*p.scrsiz(4));
    Screen(wip(16),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(16),instr{13});
    Screen(wip(16),'DrawText',instr{13},(p.scrsiz(3)-bourec(3))/2,.43*p.scrsiz(4));
    Screen(wip(16),'TextSize',20); bourec=Screen('TextBounds', wip(16),instr{14});
    Screen(wip(16),'DrawText',instr{14},(p.scrsiz(3)-bourec(3))/2,.5*p.scrsiz(4));
    Screen(wip(16),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(16),instr{15});
    Screen(wip(16),'DrawText',instr{15},(p.scrsiz(3)-bourec(3))/2,.53*p.scrsiz(4));
    Screen(wip(16),'TextSize',20); bourec=Screen('TextBounds', wip(16),instr{16});
    Screen(wip(16),'DrawText',instr{16},(p.scrsiz(3)-bourec(3))/2,.6*p.scrsiz(4));
    Screen(wip(16),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(16),instr{17});
    Screen(wip(16),'DrawText',instr{17},(p.scrsiz(3)-bourec(3))/2,.63*p.scrsiz(4));
    Screen(wip(16),'TextSize',20); bourec=Screen('TextBounds', wip(16),instr{18});
    Screen(wip(16),'DrawText',instr{18},(p.scrsiz(3)-bourec(3))/2,.7*p.scrsiz(4));
    Screen(wip(16),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(16),instr{19});
    Screen(wip(16),'DrawText',instr{19},(p.scrsiz(3)-bourec(3))/2,.73*p.scrsiz(4));
    Screen(wip(16),'TextSize',20); bourec=Screen('TextBounds', wip(16),instr{20});
    Screen(wip(16),'DrawText',instr{20},(p.scrsiz(3)-bourec(3))/2,.85*p.scrsiz(4));
    bourec=Screen('TextBounds', wip(16),instr{21});
    Screen(wip(16),'DrawText',instr{21},(p.scrsiz(3)-bourec(3))/2,.9*p.scrsiz(4));
    Screen(wip(16),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(16),instr{23});
    Screen(wip(16),'DrawText',instr{23},(p.scrsiz(3)-bourec(3))/2,.95*p.scrsiz(4));
    
    wip(3)=Screen(0,'OpenOffscreenWindow',p.gcl); % fixation cross
    Screen(wip(3),'TextColor',p.wflu*p.mgv*[1 1 1]);
    Screen(wip(3),'TextSize',p.chsiz);
    DrawFormattedText(wip(3),instr{36},'center','center');
    
    wip(5)=Screen(0,'OpenOffscreenWindow',p.gcl); % ITI dim fixation cross
    Screen(wip(5),'TextColor',p.gflu*p.mgv*[1 1 1]);
    Screen(wip(5),'TextSize',p.chsiz);
    DrawFormattedText(wip(5),instr{36},'center','center');
    
    %%% reponse mapping display windows     
    % detection
    wip(6)=Screen(0,'OpenOffscreenWindow',p.gcl);  
    Screen(wip(6),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    DrawFormattedText(wip(6),instr{24},'center','center');
    % confidence on anything 
    wip(7)=Screen(0,'OpenOffscreenWindow',p.gcl);  
    Screen(wip(7),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    DrawFormattedText(wip(7),instr{25},'center','center');
    if flshmd==1 
        % report flash (2 options)
        wip(8)=Screen(0,'OpenOffscreenWindow',p.gcl);  
        Screen(wip(8),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
        DrawFormattedText(wip(8),instr{26},'center','center');
    elseif flshmd==2
        % report flash (3 options)
        wip(9)=Screen(0,'OpenOffscreenWindow',p.gcl);  
        Screen(wip(9),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
        DrawFormattedText(wip(9),instr{27},'center','center');
    end
    % temporal order of the mental and physical images
    wip(13)=Screen(0,'OpenOffscreenWindow',p.gcl);  
    Screen(wip(13),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    DrawFormattedText(wip(13),instr{31},'center','center');
    % relative brightness of mental and physical images
    wip(17)=Screen(0,'OpenOffscreenWindow',p.gcl);  
    Screen(wip(17),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    DrawFormattedText(wip(17),instr{32},'center','center');
    % either side (detection)
    wip(12)=Screen(0,'OpenOffscreenWindow',p.gcl);  
    Screen(wip(12),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    Screen(wip(12),'TextSize',p.chsiz);
    DrawFormattedText(wip(12),instr{35},'center','center');
    % imperative choice of side (imagery)
    % left
    wip(18)=Screen(0,'OpenOffscreenWindow',p.gcl);  
    Screen(wip(18),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    Screen(wip(18),'TextSize',p.chsiz);
    DrawFormattedText(wip(18),instr{33},'center','center');
    % right
    wip(19)=Screen(0,'OpenOffscreenWindow',p.gcl);  
    Screen(wip(19),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    Screen(wip(19),'TextSize',p.chsiz);
    DrawFormattedText(wip(19),instr{34},'center','center');
    
    
%%%%%%%%%%%%%%%%%
% task
%%%%%%%%%%%%%%%%%
    
    HideCursor;
    p.PriLev=MaxPriority(wip(1));
    Priority(p.PriLev);

    t0=GetSecs; 
    Screen(wip(1),'DrawTexture',wip(5)); % fixation cross
    Screen('Flip',wip(1));
    % keypress by experimenter to continue
    [~,kc]=KbWait([],2);
    while ~kc(KbName(contkey))==1 
        [~,kc]=KbWait([],2); WaitSecs('YieldSecs',0.1);
    end

    %%% Habituation and calibration block: 
    % only detection, to habituate the subject to beep-stimulus delay
    % also, it is advisable to discard to first few fMRI scans
    Screen(wip(1),'DrawTexture',wip(15)); 
    [~, onset_tsktxth]=Screen('Flip',wip(1));
    % keypress by experimenter to continue
    [~,kc]=KbWait([],2);
    while ~kc(KbName(contkey))==1 
        [~,kc]=KbWait([],2); WaitSecs('YieldSecs',0.1);
    end

    % Wait for scanner trigger
    [~,triggerh,KeyCodeT]=KbCheck;
    while KeyCodeT(KbName(trigkey))==0 
        [~,triggerh,KeyCodeT]=KbCheck;
        WaitSecs(0.005);
    end

    Screen(wip(1),'DrawTexture',wip(5));Screen('Flip',wip(1));
    WaitSecs(p.prebk);

    for i=1:p.nht
        % Interrupt by pressing before trial starts
        if KbCheck && allowquit, [~,~,kc]=KbCheck; 
           if kc(KbName('F10'))==1, break; 
           elseif kc(KbName('F11'))==1, return; 
           end
        end

        % reinitializing variables
        kbi1h=KbName('9(');kbi2h=KbName('9(');% KbName(105)='9'
        onset_fp=t0;onset_be=t0;onset_st=t0;offset_st=t0;
        onset_q1=t0;rt1=t0;onset_q2=t0;rt2=t0;        
        whichd1h=9;whichd2h=9;
        KeyCode1=zeros(1,256);KeyCode2=zeros(1,256);

        % Interleave half of trials with no stimulus, lest the subject 
        % assigns high probability to stimulus presence in the main task
        lrh=round(rand); % 0 left, 1 right
        % Easy flash to allow subject to habituate to csi 
        tint=0.1+0.1*randn; % gaussian pdf of flash intensity, easy
        tint=min(p.lurgmax,max(0,tint)); %restrict to range of contrasts that our equipment can produce
        tint=round(tint*p.mgv)/p.mgv; %restrict grain of log contrasts
        tsug_r=log10(tint);
        
        % bilateral attention prompt
        if flshmd==1
            Screen(wip(1),'DrawTexture',wip(5)); 
        elseif flshmd~=1
            Screen(wip(1),'DrawTexture',wip(12)); 
        end
        Screen('Flip',wip(1)); WaitSecs(p.lrdi);

        %draw flash and noisebg in buffer, all parameters passed on the fly
        [I64,~,~,~,N64]=E5flash2(flshmd,p.bglu,tint,'FS',lrh,p.noam); % lrh is safely ignored if flshmd=1 
        if viswon
            I=PsychVideoSwitcher('MapLuminanceToRGB',I64,p.btrr);
            N=PsychVideoSwitcher('MapLuminanceToRGB',I64,p.btrr);
        else
            I=uint8(I64*p.mgv);
            N=uint8(N64*p.mgv);
        end
        wip(4)=Screen(wip(1),'MakeTexture',I+N);
        Screen(wip(4),'TextColor',p.wflu*p.mgv*[1 1 1]);
        Screen(wip(4),'TextFont',p.fontname); Screen(wip(4),'TextSize',p.chsiz);
        DrawFormattedText(wip(4),instr{36},'center','center');
        % adding noise bg for static noise display mode(withDynNoise=0)
        wip(2)=Screen(wip(1),'MakeTexture',N);
        Screen(wip(2),'TextColor',p.wflu*p.mgv*[1 1 1]);
        Screen(wip(2),'TextFont',p.fontname); Screen(wip(2),'TextSize',p.chsiz);
        DrawFormattedText(wip(2),instr{36},'center','center');
        
        % Presenting stimulus (or not)
        if ~withDynNoise
            Screen(wip(1),'DrawTexture',wip(2)); [~,onset_fp]=Screen('Flip',wip(1));
            WaitSecs(p.presti);
            PsychPortAudio('Start', PAhandle, 1, 0, 0);
            offset = 0;
            while offset == 0 % spin-wait until first sample is played
                status = PsychPortAudio('GetStatus', PAhandle);
                offset = status.PositionSecs;
                if offset>0, break; end
                WaitSecs('YieldSecs', 0.001);
            end
            onset_be = status.StartTime;
            PsychPortAudio('Stop', PAhandle, 1);
            %or Beeper(400,0.4,0.15); %sound(sbeep); 
            WaitSecs(p.presi0);  % fixed csi for habituation
            Screen(wip(1),'DrawTexture',wip(4)); [~,onset_st]=Screen('Flip',wip(1));
            % show stimulus until sdi elapses
            while (GetSecs-onset_st)<=p.sdi
                % poll for a response: subjects can respond before stimulus terminates
                if (KeyCode1(KbName(d1keys{1}))==1 || KeyCode1(KbName(d1keys{2}))==1)
                    break;
                end
                [~,rt1,KeyCode1]=KbCheck;
                % Wait 1 ms before checking the keyboard again to prevent overload 
                % of the machine at elevated Priority():
                WaitSecs(0.001);
            end         %WaitSecs('UntilTime',onset_st+p.sdi);
            Screen(wip(1),'DrawTexture',wip(2)); [~, offset_st]=Screen('Flip',wip(1));
            Screen('Close',wip(2));
            WaitSecs(p.posti);
        elseif withDynNoise
            onset_be = GetSecs+p.presti; % inaccurate! too much hassle to write good code
            PsychPortAudio('Start', PAhandle, 1, onset_be,0);
            onset_fp=dynoiz(p.presti,wip(1),p,BM);
            dynoiz(p.presti+p.presi0-p.beepd,wip(1),p,BM); % fixed csi for habituation
            % show stimulus until sdi elapses
            [onset_st,rt1,KeyCode1]=dynoiz(p.sdi,wip(1),p,I,KeyCode1,d1keys);
            offset_st=dynoiz(p.posti,wip(1),p,BM);
        end

        % detection question: loop until valid key pressed or reswi terminates
        Screen(wip(1),'DrawTexture',wip(6)); [~, onset_q1]=Screen('Flip',wip(1));
        while (KeyCode1(KbName(d1keys{1}))==0 && KeyCode1(KbName(d1keys{2}))==0 && ...
                KeyCode1(KbName(d1keys{3}))==0 && KeyCode1(KbName(d1keys{4}))==0 && ...
                KeyCode1(KbName(d1keys{5}))==0) && (GetSecs-onset_q1)<=p.respwid1
            [~,rt1,KeyCode1]=KbCheck;
             WaitSecs(0.001);
        end
        % computing answer
        if ~isempty(find(KeyCode1,1)) && length(find(KeyCode1))==1
            kbi1h=find(KeyCode1);
            if flshmd==1
                switch find(KeyCode1)
                    case KbName(d1keys{1}), whichd1h=1;
                    case KbName(d1keys{2}), whichd1h=0;
                    otherwise, whichd1h=NaN;
                end
            elseif flshmd==2
                switch find(KeyCode1)
                    case KbName(d1keys{3}), whichd1h=1;
                    case KbName(d1keys{4}), whichd1h=0;
                    case KbName(d1keys{5}), whichd1h=2;
                    otherwise, whichd1h=NaN;
                end
            end
        else
            kbi1h=NaN; 
            whichd1h=NaN;
        end
        KbReleaseWait; 

        % second question  
        Screen(wip(1),'DrawTexture',wip(7)); [~, onset_q2]=Screen('Flip',wip(1)); 
        while (KeyCode2(KbName(crkeys{1}))==0 && KeyCode2(KbName(crkeys{2}))==0 ...
                && KeyCode2(KbName(crkeys{3}))==0 && KeyCode2(KbName(crkeys{4}))==0) ...
                && (GetSecs-onset_q2)<=p.respwid2
            [~,rt2,KeyCode2]=KbCheck;
            WaitSecs(0.001);
        end
        if ~isempty(find(KeyCode2,1)) && length(find(KeyCode2))==1 
            kbi2h=find(KeyCode2);
            switch find(KeyCode2)
                case KbName(crkeys{1}), whichd2h=1;
                case KbName(crkeys{2}), whichd2h=2;
                case KbName(crkeys{3}), whichd2h=3;
                case KbName(crkeys{4}), whichd2h=4;
                otherwise, whichd2h=NaN;
            end
        else
            kbi2h=NaN; 
            whichd2h=NaN;
        end
        KbReleaseWait; 

        % Wait end of trial
        Screen(wip(1),'DrawTexture',wip(5)); Screen('Flip',wip(1));
        WaitSecs(p.postr);

        h.timelogh(:,i)=[onset_tsktxth-t0;triggerh-t0;onset_fp-t0;...
            onset_be-t0;onset_st-t0;offset_st-t0;onset_q1-t0;rt1-t0;...
            onset_q2-t0;rt2-t0];

        if isempty(whichd1h) || isnan(whichd1h) || tint==0
            continue
        else % writing in results structure
            h.sideh(i)=lrh;
            h.tinth(:,i)=[tsug_r;tint];
            h.kbih(:,i)=[kbi1h;kbi2h];
            h.d1h(i)=whichd1h;
            h.d2h(i)=whichd2h;
        end    
    end    
    

    %%% main task %%%
    erco=0;
    k=0;

    for j=fromBlockNum:p.nb
        
        onset_sestxt=t0;onset_tsktxt=t0;% initialize variables to default values
        
        if mod(j,p.nbps)==1
            newSesTxt=sprintf('Session %d',(j-1+p.nbps)/p.nbps);
            wip(20)=Screen(0,'OpenOffscreenWindow',p.gcl);  
            Screen(wip(20),'TextColor',p.instexlu*p.mgv*[1 1 1]);
            bourec=Screen('TextBounds', wip(20),newSesTxt);
            Screen(wip(20),'DrawText',newSesTxt,(p.scrsiz(3)-bourec(3))/2,.5*p.scrsiz(4));
            Screen(wip(1),'DrawTexture',wip(20)); [~,onset_sestxt]=Screen('Flip',wip(1));
            WaitSecs(8);
            Screen(wip(1),'DrawTexture',wip(5));Screen('Flip',wip(1));
            Screen('Close',wip(20));
            WaitSecs(2);
        else
            WaitSecs(2);
        end
            
        if mod(j,p.nk)==1 %mod=1:detection    (p.nk is 2 or 3) 
            Screen(wip(1),'DrawTexture',wip(15));onset_tsktxt=Screen('Flip',wip(1));
        else %if mod(j,p.nk)~=1 , mod=0or2:imagery
            Screen(wip(1),'DrawTexture',wip(16));onset_tsktxt=Screen('Flip',wip(1));
        end
        stlr=mod(randperm(p.ntpb),2);  % 0 left, 1 right
        % keypress by experimenter to continue
        [~,kc]=KbWait([],2);
        while ~kc(KbName(contkey))==1 
            [~,kc]=KbWait([],2); WaitSecs('YieldSecs',0.1);
        end
        
        % Wait for scanner trigger
        [~,trigger,KeyCodeT]=KbCheck;
        while KeyCodeT(KbName(trigkey))==0 
            [~,trigger,KeyCodeT]=KbCheck;
            WaitSecs(0.005);
        end
        
        Screen(wip(1),'DrawTexture',wip(5));Screen('Flip',wip(1));
	    WaitSecs(p.prebk);
    
        for i=1:p.ntpb
            % Interrupt by pressing before a trial starts
            if KbCheck && allowquit, [~,~,kc]=KbCheck; 
               if kc(KbName('F10'))==1, break; 
               elseif kc(KbName('F11'))==1, return; 
               end
            end
            
            % initialize variables to default values
            kbi1=KbName('9(');kbi2=KbName('9(');kbi3=KbName('9(');kbi4=KbName('9(');
            onset_fp=t0;onset_be=t0;onset_st=t0;offset_st=t0;
            onset_q1=t0;rt1=t0;onset_q2=t0;rt2=t0;onset_q3=t0;rt3=t0;onset_q4=t0;rt4=t0;        
            whichd1=9;whichd2=9;
            whichi0=9;whichi11=9;whichi12=9;whichi21=9;whichi22=9;whichi23=9;
            KeyCode1=zeros(1,256);KeyCode2=zeros(1,256);
            KeyCode3=zeros(1,256);KeyCode4=zeros(1,256);
            
            tsug=QuestQuantile(q);	     % recommended by Pelli (1987)
            % we can test any intensity, not necessarily Quest's suggestion
            tint=10^tsug;
            tint=min(p.lurgmax,max(0,tint)); %restrict range of contrasts 
            tint=round(tint*p.mgv)/p.mgv; %restrict grain of contrasts
            % issue warning if the display grayscale resolution is surpassed 3 times
            if tint < 1/p.mgv    
                erco=erco+1;
                tint=1/p.mgv; % avoid overflowing the pdf
                if erco > 2
                    warning('KuvikWarning:ExceededDeviceResolution',...
                        'Monitor grayscale resolution is too coarse.');
                end
            end
            tsug_r=log10(tint);
            % stimulus absent as control
            if trm_rps(j,i)==6
                tint=0;
            end
            
            % imperative imagery side choice and laterality of the actual stimulus
            if flshmd==1
                Screen(wip(1),'DrawTexture',wip(5));
                [~,onset_chlrtxt]=Screen('Flip',wip(1));
            elseif flshmd~=1
                if mod(j,p.nk)==1  % detection
                    Screen(wip(1),'DrawTexture',wip(12));
                    [~,onset_chlrtxt]=Screen('Flip',wip(1));
                    imlr=NaN;
                elseif mod(j,p.nk)==2  % imagery left
                    Screen(wip(1),'DrawTexture',wip(18));
                    [~,onset_chlrtxt]=Screen('Flip',wip(1));
                    imlr=0;
                elseif mod(j,p.nk)==0  % imagery right
                    Screen(wip(1),'DrawTexture',wip(19));
                    [~,onset_chlrtxt]=Screen('Flip',wip(1));
                    imlr=1;
                end
            end
            WaitSecs(p.lrdi);
                        
            %draw flash and noisebg in buffer, all parameters passed on the fly
            [I64,~,~,~,N64]=E5flash2(flshmd,p.bglu,tint,'FS',stlr(i),p.noam); 
            if viswon
                I=PsychVideoSwitcher('MapLuminanceToRGB',I64,p.btrr);
                N=PsychVideoSwitcher('MapLuminanceToRGB',I64,p.btrr);
            else
                I=uint8(I64*p.mgv);
                N=uint8(N64*p.mgv);
            end
            wip(4)=Screen(wip(1),'MakeTexture',I+N);
            Screen(wip(4),'TextColor',p.wflu*p.mgv*[1 1 1]);
            Screen(wip(4),'TextFont',p.fontname); Screen(wip(4),'TextSize',p.chsiz);
            DrawFormattedText(wip(4),instr{36},'center','center');
            % adding noise bg for static noise display mode(withDynNoise=0)
            wip(2)=Screen(wip(1),'MakeTexture',N);
            Screen(wip(2),'TextColor',p.wflu*p.mgv*[1 1 1]);
            Screen(wip(2),'TextFont',p.fontname); Screen(wip(2),'TextSize',p.chsiz);
            DrawFormattedText(wip(2),instr{36},'center','center');
                         
    %%% DESBICHE  optimal noam-lurgmax combination? q update correct?
    
    
            % presenting stimulus (or not)
            if trm_rps(j,i)==6
                cvi=p.csi(randi(5));  %cue-blank interval
            else
                cvi=p.csi(trm_rps(j,i)); %cue-flash interval
            end
            if ~withDynNoise
                Screen(wip(1),'DrawTexture',wip(2)); [~,onset_fp]=Screen('Flip',wip(1));
                WaitSecs(p.presti);
                PsychPortAudio('Start', PAhandle, 1, 0, 0);
                offset = 0;
                while offset == 0 % spin-wait until first sample is played
                    status = PsychPortAudio('GetStatus', PAhandle);
                    offset = status.PositionSecs;
                    if offset>0, break; end
                    WaitSecs('YieldSecs', 0.001);
                end
                onset_be = status.StartTime;
                PsychPortAudio('Stop', PAhandle, 1);
                %or Beeper(400,0.4,0.15); %sound(sbeep);  
                WaitSecs(cvi); 
                Screen(wip(1),'DrawTexture',wip(4)); [~,onset_st]=Screen('Flip',wip(1)); 
                % show stimulus until sdi elapses
                while (GetSecs-onset_st)<=p.sdi
                    % poll for a response: subjects can respond before stimulus terminates
                    if (KeyCode1(KbName(d1keys{1}))==1 || KeyCode1(KbName(d1keys{2}))==1)
                        break;
                    end
                    [~,rt1,KeyCode1]=KbCheck;
                    % Wait 1 ms before checking the keyboard again to prevent overload 
                    % of the machine at elevated Priority():
                    WaitSecs(0.001);
                end      %WaitSecs('UntilTime',onset_st+p.sdi);
                Screen(wip(1),'DrawTexture',wip(2)); [~,offset_st]=Screen('Flip',wip(1));
                Screen('Close',wip(2));
                WaitSecs(p.posti);
            elseif withDynNoise
                onset_be = GetSecs+p.presti; % inaccurate! too much hassle to write good code
                PsychPortAudio('Start', PAhandle, 1, onset_be,0);
                onset_fp=dynoiz(p.presti,wip(1),p,BM);
                dynoiz(p.presti+cvi-p.beepd,wip(1),p,BM); 
                % show stimulus until sdi elapses
                [onset_st,rt1,KeyCode1]=dynoiz(p.sdi,wip(1),p,I,KeyCode1,d1keys);
                offset_st=dynoiz(p.posti,wip(1),p,BM);
            end
          
            % recording subject feedback    
            if mod(j,p.nk)==1 %mod=1:detection
                % regardless of flshmd, here only detection is addressed
                
                % d1:detection question; loop until valid key is pressed or reswi terminates
                Screen(wip(1),'DrawTexture',wip(6)); [~,onset_q1]=Screen('Flip',wip(1));
                while (KeyCode1(KbName(d1keys{1}))==0 && KeyCode1(KbName(d1keys{2}))==0 ...
                        && KeyCode1(KbName(d1keys{3}))==0 && KeyCode1(KbName(d1keys{4}))==0 ...
                        && KeyCode1(KbName(d1keys{5}))==0) && (GetSecs-onset_q1)<=p.respwid1
                    [~,rt1,KeyCode1]=KbCheck;
                    WaitSecs(0.001);
                end
                if ~isempty(find(KeyCode1,1)) && length(find(KeyCode1))==1
                    kbi1=find(KeyCode1);
                    if flshmd==1
                        switch find(KeyCode1)
                            case KbName(d1keys{1}), whichd1=1;
                            case KbName(d1keys{2}), whichd1=0;
                            otherwise, whichd1=NaN;
                        end
                    elseif flshmd==2
                        switch find(KeyCode1)
                            case KbName(d1keys{3}), whichd1=1;
                            case KbName(d1keys{4}), whichd1=0;
                            case KbName(d1keys{5}), whichd1=2;
                            otherwise, whichd1=NaN;
                        end
                    end
                else
                    kbi1=NaN; 
                    whichd1=NaN;
                end
                KbReleaseWait; 

                % d2:CR question on detection
                Screen(wip(1),'DrawTexture',wip(7)); [~,onset_q2]=Screen('Flip',wip(1)); 
                while (KeyCode2(KbName(crkeys{1}))==0 && KeyCode2(KbName(crkeys{2}))==0 ...
                        && KeyCode2(KbName(crkeys{3}))==0 && KeyCode2(KbName(crkeys{4}))==0) ...
                        && (GetSecs-onset_q2)<=p.respwid2
                    [~,rt2,KeyCode2]=KbCheck;
                    WaitSecs(0.001);
                end
                if ~isempty(find(KeyCode2,1)) && length(find(KeyCode2))==1 
                    kbi2=find(KeyCode2);
                    switch find(KeyCode2)
                        case KbName(crkeys{1}), whichd2=1;
                        case KbName(crkeys{2}), whichd2=2;
                        case KbName(crkeys{3}), whichd2=3;
                        case KbName(crkeys{4}), whichd2=4;
                        otherwise, whichd2=NaN;
                    end
                else
                    kbi2=NaN; 
                    whichd2=NaN;
                end
                KbReleaseWait; 
            else %if mod(j,p.nk)~=1, imagery
                if flshmd==1
                    % i1: perception under imagery
                    Screen(wip(1),'DrawTexture',wip(8)); [~,onset_q1]=Screen('Flip',wip(1));
                    while (KeyCode1(KbName(ikeys{1}))==0 && ...
                            KeyCode1(KbName(ikeys{2}))==0) && (GetSecs-onset_q1)<=p.respwii0
                        [~,rt1,KeyCode1]=KbCheck;
                        WaitSecs(0.001);
                    end
                    if ~isempty(find(KeyCode1,1)) && length(find(KeyCode1))==1
                        kbi1=find(KeyCode1);
                        switch find(KeyCode1)
                            case KbName(ikeys{1}), whichi1=1;
                            case KbName(ikeys{2}), whichi1=2;
                            otherwise, whichi1=NaN;
                        end
                    else
                        kbi1=NaN; 
                        whichi1=NaN;
                    end
                    KbReleaseWait; 
                    
                    % i2: CR question
                    Screen(wip(1),'DrawTexture',wip(7)); [~,onset_q2]=Screen('Flip',wip(1)); 
                    while (KeyCode2(KbName(crkeys{1}))==0 && KeyCode2(KbName(crkeys{2}))==0 ...
                            && KeyCode2(KbName(crkeys{3}))==0 && KeyCode2(KbName(crkeys{4}))==0) ...
                            && (GetSecs-onset_q2)<=p.respwid2
                        [~,rt2,KeyCode2]=KbCheck;
                        WaitSecs(0.001);
                    end
                    if ~isempty(find(KeyCode2,1)) && length(find(KeyCode2))==1 
                        kbi2=find(KeyCode2);
                        switch find(KeyCode2)
                            case KbName(crkeys{1}), whichi2=1;
                            case KbName(crkeys{2}), whichi2=2;
                            case KbName(crkeys{3}), whichi2=3;
                            case KbName(crkeys{4}), whichi2=4;
                            otherwise, whichi2=NaN;
                        end
                    else
                        kbi2=NaN; 
                        whichi2=NaN;
                    end
                    KbReleaseWait; 
                    
                elseif flshmd~=1
                    % i1: perception under imagery
                    Screen(wip(1),'DrawTexture',wip(9)); [~,onset_q1]=Screen('Flip',wip(1));
                    while (KeyCode1(KbName(ikeys{4}))==0 && KeyCode1(KbName(ikeys{5}))==0 ...
                            && KeyCode1(KbName(ikeys{6}))==0) && (GetSecs-onset_q1)<=p.respwii0
                        [~,rt1,KeyCode1]=KbCheck;
                         WaitSecs(0.001);
                    end
                    if ~isempty(find(KeyCode1,1)) && length(find(KeyCode1))==1
                        kbi1=find(KeyCode1);
                        switch find(KeyCode1)
                            case KbName(ikeys{4}), whichi1=1;
                            case KbName(ikeys{5}), whichi1=2;
                            case KbName(ikeys{6}), whichi1=3;
                            otherwise, whichi1=NaN;
                        end
                    else   
                        kbi1=NaN; 
                        whichi1=NaN;
                    end
                    KbReleaseWait; 
                    
                    % i2: CR question
                    Screen(wip(1),'DrawTexture',wip(7)); [~,onset_q2]=Screen('Flip',wip(1)); 
                    while (KeyCode2(KbName(crkeys{1}))==0 && KeyCode2(KbName(crkeys{2}))==0 ...
                            && KeyCode2(KbName(crkeys{3}))==0 && KeyCode2(KbName(crkeys{4}))==0) ...
                            && (GetSecs-onset_q2)<=p.respwid2
                        [~,rt2,KeyCode2]=KbCheck;
                        WaitSecs(0.001);
                    end
                    if ~isempty(find(KeyCode2,1)) && length(find(KeyCode2))==1 
                        kbi2=find(KeyCode2);
                        switch find(KeyCode2)
                            case KbName(crkeys{1}), whichi2=1;
                            case KbName(crkeys{2}), whichi2=2;
                            case KbName(crkeys{3}), whichi2=3;
                            case KbName(crkeys{4}), whichi2=4;
                            otherwise, whichi2=NaN;
                        end
                    else
                        kbi2=NaN; 
                        whichi2=NaN;
                    end
                    KbReleaseWait;
                end
                
                % i3: if i1 suggests superposition for both flshmd 1 and 2
                if whichi1==2
                    % i3: synchrony level 
                    Screen(wip(1),'DrawTexture',wip(13)); [~,onset_q3]=Screen('Flip',wip(1)); 
                    while (KeyCode3(KbName(itkeys{1}))==0 && KeyCode3(KbName(itkeys{2}))==0 ...
                            && KeyCode3(KbName(itkeys{3}))==0) && (GetSecs-onset_q3)<=p.respwii22
                        [~,rt3,KeyCode3]=KbCheck;
                        WaitSecs(0.001);
                    end
                    if ~isempty(find(KeyCode3,1)) && length(find(KeyCode3))==1 
                        kbi3=find(KeyCode3);
                        switch find(KeyCode3)
                            case KbName(itkeys{1}), whichi3=1;
                            case KbName(itkeys{2}), whichi3=2;
                            case KbName(itkeys{3}), whichi3=3;
                            otherwise, whichi3=NaN;
                        end
                    else
                        kbi3=NaN; 
                        whichi3=NaN;
                    end
                    KbReleaseWait; 
                    
                    % i3: relative brightness  
                    Screen(wip(1),'DrawTexture',wip(17)); [~,onset_q4]=Screen('Flip',wip(1)); 
                    while (KeyCode4(KbName(ibkeys{1}))==0 && KeyCode4(KbName(ibkeys{2}))==0 ...
                            && KeyCode4(KbName(ibkeys{3}))==0) && (GetSecs-onset_q4)<=p.respwii23
                        [~,rt4,KeyCode4]=KbCheck;
                        WaitSecs(0.001);
                    end
                    if ~isempty(find(KeyCode4,1)) && length(find(KeyCode4))==1 
                        kbi4=find(KeyCode4);
                        switch find(KeyCode4)
                            case KbName(ibkeys{1}), whichi4=1;
                            case KbName(ibkeys{2}), whichi4=2;
                            case KbName(ibkeys{3}), whichi4=3;
                            otherwise, whichi4=NaN;
                        end
                    else
                        kbi4=NaN; 
                        whichi4=NaN;
                    end
                    KbReleaseWait; 
                end
                
            end
            
            % Wait end of trial
            Screen(wip(1),'DrawTexture',wip(5)); Screen('Flip',wip(1));
            WaitSecs(p.postr);
                    
            % logging into data arrays
            k=k+1;
            h.side(:,k)=[stlr(i); imlr];
            h.tint(k)=tint;
            h.csi(k)=cvi;
            h.kbi(:,k)=[kbi1;kbi2;kbi3;kbi4];
            if mod(j,p.nk)==1 %mod=1:detection
                h.d1(k)=whichd1;
                h.d2(k)=whichd2;
                h.i1(k)=NaN;
                h.i2(k)=NaN;
                h.i3(k)=NaN;
                h.i4(k)=NaN;
            else %mod(j,p.nk)~=1:imagery
                h.d1(k)=NaN;
                h.d2(k)=NaN;
                h.i1(k)=whichi1;
                h.i2(k)=whichi2;
                if whichi1==2
                    h.i3(k)=whichi3;
                    h.i4(k)=whichi4;
                else
                    h.i3(k)=NaN;
                    h.i4(k)=NaN;
                end
            end
            h.timelog(:,k)=[onset_sestxt-t0;onset_tsktxt-t0;trigger-t0;...
                onset_fp-t0;onset_be-t0;onset_st-t0;offset_st-t0;...
                onset_q1-t0;rt1-t0;onset_q2-t0;rt2-t0;onset_q3-t0;rt3-t0;...
                onset_q4-t0;rt4-t0];

            % update the pdf: add the new data(intensity and response)
            if tint~=0   % tint not zero
                if mod(j,p.nk)==1 && ~isnan(whichd1) % detection block
                    if flshmd==1
                        q=QuestUpdate(q,tsug_r,whichd1);
                    elseif flshmd~=1
                        q=QuestUpdate(q,tsug_r,istrue(whichd1==stlr(i)+1));
                    end
                elseif mod(j,p.nk)==2 && ~isnan(whichi1) % imagery left
                    if flshmd==1
                        q=QuestUpdate(q,tsug_r,whichi1==2);
                    elseif flshmd~=1
                        q=QuestUpdate(q,tsug_r, ...
                            istrue(whichi1==2&&stlr(i)==0 || whichi1==3&&stlr(i)==1));
                    end
                elseif mod(j,p.nk)==0 && ~isnan(whichi1) % imagery right
                    if flshmd==1
                        q=QuestUpdate(q,tsug_r,whichi1==2);
                    elseif flshmd~=1
                        q=QuestUpdate(q,tsug_r, ...
                            istrue(whichi1==2&&stlr(i)==1 || whichi1==3&&stlr(i)==0));
                    end
                end
            end
        end    
        
       % Save block data backup
       p.timeseg(j+1,:)=datevec(now);
       p.q=q;p.ppdfm=QuestMean(q); p.ppdfsd=QuestSd(q);  
       save(['ptbak' num2str(j) '-' num2str(p.nb) p.filename29],'p','h');
       
    end

    PsychPortAudio('Close');
    Screen('CloseAll');
    Screen('Preference','VisualDebugLevel',oldvdl);
    Screen('LoadNormalizedGammaTable',0,oldgt); % default: oldgt=(0:1/255:1)' 
    RestrictKeysForKbCheck([]);
    ShowCursor;
    Priority(0);
    
    % Ask Quest for the final estimate of threshold
    p.ppdfm=QuestMean(q); % Recommended by Pelli(1989) and King-Smith etal.(1994)
    p.ppdfsd=QuestSd(q);

    % Save data
    if flshmd==1, h=rmfield(h,{'side', 'sideh'}); end
    save(p.filename30,'p','h')
       
catch ME
    
    PsychPortAudio('Close');
    Screen('CloseAll');
    Screen('Preference','VisualDebugLevel',oldvdl);
    Screen('LoadNormalizedGammaTable',0,oldgt); % default: oldgt=(0:1/255:1)' 
    RestrictKeysForKbCheck([]);
    ShowCursor;
    Priority(0);
    
    p,keyboard
    rethrow(ME);
end % try ... catch %


%{
% Deprecated code
    % one stimulus seen(i1)
    if whichi0==1
        % i11: CR
        Screen(wip(1),'DrawTexture',wip(9)); [~,onset_q2]=Screen('Flip',wip(1)); 
        while (KeyCode2(KbName('1!'))==0 && KeyCode2(KbName('2@'))==0 ...
                && KeyCode2(KbName('3#'))==0 && KeyCode2(KbName('4$'))==0) ...
                && (GetSecs-onset_q2)<=p.respwii11
            [~,rt2,KeyCode2]=KbCheck;
            WaitSecs(0.001);
        end
        if ~isempty(find(KeyCode2,1)) && length(find(KeyCode2))==1 
            kbi2=find(KeyCode2);
            switch find(KeyCode2)
                case KbName('1!'), whichi11=1;
                case KbName('2@'), whichi11=2;
                case KbName('3#'), whichi11=3;
                case KbName('4$'), whichi11=4;
                otherwise, whichi11=NaN;
            end
        else
            kbi2=NaN; 
            whichi11=NaN;
        end
        KbReleaseWait; 
        % i12: agency rating
        Screen(wip(1),'DrawTexture',wip(11)); [~,onset_q3]=Screen('Flip',wip(1)); 
        while (KeyCode3(KbName('1!'))==0 && KeyCode3(KbName('2@'))==0 ...
                && KeyCode3(KbName('3#'))==0 && KeyCode3(KbName('4$'))==0) ...
                && (GetSecs-onset_q3)<=p.respwii12
            [~,rt3,KeyCode3]=KbCheck;
            WaitSecs(0.001);
        end
        if ~isempty(find(KeyCode3,1)) && length(find(KeyCode3))==1 
            kbi3=find(KeyCode3);
            switch find(KeyCode3)
                case KbName('1!'), whichi12=1;
                case KbName('2@'), whichi12=2;
                case KbName('3#'), whichi12=3;
                case KbName('4$'), whichi12=4;
                otherwise, whichi12=NaN;
            end
        else
            kbi3=NaN; 
            whichi12=NaN;
        end
        KbReleaseWait; 
    end
%}
