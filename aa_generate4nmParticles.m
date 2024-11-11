%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to generate 4-nm particles with similar angle
% Shift the table 4-nm
% Then combine and remove duplication
% NOTE: dynamo check for the particles when combining, so need to generate a fake folder
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%% Activate Dynamo
run  /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage2/Thibault/20240905_SPEF1MTs/MTavg/';

%% Input
particleDir = sprintf('%sparticles_repick', prjPath);
pixelSize = 8.48; % Angstrom per pixel
shiftA = 41.4; % Angstrom
boxSize = 80;
mw = 12;
dTh = 30; % distance threshold
starFile = 'merged_particles_repick_13PF_short.star';
tableAlnFileName = 'merged_particles_repick_13PF_short_align.tbl'; % merge particles before particle alignment for robust but must be merged_particles_align to use doInitialAngle
starShiftFile = 'merged_particles_repick_13PF_short_shift.star';
tableShiftFileName = ['merged_particles_repick_13PF_short_align_shift' num2str(shiftA) '.tbl'];

combinedStarFile = 'merged_particles_repick_13PF_4nm.star';
combinedTableFile = 'merged_particles_repick_13PF_4nm.tbl';

%% loop through all tomograms
tAll = dread(tableAlnFileName);


%% Transform the tomograms
Tp.type = 'shiftrot';
Tp.shifts = [0 0 shiftA/pixelSize];
Tp.eulers = [0 0 0];
	
tAll_shift = dynamo_table_rigid(tAll, Tp);

dwrite(tAll_shift, tableShiftFileName);



% Combine with previous table
targetFolder = {};
tableName ={};

targetFolder = {'merged_particles_repick_13PF_short.star', 'merged_particles_repick_13PF_short_shift.star' };
tableName = {tableAlnFileName, tableShiftFileName};

% create ParticleListFile object (this object only exists temporarily in matlab)
plfClean = dpkdata.containers.ParticleListFile.mergeDataFolders(targetFolder,'tables',tableName);

% create and write the .star file
plfClean.writeFile(combinedStarFile)

% create merged table
tMerged = plfClean.metadata.table.getClassicalTable();
dwrite(tMerged,combinedTableFile);

tMergedClean = dpktbl.exclusionPerVolume(tMerged, dTh/pixelSize);
dwrite(tMergedClean, 'removed.tbl');

