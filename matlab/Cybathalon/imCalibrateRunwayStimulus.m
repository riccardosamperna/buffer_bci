configureIM;
initgetwTime;
initsleepSec;

% pre-build the time-line for the whole experiment
tgtSeq=mkStimSeqRand(nSymbs,nSeq);
% insert the rest between tgts to make a complete stim sequence + event seq with times
trlEP   = (trialDuration+baselineDuration+intertrialDuration)./epochDuration;
stimSeq = zeros(size(tgtSeq,1)+1,size(tgtSeq,2)*trlEP);
%zeros(size(tgtSeq,1)+1,size(tgtSeq,2)*(trialDuration+baselineDuration+intertrialDuration)./epochDuration);										  
stimTime=(0:size(stimSeq,2))*epochDuration; % stimulus times										  
eventSeq=true(1,size(stimSeq,2));           % when to send events

										  % the normal trials
stimSeq(1:nSymbs,:)=reshape(repmat(tgtSeq,trlEP,1),size(tgtSeq,1),[]); % tgts
stimSeq(nSymbs+1,:)=0; % add a stimseq for the rest/baseline cue
										  % the baseline phase
stimSeq(:,1:trlEP:end)=0;      stimSeq(nSymbs+1,1:trlEP:end)=1;
			% the RTB phase at end of every trial ends with a RTB = no stimulus & no event
stimSeq(:,trlEP:trlEP:end)=0;  eventSeq(1,trlEP:trlEP:end)=false;


										  % setup image to hold the task runway
visDur   = 10;
% number frames store in the visible window, padded with enough extra to not need updating during trial
visFrames= (visDur+trialDuration)./frameDuration; 
visImg   = zeros(nSymbs,visFrames,3); % rgb image to render
visT0    = 0; % absolute time visible fragement of the image starts
visEnd   = 0; % index of the end of the valid part of the image


% make the stimulus
%figure;
fig=figure(2);
set(fig,'Name','Imagined Movement','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',axLim,'xlimmode','manual','ylim',axLim,'ylimmode','manual','Ydir','normal');
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels

% setup for the runway: N.B. xdata/ydata are the centers of the pixels!
xdata=[axLim(1)+.3*diff(axLim) axLim(2)]; ydata=axLim;
h(1)=image('xdata',mean(xdata)+diff(xdata)/2*[-1 1]*(visFrames-1)/visFrames,...
			  'ydata',mean(ydata)+diff(ydata)/2*[-1 1]*(nSymbs-1)/nSymbs,'cdata',repmat(shiftdim(bgColor(:),-2),[nSymbs,visFrames,1])); % start 10% into the axes
imgh=h(1);
										  % add labels for each row.
ylim=get(ax,'ylim'); ypos=linspace(ylim(1),ylim(2),nSymbs+2); ypos=ypos(2:end-1);
for si=1:nSymbs;
  snm=sprintf('%d',si);
  if ( ~isempty(symbCue) ) snm=sprintf('%d %s',si,symbCue{si}); end;
  h(si+1)=text(axLim(1)+.3*diff(axLim),ypos(si),snm,...
					'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle',...
					'fontunits','pixel','fontsize',.08*wSize(4),...
					'color',txtColor,'visible','on');
end

										  % clear the display
set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');

% wait for starting button press
set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

sendEvent('stimulus.training','start');



% play the stimulus
% animation loop
t0=getwTime(); % absolute start time for the experiment
for ei=1:size(stimSeq,2);

										  % render stimSeq into the visImage
										  % find epoch to start with
  epI=[];
  for fi=visEnd+1:size(visImg,2); % render into the frameBuffer
	 visImg(:,fi,:) = repmat(bgColor,size(visImg,1),1); % start as background color
	 starttfi= visT0+(fi-1)*frameDuration; % start time for the current frame
	 % find which epoch contains this frame
	 if ( isempty(epI) ) 
		epI=find(starttfi>=stimTime,1,'last');
	 else
		if ( starttfi>=stimTime(min(end,epI+1)) ) epI=epI+1; end % move to next epoch of needed
	 end
	 if ( ~isempty(epI) && epI<size(stimSeq,2) )
		ss=stimSeq(:,epI);
		if ( any(ss>0) ) % set target cols
		  if ( ss(end) ) % rest
			 visImg(:,fi,:)             =repmat(fixColor,nSymbs,1);
		  else % tgt
			 visImg(ss(1:nSymbs)>0,fi,:)=repmat(tgtColor,sum(ss(1:nSymbs)>0),1);
		  end
		end
	 end
  end
  visEnd=fi; % update the end valid-data indicator
  
  % send the epoch events
  if ( ~eventSeq(ei) ) % should we send an event
	 set(txthdl,'string','','color',txtColor,'visible','on');		  
  else
	 if ( stimSeq(end,ei) ) % baseline epoch
		sendEvent('stimulus.baseline','start');
		if ( ~isempty(baselineClass) ) % treat baseline as a special class
		  sendEvent('stimulus.target',baselineClass);
		  set(txthdl,'string',baselineClass,'color',txtColor,'visible','on');
		else
		  set(txthdl,'string','rest');
		end
	 else % target action epoch
		tgtIdx=find(stimSeq(:,ei)>0);
		if ( ~isempty(symbCue) )
		  set(txthdl,'string',sprintf('%s ',symbCue{tgtIdx}),'color',txtColor,'visible','on');
		  tgtNm = '';
		  for ti=1:numel(tgtIdx);
			 if(ti>1) tgtNm=[tgtNm ' + ']; end;
			 tgtNm=sprintf('%s%d %s ',tgtNm,tgtIdx,symbCue{tgtIdx});
		  end
		else
		  tgtNm = tgtIdx; % human-name is position number
		end
		fprintf('%d) tgt=%10s : \n',ei,tgtNm);
		sendEvent('stimulus.target',tgtNm);
	 end
  end

  % run the animation
  et=getwTime()-t0;
  fprintf('%d) Tgt=[%6.2f-%6.2f]\tTrue=%6.2f\tdiff=%g\n',ei,stimTime(ei:ei+1),et,et-stimTime(ei));
  animateDuration = stimTime(ei+1)-stimTime(ei);
  set(h,'visible','on');
  animateRunway
  
end
% end training marker
sendEvent('stimulus.training','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
