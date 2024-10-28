%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align intra average of each doublet with a reference
% and transform all the alignment to an updated table.
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TODO
% Incoporate the subunit initial rot angle (tdrot)
% TODO Incorporate random rotation for microtubule alignment?

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage2/Thibault/20240905_SPEF1MTs/MTavg/';

%% Input
pixelSize = 8.48;
boxSize = 80;
filamentListFile = 'filamentList.csv';
alnDir = sprintf('%sintraAln', prjPath);
particleDir = sprintf('%sparticles', prjPath);
previewDir =[alnDir '/preview']; % created from previously
mw = 12; % Number of parallel workers to run
gpu = [0:5]; % Alignment using gpu
initRefFile = 'reference_manualAln_masked.em';
coneFlip = 0; % Search for polarity. 1 is yes. Recommended to pick with polarity and set to 0
avgLowpass = 25; % Angstrom
alnLowpass = 25; % Angstrom
shiftLimit = [10 10 5]; % Limit Z in pixel half of periodicity
newRefFile = 'reference_manualAln_r2.em';

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
	boxSize = length(filamentAvg);
	if coneFlip > 0
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template,[1 alnLowpassPix]),'cr',15,'cs',5,'ir',360,'is',10,'dim',boxSize, 'limm',1,'lim',shiftLimit,'rf',5,'rff',2, 'cone_flip', 1); % cone_flip
	else
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template,[1 alnLowpassPix]),'cr',5,'cs',5,'ir',10,'is',10,'dim',boxSize, 'limm',1,'lim',shiftLimit,'rf',5,'rff',2); % no cone_flip
	end
	%dview(sal.aligned_particle);
	% 0.2b Write out the transform
	writematrix([sal.p_shifts sal.p_eulers], [particleDir '/' filamentList{idx} '/manual_xform.tbl'], 'Delimiter', 'tab', 'FileType', 'text');
	
	% Write out preview
	newTemplate = newTemplate + sal.aligned_particle;
	% Read last table from alignment
	tFilament = dread([particleDir '/' filamentList{idx} '/aligned.tbl']);
	tFilament_ali = dynamo_table_rigid(tFilament, sal.Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned_manual.tbl']);
	% Write aligned intraAvg
	dwrite(sal.aligned_particle, [alnDir '/avg/' filamentList{idx} '_manual_aln2.em']);

end
 
cd ..


%% Calculate average
newTemplate = newTemplate/noFilament;
dwrite(newTemplate, newRefFile);
