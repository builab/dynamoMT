%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align the manual rot reference
% dynamoDMT v0.11
% Identical between 13 and 14 PF, just change list & ref
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Skip the one with 0 to save time.

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';

%% Input
pixelSize = 8.48;
boxSize = 80;
filamentListFile = 'filamentRepickList14PFManualRot.csv';
alnDir = sprintf('%sintraAlnSuper_repick', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
previewDir =[alnDir '/preview']; % created from previously
mw = 10; % Number of parallel workers to run
gpu = [0]; % Alignment using gpu
initRefFile = 'templates/hSPEF1x2_14PFMT_25A.em';
coneFlip = 0; % Definitely 0 coneflip
avgLowpass = 25; % Angstrom
alnLowpass = 25; % Angstrom
shiftLimit = [10 10 6]; % Limit Z in pixel half of periodicity
newRefFile = 'average_repick_14PF_manualaln.em'; % Average of the manually rot ones only

%%
filamentList = readcell(filamentListFile, 'Delimiter', ',');
noFilament = size(filamentList, 1);
template = dread(initRefFile);
alnLowpassPix = round(pixelSize/alnLowpass*boxSize);
newTemplate = zeros(boxSize, boxSize, boxSize);

% Need to go into alnDir to read the intraAln project
cd(alnDir)

%% Calculate the alignment of the filamentAverage to the initial reference
% transform the corresponding table for all particles
count = 0;

for idx = 1:noFilament
	filamentAvg = dread(['avg/' filamentList{idx, 1} '_manual_aln.em']);
	if abs(filamentList{idx, 2}) > 0 % Skip everything not manual
		disp(['Align ' filamentList{idx, 1}]);
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template,[1 alnLowpassPix]),'cr',9,'cs',3,'ir',21,'is',3,'dim',boxSize, 'limm',1,'lim',shiftLimit,'rf',2,'rff',2, 'cone_flip', coneFlip); % cone_flip
		xform = [sal.p_shifts sal.p_eulers];
		Tp = sal.Tp;
		newTemplate = newTemplate + sal.aligned_particle;
		count = count + 1;
		dwrite(sal.aligned_particle, [alnDir '/avg/' filamentList{idx, 1} '_manual_aln2.em']);
	else
		xform = [0 0 0 0 0 0];
		Tp.type = 'shiftrot';
		Tp.shifts = [0 0 0];
		Tp.eulers = [0 0 0];
		%newTemplate = newTemplate + filamentAvg;
		%dwrite(filamentAvg, [alnDir '/avg/' filamentList{idx, 1} '_manual_aln2.em']);
	end

	writematrix(xform , [particleDir '/' filamentList{idx, 1} '/manual_xform.tbl'], 'Delimiter', 'tab', 'FileType', 'text');

	% Read last table from alignment
	tFilament = dread([particleDir '/' filamentList{idx, 1} '/aligned.tbl']);
	tFilament_ali = dynamo_table_rigid(tFilament, Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx, 1} '/aligned_manual.tbl']);

end
 
cd ..


%% Calculate average
if count > 0
	newTemplate = newTemplate/count;
	dwrite(newTemplate, newRefFile);
else
	disp('No manually rot filament found');
end
