%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to recrop new particles in the case of replacing
% tomograms with a new set of tomograms
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%% Before Running Script %%%%%%%%%%
%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';


%%%%%%% Variables subject to change %%%%%%%%%%%
docFilePath = sprintf('%scatalogs/tomogramsOld.doc', prjPath);
modelDir = sprintf('%smodels_repick', prjPath);
particleDir = sprintf('%sparticles_repick_test', prjPath);
c001Dir = sprintf('%scatalogs/c001', prjPath);
pixelSize = 8.48; % Angstrom per pixel
boxSize = 80;
mw = 12;
filamentListFile = sprintf('%sfilamentRepickList14PF.csv', prjPath);
avgLowpass = 30; % Angstrom

tableAllFileName = 'merged_particles_repick_14PF_align.tbl';
starFileName = 'merged_particles_repick_14PF.star';
my_vpr = 'pAlnRepickParticles14PF';
newRefFile = 'average_warpRepickParticles_14PF.em';

%%%%%%% Do not change anything under here %%%%%

%% loop through all tomograms
filamentList = readcell(filamentListFile, 'Delimiter', ',');


%% Loop through the list
targetFolder = {};
for idx = 1:size(filamentList, 1)
	tableName = [particleDir '/' filamentList{idx} '/crop.tbl'];
	targetFolder{idx} = [particleDir '/' filamentList{idx}];

    % 0.2b
	t = dread(tableName);

    dtcrop(docFilePath, t, targetFolder{idx}, boxSize, 'mw', mw);
    oa_all = daverage(targetFolder{idx}, 't', t, 'fc', 1, 'mw', mw);
    dwrite(dynamo_bandpass(oa_all.average, [1 round(pixelSize/avgLowpass*boxSize)]), [targetFolder{idx} '/average.em']);
end

%% Average everything


%plfNew = dpkdata.containers.ParticleListFile.read(starFileName);
output = dynamo_average(starFileName,'table',dread(tableAllFileName), 'fc', 1, 'mw', mw);
dwrite(output.average, newRefFile);
