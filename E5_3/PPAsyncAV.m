%
screenid = max(Screen('Screens'));
win = Screen('OpenWindow', screenid, 0);
ifi=Screen('GetFlipInterval',win);
%}
    
InitializePsychSound %(1) if reallyneedlowlatency

%if ~IsLinux, PsychPortAudio('Verbosity', 10); end 

% Force GetSecs and WaitSecs into memory to avoid latency later on:
GetSecs; WaitSecs(0.1);

% If 'exactstart' wasn't provided, assume user wants to test exact sync of
% audio and video onset, instead of testing total onset latency:
exactstart = [];
if isempty(exactstart), exactstart = 1; end
if exactstart
    fprintf('Will test accuracy of scheduled sound onset, i.e. how well the driver manages to\n');
    fprintf('emit sound at exactly the specified "when" deadline. Sound should start in exact\n');
    fprintf('sync with display black-white transition (or at least very close - < 1 msec off).\n');
    fprintf('The remaining bias can be corrected by providing the bias as "latbias" parameter\n');
    fprintf('to this script. Variance of sound onset between trials should be very low, much\n');
    fprintf('smaller than 1 millisecond on a well working system.\n\n');
else
    fprintf('Will test total latency for immediate start of sound playback, i.e., the "when"\n');
    fprintf('parameter is set to zero. The difference between display black-white transition\n');
    fprintf('and start of emitted sound will be the total system latency.\n\n');
end

% Default to auto-selected default output device if none specified:
deviceid = [];
if isempty(deviceid), deviceid = -1; end
if deviceid == -1
    fprintf('Will use auto-selected default output device. This is the system default output\n');
    fprintf('device in "normal" (=reliable but high latency) mode. In low-latency mode its the\n');
    fprintf('device with the lowest inherent latency on your system (as determined by some internal\n');
    fprintf('heuristic). If you are not satisfied with the results you may query the available devices\n');
    fprintf('yourself via a call to devs = PsychPortAudio(''GetDevices''); and provide the device index\n');
    fprintf('of a suitable device\n\n');
else
    fprintf('Selected the following output device (deviceid=%i) according to your spec:\n', deviceid);
    devs = PsychPortAudio('GetDevices');
    for idx = 1:length(devs)
        if devs(idx).DeviceIndex == deviceid
            break;
        end
    end
    disp(devs(idx));
end

% Request latency mode 2, which used to be the best one in our measurement:
% classes 3 and 4 didn't yield any improvements, sometimes they even caused
% problems.
reqlatencyclass = 2;

% Requested output frequency, may need adaptation on some audio-hw:
 %'freq' Requested playback/capture rate in samples per second (Hz). 
 % Defaults to a value that depends on the requested latency mode.
freq = 44100;   % Must set this. 96khz, 48khz, 44.1khz.
 %'buffersize' requested size and number of internal audio buffers, smaller
 % numbers mean lower latency but higher system load and some risk of 
 % overloading, which would cause audio dropouts. 
buffersize = 0;     % Pointless to set this. Auto-selected to be optimal.
 %'suggestedLatency' optional requested latency in s. PortAudio selects 
 % internal operating parameters depending on sampleRate, suggestedLatency 
 % and buffersize as well as device internal properties to optimize for low 
 % latency output. Best left alone, only here as manual override in case 
 % all the auto-tuning cleverness fails.
suggestedLatencySecs = [];
if IsWin
    % Hack to accomodate bad Windows systems or sound cards. By default,
    % the more aggressive default setting of something like 5 msecs can
    % cause sound artifacts on cheaper / less pro sound cards:
    suggestedLatencySecs = 0.015 %#ok<NOPRT>
    fprintf('Choosing a high suggestedLatencySecs setting of 15ms to account for shoddy Windows OS.\n');
    fprintf('For low-latency applications, you may want to tweak this to lower values if your system works better than average timing-wise.\n');
end

% latbias needs to be determined via measurement once for each piece of 
% audio hardware:
latbias = [];
if isempty(latbias)
    % Unknown system: Assume zero bias. User can override with measured
    % values:
    fprintf('No "latbias" provided. Assuming zero bias. You''ll need to determine this via measurement for best results...\n');
    latbias = 0;
end


%%% Open audio device for low-latency output:
pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, 2, buffersize, suggestedLatencySecs);

% Tell driver about hw inherent latency, determined via calibration once:
prelat = PsychPortAudio('LatencyBias', pahandle, latbias); %#ok<NOPRT,NASGU>
postlat = PsychPortAudio('LatencyBias', pahandle); %#ok<NOPRT,NASGU>

% Generate some beep sound 1000 Hz, 0.1 secs, 50% amplitude:
mynoise(1,:) = 0.5 * MakeBeep(1000, 0.1, freq);
mynoise(2,:) = mynoise(1,:);

% Fill buffer with data:
PsychPortAudio('FillBuffer', pahandle, mynoise);
 
% Set waitframes to a good default, if none is provided by user:
waitframes = []; 
if isempty(waitframes)
    % We try to choose a waitframes that maximizes the chance of hitting
    % the onset deadline. We are conservative in our estimate, because a
    % few video refresh cycles hardly matter for this test, but increase
    % our chance of success without need for manual tuning by user:
    if isempty(suggestedLatencySecs)
        % Let's assume 12 ms on Linux and OSX as a achievable latency by
        % default, then double it:
        waitframes = ceil((2 * 0.012) / ifi) + 1;        
    else
        % Whatever was provided, then double it:
        waitframes = ceil((2 * suggestedLatencySecs) / ifi) + 1;
    end
end
fprintf('\n\nWaiting %i video refresh cycles before white-flash.\n', waitframes);

% Perform one warmup trial, to get the sound hardware fully up and running,
% performing whatever lazy initialization only happens at real first use.
% This "useless" warmup will allow for lower latency for start of playback
% during actual use of the audio driver in the real trials:
PsychPortAudio('Start', pahandle, 1, 0, 1);
PsychPortAudio('Stop', pahandle, 1);

% Ok, now the audio hardware is fully initialized and our driver is on
% hot-standby, ready to start playback of any sound with minimal latency.

% Wait for keypress.
KbStrokeWait;


% Realtime scheduling: Can be used if otherwise timing is not good enough.
% Priority(MaxPriority(wip(1)));

% This flip clears the display to black and returns timestamp of black onset:
[vbl1 visonset1 FlipTimestamp Missed Beampos]=Screen('Flip',win);

% Prepare black-white transition:
Screen('FillRect', win, 255);
Screen('DrawingFinished', win);
if exactstart
    % Schedule start of audio at exactly the predicted visual stimulus
    % onset caused by the next flip command.
    PsychPortAudio('Start', pahandle, 1, visonset1 + waitframes * ifi, 0);
end

% Ok, the next flip will do a black-white transition...
[vbl visual_onset t1] = Screen('Flip', win, vbl1 + (waitframes-0.5) * ifi);
if ~exactstart
    % No test of scheduling, but of absolute latency: Start audio
    % playback immediately:
    PsychPortAudio('Start', pahandle, 1, 0, 0);
end
t2 = GetSecs;

% Spin-Wait until hw reports the first sample is played...
offset = 0;
while offset == 0
    status = PsychPortAudio('GetStatus', pahandle);
    offset = status.PositionSecs;
    t3=GetSecs;
    %PredictedLatency: Is the latency in s of your driver+hardware combo. 
    % It tells you, how far ahead of time a sound device must be started 
    % ahead of the requested onset time via PsychPortAudio('Start'...) 
    % to make sure it actually starts playing in time. High quality systems 
    % like Linux or MacOS/X may allow values as low as 5 ms or less on 
    % standard hardware. Other OSs may require dozens or hundreds of ms of 
    % headstart. Caution: In full-duplex mode, this value only refers to 
    % the latency on the sound output, not in the sound input! Also, this 
    % is just an estimate, not 100% reliable.
    plat = status.PredictedLatency;
    fprintf('Predicted Latency: %6.6f ms.\n', plat*1000);
    if offset>0
        break; 
    end
    WaitSecs('YieldSecs', 0.001);
end
audio_onset = status.StartTime;
fprintf('Expected visual onset at %6.6f s.\n', visual_onset-visual_onset);
fprintf('Sound started between %6.6f and  %6.6f\n', t1-visual_onset, t2-visual_onset);
fprintf('Expected latency sound - visual = %6.6f\n', t2 - visual_onset);%
fprintf('First sound buffer played at %6.6f\n', t3-visual_onset);
fprintf('Flip delay = %6.6f s.  Flipend vs. VBL %6.6f\n', vbl - vbl1, t1-vbl);
fprintf('Delay start vs. played: %6.6f s, offset %f\n', t3 - t2, offset);
fprintf('Buffersize %i, xruns = %i, playpos = %6.6f s.\n', status.BufferSize, status.XRuns, status.PositionSecs);
fprintf('Screen    expects visual onset at %6.6f s.\n', visual_onset-visual_onset);
fprintf('PortAudio expects audio onset  at %6.6f s.\n', audio_onset-visual_onset);
fprintf('Expected audio-visual delay    is %6.6f ms.\n', (audio_onset - visual_onset)*1000.0);
 
% Stop playback:
PsychPortAudio('Stop', pahandle, 1);

% Wait a bit...
WaitSecs(0.3);
Screen('FillRect', win, 0);
telapsed = Screen('Flip', win) - visual_onset; %#ok<NASGU>
WaitSecs(0.6);


% Done, close driver and display:
Priority(0);
PsychPortAudio('Close');
Screen('CloseAll');

