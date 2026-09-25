function download_img(isVerbose)
%DOWNLOAD_IMG 演習用の画像データを data フォルダにダウンロードする
%
%   VIE.DOWNLOAD_IMG() は Kodak Lossless True Color Image Suite の画像
%   kodim01.png 〜 kodim24.png を VieWork プロジェクトの data フォルダに
%   ダウンロードします。すでに存在するファイルは再取得しません。
%
%   VIE.DOWNLOAD_IMG(ISVERBOSE) で進捗表示の有無を指定します（既定 true）。
%
%   データは Git の管理外です。クローン直後に一度実行してください。
%
%   See also VIE.PRJFOLDERS
%
% Copyright (c) Shogo MURAMATSU, 2026
% All rights reserved.
%

arguments
    isVerbose (1,1) logical = true
end

datfolder = vie.prjfolders();

baseurl = "https://www.r0k.us/graphics/kodak/kodak/";
for idx = 1:24
    fname = "kodim" + num2str(idx,'%02d') + ".png";
    dstfile = fullfile(datfolder,fname);
    if isfile(dstfile)
        if isVerbose
            fprintf('%s はすでに %s にあります\n',fname,datfolder);
        end
        continue
    end
    img = imread(baseurl + fname);
    imwrite(img,dstfile)
    if isVerbose
        fprintf('%s をダウンロードして %s に保存しました\n',fname,datfolder);
    end
end

disp('出典: <a href="http://www.r0k.us/graphics/kodak/">Kodak Lossless True Color Image Suite</a>')

end
