%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to generate 4-nm particles with similar angle
% Shift the table 4-nm
% Then combine and remove duplication
% NOTE: dynamo check for the particles when combining, so need to generate a fake folder
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO: Short the new filament to incorporate the HelicalID and Track

%%%%%%%% Before Running Script %%%%%%%%%%
%% Activate Dynamo
run  /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';

%% Input
particleDir = sprintf('%sparticles_repick', prjPath);
pixelSize = 8.48; % Angstrom per pixel
shiftA = 42.2; % Angstrom
boxSize = 80;
mw = 12;
dTh = 30; % distance threshold
starFile = 'merged_particles_repick_14PF.star';
tableAlnFileName = 'merged_particles_repick_14PF_align.tbl'; % merge particles before particle alignment for robust but must be merged_particles_align to use doInitialAngle
starPlusShiftFile = 'merged_particles_repick_14PF_shift_plus.star';
starMinusShiftFile = 'merged_particles_repick_14PF_shift_minus.star';
tablePlusShiftFileName = ['merged_particles_repick_14PF_align_shift_plus' num2str(shiftA) '.tbl'];
tableMinusShiftFileName = ['merged_particles_repick_14PF_align_shift_minus' num2str(shiftA) '.tbl'];

combinedShiftStarFile = 'merged_particles_repick_14PF_shift.star';
combinedShiftTableFile = ['merged_particles_repick_14PF_align_shift' num2str(shiftA) '.tbl'];
combinedStarFile = 'merged_particles_repick_14PF_4nm.star';
combinedTableFile = 'merged_particles_repick_14PF_4nm.tbl';

%% loop through all tomograms
tAll = dread(tableAlnFileName);


%% Transform the tomograms
Tp_plus.type = 'shiftrot';
Tp_plus.shifts = [0 0 shiftA/pixelSize];
Tp_plus.eulers = [0 0 0];
tAll_shift_plus = dynamo_table_rigid(tAll, Tp_plus);
dwrite(tAll_shift_plus, tablePlusShiftFileName);

Tp_minus = Tp_plus;
Tp_minus.shifts = [0 0 -shiftA/pixelSize];
tAll_shift_minus = dynamo_table_rigid(tAll, Tp_minus);
dwrite(tAll_shift_minus, tableMinusShiftFileName);


% Combine Shift Table File
targetFolders = {};
tableName ={};

targetFolders = {starPlusShiftFile, starMinusShiftFile};
tableName = {tablePlusShiftFileName, tableMinusShiftFileName};

% create ParticleListFile object (this object only exists temporarily in matlab)
plfCleanShift = dpkdata.containers.ParticleListFile.mergeDataFolders(targetFolders,'tables',tableName);

% create and write the .star file
plfCleanShift.writeFile(combinedShiftStarFile)

% create merged table
tMergedShift = plfCleanShift.metadata.table.getClassicalTable();
tMergedShiftClean = dpktbl.exclusionPerVolume(tMergedShift, dTh/pixelSize);
dwrite(tMergedShiftClean, combinedShiftTableFile);

% Combine 4nm 

targetFolders = {starFile, starPlusShiftFile, starMinusShiftFile};
tableName = {tableAlnFileName, tablePlusShiftFileName, tableMinusShiftFileName};

plfClean = dpkdata.containers.ParticleListFile.mergeDataFolders(targetFolders,'tables',tableName);
plfClean.writeFile(combinedStarFile)

% create merged table
tMerged = plfClean.metadata.table.getClassicalTable();
tMergedClean = dpktbl.exclusionPerVolume(tMerged, dTh/pixelSize);
dwrite(tMergedClean, combinedTableFile);


