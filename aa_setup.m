%%%%%%%%%%%%%%%%%%%%
% Set up the project
%%%%%%%%%%%%%%%%%%%%
% Import tomogram & create catalog using the GUI
catPath = '../catalogs/c001';
docFilePath = '../catalogues/tomograms.doc'; % This has to be consistent with the vll after catalog creation
vllFilePath = '../catalogues/tomograms.vll';

% If using command line
cd catalogs
% Create new catalogue from vll file, delete old one
dcm -create c001 -fromvll tomograms.vll -delete_old 1

% Crop data
