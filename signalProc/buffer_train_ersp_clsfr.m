function [clsfr,res]=buffer_train_ersp_clsfr(X,Y,hdr,varargin);
% train ERSP (frequency-domain) classifier with ft-buffer based data/events input
%
%   [clsfr,res]=buffer_train_ersp_clsfr(X,Y,hdr,varargin);
%
% Inputs:
%  X -- [ch x time x epoch] data
%       OR
%       [struct epoch x 1] where the struct contains a buf field of buffer data
%       OR
%       {[float ch x time] epoch x 1} cell array of data
%  Y -- [epoch x 1] set of labels for the data epochs
%       OR
%       [struct epoch x 1] set of buf event structures which contain epoch labels in value field
%  hdr-- [struct] buffer header structure
% Options:
%  capFile -- [str] name of file which contains the electrode position info  ('1010')
%  overridechnms -- [bool] does capfile override names from the header    (false)
%  varargin -- all other options are passed as option arguments to train_ersp_clsfr
% Outputs:
%  clsfr   -- [struct] a classifer structure
%  res     -- [struct] a results structure
%
% See Also: train_ersp_clsfr
opts=struct('capFile','1010','overridechnms',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<3 ) error('Insufficient arguments'); end;
% extract the data - from field begining with trainingData
if ( iscell(X) ) 
  if ( isnumeric(X{1}) ) 
    X=cat(3,X{:});
  else
    error('Unrecognised data format!');
  end
elseif ( isstruct(X) )
  X=cat(3,X.buf);
end 
X=single(X);
if ( isstruct(Y) ) Y=cat(1,Y.value); end; % convert event struct into labels

fs=[];
if ( isstruct(hdr) )
  if ( isfield(hdr,'channel_names') ) chNames=hdr.channel_names; end;
  if ( isfield(hdr,'fsample') ) fs=hdr.fsample; end;
elseif ( iscell(hdr) && isstr(hdr{1}) )
  chNames=hdr;
end

% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names
iseeg=[di.extra.iseeg];

% call the actual function which does the classifier training
[clsfr,res]=train_ersp_clsfr(X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
return;