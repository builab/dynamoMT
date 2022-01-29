% Script to convert IMOD model to filament torsion model
% Using GUI https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Filament_model
% Imod coordinate should be in text file, clicking along the filament (no direction needed)
% model2point -Contour imodModel.mod imodModel.txt
% Write out the filament list/folder for further processing as well
% NOTE: Important to have tomogram number 

% Input
docFilePath = 'catalogs/tomograms.doc';
modelDir = 'models';
pixelsize = 8.48; % Angstrom per pixel
periodicity = 168; % Using 16-nm of doublet for DMT 
subunits_dphi = 0;  % for free microtubule but can be restricted in the cilia
subunits_dz = periodicity/pixelsize; % in pixel repeating unit dz = 8.4 nm = 168 Angstrom/pixelSize
%boxSize = 96; % Extracted subvolume size
%mw = 12; % Number of parallel worker to run
filamentListFile = 'filamentList.csv';

% Script
% loop through all tomograms
fileID = fopen(docFilePath); D = textscan(fileID,'%d %s'); fclose(fileID);
tomoID = D{1,1}'; % get tomogram ID
nTomo = length(D{1,2}); % get total number of tomograms

filamentList = {};

% Loop through tomograms
for idx = 1:nTomo
    tomo = D{1,2}{idx,1};
    [tomoPath,tomoName,ext] = fileparts(tomo);
    % Modify specific to name
    tomoName = strrep(tomoName, '_SIRT4_rec', '');
    imodModel = [modelDir '/' tomoName '.txt'];
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
        
        % Add to the list
        filamentList{end + 1} = [tomoName '_' num2str(contour(i))];

        % Testing this block
        t = m{i}.grepTable();
        dwrite(t, [modelDir '/' tomoName '_' num2str(contour(i)) '.tbl']);
        %dtcrop(docFilePath, t, ['particles/' tomoName '_' num2str(contour(i))], boxSize, 'mw', mw) % mw = number of workers to run
        % Optional for visualization of table
        %dtplot(['particles/' tomoName '_' num2str(contour(i)) '/crop.tbl'], 'pf', 'oriented_positions');
    end
    
    % Write the DynamoModel
    dwrite(m, modelout)

end

% Write out list file
writecell(filamentList, filamentListFile);
