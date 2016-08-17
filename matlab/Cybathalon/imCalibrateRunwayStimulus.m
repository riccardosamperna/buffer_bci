configRun=true;
configureIM;

[tgtSeq]=mkStimSeqRand(nSymbs,nSeq);
% insert the rest between tgts to make a complete stim sequence + event seq with times
trlEP   = (trialDuration+baselineDuration+intertrialDuration)./epochDuration;
stimSeq = reshape(repmat(tgtSeq,trlEP,1),size(tgtSeq,1),[]);
stimSeq(nSymbs+1,:)=0; % add a stimseq for the rest/baseline cue
%zeros(size(tgtSeq,1)+1,size(tgtSeq,2)*(trialDuration+baselineDuration+intertrialDuration)./epochDuration);
										  % Every trial starts with a baseline cue
stimSeq(:,1:trlEP:end)=0; stimSeq(nSymbs+1,1:trlEP:end)=1;
										  % Every trial ends with a RTB = no stimulus
stimSeq(:,trlEP:trlEP:end)=0;

										  % stimulus times
stimTime=(0:size(stimSeq,2))*epochDuration;

% render loop
visDur   =10;
visFrames=(visDur+trialDuration)./frameDuration; % number frames store in the visible window
visImg   =zeros(nSymbs,visFrames,3); % rgb image to render



clf;
imgh=image(visImg(:,1:visDur/frameDuration,:));
set(gca,'visible','off');

% animation loop
t0=getwTime(); % start sequence
visT0 = 0;
visEnd= 0; % end of visible image as [index, time]
for ei=1:size(stimTime,2);

										  % render stimSeq into the visImage
										  % find epoch to start with
  tfi=visT0+visEnd*frameDuration;
  epI=find(tfi>stimTime,1,'last')+1; if ( isempty(epI) ) epI=1; end;
  for fi=visEnd+1:size(visImg,2); % render into the frameBuffer
	 visImg(:,fi,:) = repmat(bgColor,size(visImg,1),1); % start as background color
	 tfi= visT0+fi*frameDuration; % time for the current col
	 if ( tfi>stimTime(epI+1) ) epI=epI+1; end % move to next epoch of needed
	 ss=stimSeq(:,epI);
	 if ( any(ss>0) ) % set target cols
		if ( ss(end) ) % rest
		  visImg(:,fi,:)             =repmat(fixColor,nSymbs,1);
		else % tgt
		  visImg(ss(1:nSymbs)>0,fi,:)=repmat(tgtColor,sum(ss(1:nSymbs)>0),1);
		end
	 end
  end
  visEnd=fi; % update the end valid-data indicator
  
  fprintf('%d) Tgt=%g True=%g\n',ei,stimTime(ei),getwTime()-t0);
  animateDuration = stimTime(ei+1)-stimTime(ei);
  a0=t0+visT0; % absolute time of start of this sequence
  elapsedTime=getwTime()-a0;ofi=-1;fi=ceil(elapsedTime/frameDuration);
  while ( elapsedTime<animateDuration )
	 if ( ofi~=fi ) % only actually draw if something changed
		set(imgh,'cdata',visImg(:,fi+(1:visDur/frameDuration),:)); % update display
		drawnow;
	 end
	 if ( verb>1 ) fprintf('%d) f=%d t=%g t_e=%g\n',ei,fi,getwTime()-t0,getwTime()-a0) end;
	 sleepSec(frameDuration*.5);
	 f0=getwTime();
	 elapsedTime = f0-a0; % time left to run in this trial
	 ofi=fi;
	 fi=ceil(elapsedTime/frameDuration); % get closest frame time
	 if ( fi-ofi>1 )
		fprintf('%d) Dropped frames %d...\n',fi,ofi-fi);
	 end
  end
  set(imgh,'cdata',visImg(:,fi+(1:visDur/frameDuration),:)); % update display
  drawnow;

										  % shift the image and update visEnd
  visImg(:,1:(visEnd-fi+1),:)=visImg(:,fi:visEnd,:);
  visEnd=visEnd-fi+1; % shift back the end of correct info
  visT0 =visT0+((fi-1)*frameDuration); % shift start of the matrix forward
  
end
