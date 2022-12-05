%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to move the origin of the subtomo for new table, cmm file & imod file
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: Box center = BoxSize/2 + 1
% Shift vector = NewOrigin - Box center

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20221128_TetraCU428Membrane_26k_TS/doublet_16nm/';

%%%%%%%%
%% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
modelDir = sprintf('%smodels', prjPath);
tableAlnFileName = 'particles_segment/all.tbl'; % merge particles after particle alignment for robust 
shiftVector = [-6 0 0]; % Shift vector in pixel, measure from the map just like relion (-6 for Atubule, 10 for B-tubule)

outCmm = 'doublet_Atub.cmm';
outImod = 'doublet_Atub.txt';
outTbl = 'doublet_Atub.tbl';
radius = 6;


% Read the list of filament to work with
tOri = dread(tableAlnFileName);

% Transform table
T = dynamo_rigid('shifts', -shiftVector); % create transformation
tOri_shift = dynamo_table_rigid(tOri, T); % transform table

% Reset the origin
tOri_adjusted = tOri_shift;

tOri_adjusted(:, 24:26) = tOri_shift(:, 24:26) + round(tOri_shift(:, 4:6));
tOri_adjusted(:, 4:6) = tOri_shift(:, 4:6) - round(tOri_shift(:, 4:6));

dwrite(tOri_shift, [modelDir '/' outTbl]);
dynamo_table2chimeramarker([modelDir '/' outCmm], tOri_adjusted, radius);

dlmwrite([modelDir '/' outImod], tOri_adjusted(:, 23:26), 'delimiter', ' ');

% You can do 'point2model singlet.txt singlet.mod'