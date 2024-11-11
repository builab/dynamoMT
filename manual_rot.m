%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Manual_rot to fix alignment
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Modify the xform.tbl before.
% Run after aa_alignIntraAvg.m

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
initRefFile = 'ref_MT13PF_SPEF1.em';
coneFlip = 1; % Search for polarity. 1 is yes. Recommended to pick with polarity and set to 0
avgLowpass = 25; % Angstrom
alnLowpass = 25; % Angstrom
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

	t_xform = load([particleDir '/' filamentList{idx} '/xform.tbl']);
	Tp.type = 'shiftrot';
	Tp.shifts = t_xform(1, 1:3);
	Tp.eulers = t_xform(1,4:6);
	
	% Read last table from alignment
	tFilament = dread(tPath);
	% Read last transformation & applied to table
	tFilament_ali = dynamo_table_rigid(tFilament, Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned.tbl']);
	% Write aligned intraAvg
	avg = daverage([particleDir '/' filamentList{idx}], 't', tFilament_ali, 'fc', 1, 'mw', mw);
	dwrite(avg.average, [alnDir '/avg/' filamentList{idx} '_aln.em']);

end
 
cd ..
