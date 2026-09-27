function [X, imgfile] = msipimg(idx, sz, mode)
%MSIPIMG 教科書のサンプル画像 msipimg##.tif を読み込む
%
%   X = VIE.MSIPIMG(IDX) は，教科書 MsipText のサンプル画像
%   msipimgNN.tif（NN = IDX，1〜8，512×512 のカラー画像）を uint8 の
%   RGB 配列として返します。スライドに採用する写真はこの 8 枚に限ります。
%
%   X = VIE.MSIPIMG(IDX, SZ) は大きさ SZ（スカラーなら正方形）に縮小します。
%   X = VIE.MSIPIMG(IDX, SZ, "gray") はグレースケール（rgb2gray）で返します。
%   [X, IMGFILE] = VIE.MSIPIMG(...) は読み込んだファイルの場所も返します。
%
%   画像は次の順に探します。
%     1. VieWork の data フォルダ
%     2. VieWork と同じ階層に置いた MsipWorkM の data フォルダ
%     3. GitHub（msiplab/MsipWorkM）から data フォルダに取得
%
%   内容：01 海岸，02 花束，03 マカロン，04 石造りの建物，05 石像の顔，
%         06 縞模様の路面，07 モンブラン，08 スイカ
%
%   例:
%       X = vie.msipimg(2);                 % 花束（カラー，512×512）
%       Y = vie.msipimg(4, 256, "gray");    % 建物（グレースケール，256×256）
%
%   See also VIE.PRJFOLDERS
%
% Copyright (c) Shogo MURAMATSU, 2026
% All rights reserved.
%

arguments
    idx (1,1) double {mustBeInteger, mustBeInRange(idx,1,8)}
    sz double = []
    mode (1,1) string {mustBeMember(mode,["rgb","gray"])} = "rgb"
end

fname = sprintf("msipimg%02d.tif", idx);
[datfolder,~,prjroot] = vie.prjfolders();
imgfile = fullfile(datfolder, fname);
if ~isfile(imgfile)
    sibling = fullfile(fileparts(prjroot), "MsipWorkM", "data", fname);
    if isfile(sibling)
        imgfile = sibling;
    else
        websave(imgfile, "https://raw.githubusercontent.com/msiplab/MsipWorkM/master/data/" + fname);
    end
end

X = imread(imgfile);
if size(X,3) == 4          % アルファチャネルがあれば落とす
    X = X(:,:,1:3);
end
if mode == "gray"
    X = rgb2gray(X);
end
if ~isempty(sz)
    if isscalar(sz), sz = [sz sz]; end
    X = imresize(X, sz, "bicubic");
end

end
