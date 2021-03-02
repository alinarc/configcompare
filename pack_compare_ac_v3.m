close all
clear

format shortg 

moduleV = [50; 100];
blockAh = 100; % limiting the Ah with one balancing circuit to 100
modulekWh = [1:1:10]'; % desired module capacity range

packV = 650; 
packkWh = 400;
cellVmax = 3.6;
cellVmin = 1.5;

nCellSer = floor(moduleV./cellVmax); % # of series cells in a string with 50, 100 V
stringkWh_actual = cellVmax * nCellSer * blockAh / 1000;
nStringPar = round(modulekWh ./ stringkWh_actual'); % # of parallel strings in modules of specifed sizes

modulekWh_actual = stringkWh_actual' .* nStringPar;
moduleV_actual = cellVmax * nCellSer;

nModSer = round(packV./moduleV_actual);
packV_actual = nModSer .* moduleV_actual;

nModPar = round(packkWh ./ (nModSer' .* modulekWh_actual));
packkWh_actual = modulekWh_actual .* nModSer' .* nModPar;

nBalCircuits = get_num_bal_circuits(cellVmax, moduleV, packV, blockAh, ...
    modulekWh, packkWh); % total # balancing circuits in a pack
nBalCircuits_norm = nBalCircuits./packkWh_actual;
%pause

rowNames1 = cell(size(moduleV));
varNames1 = cell(size(modulekWh));

for i = 1:size(moduleV)
    rowNames1{i} = sprintf('%d V modules', moduleV(i));
end

for i = 1:size(modulekWh)
    varNames1{i} = sprintf('%d kWh modules', modulekWh(i));
end

T1 = array2table(nBalCircuits');
T1.Properties.RowNames = rowNames1;
T1.Properties.VariableNames = varNames1;
title1 = sprintf('Number of balancing circuits required in %d kWh pack', packkWh);

disp(title1)
disp(T1)

figure
subplot(1,2,1)
plot(modulekWh, nBalCircuits(:,1), '-o', modulekWh, nBalCircuits(:,2),'-o')
legend('50 V modules', '100 V modules')
xlabel('Module capacity (kWh)')
ylabel(sprintf('# balancing circuits in %d kWh pack', packkWh))
title('Number of balancing circuits in pack for different module configurations')
subplot(1,2,2)
plot(modulekWh, packkWh_actual(:,1), '-o', modulekWh, packkWh_actual(:,2), '-o')
xlabel('Module capacity (kWh)')
ylabel('Actual pack capacity (kWh)')
title('Actual pack capacity for different module configurations')
legend('50 V modules', '100 V modules')

%axis([0 50 1100 2200])
%pause

nBalCircuits_t = reshape(nBalCircuits,(size(modulekWh,1)*size(moduleV,1)),1);
packkWh_actual_t = reshape(packkWh_actual, size(nBalCircuits_t));
pctOversize = (packkWh_actual_t - packkWh) ./ packkWh * 100;

packVmax = zeros(size(modulekWh,1), size(moduleV,1));
packVmin = zeros(size(packVmax));
for i = 1:size(modulekWh)
    packVmax(i,:) = cellVmax .* (nCellSer .* nModSer)';
    packVmin(i,:) = cellVmin .* (nCellSer .* nModSer)';
end

packVmax_t = reshape(packVmax, size(nBalCircuits_t));
packVmin_t = reshape(packVmin, size(nBalCircuits_t));

alpha = 'abcdefghijklmnopqrztuvwxyz';
rowNames2 = cell(size(modulekWh,1), size(moduleV,1));
for i = 1:size(modulekWh,1)
    for j = 1:size(moduleV,1)
        rowNames2{i,j} = sprintf('%d.%c) %d V %d kWh %ds%dp', j, alpha(i), moduleV(j), modulekWh(i), nModSer(j), nModPar(i,j));
    end
end

varNames2 = {'# balancing circuits per pack', 'Actual pack capacity (kWh)', ...
    'Percent oversized (%)', 'Max pack voltage (V)', 'Min pack voltage (V)'};

T2 = table(nBalCircuits_t, packkWh_actual_t, pctOversize, packVmax_t, packVmin_t);
T2.Properties.RowNames = rowNames2;
T2.Properties.VariableNames = varNames2;
title2 = 'Pack comparisons for 50/100V, 10-40 kWh modules';
disp(title2)
disp(T2)

