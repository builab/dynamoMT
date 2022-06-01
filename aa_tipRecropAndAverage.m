%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to average the tip complex with bigger box size
% dynamoDMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/tip_complex/';

%%%%%%%%

% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
newBoxSize = 220;
pixelSize = 8.48;
lowpass = 40; % 40 Angstrom for the tip complex
mw = 12;
tableAlnFileName = 'merged_particles_align.tbl'; % merge particles after alignment

tblAll = dread(tableAlnFileName);

% Crop with new parameters
dtcrop(docFilePath, tblAll, particleDir, newBoxSize);

% Average using the new table to avoid missing particles
tRecrop = dread([particleDir '/crop.tbl']);
oa = daverage(particleDir, 't', tRecrop, 'fc', 1, 'mw', mw);
dwrite(dynamo_bandpass(oa.average, [1 round(pixelSize/lowpass*newBoxSize)]), ['tip_complex_b' num2str(newBoxSize) '.em']);
