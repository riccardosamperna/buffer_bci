configureIM;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

% make the stimulus
%figure;
fig=figure(2);
set(fig,'Name','Imagined Movement','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',axLim,'ylim',axLim,'Ydir','normal');

stimPos=[]; h=[]; htxt=[];
stimRadius=diff(axLim)/4;
cursorSize=stimRadius/2;
theta=linspace(0,2*pi,nSymbs+1)+pi/2; % N.B. pos1=N so always left-right symetric
theta=theta(1:end-1);
stimPos=[cos(theta);sin(theta)];

set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');

set(txthdl,'string', {calibrate_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;
pause(1);

nSeq = 15;
tgtNames = {'Task1','Task2','Task3'};
sendEvent('stimulus.training','start');
for k = 1:length(tgtNames)
     
    for i = 1:nSeq
        set(txthdl,'string',tgtNames{k},'color',[1 0 0], 'visible', 'on');drawnow;
        sendEvent('stimulus.baseline','start');
        sleepSec(1);
        sendEvent('stimulus.baseline','end'); 
        set(txthdl,'string',tgtNames{k},'color',[0 1 0]);drawnow;
        sendEvent('stimulus.trial','start');
        sendEvent('stimulus.target',tgtNames{k});
        sleepSec(3);
        sendEvent('stimulus.trial','end');
        set(txthdl,'string',''); drawnow;
        sleepSec(1);
    end
    set(txthdl,'string', {calibrate_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
    waitforbuttonpress;
    set(txthdl,'visible', 'off'); drawnow; sleepSec(intertrialDuration);
end 
sendEvent('stimulus.training','end');

