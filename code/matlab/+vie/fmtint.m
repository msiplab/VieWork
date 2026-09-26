function s = fmtint(v)
%FMTINT 整数を 3 桁ごとにカンマで区切った LaTeX 用の文字列にする
%
%   S = VIE.FMTINT(V) は数値 V を四捨五入して整数にし，
%   3 桁ごとに "{,}" を挟んだ文字列を返します（数式中で余分な空白が入らない）。
%
%   例:
%       vie.fmtint(16588800)     % "16{,}588{,}800"
%
%   See also VIE.SAVETEX
%
% Copyright (c) Shogo MURAMATSU, 2026
% All rights reserved.
%
arguments
    v (1,1) {mustBeNumeric}
end
s = string(sprintf("%d", round(v)));
s = regexprep(s, "(\d)(?=(\d{3})+$)", "$1{,}");
end
