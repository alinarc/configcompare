close all
clear

format shortg

moduleV = 50; % fixing module voltage to~50 V.
modulekWh = 3.5; % fixing module capacity to ~3.5 kWh
balAh = 100; % limit each balancing circuit to no more than 100 Ah
cellAh = [10; 50; 100]; % consider diff cell sizes

packV = [680; 1000];
packVmax = max(packV);
packkWh_eol = 400;
packpct_eol = 0.8;
packkWh = packkWh_eol / packpct_eol;

cellV = [2.5 3.65; 1.5 2.9; 1.2 2.5]; % cellV ranges for K2 LFP/Graphite, LMO/LTO, LFP/LTO
cellType = {'K2 LFP/Graphite'; 'LMO/LTO'; 'LFP/LTO'};
cellVnom = mean(cellV,2); % use mean cellV to compute modulekWh
cellVmax = max(cellV, [], 2);
cellVmin = min(cellV, [], 2);

nCellSer = ceil(moduleV./cellVmax);

moduleV_actual = nCellSer .* cellV; % max and min of module voltage
moduleVmax = max(moduleV_actual, [], 2);
moduleVmin = min(moduleV_actual, [], 2);
moduleVnom = nCellSer .* cellVnom; % nominal module voltage, used to compute capacity
moduleAh = modulekWh .* 1000 ./ moduleVnom; % may not use this: may just fix moduleAh to 100 for ease of comparison

nCellPar = round(balAh ./ cellAh)
moduleAh_actual = nCellPar .* cellAh;

nBalModule = nCellSer .* ceil(moduleAh_actual ./ balAh);
modulekWh_actual = moduleVnom .* moduleAh_actual / 1000; % Andrew used this mean cellV (cellVnom) to compute modulekWh, not sure why

nModSer = ceil(packVmax ./ moduleVmax);
nModPar = ceil(packkWh ./ (nModSer .* modulekWh_actual));

packV_actual = nModSer .* moduleV_actual;
packVmax_actual = max(packV_actual, [], 2);
packVmin_actual = min(packV_actual, [], 2);
nBalPack = nBalModule .* nModSer .* nModPar;
packkWh_actual = modulekWh_actual .* nModSer .* nModPar;

% figure
% subplot(1,2,1)
% plot(modulekWh_actual(:,1), nBalPack(:,1), '-o', modulekWh_actual(:,2), nBalPack(:,2),'-o')
% legend('50 V modules', '100 V modules')
% xlabel('Module capacity (kWh)')
% ylabel(sprintf('# balancing circuits in %d kWh pack', packkWh))
% title('Number of balancing circuits in AC pack for different module configurations')
% xticks(modulekWh')
% xtickangle(45)
% subplot(1,2,2)
% %figure
% plot(modulekWh_actual(:,1), packkWh_actual(:,1), '-o', modulekWh_actual(:,2), packkWh_actual(:,2), '-o')
% xlabel('Module capacity (kWh)')
% ylabel('Actual pack capacity (kWh)')
% xticks(modulekWh')
% xtickangle(45)
% title('Actual AC pack capacity for different module configurations')
% legend('50 V modules', '100 V modules')

cellV_t = cell(size(cellType));
for i = 1:size(cellV_t)
    cellV_t{i} = sprintf('%g-%g', cellVmin(i), cellVmax(i));
end
cellInfo = table(cellType, cellV_t);
cellInfo.Properties.VariableNames = {'Type', 'Voltage (V)'};
disp(cellInfo)

moduleConfig = cell(size(cellType,1), size(cellAh,1))
for i = 1:size(moduleConfig,1)
    for j = 1:size(moduleConfig,2)
        moduleConfig{i,j} = sprintf('%gs%gp', nCellSer(i), nCellPar(j));
    end
end
varNames1 = {sprintf('%g Ah cells', cellAh(1)), ...
    sprintf('%g Ah cells', cellAh(2)), sprintf('%g Ah cells', cellAh(3))};
moduleConfig = string(moduleConfig);
Module_Config = table(moduleConfig(:,1), moduleConfig(:,2),moduleConfig(:,3));
Module_Config.Properties.VariableNames = varNames1';
disp(Module_Config)

modulekWh_actual_t = cell(size(cellType));
packConfig = cell(size(cellType));
packkWh_actual_t = cell(size(packConfig));
packV_actual_t = cell(size(packConfig));
for i = 1:size(packConfig)
    packConfig{i} = sprintf('%ds%dp', nModSer(1), nModPar(i));
    modulekWh_actual_t{i} = sprintf('%0.2f', modulekWh_actual(i));
    packkWh_actual_t{i} = sprintf('%0.2f', packkWh_actual(i));
    packV_actual_t{i} = sprintf('%g-%g', packVmin_actual(i), packVmax_actual(i));
end

packConfig = string(packConfig);
modulekWh_actual_t = string(modulekWh_actual_t);
packkWh_actual_t = string(packkWh_actual_t);
packV_actual_t = string(packV_actual_t);

varNames = {'Type', 'V', '10 Ah cells', '50 Ah cells', '100 Ah cells', 'Module kWh', 'Pack config', 'Pack kWh','Pack V', '# bal circuits/pack'};

%rowNames = reshape(rowNames, size(moduleAh_t));
%title1 = sprintf('Pack comparisons for %g-%g kWh modules. \n Vmod = %g-%g V, Vpack = %g-%g V', ...
%    min(modulekWh), max(modulekWh), moduleVmin, moduleVmax, min(packV), max(packV));

T = table(string(cellType), string(cellV_t), moduleConfig(:,1), moduleConfig(:,2), moduleConfig(:,3),...
    modulekWh_actual_t, packConfig, packkWh_actual_t, packV_actual_t, nBalPack);
T.Properties.VariableNames = varNames;
T = mergevars(T, {'Type', 'V'}, 'NewVariableName', 'Cell info', 'MergeAsTable', true);
T = mergevars(T, {'10 Ah cells','50 Ah cells', '100 Ah cells'},...
    'NewVariableName', 'Module config', 'MergeAsTable', true);
disp(T)


fig = uifigure('HandleVisibility','on','Position', [500 500 600 550]);
% fig.Position = [500 500 520 520];

t = uitable(fig, 'Data', T, 'Position', [0 270 600 250]);
%t.Position(3:4) = t.Extent(3:4);
s = uistyle('HorizontalAlignment', 'center');
addStyle(t,s);



