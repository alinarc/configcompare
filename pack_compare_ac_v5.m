close all
clear

format shortg

moduleV = [50;100];
modulekWh = [1.5; 2.5; 3.5; 5; 7.5; 10; 20; 30; 40];
balAh = 100; % limit each balancing circuit to no more than 100 Ah
cellAh = 10;

packV = 1000;
packVmin = 680;
packkWh = 400;
cellVmax = 3.6;
cellVmin = 1.5;
cellVnom = (cellVmax + cellVmin)/2; % use mean cellV to compute modulekWh?

nCellSer = ceil(moduleV./cellVmax);
moduleVmax = cellVmax * nCellSer;
moduleVmin = cellVmin * nCellSer;
moduleVnom = cellVnom * nCellSer;
reqdAh = modulekWh * 1000 ./ moduleVnom';

nCellPar = round(reqdAh ./ cellAh);
moduleAh_actual = nCellPar .* cellAh;
moduleAh_actual(moduleAh_actual > balAh) = 0;

maxAh = max(modulekWh) * 1000 ./ moduleVnom';
maxAh = ceil(maxAh./balAh) * balAh;
moduleAh_actual = [moduleAh_actual; 0 0];

addlAh = [200; 300; (400:200:maxAh(1))'; (100:100:maxAh(2))'];
[row, col] = find(moduleAh_actual == 0);

for i=1:size(row,1)
    moduleAh_actual(row(i),col(i)) = addlAh(i);
end

pause

nBalModule = nCellSer' .* ceil(moduleAh_actual ./ balAh);
modulekWh_actual = nCellSer' .* cellVnom .* moduleAh_actual / 1000; % Andrew used this mean cellV (cellVnom) to compute modulekWh, not sure why

nModSer = ceil(packV ./ moduleVmax);
nModPar = ceil(packkWh ./ (nModSer' .* modulekWh_actual));

packV = nModSer .* [moduleVmin moduleVmax];

nBalPack = nBalModule .* nModSer' .* nModPar;
packkWh_actual = modulekWh_actual .* nModSer' .* nModPar;


figure
subplot(1,2,1)
plot(modulekWh, nBalPack(:,1), '-o', modulekWh, nBalPack(:,2),'-o')
legend('50 V modules', '100 V modules')
xlabel('Module capacity (kWh)')
ylabel(sprintf('# balancing circuits in %d kWh pack', packkWh))
title('Number of balancing circuits in AC pack for different module configurations')
xticks(modulekWh')
xtickangle(45)
subplot(1,2,2)
%figure
plot(modulekWh, packkWh_actual(:,1), '-o', modulekWh, packkWh_actual(:,2), '-o')
xlabel('Module capacity (kWh)')
ylabel('Actual pack capacity (kWh)')
xticks(modulekWh')
xtickangle(45)
title('Actual AC pack capacity for different module configurations')
legend('50 V modules', '100 V modules')

moduleAh_t = reshape(moduleAh_actual, size(modulekWh,1)*size(moduleV,1),1);
nBalPack_t = reshape(nBalPack, size(moduleAh_t));
modulekWh_actual_t = reshape(modulekWh_actual,size(moduleAh_t));

packkWh_actual_t = reshape(packkWh_actual, size(moduleAh_t));
nModPar_t  = reshape(nModPar, size(moduleAh_t));
packConfig = cell(size(moduleAh_t));
modulekWh_actual_t1 = cell(size(moduleAh_t));
packkWh_actual_t1 = cell(size(moduleAh_t));
for i = 1:size(moduleAh_t)
    packConfig{i} = sprintf('%ds%dp', nModSer(1), nModPar_t(i));
    if i > size(modulekWh)
        packConfig{i} = sprintf('%ds%dp', nModSer(2), nModPar_t(i));
    end
    modulekWh_actual_t1{i} = sprintf('%0.2f', modulekWh_actual_t(i));
    packkWh_actual_t1{i} = sprintf('%0.2f', packkWh_actual_t(i));
end

packConfig = string(packConfig);
modulekWh_actual_t1 = string(modulekWh_actual_t1);
packkWh_actual_t1 = string(packkWh_actual_t1);

varNames = {'Module Ah', 'Module kWh', 'Pack config', '# bal circuits/pack', 'Pack capacity (kWh)'};
rowNames = cell(size(modulekWh,1), size(moduleV,1));
for i = 1:size(modulekWh)
    rowNames{i} = sprintf('%g kWh module', modulekWh(i));
end
%rowNames = reshape(rowNames, size(moduleAh_t));
%title1 = sprintf('Pack comparisons for %g-%g kWh modules. \n Vmod = %g-%g V, Vpack = %g-%g V', ...
%    min(modulekWh), max(modulekWh), moduleVmin, moduleVmax, min(packV), max(packV));
C = {moduleAh_t(1:size(modulekWh)), modulekWh_actual_t1(1:size(modulekWh)), ...
   packConfig(1:size(modulekWh)), nBalPack_t(1:size(modulekWh)), packkWh_actual_t1(1:size(modulekWh))};
T = table(C{:});
T.Properties.RowNames = rowNames(:,1);
T.Properties.VariableNames = varNames;
%disp(title1)
disp(T)

C2 = {moduleAh_t(size(modulekWh)+1:end), modulekWh_actual_t1(size(modulekWh)+1:end), ... 
    packConfig(size(modulekWh)+1:end), nBalPack_t(size(modulekWh)+1:end), packkWh_actual_t1(size(modulekWh)+1:end)};
T2 = table(C2{:});
T2.Properties.RowNames = rowNames(:,1);
T2.Properties.VariableNames = varNames;
disp(T2)

fig = uifigure('HandleVisibility','on','Position', [500 500 800 550]);
% fig.Position = [500 500 520 520];

t = uitable(fig, 'Data', T, 'Position', [0 250 800 230]);
%t.Position(3:4) = t.Extent(3:4);
s = uistyle('HorizontalAlignment', 'center');
addStyle(t,s);
title1 = sprintf('%gV modules: Vmod = %g-%g V, Vpack = %g-%g V, %g cells in series', ...
    moduleV(1), moduleVmin(1), moduleVmax(1), min(packV(1,:)), max(packV(1,:)), nCellSer(1));
title1_obj = uitextarea(fig, 'Value', title1,'Position', [0 480 800 20]);
s1 = uistyle('FontColor', 'r');

row1 = find(moduleAh_t(1:size(modulekWh)) > balAh);
col1 = ones(size(row1));
addStyle(t,s1, 'cell',[row1,col1])

row12 = find(packkWh_actual_t(1:size(modulekWh)) > 600);
col12 = 5*ones(size(row12));
addStyle(t,s1,'cell', [row12,col12])


t2 = uitable(fig, 'Data', T2, 'Position', [0 0 800 230]);
addStyle(t2,s);
title2 = sprintf('%gV modules: Vmod = %g-%g V, Vpack = %g-%g V, %g cells in series', ...
    moduleV(2), moduleVmin(2), moduleVmax(2), min(packV(2,:)), max(packV(2,:)), nCellSer(2));
title2_obj  = uitextarea(fig, 'Value', title2, 'Position', [0 230 800 20]);

row2 = find(moduleAh_t(size(modulekWh)+1:end) > balAh);
col2 = ones(size(row2));
addStyle(t2, s1, 'cell', [row2, col2])

row22 = find(packkWh_actual_t(size(modulekWh)+1:end) > 600);
col22 = 5*ones(size(row22));
addStyle(t2, s1, 'cell', [row22, col22])