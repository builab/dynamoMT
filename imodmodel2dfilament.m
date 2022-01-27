% Script to convert IMOD model to filament torsion model
% Using GUI https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Filament_model
% Imod coordinate should be in text file, clicking along the filament (no direction needed)
% model2point -Contour imodModel.mod imodModel.txt

% Input
docFilePath = 'catalogs/tomograms.doc';
modelPath = 'models';
pixelsize = 8.48; % Angstrom per pixel
periodicity = 84; % Periodicity of tubulin
subunits_dphi = 0;  % for free microtubule but can be restricted in the cilia
subunits_dz = periodicity/pixelsize; % in pixel repeating unit dz = 8.4 nm = 84 Angstrom/pixelSize

% Script
% loop through all tomograms
fileID = fopen(docFilePath); D = textscan(fileID,'%d %s'); fclose(fileID);
tomoID = D{1,1}'; % get tomogram ID
nTomo = length(D{1,2}); % get total number of tomograms

% Loop through tomograms
for idx = 1:nTomo
    tomo = D{1,2}{idx,1};
    [tomoPath,tomoName,ext] = fileparts(tomo);
    % Modify specific to name
    tomoName = strrep(tomoName, '_SIRT4_rec', '');
    imodModel = [modelPath '/' tomoName '.txt'];
    modelout = strrep(imodModel, '.txt', '.omd');
    
    allpoints = load(imodModel);
    
    m = {}; % Cell array contains all filament
    contour = unique(allpoints(:, 1));
    % Loop through filaments
    for i = 1:length(contour)
        filamentid = contour(i);
        points = allpoints(allpoints(:, 1) == filamentid, 2:4);
        m{i} = dmodels.filamentWithTorsion();
        m{i}.subunits_dphi = subunits_dphi;
        m{i}.subunits_dz = subunits_dz;
        m{i}.name = [tomoName '_' num2str(contour(i))];
        % Import coordinate
        m{i}.points = points;
        % Create backbone
        m{i}.backboneUpdate();
        % Update crop point (can change dz)
        m{i}.updateCrop();
        % Link to catalog
        m{i}.linkCatalogue('catalogs/c001', 'i', idx);
        m{i}.saveInCatalogue();
    end
    
    % Write the DynamoModel
    dwrite(m, modelout)

end
