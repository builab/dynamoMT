%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to generate initial average
% dynamoDMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/tip_CP_dPhi/';

%%%%%%%%

% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
filamentListFile = sprintf('%sfilamentList.csv', prjPath);
modelDir = sprintf('%smodels', prjPath);
particleDir = sprintf('%sparticles', prjPath);
boxSize = 96; % Extracted subvolume size
mw = 12; % Number of parallel workers to run
lowpass = 16; % Filter the initial average to 60

% Read the list of filament to work with
filamentList = readcell(filamentListFile, 'Delimiter', ',');

% Crop & generate initial average
for idx = 1:length(filamentList)
  tableName = [modelDir '/' filamentList{idx} '.tbl'];
  targetFolder = [particleDir '/' filamentList{idx}];
  disp(['Reading ' filamentList{idx}]);
  tImport = dread(tableName);
  
  % Cropping subtomogram out
  dtcrop(docFilePath, tImport, targetFolder, boxSize, 'mw', mw);
  
  % Plotting (might not be optimum since plotting everything here)
  dtplot(tImport, 'pf', 'oriented_positions');
  
  % Generate average from ~10 middle particles for template generation
  % Error might be generated here
  midIndex = floor(size(tImport, 1)/2);
  if size(tImport, 1) > 15
      tImport = tImport(midIndex - 3: midIndex + 4, :);
  end 
 
  oa = daverage(targetFolder, 't', tImport, 'fc', 1, 'mw', mw);
  dwrite(dynamo_bandpass(oa.average, [1 lowpass]), [targetFolder '/template.em']);
  dtplot([targetFolder '/crop.tbl'], 'pf', 'oriented_positions');
	view(-230, 30);axis equal;
	print([targetFolder '/pick_' tomoName] , '-dpng');
end
