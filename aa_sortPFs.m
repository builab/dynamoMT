%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to sort MT into 13 or 14 PF
% Also check for polarity
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TODO
% Incoporate the subunit initial rot angle (tdrot)
% TODO Incorporate random rotation for microtubule alignment?

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage2/Thibault/20240905_SPEF1MTs/MTavg/';

%% Input
pixelSize = 8.48;
boxSize = 80;
filamentListFile = 'filamentList.csv';
alnDir = sprintf('%sintraAln_twist', prjPath);
particleDir = sprintf('%sparticles_twist', prjPath);
previewDir =[alnDir '/preview']; % created from previously
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
initRefFiles = {'ref_MT13PF_SPEF1_new.em', 'ref_MT14PF_SPEF1_new.em'};
refPFs = [13 14];
coneFlip = 1; % Search for polarity. 1 is yes. Recommended to pick with polarity and set to 0
avgLowpass = 25; % Angstrom
alnLowpass = 25; % Angstrom
shiftLimit = [10 10 5]; % Limit Z in pixel half of periodicity
newRefFile = 'reference_intraAln.em';
filamentPFListFile = sprintf('%sfilamentPFList.csv', prjPath);


%%
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
  	
  	sal = {};
  	maxCC = 0;
  	maxPF = 0;
  	for refIdx = 1:length(template)
  		sal{refIdx} = dalign(dynamo_bandpass(filamentAvg,[1 alnLowpassPix]), dynamo_bandpass(template{refIdx},[1 alnLowpassPix]),'cr',10,'cs',5,'ir',360,'is',10,'dim',boxSize, 'limm',1,'lim',shiftLimit,'rf',5,'rff',2, 'cone_flip', coneFlip); % cone_flip
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
	imwrite(mat2gray(img), [previewDir '/' filamentList{idx} '_aln.png']);
	% Read last table from alignment
	tFilament = dread(tPath);
	% Read last transformation & applied to table
	tFilament_ali = dynamo_table_rigid(tFilament, sal{maxPF}.Tp);
	% Write table
	dwrite(tFilament_ali, [particleDir '/' filamentList{idx} '/aligned.tbl']);
	% Write aligned intraAvg
	dwrite(sal{maxPF}.aligned_particle, [alnDir '/avg/' filamentList{idx} '_aln.em']);
	
	% Read polarity here
	if abs(sal{maxPF}.p_eulers(2)) > 90
		% Flipping polarity
		filamentPFList{idx, 2} = 1;
	else
		% Not flipping polarity
		filamentPFList{idx, 2} = 0;
	end
	
	disp([num2str(idx) ' ' num2str(maxPF)]);
	% Write PF list
	filamentPFList{idx, 1} = filamentList{idx};
	filamentPFList{idx, 3} = refPFs(maxPF);
	   
end
 
cd ..


%% Calculate average
%newTemplate = newTemplate/noFilament;
%dwrite(newTemplate, newRefFile);
writecell(filamentPFList, filamentPFListFile);

% Write separate list files for different PFs
numPF = cell2mat(filamentPFList(:, 3));
for i = refPFs
	subFilamentList = filamentPFList(numPF == i, :);
	writecell(subFilamentList, strrep(filamentPFListFile, '.csv', [num2str(i) 'PF.csv']));
end
