%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to average based on a tbl and particles
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo

run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage2/Thibault/20240905_SPEF1MTs/MTavg/';

%% Input
boxSize = 80;
pixelSize = 8.48;
avgFileName = '13PF_short.em';
particleDir = sprintf('%sparticles_repick', prjPath);
mw = 6; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
tableFileName = 'merged_particles_repick_13PF_short_align.tbl'; % merged particles table all
starFileName = 'merged_particles_repick_13PF_short2.star'; % star file name for merged particles, replace to the right particles
finalLowpass = 25; % Now implemented using in Angstrom

%%
% Combine all the particles into one table

tMerged = dread(tableFileName);

avg = daverage(starFileName, 't', tMerged, 'fc', 1, 'mw', mw);

dwrite(dynamo_bandpass(avg.average, [1 round(pixelSize/finalLowpass*boxSize)])*(-1), avgFileName);
