function multiparam

spatialDomainSize = 10000; % micrometers
spatialDomainStep = 100; % micrometers
timeDomainSize = 100000; % seconds
timeDomainStep = 50; % seconds

tipVelocity = 0.11574; % This is about 1cm growth per day.

paramInitValues = struct( ...
  'actBaseProd', 0.0033, ...
  'actDecayCoeff', 0.00019, ...
  'actDenominatorDefault', 1, ...
  'actDiffuCoeff', 0.001, ...
  'actSourceDensity', 0.00018, ...
  'inhDecayCoeff', 0.00025, ...
  'inhDiffuCoeff', 20, ...
  'inhSourceDensity', 0.00001 ...
);

howManyParametersToTweak = size(fieldnames(paramInitValues), 1);
matrixWhoseEachRowIndicatesWhetherAParamWillBeTweaked = ...
  dec2bin(0:2^howManyParametersToTweak - 1) - '0';

tableSavePath = ...
  fullfile(fileparts(fileparts(mfilename('fullpath'))), 'multiparam_table.md');

% empty file and write out the table header
tableFileFid = fopen(tableSavePath, 'w');
fprintf( ...
  tableFileFid, ...
  strjoin( ...
    { ...
      'index', ...
      'c', ...
      'mu', ...
      'h_0', ...
      'D_a', ...
      'rho_a', ...
      'nu', ...
      'D_h', ...
      'rho_h', ...
      'Spatial intervals mean', ...
      'Spatial intervals stdev', ...
      'Spatial peaks count', ...
      'Any negative act concen?', ...
      'Any negative inh concen?', ...
      'Activator image', ...
      'Inhibitor image', ...
    }, ...
    ' | ' ...
  ) ...
);
fprintf(tableFileFid, '\n');
fprintf( ...
  tableFileFid, ...
  strjoin( ...
    { ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------', ...
      '------' ...
    }, ...
    ' | ' ...
  ) ...
);
fprintf(tableFileFid, '\n');

for rowIdx = 1:size(matrixWhoseEachRowIndicatesWhetherAParamWillBeTweaked, 1)
  row = matrixWhoseEachRowIndicatesWhetherAParamWillBeTweaked(rowIdx, :);

  actBaseProd = paramInitValues.actBaseProd           * (1 + (row(1) > 0) * 9);
  actDecayCoeff = paramInitValues.actDecayCoeff       * (1 + (row(2) > 0) * 9);
  actDenominatorDefault = ...
    paramInitValues.actDenominatorDefault             * (1 + (row(3) > 0) * 9);
  actDiffuCoeff = paramInitValues.actDiffuCoeff       * (1 + (row(4) > 0) * 9);
  actSourceDensity = paramInitValues.actSourceDensity * (1 + (row(5) > 0) * 9);
  inhDecayCoeff = paramInitValues.inhDecayCoeff       * (1 + (row(6) > 0) * 9);
  inhDiffuCoeff = paramInitValues.inhDiffuCoeff       * (1 + (row(7) > 0) * 9);
  inhSourceDensity = paramInitValues.inhSourceDensity * (1 + (row(8) > 0) * 9);

  pdeSolutions = getPdeSolutions( ...
    actBaseProd, ...
    actDecayCoeff, ...
    actDenominatorDefault, ...
    actDiffuCoeff, ...
    actSourceDensity, ...
    tipVelocity, ...
    inhDecayCoeff, ...
    inhDiffuCoeff, ...
    inhSourceDensity, ...
    spatialDomainSize, ...
    spatialDomainStep, ...
    timeDomainSize, ...
    timeDomainStep);

  actConcenSolutions = pdeSolutions(:,:,1);
  inhConcenSolutions = pdeSolutions(:,:,2);
  
  if min(actConcenSolutions(:)) < 0
    actHasNegConcen = 'Y';
  else
    actHasNegConcen = 'N';
  end

  if min(inhConcenSolutions(:)) < 0
    inhHasNegConcen = 'Y';
  else
    inhHasNegConcen = 'N';
  end

  computeSpatialIntervalsAtThisTMeshIndex = size(actConcenSolutions, 1);
  [allLocalMaxima, allLocalMaximaLocations] = ...
    findpeaks(actConcenSolutions(computeSpatialIntervalsAtThisTMeshIndex, :));
  [~, essentialMaximaLocations] = findpeaks(allLocalMaxima);
  
  essentialMaximaCount = size(essentialMaximaLocations, 2);

  spatialIntervalPeakLocations = zeros(essentialMaximaCount);
  
  for i = 1:essentialMaximaCount
    spatialIntervalPeakLocations(i) = ...
      allLocalMaximaLocations(essentialMaximaLocations(i));
  end
  
  spatialIntervalsMean = ...
    mean(diff(spatialIntervalPeakLocations)) * spatialDomainStep;
  spatialIntervalsStdev = ...
    std(diff(spatialIntervalPeakLocations)) * spatialDomainStep;
  spatialPeakCount = length(spatialIntervalPeakLocations);

  fprintf( ...
    tableFileFid, ...
    strcat( ...
      strjoin({ ...
        '%d', ... % rowIdx
        '%.6f', ... % actBaseProd
        '%.6f', ... % actDecayCoeff
        '%.6f', ... % actDenominatorDefault
        '%.6f', ... % actDiffuCoeff
        '%.6f', ... % actSourceDensity
        '%.6f', ... % inhDecayCoeff
        '%.6f', ... % inhDiffuCoeff
        '%.6f', ... % inhSourceDensity
        '%.2f', ... % spatialIntervalsMean
        '%.2f', ... % spatialIntervalsStdev
        '%d', ... % spatialPeakCount
        '%s', ... % actHasNegConcen
        '%s', ... % inhHasNegConcen
        strcat( ...
          '![](./assets/multiparam_results/', ...
          num2str(rowIdx), ...
          '-act.png)'), ...
        strcat( ...
          '![](./assets/multiparam_results/', ...
          num2str(rowIdx), ...
          '-inh.png)'), ...
      }, ' | '), ...
      '\n' ...
    ), ...
    rowIdx, ...
    actBaseProd, ...
    actDecayCoeff, ...
    actDenominatorDefault, ...
    actDiffuCoeff, ...
    actSourceDensity, ...
    inhDecayCoeff, ...
    inhDiffuCoeff, ...
    inhSourceDensity, ...
    spatialIntervalsMean, ...
    spatialIntervalsStdev, ...
    spatialPeakCount, ...
    actHasNegConcen, ...
    inhHasNegConcen ...
  );

  actSavePath = ...
    fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
      'multiparam_results', strcat(num2str(rowIdx), '-act.fig'));
  inhSavePath = ...
    fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
      'multiparam_results', strcat(num2str(rowIdx), '-inh.fig'));

  actFig = getActOrInhConcens3DFigure( ...
    [
      'a(x,t) : ' ...
      ' v=',num2str(tipVelocity), ...
      ' c=',num2str(actBaseProd), ...
      ' \mu=',num2str(actDecayCoeff), ...
      ' h_0=',num2str(actDenominatorDefault), ...
      ' D_a=',num2str(actDiffuCoeff), ...
      ' \rho_a=',num2str(actSourceDensity), ...
      ' \nu=',num2str(inhDecayCoeff), ...
      ' D_h=',num2str(inhDiffuCoeff), ...
      ' \rho_h=',num2str(inhSourceDensity) ...
    ], ...
    actConcenSolutions, ...
    spatialDomainSize, ...
    spatialDomainStep, ...
    timeDomainSize, ...
    timeDomainStep);
  saveas(actFig, actSavePath);

  inhFig = getActOrInhConcens3DFigure( ...
    [
      'h(x,t) : ' ...
      ' v=',num2str(tipVelocity), ...
      ' c=',num2str(actBaseProd), ...
      ' \mu=',num2str(actDecayCoeff), ...
      ' h_0=',num2str(actDenominatorDefault), ...
      ' D_a=',num2str(actDiffuCoeff), ...
      ' \rho_a=',num2str(actSourceDensity), ...
      ' \nu=',num2str(inhDecayCoeff), ...
      ' D_h=',num2str(inhDiffuCoeff), ...
      ' \rho_h=',num2str(inhSourceDensity) ...
    ], ...
    inhConcenSolutions, ...
    spatialDomainSize, ...
    spatialDomainStep, ...
    timeDomainSize, ...
    timeDomainStep);
  saveas(inhFig, inhSavePath);

  close all;

end
