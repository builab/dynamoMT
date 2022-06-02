%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align 32nm repick average of each doublet with a reference
% and transform all the alignment to an updated table.
  The alignment should be done in 2 steps.
  (1) Align the entire RepickAvg to the 32-nm ref
  (2) Align the transformed Repick Avg to 32-nm with a mask highlighting the 32-nm feature and Z-translate only
% dynamoDMT v0.11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/base_CP/';

% Input
filamentListFile = 'filamentList.csv';
particleDir = sprintf('%sparticles_repick', prjPath);
alnDir = sprintf('%srepick_aln_32nm', prjPath);

mw = 12; % Number of parallel workers to run
gpu = [0:5]; % Alignment using gpu

initRefFile = 'ref_base_32nm.em'; % 32-nm ref file
coneFlip = 0; % Search for polarity. 1 is yes. Recommended to pick with polarity and set to 0
newRefFile = 'reference_repick_32nm.em';
lowpass = 40; % Fourier pixel. Filter the average to 30 Angstrom equivalent
zshift_limit = 20; % ~16nm

mask_32nm = 'masks/mask_base_cp_32nm_features.em'; % Mask for 32-nm alignment


filamentList = readcell(filamentListFile, 'Delimiter', ',');
noFilament = length(filamentList);
template = dread(initRefFile);

mkdir(alnDir)

% Calculate the alignment of the filamentAverage to the initial reference
% transform the corresponding table for all particles
for idx = 1:noFilament
	aPath = ([particleDir '/' filamentList{idx} '/template32nm.em']); % Read the path of the alignment project average
	tPath = ([particleDir '/' filamentList{idx} '/crop_32nm.tbl']); 
	filamentAvg = dread(aPath);
	
	% First round alignment
	if coneFlip > 0
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 lowpass]), dynamo_bandpass(template,[1 lowpass]),'cr',10,'cs',5,'ir',360,'is',5,'dim',144, 'limm',1,'lim',[5,5,zshift_limit],'rf',5,'rff',2, 'cone_flip', 1); % cone_flip
	else
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 lowpass]), dynamo_bandpass(template,[1 lowpass]),'cr',10,'cs',5,'ir',360,'is',5,'dim',144, 'limm',1,'lim',[5,5,zshift_limit],'rf',5,'rff',2); % no cone_flip
	end
	%dview(sal.aligned_particle);
	% Preparation for the 2nd alignment round, can turn off
	dwrite(sal.aligned_particles, [alnDir '/' filamentList{idx} '_aln_r1.em']);
	
	% 2nd round alignment, shift alignment only
	if coneFlip > 0
  		sal2 = dalign(dynamo_bandpass(sal.aligned_particles,[1 lowpass]), dynamo_bandpass(template,[1 lowpass]),'cr',0,'cs',5,'ir',0,'is',5,'dim',144, 'limm',1,'lim',[5,5,zshift_limit],'rf',5,'rff',2, 'cone_flip', 1, 'file_mask', mask_32nm); % cone_flip
	else
  		sal2 = dalign(dynamo_bandpass(sal.aligned_particles,[1 lowpass]), dynamo_bandpass(template,[1 lowpass]),'cr',0,'cs',5,'ir',0,'is',5,'dim',144, 'limm',1,'lim',[5,5,zshift_limit],'rf',5,'rff',2, 'file_mask', mask_32nm); % no cone_flip
	end
	
	% Read last table from alignment
	tFilament = dread(tPath);
	% Read last transformation & applied to table
	tFilament_ali = dynamo_table_rigid(tFilament, sal.Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned_r1.tbl'])
	
	% Apple 2nd round alignment
	tFilament_ali_r2 = dynamo_table_rigid(tFilament_ali, sal2.Tp);
	% Write table
	dwrite(tFilament_ali_r2, [particleDir '/' filamentList{idx} '/aligned.tbl'])
	
	% For Checking
	dwrite(sal2.aligned_particles, [alnDir '/' filamentList{idx} '_aln_r2.em']);

end
 

% Generate updated reference
for idx = 1:noFilament
	% Read the updated table
	tFilament_ali = dread([particleDir '/' filamentList{idx} '/aligned.tbl']); % Deviate from 16-nm repick
	targetFolder = [particleDir '/' filamentList{idx}];
	disp(targetFolder)
	oa = daverage(targetFolder, 't', tFilament_ali, 'fc', 1, 'mw', mw);
	dwrite(dynamo_bandpass(oa.average, [1 lowpass]), [targetFolder '/alignedTemplate.em']);

	if idx == 1
		newTemplate = oa.average;
	else
		newTemplate = newTemplate + oa.average;
	end
end

% Calculate average
newTemplate = newTemplate/noFilament;
dwrite(newTemplate, newRefFile);
