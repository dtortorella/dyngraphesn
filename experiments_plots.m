load experiments.mat
M = mean(Acc, 4);
S = std(Acc, [], 4);
titleTexts = {'dblp ct1', 'facebook ct1', 'highschool ct1', 'infectious ct1', 'mit ct1', 'tumblr ct1', 'dblp ct2', 'facebook ct2', 'highschool ct2', 'infectious ct2', 'mit ct2', 'tumblr ct2'};
figure;
tiledlayout(2, 6, 'TileSpacing', 'compact');
markers = ['o', 's', '^', 'h', 'd'];
for i = 1:length(titleTexts)
    nexttile;
    %errorbar(squeeze(M(i,:,:)), squeeze(S(i,:,:)), 's-', 'CapSize', 0);
    hPlot = plot(squeeze(M(i,:,:)), '.-', 'MarkerSize', 6);
    for k = 1:length(H)
        hPlot(k).Marker = markers(k);
        hPlot(k).MarkerFaceColor = hPlot(k).Color;
        hPlot(k).MarkerEdgeColor = 'w';
    end
    xlim([L(1)-.2 L(end)+.2]);
    xticks(L);
    set(gca, 'XTickLabelRotation', 0);
    title(titleTexts{i});
end
hLegend = legend(hPlot, {'H = 1', 'H = 2', 'H = 4', 'H = 8', 'H = 16'}, 'Orientation', 'horizontal');
hLegend.ItemTokenSize = [10,20];
