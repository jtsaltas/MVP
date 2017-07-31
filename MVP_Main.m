clear,clc
strFILE = 'inputs/SkyRangerTMotor.txt';

% variables - atmospheric, component geometries, component masses
[seqV, flowTEMP, flowALT, flowRHO, flowMU, flowM, flowR, flowALPHAT, ...
    angCLIMBdeg, angSIDEdeg, numLEADROTOR, geomTypeROTOR, geomNumROTORS,...
    geomDIAMETER, geomNumBLADES, geomARMlength, geomARMradius, ...
    geomBODYheight, geomBODYradius, geomLEGlength, geomLEGradius, ...
    geomLEGcentreradius, geomLEGcentreheight, geomPAYLOADlength, ...
    geomPAYLOADradius, geomPAYLOADheight, geomMOTORheight, ...
    geomMOTORradius, geomHUBheight, geomCGheight, massMOTOR, massARM, ...
    massLEG, massPAYLOAD, massBODY, massVEHICLE] = fcnMVPREAD(strFILE);

% Calculate Reynolds number to CDY database for cylinder and sphere
[cylinderRE, cylinderCDY, sphereRE, sphereCDY] = fcnRECURVE();

% Calculate wetted area of each component
[areaLEG, areaARM, areaBODY, areaPAYLOAD, areaMOTOR] = ...
    fcnCOMPONENTAREA(geomLEGlength, geomLEGradius, geomARMlength, ...
    geomARMradius, geomBODYradius, geomPAYLOADradius, geomPAYLOADlength,...
    geomMOTORradius, geomMOTORheight);

% Create a table with all rotor performance from database
[tabLOOKUP, vecANGLELST] = fcnLOADTABLES(geomTypeROTOR);

[positionROTOR, positionMOTOR, positionARM, positionLEG,...
            positionBODY, positionPAYLOAD] = fcnCOORDSETUP(numLEADROTOR, geomNumROTORS,...
            geomARMlength, geomBODYradius, geomMOTORradius, geomLEGcentreradius, geomLEGcentreheight, ...
            geomPAYLOADheight, geomHUBheight, geomCGheight);

rotorHUBLOCATIONS = [-0.4020         0   -0.0315;
         0   -0.4020   -0.0315;
    0.4020         0   -0.0315;
         0    0.4020   -0.0315];

% START VELOCITY SEQUENCE
for i = 1:size(seqV,1)
    flowV = seqV(i);  
    flowq = 0.5*flowRHO*flowV^2;    % Calculate the drag of each component
    
    [powerPARASITIC, dragVEHICLE, dragARM, dragLEG, dragBODY, dragMOTOR,...
            dragPAYLOAD] = fcnDRAGPREDICT(geomNumROTORS, flowV, flowRHO, ...
            flowMU, cylinderRE, cylinderCDY, sphereRE, sphereCDY, areaARM, ...
            areaLEG, areaMOTOR, areaPAYLOAD, areaBODY, geomARMradius, ...
            geomLEGradius, geomMOTORradius, geomPAYLOADradius, geomBODYradius);
    
    [rotorTHRUST, rotorAngINFLOW, rotorVelINFLOW,...
            rotorRPM, dragBODYinduced, liftBODY,...
            pitchVEHICLEdeg] = fcnFORCETRIM( flowq, flowRHO, geomNumROTORS, ...
            geomBODYradius, dragVEHICLE, massVEHICLE, tabLOOKUP, vecANGLELST );
        
    [vi_int, vi_self, skewRAD, wi, rotorAngINFLOW, rotorVelINFLOW, rotorRPM, rotorPx, rotorPy,...
            rotorMx, rotorMy, rotorCP, rotorCMx, rotorJinf] = fcnPREDICTRPM(flowq,flowRHO,...
            geomNumROTORS,geomNumBLADES,geomDIAMETER,positionROTOR,...updated rotor position from rotorRUBlocation 
            rotorTHRUST,rotorRPM,rotorAngINFLOW,rotorVelINFLOW,...
            pitchVEHICLEdeg, tabLOOKUP, vecANGLELST);
    
    [powerROTOR, powerTOTAL, powerVEHICLE] = fcnROTORPOWER (flowRHO, geomDIAMETER,...
            geomNumROTORS, rotorCP, rotorRPM, powerPARASITIC);

    [ momentROTORTHRUST, momentROTORPx, momentROTORPy, momentROTORMx, momentROTORMy,...
            momentWEIGHTMOTOR, momentWEIGHTARM, momentDRAGMOTOR, momentDRAGARM, momentWEIGHTLEG,...
            momentDRAGLEG, momentWEIGHTBODY, momentWEIGHTPAYLOAD, momentDRAGBODY, momentDRAGPAYLOAD, momentTOTAL ] ...
            = fcnCALCMOMENTS(massMOTOR, massARM, massLEG, massPAYLOAD, massBODY, ...
            positionROTOR, positionMOTOR, positionARM, positionLEG, positionBODY, positionPAYLOAD,...
            dragVEHICLE, dragARM, dragLEG, dragBODY, dragMOTOR, dragPAYLOAD, dragBODYinduced, liftBODY,...
            rotorTHRUST, rotorPx, rotorPy, rotorMx, rotorMy,pitchVEHICLEdeg, geomNumROTORS);
            
            
     %varify COORDSETUP function
     %add moment function       
     %add moment trim
     %add Px convergence(from last time step)
     %make new lookup function to find thrust based on RPM
     %make file that generates plots
     %validate WIM
end

% fcnFORCETRIM
%   input:  dragVEHICLE -|
%           massVEHICLE -| first guess pitch (include P force from last iteration?)
%           V --> q     - for lookup table
%           rotor file  - for lookup table
%           geomNumROTORS - divides total forces
%           flowRHO
%           V
%           geomBODYradius
