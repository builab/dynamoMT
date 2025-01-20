%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align repick average of each doublet with a reference
% and transform all the alignment to an updated table.
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% There should be the option to use the middle region only
% Does mid region alignment better? Yes
% Modify for 13 & 14 accordingly

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';

%%%%%%% Variables subject to change %%%%%%%%%%%
pixelSize = 8.48;
boxSize = 80;
filamentRepickListFile = 'filamentRepickList14PF.csv';
particleDir = sprintf('%sparticles_repick', prjPath);
alnDir = sprintf('%sintraAlnSuper_repick', prjPath);
previewDir =[particleDir '/preview']; % created from previously
mw = 10; % Number of parallel workers to run
gpu = [0]; % Alignment using gpu
initRefFile = 'templates/hSPEF1x2_14PFMT_25A.em'; % Use the simulated ref with SPEF1 density
coneFlip = 0; % Keep 0 since we correct for polarity already
alnLowpass = 20; % Angstrom
avgLowpass = 20; % Angstrom
zshift_limit = 6; % ~4nm shift limit in pixel for 8 nm repeat, 8nm shift for 16-nm repeat
newRefFile = 'average_repick_14PF.em';
skipIntraAln = 0; % use this option for doublet microtubule, perhaps not for base-CP & tip-CP until careful test
useMidRegionOnly = 1; % use mid region only to amplify the signal


%%%%%%% Do not change anything under here %%%%%

filamentList = readcell(filamentRepickListFile, 'Delimiter', ',');
noFilament = length(filamentList);
template = dread(initRefFile);
newTemplate = zeros(boxSize, boxSize, boxSize);


alnLowpassPix = round(pixelSize/alnLowpass*boxSize);
mkdir(previewDir)

% Need to go into alnDir to read the intraAln project
cd(alnDir)

%% Calculate the alignment of the filamentAverage to the initial reference
% transform the corresponding table for all particles
for idx = 1:noFilament
	% v0.2b
	if skipIntraAln > 0
		%aPath = ([particleDir '/' filamentList{idx} '/average.em']); % Read the path of the alignment project average
		aPath = ([particleDir '/' filamentList{idx} '/template.em']); % Read the path of the alignment project average
		tPath = ([particleDir '/' filamentList{idx} '/crop.tbl']); 
    else
        if useMidRegionOnly > 0
            filamentAvg = dread([alnDir '/avg/' filamentList{idx} '_mid.em']);
        else
            filamentAvg = dread(ddb([filamentList{idx} ':a'])); % Read the path of the alignment project average
        end
        tPath = ddb([filamentList{idx} ':rt']);
	end
    disp(filamentList{idx})

	sal = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template,[1 alnLowpassPix]),'cr',10,'cs',5,'ir',360,'is',5,'dim',boxSize, 'limm',1,'lim',[5, 5, zshift_limit],'rf',3,'rff',2, 'cone_flip', coneFlip); % no cone_flip
	

	% Write out matrix for transformation
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
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned.tbl']);
	% Write aligned intraAvg
	dwrite(sal.aligned_particle, [alnDir '/avg/' filamentList{idx} '_aln.em']);

end

cd ..

%% Calculate average
newTemplate = newTemplate/noFilament;
dwrite(newTemplate, newRefFile);
