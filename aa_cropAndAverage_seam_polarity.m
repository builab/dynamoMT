%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to generate initial average
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage2/Thibault/20240905_SPEF1MTs/MTavg/';

%%%%%%%%

%% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
filamentListFile = sprintf('%sfilamentListFix.csv', prjPath);
modelDir = sprintf('%smodels', prjPath);
particleDir = sprintf('%sparticles_twist', prjPath);
pixelSize = 8.48; % Use to calculate lowpass
boxSize = 80; % Extracted subvolume size
mw = 12; % Number of parallel workers to run
lowpass = 60; % In Angstrom Filter the initial average to 60
minPartNo = 4; % Minimum particles number per Filament 4 is reasonable


% Read the list of filament to work with
filamentList = readcell(filamentListFile, 'Delimiter', ',');

filamentListNew = {};

%% Crop & generate initial average
for idx = 1:length(filamentList)
  tableName = [modelDir '/' filamentList{idx} '.tbl'];
  targetFolder = [particleDir '/' filamentList{idx}];
  disp(['Reading ' filamentList{idx}]);
  tImport = dread(tableName);
  
  % Cropping subtomogram out
  % v0.2b catching exception
  try
  	dtcrop(docFilePath, tImport, targetFolder, boxSize, 'mw', mw);
  
  	% Generate average from ~10 middle particles for template generation
  	% Error might be generated here, using tCrop instead of tImport will be a lot safer
  	tCrop = dread([targetFolder '/crop.tbl']);
  	if size(tCrop, 1) > 15
    		midIndex = floor(size(tCrop, 1)/2);
      		tCrop = tCrop(midIndex - 3: midIndex + 4, :);
  	end 

	 % Extra line to reset rotation angle for initial reference
 	tCrop(:, 9) = tCrop(:, 9)*0;
 
  	oa = daverage(targetFolder, 't', tCrop, 'fc', 1, 'mw', mw);
  	dwrite(dynamo_bandpass(oa.average, [1 round(pixelSize/lowpass*boxSize)]), [targetFolder '/template.em']);
  	if size(tCrop, 1) > 1 % dtplot error with one particle
  		dtplot([targetFolder '/crop.tbl'], 'pf', 'oriented_positions');
  		view(-230, 30); axis equal;
  		print([targetFolder '/pick_' filamentList{idx}] , '-dpng');
  		close all
  	end
  catch
  	warning(['Skip: Contour ' filamentList{idx} 'does not have enough particles!'])
  	continue;
  end
  if size(tImport, 1) < minPartNo
    disp(['Skip ' tomoName ' Contour ' num2str(contour(i)) ' with less than ' num2str(minPartNo) ' particles'])
    continue
  end
  % If cropping working well and more than minimum particles
  filamentListNew{end + 1, 1} = filamentList{idx};
end

%% 0.2b Writing new list
if size(filamentListNew, 1) < size(filamentList, 1)
	% Backup old filamentList & write new one
	copyfile(filamentListFile, [filamentListFile '.bak']);
	writecell(filamentListNew, filamentListFile);
end
