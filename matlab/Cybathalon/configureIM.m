%----------------------------------------------------------------------
% One-Time initialization code
% guard to not run the slow one-time-only config code every time...
if ( ~exist('configRun','var') || isempty(configRun) ) 

  % setup the paths
  run ../utilities/initPaths.m;

  buffhost='localhost';buffport=1972;
  % wait for the buffer to return valid header information
  hdr=[];
  while( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) %wait for the buffer to contain valid data
	 try 
		hdr=buffer('get_hdr',[],buffhost,buffport); 
	 catch
		hdr=[];
		fprintf('Invalid header info... waiting.\n');
	 end;
	 pause(1);
  end;

  % set the real-time-clock to use
  initgetwTime;
  initsleepSec;

  if ( exist('OCTAVE_VERSION','builtin') ) 
	 page_output_immediately(1); % prevent buffering output
	 if ( ~isempty(strmatch('qt',available_graphics_toolkits())) )
		graphics_toolkit('qt'); 
	 elseif ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
		graphics_toolkit('qthandles'); 
	 elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
		graphics_toolkit('fltk'); % use fast rendering library
	 end
  end

  % One-time configuration has successfully completed
  configRun=true;
end
%----------------------------------------------------------------------

%----------------------------------------------------------------------
% Application specific config
verb         =0; % verbosity level for debug messages, 1=default, 0=quiet, 2=very verbose
buffhost     ='localhost';
buffport     =1972;
symbCue      ={'Feet' 'Left-Hand' 'Right-Hand'};
<<<<<<< 786aa37580d3f6503b6103a00ccf33f93a33aeea
%symbCue      ={'Tongue' 'Song' 'Right-Hand'}; % config for Toine
=======
>>>>>>> instruction strings and better mix of scoping tasks
nSymbs       =numel(symbCue); % E,N,W,S for 4 outputs, N,W,E  for 3 outputs
baselineClass='99 Rest'; % if set, treat baseline phase as a separate class to classify
rtbClass     =[];


nSeq              =20*nSymbs; % 20 examples of each target
epochDuration     =1.5;
trialDuration     =epochDuration*3; % 3*20 = 60 classification trials per class = 4.5s trials
baselineDuration  =epochDuration;   % = 1.5s baseline
intertrialDuration=epochDuration;   % = 1.5s post-trial
feedbackDuration  =epochDuration;
errorDuration     =epochDuration*2; %= 3s penalty for mistake

contFeedbackTrialDuration =10;
neurofeedbackTrialDuration=30;
warpCursor   = 1; % flag if in feedback BCI output sets cursor location or how the cursor moves
moveScale    = .1;
feedbackMagFactor = 1.3; % how much we magnify the feedback cursor location

axLim        =[-1.5 1.5]; % size of the display axes
winColor     =[.0 .0 .0]; % window background color
bgColor      =[.2 .2 .2]; % background/inactive stimuli color
fixColor     =[.8  0  0];  % fixitation/get-ready cue point color
tgtColor     =[0  .7  0];  % target color
fbColor      =[0   0 .8];  % feedback color
txtColor     =[.9 .9 .9]; % color of the cue text
errorColor   =[.8  0 0];  % error feedback color


animateFix   = true; % do we animate the fixation point during training?
frameDuration= .25; % time between re-draws when animating the fixation point
animateStep  = diff(axLim)*.01; % amount by which to move point per-frame in fix animation


%----------------------------------------------------------------------------------------------
% stimulus type specific configuration
calibrate_instruct ={'When instructed perform the indicated' 'actual movement'};

epochfeedback_instruct={'When instructed perform the indicated' 'actual movement.  When trial is done ' 'classifier prediction with be shown' 'with a blue highlight'};

contfeedback_instruct={'When instructed perform the indicated' 'actual movement.  The fixation point' 'will move to show the systems' 'current prediction'};
contFeedbackTrialDuration =10;

neurofeedback_instruct={'Perform mental tasks as you would like.' 'The fixation point will move to' 'show the systems current prediction'};
neurofeedbackTrialDuration=30;

centerout_instruct={'Complete the indicated tasks as rapidly as possible.' 'The fixation point will move to' 'show the current prediction' 'Trials end when fixation hits the target' 'or time runs out.' 'Hitting the wrong target incurs a time penalty'};
earlyStoppingFilt=[]; % dv-filter to determine when a trial has ended
%earlyStoppingFilt=@(x,s,e) gausOutlierFilt(x,s,2); % dv-filter to determine when a trial has ended

%----------------------------------------------------------------------------------------------
% classifier training configuration

% Calibration/data-recording options
trlen_ms      =epochDuration*1000; % how much data to use in each classifier training example
offset_ms     =[0 0];%[250 250]; % give .25s for user to start/finish
calibrateOpts ={'offset_ms',offset_ms};
adaptHalfLife_ms = 10*1000; %10s

										% classifier training options
welch_width_ms=250; % width of welch window => spectral resolution
step_ms       =welch_width_ms/2;% N.B. welch defaults=.5 window overlap, use step=width/2 to simulate
trialadaptfactor=exp(log(.5)/(adaptHalfLife_ms/trlen_ms)); % adapt rate when apply per-trial
contadaptfactor =exp(log(.5)/(adaptHalfLife_ms/welch_width_ms)); % adapt rate when apply per welch-win
contFeedbackFiltLen=(trialDuration*1000/step_ms); % number cont-feedback predictions to average to get output


%trainOpts={'width_ms',welch_width_ms,'badtrrm',0}; % default: 4hz res, stack of independent one-vs-rest classifiers
trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','wht','objFn','mlr_cg','binsp',0,'spMx','1vR'}; % whiten + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','trwht','adaptspatialfilt',trialadaptfactor,'objFn','mlr_cg','binsp',0,'spMx','1vR'}; % adaptive-whiten + direct multi-class training
%trainOpts = {'spType',{{1 3} {2 4}}}; % train 2 classifiers, 1=N vs S, 2=E vs W

% Epoch feedback opts
%%0) Use exactly the same classification window for feedback as for training, but
%%   but also include a bias adaption system to cope with train->test transfer
earlyStopping=false;%true;
epochFeedbackOpts={'trlen_ms',trialDuration*1000}; % raw output
%epochFeedbackOpts={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/50))}; % bias-apaption

% Epoch feedback with early-stopping, config using the user feedback table
userFeedbackTable={'epochFeedback_es' 'cont' {'predFilt',@(x,s,e) gausOutlierFilt(x,s,3.0,trialDuration*1000./step_ms),'trlen_ms',welch_width_ms}};
% Epoch feedback with early-stopping, (cont-classifer, so update adaptive whitener constant)
userFeedbackTable={'epochFeedback_es' 'cont' {'predFilt',@(x,s,e) gausOutlierFilt(x,s,3.0,trialDuration*1000./step_ms),'trlen_ms',welch_width_ms,'adaptspatialfilt',contadaptfactor}};


% different feedback configs (should all give similar results)

%%1) Use exactly the same classification window for feedback as for training, but apply more often
%contFeedbackOpts ={'step_ms',welch_width_ms}; % apply classifier more often
%%   but also include a bias adaption system to cope with train->test transfer
%contFeedbackOpts ={'predFilt',@(x,s,e) biasFilt(x,s,exp(log(.5)/100)),'step_ms',250};
stimSmoothFactor= 0; % additional smoothing on the stimulus, not needed with 3s trlen

%%2) Classify every welch-window-width (default 250ms), prediction is running average of full trials worth of data, no-bias adaptation
%% N.B. this is numerically identical to option 1) above, but computationally *much* cheaper 
contFeedbackOpts ={'rawpredEventType','classifier.rawprediction','predFilt',-contFeedbackFiltLen,'trlen_ms',welch_width_ms};
% classify every welch-window-width, update adapt-filt hl w.r.t. shorter input windows
%contFeedbackOpts ={'predFilt',-(trlen_ms/step_ms),'trlen_ms',welch_width_ms,'adaptspatialfilt',exp(log(.5)/(adaptHalfLife_ms/welch_width_ms))};


%%3) Classify every welch-window-width (default 500ms), with bias-adaptation
%contFeedbackOpts ={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/400)),'trlen_ms',[]}; 
%stimSmoothFactor= -(trlen_ms/500);% actual prediction is average of trail-length worth of predictions
