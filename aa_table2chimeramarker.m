%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to manually assign rot angle for singlets
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20221128_TetraCU428Membrane_26k_TS/singlet/';

%%%%%%%%

%% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
modelDir = sprintf('%smodels', prjPath);
outCmm = 'singlet.cmm';
radius = 3;
tableAlnFileName = 'merged_particles_align.tbl'; % merge particles after particle alignment for robust 


% Read the list of filament to work with
tAll = dread(tableAlnFileName);

% Reset the origin
tAll_adjusted = tAll;

tAll_adjusted(24:26, :) = tAll(24:26, :) + floor(tAll(4:6, :));
tAll_adjusted(4:6, :) = tAll(4:6, :) - floor(tAll(4:6, :));

dynamo_table2chimeramarker([modelDir '/' outCmm], tAll_adjusted, radius);