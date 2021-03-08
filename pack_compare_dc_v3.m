close all
clear

format shortg

moduleV = 50;
modulekWh = 3.5;
balAh = 100; % limit each balancing circuit to no more than 100 Ah
cellAh = [10; 50; 100]

packV = [680; 1000];
packVmax = max(packV);
packkWh_eol = 400;
packpct_eol = 0.8;
packkWh = packkWh_eol / packpct_eol;

cellV = [2.5 3.65] % use mean cellV to compute modulekWh?
cellVmax = max(cellV);
cellVnom = mean(cellV,2);

nCellSer = ceil(moduleV./cellVmax);
moduleV_actual = nCellSer .* cellV; % max and min of module voltage
moduleVmax = max(moduleV_actual, [], 2);
moduleVmin = min(moduleV_actual, [], 2);
moduleVnom = nCellSer .* cellVnom; % nominal module voltage, used to compute capacity

modulekWh_actual = moduleVnom .* balAh / 1000;

nModSer_DAB = [1;2;3;1;1]; % number of series modules that share a converter
nModPar_DAB = [1;1;1;2;3];
kWhDAB = modulekWh_actual .* nModSer_DAB .* nModPar_DAB;
nDAB = round(packkWh ./ kWhDAB);
packkWh_actual = kWhDAB .* nDAB;
inputV_DAB = moduleVmax .* nModSer_DAB; % base converter ratio on min or max battery voltage?
ratio_DAB = packVmax ./ inputV_DAB;
nBalPack = nCellSer .* nModSer_DAB .* nModPar_DAB .* nDAB;
nMod_t = cell(size(nModSer_DAB));
for i = 1:size(nMod_t)
    nMod_t{i} = sprintf('%gs%gp', nModSer_DAB(i), nModPar_DAB(i));
end
    
C = {string(nMod_t), packkWh_actual, nDAB, ratio_DAB, kWhDAB, nBalPack};
T = table(C{:});
T.Properties.VariableNames = {'# modules/converter', 'Pack kWh', '# Converters', 'Converter ratio', 'Converter kW', '# balancing circuits'};
%title = sprintf('Dedicated converter vs. shared converters comparison for ',
disp(T)