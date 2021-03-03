close all
clear

format shortg

moduleV = 50;
modulekWh = [1; 2.5; 5; 7.5; 10];
balAh = 100; % limit each balancing circuit to no more than 100 Ah
cellAh = 10;

packV = 1000;
packVmin = 680;
packkWh = 400;
cellVmax = 3.6;
cellVmin = 1.5;
cellVnom = (cellVmax + cellVmin)/2; % use mean cellV to compute modulekWh?

nCellSer = round(moduleV./cellVmax);
moduleVmax = cellVmax * nCellSer;
moduleVmin = cellVmin * nCellSer;
moduleVnom = cellVnom * nCellSer;
reqdAh = modulekWh * 1000 ./ moduleVnom;

nCellPar = ceil(reqdAh ./ cellAh);
moduleAh_actual = nCellPar .* cellAh;
nBalModule = nCellSer .* ceil(moduleAh_actual ./ balAh);

modulekWh_actual = nCellSer .* cellVnom .* moduleAh_actual / 1000; % Andrew used this mean cellV (cellVnom) to compute modulekWh, not sure why

nModSer = ceil(packVmin ./ moduleVmin);
nModPar = ceil(packkWh ./ (nModSer .* modulekWh_actual));

packV = nModSer .* [moduleVmin moduleVmax];

nBalPack = nBalModule * nModSer .* nModPar;
packkWh_actual = modulekWh_actual .* nModSer .* nModPar;


moduleAh_t = reshape(moduleAh_actual, size(modulekWh,1)*size(moduleV,1),1);
nBalPack_t = reshape(nBalPack, size(moduleAh_t));
modulekWh_actual_t = reshape(modulekWh_actual,size(moduleAh_t));
packkWh_actual_t = reshape(packkWh_actual, size(moduleAh_t));

packConfig = cell(size(moduleAh_t));

for i = 1:size(moduleAh_t)
    packConfig{i} = sprintf('%ds%dp', nModSer, nModPar(i));
end
packConfig = string(packConfig);
varNames = {'Module Ah', 'Module kWh', 'Pack config', '# bal circuits/pack', 'Pack capacity (kWh)'};
rowNames = cell(size(modulekWh,1), size(moduleV,1));
for i = 1:size(modulekWh)
    rowNames{i} = sprintf('%g kWh module', modulekWh(i));
end
title = sprintf('Pack comparisons for %g-%g kWh modules. \n Vmod = %g-%g V, Vpack = %g-%g V', ...
    min(modulekWh), max(modulekWh), moduleVmin, moduleVmax, min(packV), max(packV));
C = {moduleAh_t, modulekWh_actual_t, packConfig, nBalPack_t, packkWh_actual_t};
T = table(C{:});
T.Properties.RowNames = rowNames;
T.Properties.VariableNames = varNames;
disp(title)
disp(T)
