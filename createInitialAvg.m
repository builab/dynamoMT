% Script to generate initial average

% Input
filamentListFile = 'filamentList.csv';
particleDir = 'particles';





filamentList = readcell(filamentListFile);

% Crop & generate initial average
for idx = 1:length(filamentList)
  tableName = [particleDir '/' filamentList{idx} '/crop.tbl'];
  disp(['Reading ' filamentList{idx}])
  
  

end
