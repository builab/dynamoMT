%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to do super particles
% Average every 7 particles into one
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Before Running Script %%%%%%%%%
%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';

%%%%%%%%

%%%%%%% Variables subject to change %%%%%%%%%%%
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
filamentListFile = sprintf('%sfilamentRepickList13PF.csv', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
superParticleDir = sprintf('%ssuperParticles_repick', prjPath);
pixelSize = 8.48; % Use to calculate lowpass
mw = 10; % Number of parallel workers to run
avgPart = 3; % Particle to average from the left/right side of the particles. Number avg = avgPart*2 + 1


%%%%%%% Do not change anything under here %%%%%
filamentList = readcell(filamentListFile, 'Delimiter', ',');

mkdir(superParticleDir)


%% Read the crop out and generate super particles
for idx = 1:length(filamentList)
%for idx = 1:1
  tableName = [particleDir '/' filamentList{idx} '/crop.tbl'];
  targetFolder = [particleDir '/' filamentList{idx}];
  disp(['Reading ' filamentList{idx}]);

  tImport = dread(tableName);
  template = dread([particleDir '/' filamentList{idx} '/template.em']);
  noPart = max(tImport(:, 1)); % Highest particles number is a lot more robust
  
  mkdir([superParticleDir '/' filamentList{idx}]);
  
  % Generating super particles
  for i = 1:noPart
    	if isfile([particleDir '/' filamentList{idx} '/particle_' sprintf('%0.6d', i) '.em']) == 0
    		continue;
    	end
	if (i < 4)
		startPart = 1;
	else
		startPart = i - 3;
	end
	
	if (i > noPart - 3)
		endPart = noPart;
	else
		endPart = i + 3;
	end
	superPart = zeros(size(template));
	for j = startPart:endPart
		partFile = [particleDir '/' filamentList{idx} '/particle_' sprintf('%0.6d', j) '.em'];
	   	if isfile(partFile)
    			superPart = superPart + dread(partFile);
    		end
	end	  	
	dwrite(superPart, [superParticleDir '/' filamentList{idx} '/particle_' sprintf('%0.6d', i) '.em']);
	dwrite(tImport, [superParticleDir '/' filamentList{idx} '/crop.tbl']);
	dwrite(template, [superParticleDir '/' filamentList{idx} '/template.em']);
  end
end


