function y = arr2tex(x,format)
%ARR2TEX 数値配列を LaTeX の行列本体（& と \ で区切った文字列）に変換する
%
%   Y = VIE.ARR2TEX(X) は二次元配列 X を
%       x11 & x12 & ... \
%       x21 & x22 & ...
%   の形の文字列に変換します。pmatrix や bmatrix の中身としてそのまま使えます。
%
%   Y = VIE.ARR2TEX(X,FORMAT) で数値の書式（sprintf 形式）を指定します。
%   既定は "%g" です。
%
%   MsipWorkM の msip.arr2tex と同じ出力形式です。
%
%   例:
%       vie.arr2tex([1 2; 3 4])          % "1 & 2\ 3 & 4"
%       vie.arr2tex(magic(3)/9,"%.3f")
%
%   See also VIE.SAVETEX
%
% Copyright (c) Shogo MURAMATSU, 2026
% All rights reserved.
%
arguments
    x (:,:) {mustBeNumeric}
    format (1,1) string = "%g"
end

[rows,cols] = size(x);
lines = strings(rows,1);
for i = 1:rows
    lines(i) = strjoin(arrayfun(@(v) sprintf(format,v), x(i,:)), " & ");
end
y = strjoin(lines, "\\" + newline);
end
