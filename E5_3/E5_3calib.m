function logludt=E5_3calib(flshmd,withDynNoise,pThreshold,lang,nt)
% E5_3: calibration task
% Methods: Adaptive Bayesian method to adjust performance at 75% of correct
%          4-point scales will be used for subjective reports
% Number of trials
% ni * nr = nt
% 10 * 10 = 100
% Luminance detection threshold x CSI detection threshold
% 50%: no stimulus 
% 50%: each of the 5 csi

KbName('UnifyKeyNames');
qu1keys{1}='1'; % Y left for flshmd=2, Y for flshmd=1
qu1keys{2}='2'; % N 
qu1keys{3}='3'; % Y right for flshmd=2
contkey='c';  % press this to continue
RestrictKeysForKbCheck([KbName(qu1keys{1}) KbName(qu1keys{2}) ...
    KbName(qu1keys{3}) KbName(contkey)]); %or StuckKeysDisabler
oldVDL=Screen('Preference','VisualDebugLevel',1);
show_res=0;
LoadGammaTable='';  % '', 'Acer715', 'TamagawaMonitor', not too necessary
debugmode=2;

viswon=0;
if viswon % 14-bit high luminance resolution mode with VideoSwitcher
    PsychVideoSwitcher('SwitchMode',0,viswon,0); 
end


%%%%%%%%%%%%%%%%%
% initialization
%%%%%%%%%%%%%%%%%

% Defining paremeters: layout
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
p.noam=0.35;     % gaussian noise sd: pdf clamped if noam>1/3
p.noamcl=p.noam*p.mgv; 
% Empty matrix 
BM64=p.bglu*ones(p.scrsiz(4),p.scrsiz(3));    
if viswon, BM=PsychVideoSwitcher('MapLuminanceToRGB',BM64,p.btrr);
else BM=uint8(BM64*p.mgv); end
% Defining paremeters: sound
p.ppa.deviceid=-1; p.ppa.reqlatencyclass=2; p.ppa.freq=44100;
p.ppa.buffersize=0; p.ppa.suggestedLatencySecs=[]; p.ppa.latbias=0;
p.beepv=0.5; p.beepf=400; p.beepd=0.1; 
p.beep(1,:)=0.5*MakeBeep(400,0.15,p.ppa.freq);% Generate some beep sound
p.beep(2,:)=p.beep(1,:); 
%p.sbeep=sin(1:0.5:100);
% Defining paremeters: trial sequence
p.nt=nt;               % total number of trials
p.nqd=1;                  % number of questions per trial in detection task   
p.prebk=4;           % first waiting interval
p.lrdi=0.5;  % arrow indicating side disp interval
p.presti=2;  % interval for getting prepared to imagine or detect          
p.presi0=1;             % prestimulus fixed interval
p.csi_grain=0.1;       % better to not use different csis in calibration
p.csi=p.presi0+p.csi_grain*[-2 -1 0 1 2];         % varying CSI                 
p.sdi=0.2;                   % stimulus display time in ms 
p.ni=length(p.csi);               % number of different intervals
p.posti=0.5;                     % poststimulus interval
p.postr=1;                   % trial end interval
p.iti=p.presti+p.postr;       % ITI
p.respwi=5;                   % response window
%ITI=csi+sdi+posti+respwi=100:500+100+200+5000=5400:800


% Definition of PF intensity: lwc=logb(talu,10)
% logarithm of Weber contrast of peak amplitude 
p.stluGuess=0.01; % log10(0.01)=-2

% Provide our prior knowledge to QuestCreate, and receive the data struct q
tGuess=log10(p.stluGuess);   
tGuessSd=2;
%pThreshold=0.75;        % threshold criterion expressed as P(response)==1           
beta=3.5;delta=0.01;
gamma=0.25; % because it is a 4AFC task, gamma=0.25 (assuming a perceptual(vs subjective awareness) task)
grain=0.01;range=6;                % intensity as logarithm of contrast
p.lurgmax=1-p.bglu;
p.brlosd=0.05;
q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range);
q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials

% Pseudorandom sequence of p.nt trials with varying csi
rpseq=randperm(p.nt);
%if p.nt < 20, rpseq=randperm(p.nt*3); end % just in case use triple of nt
csi_rpseq=mod(rpseq,p.ni)+1;


% Image sequence presentation and control flow statements

% Instructions text
if strcmp(lang,'EN')
    instr{1}='Calibration task';
    instr{2}=' ';
    instr{3}='Please look always at the fixation cross in the center of the screen.';
    if flshmd==1
        instr{4}='A fixed time interval after a beep sound, a flashing stimulus will be presented at the center of the screen in some trials.';
    elseif flshmd==2
        instr{4}='A fixed time interval after a beep sound, a flashing stimulus will be presented at one side of the screen in some trials.';
    end
    instr{5}='By selecting the corresponding keys, when it corresponds, you will have to report:';
    instr{6}='Detection';
    if flshmd==1
        instr{7}='R1: seen   R2: not seen';
    elseif flshmd~=1
        instr{7}='R1: seen left   R2: not seen   R3: seen right';
    end
    instr{8}='IMPORTANT: answer as fast as possible, but give priority to response accuracy';
    instr{9}='Wait for a sign to continue';
    if flshmd==1
        instr{10}='Detection\nR1: seen   R2: not seen';
    elseif flshmd~=1
        instr{10}='Detection\nR1: seen left   R2: not seen   R3: seen right';
    end
    instr{11}='+';
    instr{12}=hex2dec('2194');
    switch OSName
        case 'Linux', p.fontname='-misc-fixed-medium-r-normal--18-120-100-100-c-90-iso8859-15';
        case 'Windows', p.fontname='Courier New';
        otherwise, p.fontname='Helvetica';
    end
elseif strcmp(lang,'JP')
    instr{1}=' ';
    instr=cellfun(@double,instr,'uniformOutput',false);
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
p.monsiz=Tamagawa_fMRI.display_size;  %mm % should be like p.dispsiz 
p.vdist=Tamagawa_fMRI.visual_distance; %mm
[p.visang, p.pixperdeg, p.degperpix]=VisAng(p);
p.scrnum=Screen('Screens'); % 0 is the main screen
oldGT=Screen('ReadNormalizedGammaTable',0);
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
    case 2, PsychDebugWindowConfiguration([],.9), winsiz=[];
end

try
    % initialize KbCheck and variables to make sure they are properly 
    % allocated by Matlab - this to avoid time delays in the critical 
    % reaction time measurement part of the script
    [KeyIsDown,rt1,KeyCode1]=KbCheck;
    
    %%% Initialize audio device %%%
    InitializePsychSound;
    PAhandle=PsychPortAudio('Open',-1,[],2,44100,2,0);
    PsychPortAudio('FillBuffer', PAhandle, p.beep); % Fill buffer with data
        
    %%% Initializing data structures %%%
    wip=zeros(1,6);
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
    p.filename=['E5_3calib_',dateISO8601];
    h.csi=[];
    h.tint=[];
    h.side=[];
    h.kbi=[];
    h.det=[];
    h.timelog=[];
    h.trigger=[];

    %%% Stacking frames in buffers %%%
    wip(7)=Screen(0,'OpenOffscreenWindow',p.gcl);
    Screen(wip(7),'TextColor',p.instexlu*p.mgv*[1 1 1]);
    Screen(wip(7),'TextSize',36); bourec=Screen('TextBounds', wip(7),instr{1});
    Screen(wip(7),'DrawText',instr{1},(p.scrsiz(3)-bourec(3))/2,.1*p.scrsiz(4));
    Screen(wip(7),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(7),instr{2});
    Screen(wip(7),'DrawText',instr{2},(p.scrsiz(3)-bourec(3))/2,.2*p.scrsiz(4));
    bourec= Screen('TextBounds', wip(7),instr{3});
    Screen(wip(7),'DrawText',instr{3},(p.scrsiz(3)-bourec(3))/2,.25*p.scrsiz(4));
    bourec= Screen('TextBounds', wip(7),instr{4});
    Screen(wip(7),'DrawText',instr{4},(p.scrsiz(3)-bourec(3))/2,.35*p.scrsiz(4));
    bourec= Screen('TextBounds', wip(7),instr{5});
    Screen(wip(7),'DrawText',instr{5},(p.scrsiz(3)-bourec(3))/2,.45*p.scrsiz(4));
    Screen(wip(7),'TextSize',20); bourec=Screen('TextBounds', wip(7),instr{6});
    Screen(wip(7),'DrawText',instr{6},(p.scrsiz(3)-bourec(3))/2,.55*p.scrsiz(4));
    Screen(wip(7),'TextSize',p.fontsize); bourec=Screen('TextBounds', wip(7),instr{7});
    Screen(wip(7),'DrawText',instr{7},(p.scrsiz(3)-bourec(3))/2,.6*p.scrsiz(4));
    Screen(wip(7),'TextSize',20); bourec=Screen('TextBounds', wip(7),instr{8});
    Screen(wip(7),'DrawText',instr{8},(p.scrsiz(3)-bourec(3))/2,.75*p.scrsiz(4));
    bourec= Screen('TextBounds', wip(7),instr{9});
    Screen(wip(7),'DrawText',instr{9},(p.scrsiz(3)-bourec(3))/2,.9*p.scrsiz(4));

    wip(3)=Screen(0,'OpenOffscreenWindow',p.gcl); % fixation cross
    Screen(wip(3),'TextColor',p.wflu*p.mgv*[1 1 1]);
    Screen(wip(3),'TextSize',p.chsiz);
    DrawFormattedText(wip(3),instr{11},'center','center');
        
    wip(5)=Screen(0,'OpenOffscreenWindow',p.gcl); % ITI dim fixation cross
    Screen(wip(5),'TextColor',p.gflu*p.mgv*[1 1 1]);
    Screen(wip(5),'TextSize',p.chsiz);
    DrawFormattedText(wip(5),instr{11},'center','center');
    
    wip(6)=Screen(0,'OpenOffscreenWindow',p.gcl); % response prompt
    Screen(wip(6),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    DrawFormattedText(wip(6),instr{10},'center','center');
        
    % either side prompt (detection)
    wip(8)=Screen(0,'OpenOffscreenWindow',p.gcl);  
    Screen(wip(8),'TextColor',p.reptexlu*p.mgv*[1 1 1]);
    Screen(wip(8),'TextSize',p.chsiz);
    DrawFormattedText(wip(8),instr{12},'center','center');
    

%%%%%%%%%%%%%%%%%
% task
%%%%%%%%%%%%%%%%%

    HideCursor;
    p.PriLev=MaxPriority(wip(1));
    Priority(p.PriLev);
    
    t0=GetSecs; 
    erco=0;
    vatr=0;
    i=1;
    
    Screen(wip(1),'DrawTexture',wip(7)); 
    [~, tt]=Screen('Flip',wip(1));
    % keypress by experimenter to continue
    [~,kc]=KbWait([],2);
    while ~kc(KbName(contkey))==1 
        [~,kc]=KbWait([],2); WaitSecs('YieldSecs',0.005);
    end

    Screen(wip(1),'DrawTexture',wip(5));Screen('Flip',wip(1));
	WaitSecs(p.prebk);
               
    while i <= length(csi_rpseq) && (vatr < p.nt || QuestSd(q) > p.brlosd)
        % Interleave half of trials with no stimulus, lest the subject 
        % assigns high probability to stimulus presence in the main task
        if rand > 0.7  % stiabs=round(rand);
            stiabs=1;
        else
            stiabs=0;
        end
        lr=round(rand); % 0 left, 1 right
    
        tsug=QuestQuantile(q);	% Recommended by Pelli (1987)
    
        %we are free to test any intensity we like, not necessarily what Quest suggested
        tint=10^tsug;
        tint=min(p.lurgmax,max(0,tint)); %restrict to range of contrasts that our equipment can produce
        tint=round(tint*p.mgv)/p.mgv; %restrict grain of contrasts
        % issue error if the display grayscale resolution is surpassed 3 times
        if tint < 1/p.mgv    
            erco=erco+1;
            tint=1/p.mgv; % avoid overflowing the pdf
            if erco > 2
                error('KuvikException:ExceededDeviceResolution',...
                    'Monitor grayscale resolution is too coarse. Calibration aborted');
            end
        end
        tsug_r=log10(tint);
        % stimulus absent as control
        if stiabs
            tint=0;
        end
        
        % bilateral attention prompt
        if flshmd==1
            Screen(wip(1),'DrawTexture',wip(5)); 
        elseif flshmd~=1
            Screen(wip(1),'DrawTexture',wip(8)); 
        end
        Screen('Flip',wip(1)); WaitSecs(p.lrdi);
                
        %draw flash and noisebg in buffer, all parameters passed on the fly
        [I64,~,~,~,N64]=E5flash2(flshmd,p.bglu,tint,p.bgsiz,lr,p.noam); 
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
        DrawFormattedText(wip(4),instr{11},'center','center');
        % adding noise bg for static noise display mode(withDynNoise=0)
        wip(2)=Screen(wip(1),'MakeTexture',N);
        Screen(wip(2),'TextColor',p.wflu*p.mgv*[1 1 1]);
        Screen(wip(2),'TextFont',p.fontname); Screen(wip(2),'TextSize',p.chsiz);
        DrawFormattedText(wip(2),instr{11},'center','center');
        
        % Presenting stimulus (or not)
        if ~withDynNoise  % flash in blank bg (add noise also in prepost wip3?)
            Screen(wip(1),'DrawTexture',wip(2)); 
            [~,onset_fp]=Screen('Flip',wip(1)); % remove reponse mapping, show fp
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
            WaitSecs(p.csi(csi_rpseq(i)));
            Screen(wip(1),'DrawTexture',wip(4)); [~,onset_st]=Screen('Flip',wip(1));
            WaitSecs(p.sdi);
            Screen(wip(1),'DrawTexture',wip(2)); [~,offset_st]=Screen('Flip',wip(1));
            Screen('Close',wip(2));
            WaitSecs(p.posti);
        elseif withDynNoise    % flash in dynamic noise bg
            onset_be = GetSecs+p.presti; % inaccurate! too much hassle to write good code
            PsychPortAudio('Start', PAhandle, 1, onset_be,0);
            onset_fp=dynoiz(p.presti,wip(1),p,BM);
            %or Beeper(400,0.4,0.15); %sound(sbeep); 
            dynoiz(p.presti+p.csi(csi_rpseq(i))-p.beepd,wip(1),p,BM);
            onset_st=dynoiz(p.sdi,wip(1),p,I);
            offset_st=dynoiz(p.posti,wip(1),p,BM);
        end

        % recording subject feedback                
        Screen(wip(1),'DrawTexture',wip(6)); % show response mapping
        [~, onset_qu]=Screen('Flip',wip(1));
        [rt,KeyCode]=KbWait([],2,p.respwi+onset_qu);
        if ~isempty(find(KeyCode,1)) && length(find(KeyCode))==1
            kbi=find(KeyCode);
            if find(KeyCode)==KbName(qu1keys{1})
                whichdet=1;
            elseif find(KeyCode)==KbName(qu1keys{2})
                whichdet=0;
            elseif find(KeyCode)==KbName(qu1keys{3})
                whichdet=2;
            else
                whichdet=NaN;
            end
        else       
            kbi=NaN;
            whichdet=NaN;
        end
        KbReleaseWait; 
        
        % Wait end of trial
        Screen(wip(1),'DrawTexture',wip(5)); Screen('Flip',wip(1));
        WaitSecs(p.postr);
        
        h.timelog(:,i)=[tt-t0;t0-t0;onset_fp-t0;onset_be-t0;onset_st-t0;...
            offset_st-t0;onset_qu-t0;rt-t0];
                    
        if isempty(whichdet) || isnan(whichdet) || stiabs
            continue
        else % update the pdf and trial structures
            % Add the new datum (test intensity, observer response) to database
            if flshmd==1
                q=QuestUpdate(q,tsug_r,whichdet);
            elseif flshmd~=1
                q=QuestUpdate(q,tsug_r,istrue(whichdet==lr+1)); 
            end
            % writing in results structure
            h.side=[h.side lr];
            h.tint=[h.tint [tsug;tsug_r;tint]];
            h.csi=[h.csi p.csi(csi_rpseq(i))];
            h.kbi=[h.kbi kbi];
            h.det=[h.det whichdet];
            whichdet=[];
            vatr=vatr+1;
        end    
        i=i+1;
    end
    
    PsychPortAudio('Close');
    Screen('CloseAll');
    Screen('Preference','VisualDebugLevel',oldVDL);
    Screen('LoadNormalizedGammaTable',0,oldGT); % default: oldGT=(0:1/255:1)' 
    RestrictKeysForKbCheck([]);
    ShowCursor;
    Priority(0);

    % Ask Quest for the final estimate of threshold
    logludt=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
    loglusd=QuestSd(q);
    
    % Save data
    p.logludt=logludt;p.loglusd=loglusd;
    save(p.filename,'p','h','q')

    if show_res        
        % Printing results
        fprintf('The threshold estimate in log10 of contrast (mean+-sd) is %.2f +- %.2f',logludt1,loglusd1);
        dethrc=100*10^logludt1;
        sdleftc=100*(10^(logludt1)-10^(logludt1-loglusd1)); 
        sdrightc=100*(10^(logludt1+loglusd1)-10^(logludt1));  
        fprintf(1,'in %%contrast (mean+[-leftsd,+rightsd) %.2f+[-%.2f,+%.2f]\n',dethrc,sdleftc,sdrightc);
        dethrg=dethrc/100;
        sdleftg=sdleftc/100; 
        sdrightg=sdrightc/100;  
        fprintf('in target amplitude %d-bit gun value scale (mean+[-leftsd,+rightsd) %.2f+[-%.2f\n,+%.2f]\n',gsb,dethrg,sdleftg,sdrightg);

        % Plotting results
        %sorted list of intensities and response frequencies. t=QuestTrials(q,0.1)
        t=QuestTrials(q); 
        fprintf(' intensity     p fit         p    trials\n');
        disp([t.intensity; QuestP(q,t.intensity-logludt1);(t.responses(2,:)./sum(t.responses)); sum(t.responses)]');

        % (possibly unnormalized) probability density of candidate thresholds
        x=logb(1/128,10):grain:logb(1,10);
        figure, plot(x,QuestPdf(q,x)), title('(possibly unnormalized) pdf of candidate thresholds')  

        % psychometric function: PF=QuestP(q,x) 
        % probability of a correct (or yes) response at intensity x, assuming threshold is at x=0
        x=-1:0.01:1;
        figure, plot(x,QuestP(q,x)),title(sprintf('PF at intensity x, assuming x=0 is at threshold=%.2f',logludt1))
    end
    
catch ME
    
    PsychPortAudio('Close');
    Screen('CloseAll');
    Screen('Preference','VisualDebugLevel',oldVDL);
    Screen('LoadNormalizedGammaTable',0,oldGT);%default: oldGT=(0:1/255:1)' 
    RestrictKeysForKbCheck([]);
    ShowCursor;
    Priority(0);

    keyboard
    rethrow(ME);
end % try ... catch %