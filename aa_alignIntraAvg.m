%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align intra average of each doublet with a reference
% and transform all the alignment to an updated table.
% dynamoDMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/base_CP/';

% Input
filamentListFile = 'filamentList.csv';
alnDir = sprintf('%sintraAln', prjPath);
particleDir = sprintf('%sparticles', prjPath);
mw = 12; % Number of parallel workers to run
gpu = [0:2]; % Alignment using gpu

initRefFile = 'ref_base.em';
coneFlip = 0; % Search for polarity. 1 is yes. Recommended to pick with polarity and set to 0
newRefFile = 'ref_all.em';
lowpass = 40; % Fourier pixel. Filter the average to 30 Angstrom equivalent


filamentList = readcell(filamentListFile, 'Delimiter', ',');
noFilament = length(filamentList);
template = dread(initRefFile);

% Need to go into alnDir to read the intraAln project
cd(alnDir)

% Calculate the alignment of the filamentAverage to the initial reference
% transform the corresponding table for all particles
for idx = 1:noFilament
	aPath = ddb([filamentList{idx} ':a']); % Read the path of the alignment project average
	tPath = ddb([filamentList{idx} ':rt']);
	filamentAvg = dread(aPath);
	if coneFlip > 0
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 lowpass]), dynamo_bandpass(template,[1 lowpass]),'cr',15,'cs',5,'ir',360,'is',10,'dim',144, 'limm',1,'lim',[20,20,20],'rf',5,'rff',2, 'cone_flip', 1); % cone_flip
	else
  		sal = dalign(dynamo_bandpass(filamentAvg,[1 lowpass]), dynamo_bandpass(template,[1 lowpass]),'cr',20,'cs',10,'ir',360,'is',10,'dim',144, 'limm',1,'lim',[20,20,20],'rf',5,'rff',2); % no cone_flip
	end
	dview(sal.aligned_particle);
	% Read last table from alignment
	tFilament = dread(tPath);
	% Read last transformation & applied to table
	tFilament_ali = dynamo_table_rigid(tFilament, sal.Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned.tbl'])
end
 
cd ..

% Generate updated reference
for idx = 1:noFilament
	% Read the updated table
	tFilament_ali = dread([particleDir '/' filamentList{idx} '/aligned.tbl']); 
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
