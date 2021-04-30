function [nBlockSer, kWhModule_actual, nModSer, nModPar, kWhPack_actual] = ...
    get_ac_layout(vCell, AhBal, kWhModule_desired, kWhPack_desired, vModule_desired, vPack_desired)
% Returns details about conventional pack layout given desired
% characteristics


nBlockSer = ceil(vModule_desired ./ max(vCell,[],2));
kWhModule_actual = nBlockSer .* mean(vCell,2) .* AhBal./1000;

nModSer = floor(max(vPack_desired)./(nBlockSer .* max(vCell,[],2)));
nModPar = round(kWhPack_desired./(nModSer .* kWhModule_actual));
kWhPack_actual = kWhModule_actual .* nModSer .* nModPar;

end
