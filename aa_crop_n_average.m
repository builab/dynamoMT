% Script to generate initial average

% Input
docFilePath = 'catalogs/tomograms.doc';
filamentListFile = 'filamentList.csv';
modelDir = 'models';
particleDir = 'particles';
boxSize = 96; % Extracted subvolume size
mw = 12; % Number of parallel workers to run
lowpass = 40; % Filter the initial average to 40 Angstrom


filamentList = readcell(filamentListFile);

% Crop & generate initial average
for idx = 1:length(filamentList)
  tableName = [modelDir '/' filamentList{idx} '.tbl'];
  targetFolder = [particleDir '/' filamentList{idx}];
  disp(['Reading ' filamentList{idx}]);
  tImport = dread(tableName);

  
  % Cropping subtomogram outt
  dtcrop(docFilePath, tImport, targetFolder, boxSize, 'mw', mw); % mw = number of workers to run
  
  % Plotting (might not be optimum since plotting everything here)
  dtplot(tImport, 'pf', 'oriented_positions');
  
  % Generate average from 10 particles for template generation
  midIndex = floor(length(tImport)/2);
  tImport = tImport(midIndex - 5: midIndex + 5, :);
  oa = daverage(targetFolder, 't', tImport, 'fc', 1, 'mw', mw);
  dwrite(dynamo_bandpass(oa.average, [1 lowpass]), [targetFolder '/template.em']);
end
