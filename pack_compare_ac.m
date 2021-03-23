%% The purpose of this script is to decide on a module voltage and capacity
% for 500 kWh AC-coupled battery pack with DC bus voltage of 1000 V. To do this, we 
% compare packs composed of 50V/100V modules of varying sizes: 40-1200 Ah 
% (corr. to 1.43-42.84 kWh) modules for 50 V case, and 20-600 Ah 
% (corr. to 1.43-42.84 kWh) modules for 100 V case.
%
% To convey these comparisons, this script does 3 things:
% 1) Generates plots of the number of balancing circuits required and 
% overall pack capacity vs. the module capacity.
% 2) Generates tables summarizing pack comparisons for various sizes of 50
% V and 100 V modules.
% 3) Generates these same tables in a matlab uifigure, highlighting in red
% valure of concern

% This script assumes that each module can contain multiple blocks of 100 
% Ah connected in parallel (each with a balancing circuit). Each balancing 
% circuit is limited to a maximum of 100 Ah, with most
% module sizes being a multiple of 100 Ah to allow for max utilization of
% balancing circuits. A few cases where modules are less than 100 Ah are
% included in the comparison to show the effect of underutilizing the
% balancing circuits.

close all
clear

format shortg

moduleV = [50;100];
modulekWh = [1.5; 2.5; 3.5; 5; 7.5; 10; 20; 30; 40];
balAh = 100; % limit each balancing circuit to no more than 100 Ah
cellAh = 10;

packV = 1000;
packVmin = 680;
packkWh_eol = 400;
packpct_eol = 0.8;
packkWh = packkWh_eol / packpct_eol; % pack capacity designed to provide 400 kWh at end of life

cellVmax = 3.6; % this cell voltage range is not representative of a single chemistry, rather the entire range across 3 chemistries considered. Not really used here
cellVmin = 1.5;
cellVnom = (cellVmax + cellVmin)/2;

nCellSer = ceil(moduleV./cellVmax); % compute # of cells in series based on max cell voltage
moduleVmax = cellVmax * nCellSer;
moduleVmin = cellVmin * nCellSer;
moduleVnom = cellVnom * nCellSer;
reqdAh = modulekWh * 1000 ./ moduleVnom'; % Ah required to have module size of modulekWh at voltage moduleVnom
% note: we will use the nominal module voltage to compute module capacity

nCellPar = round(reqdAh ./ cellAh);
moduleAh_actual = nCellPar .* cellAh;
moduleAh_actual(moduleAh_actual > balAh) = 0;

maxAh = max(modulekWh) * 1000 ./ moduleVnom';
maxAh = ceil(maxAh./balAh) * balAh;
moduleAh_actual = [moduleAh_actual; 0 0];

addlAh = [200; 300; (400:200:maxAh(1))'; (100:100:maxAh(2))']; % generating desired set of module Ah values to consider
[row, col] = find(moduleAh_actual == 0);

for i=1:size(row,1)
    moduleAh_actual(row(i),col(i)) = addlAh(i); % add additional desired Ah values to set
end


nBalModule = nCellSer' .* ceil(moduleAh_actual ./ balAh);
modulekWh_actual = nCellSer' .* cellVnom .* moduleAh_actual / 1000; % use mean cellV (cellVnom) to compute modulekWh

nModSer = ceil(packV ./ moduleVmax);
nModPar = round(packkWh ./ (nModSer' .* modulekWh_actual));

packV = nModSer .* [moduleVmin moduleVmax];

nBalPack = nBalModule .* nModSer' .* nModPar;
packkWh_actual = modulekWh_actual .* nModSer' .* nModPar;

%% 1) Plot the number of balancing circuits and overall pack capacity vs. module capacity.
figure
subplot(1,2,1)
plot(modulekWh_actual(:,1), nBalPack(:,1), '-o', modulekWh_actual(:,2), nBalPack(:,2),'-o')
legend('50 V modules', '100 V modules')
xlabel('Module capacity (kWh)')
ylabel(sprintf('# balancing circuits in %d kWh pack', packkWh))
title('Number of balancing circuits in AC pack for different module configurations')
xticks(modulekWh')
xtickangle(45)
subplot(1,2,2)
%figure
plot(modulekWh_actual(:,1), packkWh_actual(:,1), '-o', modulekWh_actual(:,1), packkWh_actual(:,2), '-o')
xlabel('Module capacity (kWh)')
ylabel('Actual pack capacity (kWh)')
xticks(modulekWh')
xtickangle(45)
title('Actual AC pack capacity for different module configurations')
legend('50 V modules', '100 V modules')

%% 2) Create and print tables summarizing pack comparisons.
% Generate values for table (_t in variable names signifies that they will
% be used in the table)
moduleAh_t = reshape(moduleAh_actual, size(moduleAh_actual,1)*size(moduleV,1),1);
nBalPack_t = reshape(nBalPack, size(moduleAh_t));
modulekWh_actual_t = reshape(modulekWh_actual,size(moduleAh_t));

packkWh_actual_t = reshape(packkWh_actual, size(moduleAh_t));
nModPar_t  = reshape(nModPar, size(moduleAh_t));
packConfig = cell(size(moduleAh_t));
modulekWh_actual_t1 = cell(size(moduleAh_t));
packkWh_actual_t1 = cell(size(moduleAh_t));
for i = 1:size(moduleAh_t)
    packConfig{i} = sprintf('%ds%dp', nModSer(1), nModPar_t(i));
    if i > size(moduleAh_actual,1)
        packConfig{i} = sprintf('%ds%dp', nModSer(2), nModPar_t(i));
    end
    modulekWh_actual_t1{i} = sprintf('%0.2f', modulekWh_actual_t(i));
    packkWh_actual_t1{i} = sprintf('%0.2f', packkWh_actual_t(i));
end

packConfig = string(packConfig);
modulekWh_actual_t1 = string(modulekWh_actual_t1);
packkWh_actual_t1 = string(packkWh_actual_t1);

varNames = {'Module Ah', 'Pack config', '# bal circuits/pack', 'Pack capacity (kWh)'};
rowNames = cell(size(modulekWh_actual_t,1));
for i = 1:size(modulekWh_actual_t)
    rowNames{i} = sprintf('%.2f kWh module', modulekWh_actual_t(i));
end
%rowNames = reshape(rowNames, size(moduleAh_t));

% Use first half of the table data to generate a table  for 50 V modules
title1 = sprintf('%gV modules: Vmod = %g-%g V, Vpack = %g-%g V, %g cells in series', ...
    moduleV(1), moduleVmin(1), moduleVmax(1), min(packV(1,:)), max(packV(1,:)), nCellSer(1));
C = {moduleAh_t(1:size(moduleAh_actual,1)), packConfig(1:size(moduleAh_actual,1)), ...
    nBalPack_t(1:size(moduleAh_actual,1)), packkWh_actual_t1(1:size(moduleAh_actual,1))};
T = table(C{:});
T.Properties.RowNames = rowNames(1:size(moduleAh_actual,1),1);
T.Properties.VariableNames = varNames;
disp(title1)
disp(T)


% Use second half of table data to generate a table for 100 V modules
title2 = sprintf('%gV modules: Vmod = %g-%g V, Vpack = %g-%g V, %g cells in series', ...
    moduleV(2), moduleVmin(2), moduleVmax(2), min(packV(2,:)), max(packV(2,:)), nCellSer(2));
C2 = {moduleAh_t(size(moduleAh_actual,1)+1:end), packConfig(size(moduleAh_actual,1)+1:end), ...
    nBalPack_t(size(moduleAh_actual,1)+1:end), packkWh_actual_t1(size(moduleAh_actual,1)+1:end)};
T2 = table(C2{:});
T2.Properties.RowNames = rowNames(1:size(moduleAh_actual,1),1);
T2.Properties.VariableNames = varNames;
disp(title2)
disp(T2)

%% 3) Display tables in matlab uifigure.
% Generate same tables but in a matlab uifigure
fig = uifigure('HandleVisibility','on','Position', [500 500 800 550]);
% fig.Position = [500 500 520 520];

t = uitable(fig, 'Data', T, 'Position', [0 270 800 250]);
%t.Position(3:4) = t.Extent(3:4);
s = uistyle('HorizontalAlignment', 'center');
addStyle(t,s);
title1_obj = uitextarea(fig, 'Value', title1,'Position', [0 520 800 20]);
s1 = uistyle('FontColor', 'r');

row1 = find(moduleAh_t(1:size(moduleAh_actual,1)) > balAh);
col1 = ones(size(row1));
addStyle(t,s1, 'cell',[row1,col1])

row12 = find(packkWh_actual_t(1:size(moduleAh_actual,1)) > 600);
col12 = 4*ones(size(row12));
addStyle(t,s1,'cell', [row12,col12])


t2 = uitable(fig, 'Data', T2, 'Position', [0 0 800 250]);
addStyle(t2,s);
title2_obj  = uitextarea(fig, 'Value', title2, 'Position', [0 250 800 20]);

row2 = find(moduleAh_t(size(moduleAh_actual,1)+1:end) > balAh);
col2 = ones(size(row2));
addStyle(t2, s1, 'cell', [row2, col2])

row22 = find(packkWh_actual_t(size(moduleAh_actual,1)+1:end) > 600);
col22 = 4*ones(size(row22));
addStyle(t2, s1, 'cell', [row22, col22])