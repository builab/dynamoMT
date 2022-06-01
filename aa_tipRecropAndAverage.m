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
modelDir = sprintf('%smodels_repick', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
c001Dir = sprintf('%scatalogs/c001', prjPath);
pixelsize = 8.48; % Angstrom per pixel
newBoxSize = 200;
mw = 12;
filamentListFile = sprintf('%sfilamentListOne.csv', prjPath);
tableAlnFileName = 'merged_particles_align.tbl'; % merge particles after alignment
lowpass = 27; % Filter to 30A


% loop through all tomograms
fileID = fopen(docFilePath); D = textscan(fileID,'%d %s'); fclose(fileID);
tomoID = D{1,1}'; % get tomogram ID
nTomo = length(D{1,2}); % get total number of tomograms

tblAll = dread(tableAlnFileName);

% Loop through tomograms
dtcrop(docFilePath, tblAll, particleDir, newBoxSize);
oa = daverage(particleDir, 't', tblAll, 'fc', 1, 'mw', mw);
dwrite(dynamo_bandpass(oa.average, [1 lowpass]), 'tip_complex_recrop.em');

exit
%
for idx = 1:nTomo
    tomo = D{1,2}{idx,1};
    [tomoPath,tomoName,ext] = fileparts(tomo);
    tomono = D{1,1}(idx);
    % Modify specific to name
    tomoName = strrep(tomoName, '_rec', ''); % Remove the rec part of the name
    tableTomo = tblAll(tblAll(:,20) == tomono, :);
    tableTomo(:, 24:26) = tableTomo(:, 24:26) + tableTomo(:, 4:6); % adjust origin
    tableTomo(:, 4:6) = tableTomo(:, 4:6)*0; % Reset origin
    
    dwrite(tableTomo, [particleDir '/' tomoName '_1.tbl']);
    targetFolder = [particleDir '/'  tomoName '_1'];
  	% Cropping subtomogram out
  	dtcrop(docFilePath, tableTomo, targetFolder, newBoxSize, 'mw', mw);
end
