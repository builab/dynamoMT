%%%%%%%%%%%%%%%%%%%%
% Set up the project
%%%%%%%%%%%%%%%%%%%%
% Import tomogram & create catalog using the GUI
catPath = '../catalogs/c001';
docFilePath = '../catalogues/tomograms.doc'; % This has to be consistent with the vll after catalog creation
vllFilePath = '../catalogues/tomograms.vll';

% If using command line
cd catalogs
dcm -create c001 -fromvll tomograms.vll

% Import coordinate picked from IMOD using filament torsion model
% Using GUI https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Filament_model
% Imod coordinate should be in Text file, clicking along the filament (no direction needed)
% model2point
% Need to separate point by model file
imodModel = 'test.text'
points = load(imodModel);
pathFilament   = dmodels.filamentWithTorsion();
% we provide parameters for the individual geometries:

% filament with subunits on path. Radius is not required.
pathFilament.subunits_dphi = 0; % for free microtubule but can be restricted in the cilia
pathFilament.subunits_dz   = 10;

    


%%
% we create a figure to depict 
figure(1);clf; 

% loops on each model

% we create a cell array variable containing all models so that we can loop on it 
f = {pathFilament,helixFilament,ringFilament,randomFilament};

for i=1:length(f);
    
    % provides the same points to each filament type
    f{i}.points = points;
    
    % creates a backbone
    f{i}.backboneUpdate();
        

    % creates the crop points
    f{i}.updateCrop();
    
    % creates a subplot for each model
    h = subplot(1,4,i); % array of 1 row and 4 columns
    
    
    f{i}.plotPoints(h,'refresh',false,'hold_limits',false);        % plots points delivered by the user
    %f{i}.plotTablePoints(h,'refresh',false,'hold_limits',false);   % plots computed table Points
    f{i}.plotTableSketch(h,'refresh',false,'hold_limits',true);   % plots computed table directions
    
    % sets as title of each plot the class of the filament 
    title(class(f{i}));
     axis(h,'equal');
    axis(h,[-20,120,-20,120,-20,120]); % visualization limits
   
    
    drawnow; % updates the plot
end


% Crop data
