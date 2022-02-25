%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align intra average of each doublet with a reference
% and transform all the alignment to an updated table.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filamentListFile = 'filamentList.csv';
alnDir = 'intraAln';
particleDir = 'particles';
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
boxSize = 96;
initRefFile = 'dmt_init_avg_b96.em';
coneFlip = 1; % Search for polarity
newRefFile = 'updated_avg_b96.em';
lowpass = 20; % pixel. Filter to 40 Angstrom equivalent


filamentList = readcell(filamentListFile);
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
  		sal = dalign(dynamo_bandpass(template,[1 lowpass]), dynamo_bandpass(filamentAvg,[1 lowpass]),'cr',15,'cs',5,'ir',360,'is',10,'dim',96, 'limm',1,'lim',[20,20,20],'rf',5,'rff',2, 'cone_flip', 1); % cone_flip
	else
  		sal = dalign(dynamo_bandpass(template,[1 lowpass]), dynamo_bandpass(filamentAvg,[1 lowpass]),'cr',15,'cs',5,'ir',360,'is',10,'dim',96, 'limm',1,'lim',[20,20,20],'rf',5,'rff',2); % no cone_flip
	end
	dview(sal.aligned_particle);
	% Read last table from alignment
	tFilament = dread(tPath);
	% Read last transformation & applied to table
	tFilament_ali = dynamo_table_rigid(tFilament, sal.Tp);
	% Write table
	dwrite(tFilament_ali, ['../' particleDir '/' filamentList{idx} '/aligned.tbl'])
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
