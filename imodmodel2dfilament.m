% Import coordinate picked from IMOD using filament torsion model
% Using GUI https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Filament_model
% Imod coordinate should be in Text file, clicking along the filament (no direction needed)
% model2point -Contour imodModel.mod imodModel.txt
imodModel = 'TS_11_1.txt'
allpoints = load(imodModel);

for filamentid = 1:len(unique(allpoints)
  points = allpoints(allpoints(:, 1) = filamentid, 2:4);
end

pathFilament   = dmodels.filamentWithTorsion();
pathFilament.subunits_dphi = 0; % for free microtubule but can be restricted in the cilia
pathFilament.subunits_dz   = 10; % dz = 8.4 nm = 84 Angstrom/pixelSize

% Import coordinate
pathFilament.points = points;
    
% creates a backbone
pathFilament.backboneUpdate();
        
% creates the crop points
pathFilament.updateCrop();

% Write the DynamoModel

