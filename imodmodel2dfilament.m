% Import coordinate picked from IMOD using filament torsion model
% Using GUI https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Filament_model
% Imod coordinate should be in Text file, clicking along the filament (no direction needed)
% model2point -Contour imodModel.mod imodModel.txt

% Input
docFilePath = '../tomograms.doc';
subunits_dphi = 0;  % for free microtubule but can be restricted in the cilia
subunits_dz = 10; % repeating unit dz = 8.4 nm = 84 Angstrom/pixelSize
% Script


imodModel = 'TS_11_doublet.txt'
modelout = strrep(imodModel, '.txt', '.omd');

allpoints = load(imodModel);

m = {} % Cell array contains all filament
contour = unique(allpoints(:, 1)
for i = 1:len(contour)
  filamentid = contour(i)
  points = allpoints(allpoints(:, 1) = contour, 2:4);
  m{i} = dmodels.filamentWithTorsion();
  m{i}.subunits_dphi = subunits_dphi;
  m{i}.subunits_dz = subunits_dz;
  % Import coordinate
  m{i}.points = points;
  % Create backbone
  m{i}.backboneUpdate();
  % Update crop point (can change dz)
  m{i}.updateCrop();

end

% Write the DynamoModel
dwrite(m, modelout)
% Link to catalog
m.linkCatatalogue('myCatalogue', 'i', 1);
m.saveInCatalogue();
