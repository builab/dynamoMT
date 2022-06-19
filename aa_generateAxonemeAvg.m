%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to generate axoneme average to quickly check polarity
% Not essential but useful
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NOT DONE!!!!

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/doublet/';

% Input
pixelSize = 8.48;
boxSize = 96;
filamentListFile = 'filamentList.csv';
alnDir = sprintf('%sintraAln', prjPath);
particleDir = sprintf('%sparticles', prjPath);
previewDir =[alnDir '/preview']; % created from previously
mw = 12; % Number of parallel workers to run
gpu = [0:5]; % Alignment using gpu
avgLowpass = 30; % Angstrom

filamentList = readcell(filamentListFile, 'Delimiter', ',');
noFilament = length(filamentList);
alnLowpassPix = round(pixelSize/alnLowpass*boxSize);


% Generate axoneme average
for idx = 1:noFilament
	% Read the updated table
  % Check the same tomo
	tFilament_ali = dread([particleDir '/' filamentList{idx} '/aligned.tbl']); 
	targetFolder = [particleDir '/' filamentList{idx}];
	disp(targetFolder)
	oa = daverage(targetFolder, 't', tFilament_ali, 'fc', 1, 'mw', mw);
	dwrite(dynamo_bandpass(oa.average, [1 round(pixelSize/avgLowpass*boxSize)]), [targetFolder '/alignedTemplate.em']);

	if idx == 1
		newTemplate = oa.average;
	else
		newTemplate = newTemplate + oa.average;
	end
end

% Calculate average
newTemplate = newTemplate/noFilament;
dwrite(newTemplate, newRefFile);
