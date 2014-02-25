% E5.3: Peception-Imagery Interaction
%
% For subjects: CSI is always the same


% Preexperimental tests, calibrations and configuration

% Screen.mex
ScreentTest

% Sound
% help InitializePsychSound; BasicSoundOutputDemo; PsychPortAudioTimingTest

% Stimulus
% ContrastModulatedNoiseTheClumsyStyleDemo or ElegantStyleDemo
% AlphaImageDemo



%% E5.3calib 

clear all
flshmd=2;
withDynNoise=1;
pThreshold=0.75;
lang='EN';

% in dark room with subject beforehand, only calibration, not too necessary
ntcal=2;
logludt=E5_3calib(flshmd,withDynNoise,pThreshold,lang,ntcal);


%% E5.3main

clear all
flshmd=2;
withDynNoise=0;

pThreshold=0.75;
logludt=-2; %-2;
lang='EN';
trigkey='t';   

% in Tamagawa
isMain=0;      %<--- choose training or main
% 0: training out of the scanner: nb in [3,4,5,6]
% 1: main in the scanner nb=30 for flshmd=2, nb=20 for flshmd=1  
resume.ing=0; LastDoneBlock=1; %<--- if resuming
if resume.ing && isMain
    resume.from=LastDoneBlock+1;
end
E5_3main(flshmd,withDynNoise,pThreshold,lang,trigkey,logludt,isMain,resume)


%% Some notes
%{
Introduction:
Did you see or imagine that? When the stimulus is periliminal, it is 
    difficult to know whether you saw, imagined, or inferred the object.
This could be a demonstration of how percepts are completed with top-down 
    candidates, i.e., with expectations and memories. For example, when the
    sdi is too small, sometimes you must infer which stimulus you saw. In 
    this case, could we say that you imagined the stimulus? 
This study addresses the question of how does willfull effort to imagine a
    stimulus influence the perception and confidence on this perception
    of a periliminal target. 
Imagery, perception, confidence, and even agency maybe get entangled for
    different asynchronies, there may be different agency levels. We should
    ask the subjects whether they successfully overimposed the target and 
    the mental image, and then ask whether they feel it was them or the 
    machine who made stronger stimulus.

Doubts:
Is forcing the chosen side unnecessary? probably yes, becasue this 
    experiment aims at agency of imagery or at perception under imagery 
    topics, and not at the role of spatial uncertainty. spatial uncertainty 
    would help here to dissociate between perception and perception under 
    imagery. use different quest's q: dq and iq? are the conditions 
    compared based on the stimulus luminance or on the performance? on the 
    performance, i think. so two qs should be used. but probably they are 
    very similar. 


Prescribed task strategy: 
CSI is always the same, but targets do not appear sometimes.
T1) Detection: was there a stimulus?
T2) Imagery: imagine a target at the same timing as the screen target, i.e., 
    try to make them coincide. 

Subjects:
Normal or patients (like schizophrenic) or drugged (LSD?)

Stimulus:
The stimulus should be simple and small, as similar as possible to the kind
    of object we can image easily, like a small brief flash. Probably it is
    better to use a gray background to make the target less visible. 
Noise amplitude cannot vary because this is not only a detection task, but 
    also an imagery task. If the videoswitcher is not powerful enough, use 
    dynamic noise.
1:loglucldt1
2:loglucldt2

Timing:
The CSI between cue and stimulus will be fixed so that the subject knows 
    when to expect the stimulus. Cue with beep.
SDI = 0.5s? 0.2s? 
CSI grain = SDI/2 ?
Because the mean value for the csi vector is presi0, this will be the 
reference or control.


Paradigm: 
Task:
    CSIs must be the same for both detection and imagery blocks.
    CSIs vary, and targets do not appear with 1/6 frequency.
    They do not know with which frequency there is flash, 1/6+0.5*5/6= 58,3% hits
Detection: was there a flash or not? this is not about what you see, but
    about what was there displayed. It is not the same (?) trying to guess 
    what happened (foj) and reporting what you see (soj? pas?). 
Imagery: Imagine a target at the same timing as the screen target, i.e., 
    try to make them coincide.
Behavioral paradigm blocking: 
    5 different CSI trials and 1 stimulus absent trial 
    2 different tasks
Threshold assessment method:
    Because detection visibility will be adjusted online with a staircase 
    method to 75%, the subject will not be sure whether he sees the 
    stimulus or not. Using 1/6 catch trials
Contrast:
    75% of accuracy 

Questions: 
Did you overimpose it or there was no stimulus displayed? CR?
T1Q1) Detection in which side
T1Q2) CR on detection
T2Q0)  Choose side L|R
T2Q1) did you only image(1) or imaged and saw (2)? you saw in the other side(3)?
T2Q2) 1.[1|2]* CR of imaged/imagedandseen in same side
T2Q2) 1.3 * usual CR on seen on opposite side
T2Q31) 1.2 how did you perceive goodness of timing (overlap with remembered
    timing). order them (1preceding 2coinciding 3following)
T2Q32) 1.2 rate which stimulus was brighter (1image 2same 3target)
*These are the important questions  

Measuring:
Two phases: 
    1.	cue-stimulus with stimulus-response mapping withheld
    2.	response mapping presentation and response

fMRI:
at least 300 scans required =  2 x 5 x 30? 
If the experiment lasts 1h, 3600/300=12s per trial (but in event-related, 
    15-20s is recommended)
Blocks of event-related trials
TR=2s ? 6 slices if the ITI is 12 s

5 sessions of 10min

functional scan
structural scan
baseline 5s


TIMING ADVICE: the first time you access any MEX function or M file,
  Matlab takes several hundred milliseconds to load it from disk.
  Allocating a variable takes time too. Usually you'll want to omit those
  delays from your timing measurements by making sure all the functions you
  use are loaded and that all the variables you use are allocated, before
  you start timing. MEX files stay loaded until you flush the MEX files
  (e.g. by changing directory or calling CLEAR MEX). M files and variables
  stay in memory until you clear them.


Sakai Letter:
Hi Mario,
I like both studies. Quite interesting and original.
But practically, I think the first one, imagery and perception, shoud be
given a priority.
This study is consistent with what you have been doing using
psychophysics and EEG.
The key to success is to nicely implement confidence and agency in the
analysis design.
The experiment time is rather long
and you may have to think about how to deal with subjects' fatigue.
Unlike EEG, head motion is really troublesome for fMRI data analysis.
Head motion of larger than 3 mm cannot be corrected with motion
correction program.
Normally a single session of scan lasts for about 10-15 minutes,
and you may have to split the total trials into 6 to 9 sessions (I
prefer 15 min x 6 sess).
Your behavioral paradigm is in a sense not so exciting for subjects,
and they may sleep inside a scanner.

Creative lying is highly original but because of some technical
difficulties,
I would suggest conducting this experiment on a few subjects as a pilot.
First you need to record the voice of the subjects,
but this may cause head motion artefacts due to jaw movements.
Also I assume you are thinking about using categorical classification
(lie or truth) for training SVM,
but it is a pity to classify the subjects' rich verbal response simply
as lie or truth.
There may be some additional factor with which to classify the subjects'
response.
Choosing the right set of questionaires would be difficult
but I like the idea nonetheless.
Cheers,
Katz
Addendum: he wants also to do a mathematical model and use it as a 
          regressor in the fmri regressor matrix


%}

