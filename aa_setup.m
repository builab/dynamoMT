%%%%%%%%%%%%%%%%%%%%
% Set up the project
%%%%%%%%%%%%%%%%%%%%
% Import tomogram & create catalog using the GUI
catPath = 'catalogs/c001';
docFilePath = 'catalogs/tomograms.doc'; % This has to be consistent with the vll after catalog creation
vllFilePath = 'catalogs/tomograms.vll';


% Create new catalogue from vll file, delete old one
dcm('c', catPath, 'fromvll', vllFilePath, 'delete_old', 1)

% Import model
run imodmodel2filament.m

% Convert to table & crop

