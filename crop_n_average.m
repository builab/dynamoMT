% Script to generate initial average

% Input
docFilePath = 'catalogs/tomograms.doc';
filamentListFile = 'filamentList.csv';
modelDir = 'models';
particleDir = 'particles';
boxSize = 96; % Extracted subvolume size
mw = 12; % Number of parallel workers to run


filamentList = readcell(filamentListFile);

% Crop & generate initial average
for idx = 1:length(filamentList)
  tableName = [modelDir '/' filamentList{idx} '.tbl'];
  targetFolder = [particleDir '/' filamentList{idx}];
  disp(['Reading ' filamentList{idx}]);
  tImport = dread(tableName);

  
  % Cropping subtomogram outt
  dtcrop(docFilePath, tImport, targetFolder, boxSize, 'mw', mw); % mw = number of workers to run
  
  % Generate average from 10 particles for template generation
  midIndex = floor(length(tImport)/2);
  tImport = tImport(midIndex - 5: midIndex + 5, :);
  oa = daverage(targetFolder, 't', tImport, 'fc', 1, 'mw', mw);
  dwrite(oa.average, [targetFolder '/template.em']);
end
