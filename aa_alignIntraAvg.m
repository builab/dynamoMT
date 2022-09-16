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
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/tip_CP_dPhi/';

%% Input
pixelSize = 8.48;
boxSize = 96;
filamentListFile = 'filamentList.csv';
alnDir = sprintf('%sintraAln', prjPath);
particleDir = sprintf('%sparticles', prjPath);
previewDir =[alnDir '/preview']; % created from previously
mw = 12; % Number of parallel workers to run
gpu = [0:5]; % Alignment using gpu
initRefFile = 'reference.em';
coneFlip = 0; % Search for polarity. 1 is yes. Recommended to pick with polarity and set to 0
avgLowpass = 30; % Angstrom
alnLowpass = 30; % Angstrom
shiftLimit = [20 20 10]; % Limit Z in pixel half of periodicity
newRefFile = 'reference_intraAln.em';

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
	aPath = ddb([filamentList{idx} ':a']); % Read the path of the alignment project average
	tPath = ddb([filamentList{idx} ':rt']);
	filamentAvg = dread(aPath);
	boxSize = length(filamentAvg);
	if coneFlip > 0
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template,[1 alnLowpassPix]),'cr',15,'cs',5,'ir',360,'is',10,'dim',boxSize, 'limm',1,'lim',shiftLimit,'rf',5,'rff',2, 'cone_flip', 1); % cone_flip
	else
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template,[1 alnLowpassPix]),'cr',10,'cs',5,'ir',360,'is',10,'dim',boxSize, 'limm',1,'lim',shiftLimit,'rf',5,'rff',2); % no cone_flip
	end
	%dview(sal.aligned_particle);
	% 0.2b Write out the transform
	writematrix([sal.p_shifts sal.p_eulers], [particleDir '/' filamentList{idx} '/xform.tbl'], 'Delimiter', 'tab', 'FileType', 'text');
	
	% Write out preview
	newTemplate = newTemplate + sal.aligned_particle;
	filt_aligned_particle = dynamo_bandpass(sal.aligned_particle, [1 round(pixelSize/avgLowpass*boxSize)]);
	img = sum(filt_aligned_particle(:,:,floor(boxSize/2) - 10: floor(boxSize/2) + 10), 3);
	imwrite(mat2gray(img), [previewDir '/' filamentList{idx} '_aln.png'])
	% Read last table from alignment
	tFilament = dread(tPath);
	% Read last transformation & applied to table
	tFilament_ali = dynamo_table_rigid(tFilament, sal.Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned.tbl'])
	% Write aligned intraAvg
	dwrite(sal.aligned_particle, [alnDir '/avg/' filamentList{idx} '_aln.em'])

end
 
cd ..


%% Calculate average
newTemplate = newTemplate/noFilament;
dwrite(newTemplate, newRefFile);
