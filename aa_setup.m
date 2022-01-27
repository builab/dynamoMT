%%%%%%%%%%%%%%%%%%%%
% Set up the project
%%%%%%%%%%%%%%%%%%%%
% Import tomogram & create catalog using the GUI
catPath = '../catalogues/c001';
docFilePath = '../catalogues/tomograms.doc'; % This has to be consistent with the vll after catalog creation
vllFilePath = '../catalogues/tomograms.vll';

% If using command line
%dcm -create c001 -fromvll myList.vll

% Import coordinate picked from IMOD using filament torsion model

% Crop data
