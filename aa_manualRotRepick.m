%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to manual edit the xform file to rotate the filament
% Edit the rotation angle in the 6 column of the xform file
% If not flipping, then +, if flipping, then -
% -angle from imod mean - angle here
% Identical to aa_manualRot.m, just on repick now
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage2/Thibault/20240905_SPEF1MTs/MTavg/';

%% Input
pixelSize = 8.48;
boxSize = 80;
filamentListFileManualRot= 'filamentRepickListManualRot.csv';
alnDir = sprintf('%sintraAln_repick', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
previewDir =[alnDir '/preview']; % created from previously
mw = 2; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
avgLowpass = 25; % Angstrom
skipIntraAln = 1; % In repick, you can opt to use intraRepickAln or not

%%
filamentList = readcell(filamentListFileManualRot, 'Delimiter', ',');
noFilament = length(filamentList);

% Need to go into alnDir to read the intraAln project
cd(alnDir)

%% Calculate the alignment of the filamentAverage to the initial reference
% transform the corresponding table for all particles
for idx = 1:noFilament
	if skipIntraAln > 0
		% For the doublet, read the average seems to be great, for MT with low signal, seem like template.em, the middle section have better signal)
		%aPath = ([particleDir '/' filamentList{idx} '/average.em']); % Read the path of the alignment project average
		aPath = ([particleDir '/' filamentList{idx} '/template.em']); % Read the path of the alignment project average
		tPath = ([particleDir '/' filamentList{idx} '/crop.tbl']);
	else
		aPath = ddb([filamentList{idx,1} ':a']); % Read the path of the alignment project average
		tPath = ddb([filamentList{idx,1} ':rt']);
	end
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
	% OverWrite the old table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx,1} '/aligned.tbl']);
	% Write aligned intraAvg
	%avg = daverage([particleDir '/' filamentList{idx,1}], 't', tFilament_ali, 'fc', 1, 'mw', mw);
	average = dpkgeom.rotation.smoothShiftRot(filamentAvg, Tp.shifts, Tp.eulers);
	dwrite(dynamo_bandpass(average, [1 round(pixelSize/avgLowpass*boxSize)]), [alnDir '/avg/' filamentList{idx,1} '_manual_aln.em']);

end
 
cd ..


