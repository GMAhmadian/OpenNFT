function loadProtocolData()
% Function to load experimental protocol stored in json format.
% Note, to work with json files, use jsonlab toolbox.
%
% input:
% Workspace variables.
%
% output:
% Output is assigned to workspace variables.
%__________________________________________________________________________
% Copyright (C) 2016-2017 OpenNFT.org
%
% Written by Yury Koush, Artem Nikonorov

P = evalin('base', 'P');

[isPSC, isDCM, isSVM, isIGLM] = getFlagsType(P);

jsonFile = P.ProtocolFile;
NrOfVolumes = P.NrOfVolumes;
nrSkipVol = P.nrSkipVol;

prt = loadjson(jsonFile);

P.BaselineName = prt.BaselineName;
P.CondName = prt.CondName;

P.vectEncCond = [];
P.ProtBAS = {};
P.ProtNF = {};

P.basBlockLength = prt.Cond{1}.OnOffsets(1,2);
lCond = length(prt.Cond);

%% PSC
if strcmp(P.Prot, 'Cont') && isPSC
    P.vectEncCond = ones(1,P.NrOfVolumes-P.nrSkipVol);
    for x = 1:lCond
        for k = 1:length(prt.Cond{x}.OnOffsets(:,1)) 
            unitBlock = prt.Cond{x}.OnOffsets(k,1) : prt.Cond{x}.OnOffsets(k,2); 
            if strcmpi(prt.Cond{x}.ConditionName, 'Bas') 
                P.vectEncCond(unitBlock) = 1;
                P.ProtBAS(k,:) = {unitBlock}; 
            elseif strcmpi(prt.Cond{x}.ConditionName, 'NF') 
                P.vectEncCond(unitBlock) = 2;
                P.ProtNF(k,:) = {unitBlock};                
            end
        end
    end
end

if strcmp(P.Prot, 'Inter') && isPSC
    P.vectEncCond = ones(1,NrOfVolumes-nrSkipVol);
    for x = 1:lCond
        for k = 1:length(prt.Cond{x}.OnOffsets(:,1))
            unitBlock = prt.Cond{x}.OnOffsets(k,1) : prt.Cond{x}.OnOffsets(k,2);
            if strcmpi(prt.Cond{x}.ConditionName, 'Bas')
                P.vectEncCond(unitBlock) = 1;
                P.ProtBAS(k,:) = {unitBlock};
            elseif strcmpi(prt.Cond{x}.ConditionName, 'NF')
                P.ProtNF(k,:) = {unitBlock};
                P.vectEncCond(unitBlock) = 2;
            elseif strcmpi(prt.Cond{x}.ConditionName, 'FB')
                P.vectEncCond(unitBlock) = 3;
            end
        end
    end
end

%% DCM
if strcmp(P.Prot, 'InterBlock') && isDCM
    for x = 1:lCond
        for k = 1:length(prt.Cond{x}.OnOffsets(:,1))
            unitBlock = prt.Cond{x}.OnOffsets(k,1) : prt.Cond{x}.OnOffsets(k,2);
            if strcmpi(prt.Cond{x}.ConditionName, 'N')
                P.vectEncCond(unitBlock) = 1;
            elseif strcmpi(prt.Cond{x}.ConditionName, 'P')
                P.vectEncCond(unitBlock) = 2;
            elseif strcmpi(prt.Cond{x}.ConditionName, 'DCM')
                P.vectEncCond(unitBlock) = 3;
            elseif strcmpi(prt.Cond{x}.ConditionName, 'FB')
                P.vectEncCond(unitBlock) = 4;
            end
        end
    end
end

%% SVM
if strcmp(P.Prot, 'Cont') && isSVM
    P.vectEncCond = ones(1,P.NrOfVolumes-P.nrSkipVol);
    for x = 1:lCond
        for k = 1:length(prt.Cond{x}.OnOffsets(:,1)) 
            unitBlock = prt.Cond{x}.OnOffsets(k,1) : prt.Cond{x}.OnOffsets(k,2); 
            if strcmpi(prt.Cond{x}.ConditionName, 'Bas') 
                P.vectEncCond(unitBlock) = 1;
                P.ProtBAS(k,:) = {unitBlock}; 
            elseif strcmpi(prt.Cond{x}.ConditionName, 'NF') 
                P.vectEncCond(unitBlock) = 2;
                P.ProtNF(k,:) = {unitBlock};                
            end
        end
    end
end

P.Protocol = prt;
assignin('base', 'P', P);
end

