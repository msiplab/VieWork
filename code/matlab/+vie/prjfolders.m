function [datfolder,resfolder,prjroot] = prjfolders()
%PRJFOLDERS VieWork プロジェクトの data/results フォルダを返す
%
%   [DATFOLDER,RESFOLDER] = VIE.PRJFOLDERS() は，VieWork プロジェクトの
%   ルート直下の data フォルダと results フォルダの絶対パスを返します。
%   フォルダが存在しない場合は作成します（data と results は Git の管理外
%   なので，クローン直後には存在しません）。
%
%   [DATFOLDER,RESFOLDER,PRJROOT] = VIE.PRJFOLDERS() はプロジェクトルートも
%   返します。
%
%   プロジェクトが開かれていない場合は，このファイルの位置
%   （<root>/code/matlab/+vie/prjfolders.m）からルートを推定します。
%
%   例:
%       [datfolder,resfolder] = vie.prjfolders();
%       X = imread(fullfile(datfolder,"kodim01.png"));
%       imwrite(X,fullfile(resfolder,"vie-01-org.png"))
%
%   See also VIE.DOWNLOAD_IMG
%
% Copyright (c) Shogo MURAMATSU, 2026
% All rights reserved.
%

prjroot = "";
try
    prj = matlab.project.currentProject;
    % プロジェクトが開かれていないと，エラーにならずに空のプロジェクトが
    % 返ることがある（RootFolder が空）。その場合は下のフォールバックに回す。
    if ~isempty(prj) && strlength(string(prj.RootFolder)) > 0 ...
            && isfile(fullfile(prj.RootFolder,"VieWork.prj"))
        prjroot = string(prj.RootFolder);
    end
catch
end
if strlength(prjroot) == 0
    % ファイル位置から推定する。
    % このファイルは <root>/code/matlab/+vie/prjfolders.m にある。
    here = fileparts(mfilename("fullpath"));            % .../code/matlab/+vie
    prjroot = string(fileparts(fileparts(fileparts(here))));
end

datfolder = fullfile(prjroot,"data");
resfolder = fullfile(prjroot,"results");

for folder = [datfolder resfolder]
    if ~isfolder(folder)
        mkdir(folder)
    end
end

end
