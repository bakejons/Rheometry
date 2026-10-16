
% Open dialog to select multiple files

%%
fullfiles = getfiles();
% ---- Load everything ----------------------------------------------------
D = loadRheologyData(fullfiles);

disp(D.info)                                   % one row per sample / run

% ---- Raw access ---------------------------------------------------------
r  = D.runs(3);                                % one run
gd = r.data.ShearRate_1s;                      % shear rate  [1/s]
eta = r.data.Viscosity_cP;                     % viscosity   [cP]

% % ---- Select + plot (all 25 C runs with 5% naphtha) ----------------------
% idx = find(D.info.T_C == 25 & D.info.Naphtha_wt == 5);
% plotViscosity(D, idx);
% 
% % ---- 15% PW with Hx, no naphtha, incl. retests --------------------------
% idx = find(D.info.T_C == 25 & D.info.PW_wt == 15 & D.info.Naphtha_wt == 0);
% plotViscosity(D, idx);

% ---- Later: add runs at another temperature -----------------------------
% D = loadRheologyData('15kCSt_MO_blends_40C.csv', 'Append', D);   % T auto-detected
% D = loadRheologyData('some_file.csv', 'Append', D, 'Temperature', 40);  % or force it
% idx = find(D.info.T_C == 40);  plotViscosity(D, idx);

%% plots
close all
plotViscosity(D, 23:-1:20);
plotViscosity(D, [23, 2, 4, 3, 5]);
plotViscosity(D, [23, 6:1:9]);
plotViscosity(D, [23, 10:1:13]);
plotViscosity(D, [23, 16:-1:14]);

%%
plotViscosity(D, [23, 17:-1:14]);