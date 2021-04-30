function [nModPar, kWhPack_actual] = get_dc_layout(kWhModule, nModSer, kWhPack_desired)
% Returns details about modular pack layout given desired characteristics
% and specified number of modules in series 
    nModPar = round(kWhPack_desired./(kWhModule*nModSer)); 
    
    kWhPack_actual = kWhModule .* nModSer .* nModPar;

end
