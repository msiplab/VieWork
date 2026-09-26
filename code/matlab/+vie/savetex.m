function filename = savetex(name,content)
%SAVETEX スライドに取り込む LaTeX の断片を results フォルダに書き出す
%
%   FILENAME = VIE.SAVETEX(NAME,CONTENT) は文字列 CONTENT を
%   results/NAME.tex として UTF-8 で保存し，そのパスを返します。
%
%   ライブスクリプトで計算した数値（行列，表，数値例の答え）を，
%   手で書き写さずにスライドへ反映するための仕組みです。
%   VieSlides の tools/sync-results.ps1 が results/vie-*.tex を
%   VieSlides/snippets/ に複写し，スライドは \viesnippet{NAME} で読み込みます。
%
%   NAME は "vie-NN-..." の形（NN は講義回）にしてください。
%
%   例:
%       X = [1 2; 3 4];
%       vie.savetex("vie-04-example", "\begin{pmatrix}" + vie.arr2tex(X) + "\end{pmatrix}")
%
%   See also VIE.ARR2TEX, VIE.PRJFOLDERS
%
% Copyright (c) Shogo MURAMATSU, 2026
% All rights reserved.
%
arguments
    name (1,1) string
    content (1,1) string
end

[~,resfolder] = vie.prjfolders();
filename = fullfile(resfolder, name + ".tex");
header = "% " + name + ".tex --- VieWork のライブスクリプトが自動生成．直接編集しない．" + newline;
fid = fopen(filename,"w","n","UTF-8");
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,"%s%s%%\n",header,content);
end
