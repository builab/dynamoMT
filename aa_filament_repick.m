%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to convert IMOD model to filament torsion model
% dynamoDMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using GUI https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Filament_model
% Imod coordinate should be in text file, clicking along the filament (no direction needed)
% model2point -Contour imodModel.mod imodModel.txt
% Write out the filament list/folder for further processing as well
% NOTE: Important to have tomogram number 
% NOTE: If the filament twist (microtubule/CP), we need to define subunits_dphi to describe the torsion.
% however, it might be related to the polarity of the filament (- or + sign).
% Perhaps, should use a nearest neighbour guessing of angle

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/tip_CP_dPhi/';

%%%%%%%%

% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
modelDir = sprintf('%smodels_repick', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
c001Dir = sprintf('%scatalogs/c001', prjPath);
pixelsize = 8.48; % Angstrom per pixel
periodicity = 82.8; % Using 16-nm of doublet for DMT 
boxSize = 96;
subunits_dphi = 0.72;  % For the tip CP
subunits_dz = periodicity/pixelsize; % in pixel repeating unit dz = 8.4 nm = 168 Angstrom/pixelSize
filamentListFile = sprintf('%sfilamentList.csv', prjPath);
tableAlnFileName = 'merged_particles_aln.tbl'; % merge particles after alignment


% loop through all tomograms
fileID = fopen(docFilePath); D = textscan(fileID,'%d %s'); fclose(fileID);
tomoID = D{1,1}'; % get tomogram ID
nTomo = length(D{1,2}); % get total number of tomograms

tblAll = dread(tableAlnFileName);

% Loop through tomograms
for idx = 1:nTomo
    tomo = D{1,2}{idx,1};
    [tomoPath,tomoName,ext] = fileparts(tomo);
    tomono = D{1,1}(idx);
    % Modify specific to name
    tomoName = strrep(tomoName, '_rec', ''); % Remove the rec part of the name
    tableTomo = tblAll(tblAll(:,20) == tomono, :);

	modelout =   [modelDir '/' tomoName '.omd']  
    points = tableTomo(:, 24:26) + tableTomo(:, 4:6);
    
    contour = [1];
    % Compatible with doublet microtubule
    m = {}; % Cell array contains all filament
	for i = 1:length(contour)
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
    	m{i}.linkCatalogue(c001Dir, 'i', idx);
    	m{i}.saveInCatalogue();
        
    	t = m{i}.grepTable();
    	dwrite(t, [modelDir '/' tomoName '_' num2str(contour(i)) '.tbl']);
    	targetFolder = [particleDir '/'  tomoName '_' num2str(contour(i))];
  		% Cropping subtomogram out
  		dtcrop(docFilePath, t, targetFolder, boxSize, 'mw', mw);
  		oa = daverage(targetFolder, 't', t, 'fc', 1, 'mw', mw);
  		dwrite(dynamo_bandpass(oa.average, [1 lowpass]), [targetFolder '/template.em']);
    end 
    % Write the DynamoModel
    dwrite(m, modelout);
end
