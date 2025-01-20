%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to sort MT into 13 or 14 PF with a polarity check
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Polarity check & compare to different PF (12,13,14,15). 
% Perhaps, can check 12 & 15 manually later to see if 16 or 11 is there
% The new list will contain 3 columns (Filament, polarity, number_of_PFs)

%%%%%%%% Before Running Script %%%%%%%%%%%%%%%

%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';


%%%%%%% Variables subject to change %%%%%%%%%%%
pixelSize = 8.48;
boxSize = 80;
filamentListFile = 'filamentListTwist.csv';
alnDir = sprintf('%sintraAln_twist', prjPath);
particleDir = sprintf('%sparticles_twist', prjPath);
previewDir =[alnDir '/preview']; % created previously
mw = 12; % Number of parallel workers to run
gpu = [0]; % Alignment using gpu
initRefFiles = {'templates/12PF_8.48Apx.em', 'templates/13PF_8.48Apx.em', 'templates/14PF_8.48Apx.em', 'templates/15PF_8.48Apx.em'};
refPFs = [12 13 14 15];
coneFlip = 1; % Search for polarity. 1 is yes.
avgLowpass = 25; % Angstrom
alnLowpass = 25; % Angstrom
shiftLimit = [10 10 5]; % Limit XYZ in pixel. Z should be half of periodicity
newRefFile = 'sortPF.em';
filamentPFListFile = sprintf('%sfilamentPFList.csv', prjPath);


%%%%%%% Do not change anything under here %%%%%

filamentList = readcell(filamentListFile, 'Delimiter', ',');
noFilament = length(filamentList);
alnLowpassPix = round(pixelSize/alnLowpass*boxSize);
newTemplate = {};

template = {};
for refIdx = 1:length(initRefFiles)
	template{refIdx} = dread(initRefFiles{refIdx});
	newTemplate{refIdx} = zeros(boxSize, boxSize, boxSize);
end

filamentPFList = {};


% Need to go into alnDir to read the intraAln project
cd(alnDir)

%% Calculate the alignment of the filamentAverage to the initial reference
% transform the corresponding table for all particles
for idx = 1:noFilament
%for idx = 1:10
	aPath = ddb([filamentList{idx} ':a']); % Read the path of the alignment project average
	tPath = ddb([filamentList{idx} ':rt']);
	filamentAvg = dread(aPath);
  	disp(['Align ' filamentList{idx}]);
  	sal = {};
  	maxCC = 0;
  	maxPF = 0;
  	for refIdx = 1:length(template)
  		sal{refIdx} = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template{refIdx},[1 alnLowpassPix]),'cr',10,'cs',5,'ir',360,'is',10,'dim',boxSize, 'limm',1,'lim',shiftLimit,'rf',2,'rff',2, 'cone_flip', coneFlip); % cone_flip
		if sal{refIdx}.ccmax(end) > maxCC
			maxCC = sal{refIdx}.ccmax(end);
			maxPF = refIdx;
		end
	end
	
	% Write out the transform
	writematrix([sal{maxPF}.p_shifts sal{maxPF}.p_eulers], [particleDir '/' filamentList{idx} '/xform.tbl'], 'Delimiter', 'tab', 'FileType', 'text');
	
	% Write out preview
	newTemplate{maxPF} = newTemplate{maxPF} + sal{maxPF}.aligned_particle;
	filt_aligned_particle = dynamo_bandpass(sal{maxPF}.aligned_particle, [1 round(pixelSize/avgLowpass*boxSize)]);
	img = sum(filt_aligned_particle(:,:,floor(boxSize/2) - 10: floor(boxSize/2) + 10), 3);
	imwrite(mat2gray(img), [previewDir '/' filamentList{idx} '_aln_' num2str(refPFs(maxPF)) 'PF.png']);
	% Read last table from alignment
	tFilament = dread(tPath);
	% Read last transformation & applied to table
	tFilament_ali = dynamo_table_rigid(tFilament, sal{maxPF}.Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned.tbl']);
	% Write aligned intraAvg
	dwrite(sal{maxPF}.aligned_particle, [alnDir '/avg/' filamentList{idx} '_aln_' num2str(refPFs(maxPF)) 'PF.em']);
	
	% Read polarity here
	if abs(sal{maxPF}.p_eulers(2)) > 90
		% Flipping polarity
		filamentPFList{idx, 2} = 1;
	else
		% Not flipping polarity
		filamentPFList{idx, 2} = 0;
	end
	
	disp([filamentList{idx} ' Polarity ' num2str(filamentPFList{idx, 2}) ' ' num2str(refPFs(maxPF)) ' PFs']);
	% Write PF list
	filamentPFList{idx, 1} = filamentList{idx};
	filamentPFList{idx, 3} = refPFs(maxPF);
	   
end
 
cd ..

%% Calculate average
writecell(filamentPFList, filamentPFListFile);

% Write separate list files for different PFs
numPF = cell2mat(filamentPFList(:, 3));
for refIdx = 1:length(refPFs)
	subFilamentList = filamentPFList(numPF == refPFs(refIdx), :);
	if isempty(subFilamentList)
		disp(['No filament with ' num2str(refPFs(refIdx)) ' protofilaments']);
	else
		writecell(subFilamentList, strrep(filamentPFListFile, '.csv', [num2str(refPFs(refIdx)) 'PF.csv']));
		newTemplate{refIdx} = newTemplate{refIdx}/length(subFilamentList);
		dwrite(newTemplate{refIdx}, strrep(newRefFile, '.em', [num2str(refPFs(refIdx)) '_class.em']))
	end
end
