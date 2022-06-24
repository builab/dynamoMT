%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to go through the filament List and exclude any filament with less than X particles
% This avoids later script crashed.
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NOT DONE YET

%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/tip_CP_dPhi/';

%%%%%%%%

% Input
minPartNo = 4; % Minimum number of particles
filamentListFile = sprintf('%sfilamentList.csv', prjPath);
particleDir = sprintf('%sparticles', prjPath);
boxSize = 96; % Original extracted subvolume size


% Generate an initial reference average for each filament
filamentList = readcell(filamentListFile, 'Delimiter', ',');

filamentListNew = {};

for idx = 1:length(filamentList)
    tableName = [particleDir '/' filamentList{idx} '/crop.tbl'];
    tOri = dread(tableName);
    
    if size(tOri, 1) < minPartNo
            disp(['Skip ' filamentList{idx} ' due to no of particles'])
        	continue
    end
    
end

cd ..
