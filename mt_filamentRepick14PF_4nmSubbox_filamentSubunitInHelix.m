%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to apply alignment parameters to repick filament helical subunit model
% Should have same parameters as imodModel2Filament
% The polarity should be clear already so should be use after mt_alignRepickParticles.m
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% WORK IN PRINCIPALE but not tested

% The parameter subunit_dz and dphi should be measured from the map from
% aa_alignAllParticles13PF.m or 14PF.m
% For 14 PF, the rise is 84.4, supertwist dphi is .42 degree
% For 13 PF, the rise is 84, supertwist dphi is 0.1

%%%%%%%% Before Running Script %%%%%%%%%%
%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';


%%%%%%% Variables subject to change %%%%%%%%%%%
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
modelDir = sprintf('%smodels_subbox', prjPath);
origParticleDir = sprintf('%sparticles_repick', prjPath);
particleDir = sprintf('%sparticles_subbox', prjPath);
c001Dir = sprintf('%scatalogs/c001', prjPath);
pixelSize = 8.48; % Angstrom per pixel
periodicity = 84.4; % Measured from your average
boxSize = 80;
mw = 12;
subunits_dphi = 25.7866;  % 14PF 
subunits_dz = 9.1/pixelSize; % rise in 14PF microtubule
filamentRepickListFile = sprintf('%sfilamentSubboxList14PF.csv', prjPath);
filamentListFile = sprintf('%sfilamentRepickList14PF.csv', prjPath);
tableAlnFileName = 'merged_particles_repick_14PF_align.tbl'; % merge particles before particle alignment for robust but must be merged_particles_align to use doInitialAngle
avgLowpass = 30; % Angstrom
tomoSuffix = '_8.48Apx';
dTh = 30; % Distance Threshold in Angstrom
doExclude = 1; % Exclude particles too close
doOutlier = 1; % Exclude outlier using CC using MAD
doInitialAngle = 0; % Only turn on for axoneme case now, absolutely not for microtubule

%%%%%%% Do not change anything under here %%%%%
%% loop through all tomograms
filamentList = readcell(filamentListFile, 'Delimiter', ',');
fileID = fopen(docFilePath); D = textscan(fileID,'%d %s'); fclose(fileID);
tomoID = D{1,1}'; % get tomogram ID
nTomo = length(D{1,2}); % get total number of tomograms

tAll = dread(tableAlnFileName);

filamentRepickList = {};

%% Loop through tomograms
%for idx = 1:nTomo
for idx = 1:1
    tomo = D{1,2}{idx,1};
    [tomoPath,tomoName,ext] = fileparts(tomo);
    tomono = D{1,1}(idx);
    % Modify specific to name
    tomoName = strrep(tomoName, tomoSuffix, ''); % Remove the suffix part of the name
    tTomo = tAll(tAll(:,20) == tomono, :);
    if isempty(tTomo) == 1
        continue;
    end
      
    modelout =   [modelDir '/' tomoName '.omd'];
    contour = unique(tTomo(:, 23));
    
    m = {}; % Cell array contains all filament
    
    for i = 1:length(contour)        
        % Name of filament
        filamentName = [tomoName '_' num2str(contour(i))];
        
        tContour = tTomo(tTomo(:, 23) == contour(i), :);
        %if tContour(1, 25) > tContour(end, 25)
        %    polarity = 1;
        %else
        %	polarity = 0;
    	%end
    
        % Important: this step invert the Y axis, doing for each contour might help to check for polarity
        if doExclude > 0
            tContourEx = dpktbl.exclusionPerVolume(tContour, dTh/pixelSize);
            % Make sure to sort by particles number for not inverting angle
            tContour = sortrows(tContourEx, 1);
            disp(['Exclude ' num2str(size(tContour, 1) - size(tContourEx, 1)) ' particles due to proximity']);
        end

        %if polarity > 0
        %    tContour = flipud(tContour);
        %    disp([filamentName ' - flip polarity']);
        %end
       
        if doOutlier > 0
            cc = tContour(:, 10);
            x = median(cc);
            y = mad(cc);
            tContour = tContour(cc > x - 3*y, :);
            disp(['Contour ' num2str(contour(i)) ': Exclude ' num2str(sum(cc <= x - 3*y)) ' particles']);
        end
        
        if isempty(tContour) == 1
            continue;
        end

		Tp.type = 'shiftrot';
		Tp.shifts = [0 0 subunits_dz];
		Tp.eulers = [0 0 subunits_dphi];
		
		t = tContour;
		for pf = 1:13
			Tp.shifts = [0 0 subunits_dz]*pf;
			Tp.eulers = [0 0 subunits_dphi]*pf;
        	tRot = dynamo_table_rigid(tContour, Tp);
			t = [t; tRot];
		end         	
                
        % Just in case
        if isempty(t) == 1
          	warning(['Skip: ' tomoName  '_' num2str(contour(i)) 'does not have any particles!']);
        	continue;
        end
		
		% Additing contour number (filamentID)
        t(:,23) = contour(i); 
        
        % Check point
        dwrite(t, [modelDir '/' tomoName '_' num2str(contour(i)) '_rot.tbl']);
        targetFolder = [particleDir '/'  tomoName '_' num2str(contour(i))];
        
        % For testing
        continue;
        
        % Cropping subtomogram out
        try
       		dtcrop(docFilePath, t, targetFolder, boxSize, 'mw', mw);
        	tCrop = dread([targetFolder '/crop.tbl']);
        	oa_all = daverage(targetFolder, 't', tCrop, 'fc', 1, 'mw', mw);
        	dwrite(dynamo_bandpass(oa_all.average, [1 round(pixelSize/avgLowpass*boxSize)]), [targetFolder '/average.em']);
        	% Average the middle region again
        	if size(tCrop, 1) > 15
            	midIndex = floor(size(tCrop, 1)/2);
            	tCrop = tCrop(midIndex - 3: midIndex + 4, :);
        	end
        	oa = daverage(targetFolder, 't', tCrop, 'fc', 1, 'mw', mw);
        	dwrite(dynamo_bandpass(oa.average, [1 round(pixelSize/avgLowpass*boxSize)]), [targetFolder '/template.em']);
        
        	% Plotting save & close. dtplot seems to error if only 1 particles
        	if size(tCrop, 1) > 1
            	dtplot(tCrop, 'pf', 'oriented_positions');
            	view(-230, 30); axis equal;
            	print([targetFolder '/repick_' tomoName '_' num2str(contour(i))] , '-dpng');
            	close all
        	end
       	catch
  			warning(['Skip: ' tomoName  '_' num2str(contour(i)) 'does not have enough particles!'])
  			continue;
  		end	
  		% If it is cropping out
  		filamentRepickList{end + 1, 1} = [tomoName  '_' num2str(contour(i))];   
    end
    % Write the DynamoModel
    dwrite(m, modelout);
end

%% Write filament list out
writecell(filamentRepickList, filamentRepickListFile);


