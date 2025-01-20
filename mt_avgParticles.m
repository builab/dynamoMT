%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to use info from super particles and 
% average the normal particles
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo

run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';

%% Input
boxSize = 80;
pixelSize = 8.48;
avgFileName = '14PF_test.em';
particleDir = sprintf('%sparticles_repick_test', prjPath);
mw = 6; % Number of parallel workers to run
gpu = [0]; % Alignment using gpu
tableFileName = 'merged_particles_repick_14PF_align.tbl'; % merged particles table all
starFileName = 'merged_particles_repick_14PF_test.star'; % star file name for merged particles, replace to the right particles
finalLowpass = 25; % Now implemented using in Angstrom

%%
% Combine all the particles into one table

tMerged = dread(tableFileName);

avg = daverage(starFileName, 't', tMerged, 'fc', 1, 'mw', mw);

dwrite(dynamo_bandpass(avg.average, [1 round(pixelSize/finalLowpass*boxSize)]), avgFileName);
