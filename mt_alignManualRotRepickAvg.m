%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align the manual rot reference
% dynamoDMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Skip the one with 0 to save time.

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/20240905_SPEF1MTs/MTavg/';

%% Input
pixelSize = 8.48;
boxSize = 80;
filamentListFile = 'filamentRepickList13PFManualRot.csv';
alnDir = sprintf('%sintraAlnSuper_repick', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
previewDir =[alnDir '/preview']; % created from previously
mw = 10; % Number of parallel workers to run
gpu = [0]; % Alignment using gpu
initRefFile = 'hSPEF1_13PFMT_25A.em';
coneFlip = 0; % Definitely 0 coneflip
avgLowpass = 25; % Angstrom
alnLowpass = 25; % Angstrom
shiftLimit = [10 10 5]; % Limit Z in pixel half of periodicity
newRefFile = 'average_repick_manualaln.em';

%%
filamentList = readcell(filamentListFile, 'Delimiter', ',');
noFilament = length(filamentList);
template = dread(initRefFile);
alnLowpassPix = round(pixelSize/alnLowpass*boxSize);
newTemplate = zeros(boxSize, boxSize, boxSize);

% Need to go into alnDir to read the intraAln project
cd(alnDir)

%% Calculate the alignment of the filamentAverage to the initial reference
% transform the corresponding table for all particles
for idx = 1:noFilament
	filamentAvg = dread(['avg/' filamentList{idx} '_manual_aln.em']);
	if abs(filamentList{idx, 2}) > 0 % Skip everything not manual
		disp(['Align ' filamentList{idx, 1}]);
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template,[1 alnLowpassPix]),'cr',9,'cs',3,'ir',20,'is',10,'dim',boxSize, 'limm',1,'lim',shiftLimit,'rf',5,'rff',2, 'cone_flip', coneFlip); % cone_flip
		xform = [sal.p_shifts sal.p_eulers];
		Tp = sal.Tp;
		newTemplate = newTemplate + sal.aligned_particle;
		dwrite(sal.aligned_particle, [alnDir '/avg/' filamentList{idx} '_manual_aln2.em']);
	else
		xform = [0 0 0 0 0 0];
		Tp.type = 'shiftrot';
		Tp.shifts = [0 0 0];
		Tp.eulers = [0 0 0];
		newTemplate = newTemplate + filamentAvg;
		dwrite(filamentAvg, [alnDir '/avg/' filamentList{idx} '_manual_aln2.em']);
	end

	writematrix(xform , [particleDir '/' filamentList{idx} '/manual_xform.tbl'], 'Delimiter', 'tab', 'FileType', 'text');

	% Read last table from alignment
	tFilament = dread([particleDir '/' filamentList{idx} '/aligned.tbl']);
	tFilament_ali = dynamo_table_rigid(tFilament, Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned_manual.tbl']);

end
 
cd ..


%% Calculate average
newTemplate = newTemplate/noFilament;
dwrite(newTemplate, newRefFile);
