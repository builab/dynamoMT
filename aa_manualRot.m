%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to manual edit the xform file to rotate the filament
% Edit the rotation angle in the 6 column of the xform file
% If not flipping, then +, if flipping, then -
% -angle from imod mean - angle here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage2/Thibault/20240905_SPEF1MTs/MTavg/';

%% Input
pixelSize = 8.48;
boxSize = 80;
filamentListFileManualRot= 'filamentListManualRot.csv';
alnDir = sprintf('%sintraAln', prjPath);
particleDir = sprintf('%sparticles', prjPath);
previewDir =[alnDir '/preview']; % created from previously
mw = 10; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
avgLowpass = 25; % Angstrom

%%
filamentList = readcell(filamentListFileManualRot, 'Delimiter', ',');
noFilament = length(filamentList);

% Need to go into alnDir to read the intraAln project
cd(alnDir)

%% Calculate the alignment of the filamentAverage to the initial reference
% transform the corresponding table for all particles
for idx = 1:noFilament
	aPath = ddb([filamentList{idx,1} ':a']); % Read the path of the alignment project average
	tPath = ddb([filamentList{idx,1} ':rt']);
	filamentAvg = dread(aPath);
	boxSize = length(filamentAvg);

	t_xform = load([particleDir '/' filamentList{idx,1} '/xform.tbl']);
	t_xform(1, 6) = t_xform(1, 6) + filamentList{idx,2};
	Tp.type = 'shiftrot';
	Tp.shifts = t_xform(1, 1:3);
	Tp.eulers = t_xform(1, 4:6);
	
	% Read last table from alignment
	tFilament = dread(tPath);
	% Read last transformation & applied to table
	tFilament_ali = dynamo_table_rigid(tFilament, Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx,1} '/aligned.tbl']);
	% Write aligned intraAvg
	avg = daverage([particleDir '/' filamentList{idx,1}], 't', tFilament_ali, 'fc', 1, 'mw', mw);
	dwrite(dynamo_bandpass(avg.average, [1 round(pixelSize/avgLowpass*boxSize)]), [alnDir '/avg/' filamentList{idx,1} '_manual_aln.em']);

end
 
cd ..


