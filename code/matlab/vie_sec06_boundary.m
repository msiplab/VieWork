%[text] # 第6回 境界処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第6回のスライド（vie2026-06）で使う図と数値を作る。畳み込みと相互相関，FIR/IIR システム，可分離システム，有限長信号の畳み込みと境界処理（零値・周期・複製・対称拡張），循環畳み込み，内積・ノルムと線形フィルタ，列ベクトル化と行列表現，スペクトルノルムを扱う。
%[text] 記号は教科書（村松正吾『多次元信号・画像処理の基礎と展開』）に合わせる。配列の添え字の次元は 1 始まり（ $ \\boldsymbol{n}=(n\_1\\ n\_2)^\\top $ ， $ n\_1 $ が垂直（行）， $ n\_2 $ が水平（列））で，各次元の添え字の値は 0 始まり。MATLAB の配列の添え字（1 始まり）とは 1 ずれることに注意する。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図の配色はスライドのロゴの 3 色（メインの緑，寒色系の青，暖色系の橙）と灰色を使う。
[~,resfolder] = vie.prjfolders();
cMain = [0 136 85]/255;                             % 緑 #008855（メイン）
cCool = [46 117 182]/255;                           % 青 #2E75B6（寒色系）
cWarm = [197 90 17]/255;                            % 橙 #C55A11（暖色系）
cGray = [0.6 0.6 0.6];                              % 灰色
%%
%[text] ## 二次元畳み込みの計算例
%[text] 前回スライドの例。入力 $ 3\\times3 $ ，インパルス応答 $ 3\\times3 $ （中心が原点， $ \\mathcal{N}\_\\mathrm{h}=\\{-1,0,1\\}^2 $ ）。線形畳み込み
%[text]{"align":"center"} $ y[\\boldsymbol{n}]=\\sum\_{\\boldsymbol{m}\\in\\mathcal{N}\_x}x[\\boldsymbol{m}]h[\\boldsymbol{n}-\\boldsymbol{m}] $
%[text] の出力は $ 5\\times5 $ に広がる（ `conv2` の `full` ）。
X2 = [1 2 3; 4 5 6; 7 8 9];
H2 = [1 0 -1; 1 0 -1; 1 0 -1];
Y2 = conv2(X2, H2)                                 % full：出力は 5×5
vie.savetex("vie-06-conv2-x", vie.arr2tex(X2,"%d"));
vie.savetex("vie-06-conv2-h", vie.arr2tex(H2,"%d"));
vie.savetex("vie-06-conv2-y", vie.arr2tex(Y2,"%d"));
%[text] 左上の出力 $ y[-1,-1]=x[0,0]\\,h[-1,-1] $ は 1 項だけの積：
y00 = Y2(1,1)
vie.savetex("vie-06-conv2-y00", sprintf("%d", y00));
%[text] スライドでは出力を段階的に見せる（空欄 → 例の 1 要素だけ → 全体）。空欄は `\phantom` で幅を保ち，例の要素は暖色で強調する。
M00 = false(size(Y2)); M00(1,1) = true;             % y[-1,-1]（左上）
Mc  = false(size(Y2)); Mc(3,3)  = true;             % y[1,1]（中央）
vie.savetex("vie-06-conv2-y-blank", arr2texshow(Y2, false(size(Y2)), "%d"));
vie.savetex("vie-06-conv2-y-ex00",  arr2texshow(Y2, M00, "%d"));
vie.savetex("vie-06-conv2-y-hl00",  arr2texshow(Y2, true(size(Y2)), "%d", M00));
vie.savetex("vie-06-conv2-y-exc",   arr2texshow(Y2, Mc, "%d"));
vie.savetex("vie-06-conv2-y-hlc",   arr2texshow(Y2, true(size(Y2)), "%d", Mc));
%[text] インパルス応答の重み付け和の一例として， $ x[0,0] $ 倍したインパルス応答を位置 $ [0\ 0]^\top $ にずらしたもの（出力の左上 $ 3\times3 $ ）だけを出力の枠に書く。
Cimp = zeros(size(Y2)); Cimp(1:3,1:3) = X2(1,1)*H2;  % x[0,0] h[n - [0 0]^T]
Mimp = false(size(Y2)); Mimp(1:3,1:3) = true;
Simp = string(arrayfun(@(v) sprintf("%d", v), Cimp, "UniformOutput", false));
Simp(Mimp) = "\alert{" + Simp(Mimp) + "}";
Sy = string(arrayfun(@(v) sprintf("%d", v), Y2, "UniformOutput", false));
Simp(~Mimp) = "\phantom{" + Sy(~Mimp) + "}";              % 幅は出力 y と同じにする
vie.savetex("vie-06-conv2-y-imp00", strjoin(join(Simp, " & ", 2), "\\" + newline));
M00x = false(size(X2)); M00x(1,1) = true;          % x[0,0]
vie.savetex("vie-06-conv2-x-hl00",  arr2texshow(X2, true(size(X2)), "%d", M00x));
%[text] 相互相関の例では，カーネルの中心を入力の中央の画素 $ x[1,1] $ に合わせる。両方の中心を強調した版も書き出す。
Mcx = false(size(X2)); Mcx(2,2) = true;
vie.savetex("vie-06-conv2-x-hlc",   arr2texshow(X2, true(size(X2)), "%d", Mcx));
%[text] 各軸を反転したインパルス応答（フィルタカーネル） $ f[\\boldsymbol{n}]=h[-\\boldsymbol{n}] $ との相互相関としても同じ結果になる（ `filter2` は相関を計算する）。
W2 = rot90(H2, 2)                                   % 各軸を反転
isequal(filter2(W2, X2, "full"), Y2)
vie.savetex("vie-06-conv2-w", vie.arr2tex(W2,"%d"));
vie.savetex("vie-06-conv2-w-hlc",   arr2texshow(W2, true(size(W2)), "%d", Mcx));
%[text] 出力の中央 $ y[1,1] $ （ $ \\mathsf{x} $ の中央の画素に対応）は，反転カーネルを重ねた積和。行の順に項を並べた式もスライド用に書き出す。
yc = sum(W2 .* X2, "all")
terms = strings(1, numel(X2));
Wt = W2'; Xt = X2';                                 % 行の順（左上→右）に並べるため転置
for k = 1:numel(X2)
    terms(k) = coef2tex(Wt(k)) + "\cdot" + sprintf("%d", Xt(k));
end
vie.savetex("vie-06-conv2-terms", strjoin(terms, "+"));
vie.savetex("vie-06-conv2-yc", sprintf("%d", yc));
%%
%[text] ## FIR システムと IIR システム
%[text] インパルス応答のサポート（非零係数の存在する領域）が有限なら FIR，無限なら IIR。IIR の例として理想低域通過フィルタ（sinc 関数の積）を，FIR の例として $ 7\\times7 $ のガウシアンを，同じ範囲に描く。横軸が $ n\_2 $ （水平），奥行きが $ n\_1 $ （垂直）。
[n2g,n1g] = meshgrid(-15:15);                       % 列方向が n2，行方向が n1
hIIR = sinc(n1g/3).*sinc(n2g/3)/9;                  % 無限に広がる（ここでは一部だけ表示）
hFIR = zeros(size(n1g));
g = fspecial("gaussian", 7, 1.2);
hFIR(13:19,13:19) = g;                              % 中央 7×7 以外は零
cmapG = interp1([0 0.5 1], [cMain*0.55+0.45; cMain; cMain*0.55], linspace(0,1,64));  % 緑の濃淡
fig = figure("Units","centimeters","Position",[2 2 16 7.5]);
tiledlayout(fig,1,2,"TileSpacing","compact","Padding","compact")
titles = ["IIR（サポートが無限）","FIR（サポートが有限）"];
hs = {hIIR, hFIR};
for k = 1:2
    ax = nexttile;
    mesh(ax, n2g, n1g, hs{k}), axis(ax,"tight"), view(ax,-30,35)
    colormap(ax, cmapG)
    title(ax, titles(k))
    xlabel(ax, "$n_2$", "Interpreter","latex"), ylabel(ax, "$n_1$", "Interpreter","latex")
    set(ax, "FontSize", 9)
end
exportgraphics(fig, fullfile(resfolder,"vie-06-firiir.png"), "Resolution", 150)
%%
%[text] ## 可分離システム
%[text] $ 3\\times3 $ 矩形フィルタは $ h[n\_1,n\_2]=h\_1[n\_1]h\_2[n\_2] $ ， $ h\_1=h\_2=\\frac13(1,1,1) $ と分離できる。二次元畳み込みを一次元畳み込み 2 回で計算しても同じ結果になる。
h1 = ones(3,1)/3;
Hsep = h1*h1'                                       % 1/9 が並ぶ
Xr = magic(6);
Ya = conv2(Xr, Hsep);                               % 二次元畳み込み
Yb = conv2(conv2(Xr, h1), h1');                     % 縦（n1）→横（n2）の一次元畳み込み
maxdiff = max(abs(Ya - Yb), [], "all")              % 丸め誤差程度
%[text] 分離可能かどうかは，二次元なら特異値分解で確かめられる（ランク 1 なら非零の特異値は 1 個）。
svd(Hsep)'
%[text] $ K\\times K $ カーネルの一画素当たりの乗算回数は，そのままだと $ K^2 $ ，分離すると $ 2K $ 。
K = [3 5 9 17];
mults = [K.^2; 2*K]
vie.savetex("vie-06-sep-K",  strjoin(string(K)," & "));
vie.savetex("vie-06-sep-K2", strjoin(string(K.^2)," & "));
vie.savetex("vie-06-sep-2K", strjoin(string(2*K)," & "));
%%
%[text] ## 有限長信号の畳み込み
%[text] 前回スライドの例。 $ x[n]=(1,2,4,2) $ （ $ n=0,1,2,3 $ ）， $ h[n]=(\\frac14,\\frac12,\\frac14) $ （ $ n=-1,0,1 $ ，非因果的）。出力のサポートはミンコフスキー和 $ \\{0,1,2,3\\}+\\{-1,0,1\\}=\\{-1,0,\\ldots,4\\} $ で，6 点に増える。
x1 = [1 2 4 2];   nx1 = 0:3;
h1d = [1/4 1/2 1/4]; nh1 = -1:1;
y1 = conv(x1, h1d)                                  % n = -1,0,1,2,3,4
ny1 = (nx1(1)+nh1(1)):(nx1(end)+nh1(end))
vie.savetex("vie-06-fin-y", strjoin(compose("%g",y1),",\ "));
%[text] 入力・インパルス応答・出力を並べて描く。増えた 2 点（ $ n=-1,4 $ ）は橙で示す。
fig = figure("Units","centimeters","Position",[2 2 11.5 3.3]);
tl = tiledlayout(fig,1,8,"TileSpacing","loose","Padding","compact");
ax = nexttile(tl,[1 3]);
stemtex(ax, nx1, x1, cCool, compose("%g",x1), [-1.5 4.5], [0 4.8]);
title(ax, "$x[n]$", "Interpreter","latex")
ax = nexttile(tl,[1 2]);
stemtex(ax, nh1, h1d*4, cMain, ["1/4","1/2","1/4"], [-1.8 1.8], [0 4.8]);   % 見やすさのため 4 倍の高さで描く
title(ax, "$h[n]$", "Interpreter","latex")
text(ax, -0.32, 0.4, "$\ast$", "Units","normalized", "Interpreter","latex", "FontSize",14, "HorizontalAlignment","center")
text(ax, 1.3, 0.4, "$=$", "Units","normalized", "Interpreter","latex", "FontSize",14, "HorizontalAlignment","center")
ax = nexttile(tl,[1 3]);
stemtex(ax, ny1, y1, [cWarm; repmat(cCool,4,1); cWarm], compose("%g",y1), [-1.8 4.8], [0 4.8]);
title(ax, "$y[n]$", "Interpreter","latex")
exportgraphics(fig, fullfile(resfolder,"vie-06-fin-conv.png"), "Resolution", 300)
%%
%[text] ## 一次元の境界処理
%[text] $ x[n]=(1,2,4,2) $ を両側 2 点ずつ拡張する。教科書 3.1.3 項の式どおりに外挿の添え字を計算する局所関数 `bndpad` （このスクリプトの末尾）を使う。周期拡張は `circular` ，複製拡張は `replicate` ，対称拡張（標本間対称 HS）は `symmetric` として `padarray` でも得られる。標本上対称（WS）は `padarray` に無いので添え字を折り返して作る。
methods = ["zero","circ","repl","hs","ws"];
pads = zeros(5, numel(x1)+4);
for k = 1:5
    pads(k,:) = bndpad(x1, [0 2], methods(k));
end
pads
isequal(pads(1:4,:), [padarray(x1,[0 2],0); padarray(x1,[0 2],"circular"); ...
    padarray(x1,[0 2],"replicate"); padarray(x1,[0 2],"symmetric")])
for k = 1:5
    vie.savetex("vie-06-pad"+k, strjoin(string(pads(k,:))," & "));
end
%%
%[text] ## 画像の境界処理の例
%[text] 教科書のサンプル画像 msipimg06（縞模様の路面，256×256 に縮小）に $ 17\\times17 $ のガウシアン（ $ \\sigma\_\\mathrm{g}=4 $ ）を施す。拡張点数は 16 点（両側 8 点）。路面が明るく，画像の四辺とも明るい画素が接しているので，零値拡張で縁が黒く滲む様子がどの辺でもはっきり見える。対称拡張では滲まない。
Xc = im2double(vie.msipimg(6, 256));                % 縞模様の路面（256×256）
Xc = min(max(Xc,0),1);
fgau = fspecial("gaussian", 17, 4);
Ez = padarray(Xc, [8 8], 0);                        % 零値拡張画像
Es = padarray(Xc, [8 8], "symmetric");              % 対称拡張画像
Yz = imfilter(Xc, fgau, 0);                         % 零値拡張で処理
Ys = imfilter(Xc, fgau, "symmetric");               % 対称拡張で処理
figure
tiledlayout(2,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Ez), title("零値拡張画像")
nexttile, imshow(Yz), title("処理画像（零値拡張）")
nexttile, imshow(Es), title("対称拡張画像")
nexttile, imshow(Ys), title("処理画像（対称拡張）")
imwrite(Ez, fullfile(resfolder,"vie-06-pad-zero.png"))
imwrite(Es, fullfile(resfolder,"vie-06-pad-sym.png"))
imwrite(Yz, fullfile(resfolder,"vie-06-out-zero.png"))
imwrite(Ys, fullfile(resfolder,"vie-06-out-sym.png"))
imwrite(imresize(Yz(1:40,1:40,:), 3, "nearest"), fullfile(resfolder,"vie-06-out-zero-zoom.png"))
imwrite(imresize(Ys(1:40,1:40,:), 3, "nearest"), fullfile(resfolder,"vie-06-out-sym-zoom.png"))
%[text] 左上隅の画素の明るさ（R 成分）を比べると，零値拡張では暗くなる。
cornerv = [Xc(1,1,1) Yz(1,1,1) Ys(1,1,1)]
vie.savetex("vie-06-corner-org", sprintf("%.2f",cornerv(1)));
vie.savetex("vie-06-corner-z",   sprintf("%.2f",cornerv(2)));
vie.savetex("vie-06-corner-s",   sprintf("%.2f",cornerv(3)));
%%
%[text] ## 例題「境界処理」（教科書 3.1.3 項）
%[text] 例題「矩形フィルタ」（3.1.1 項）の配列
%[text]{"align":"center"} $ \\mathsf{x}=\\begin{pmatrix}18&9&9&9\\\\27&9&9&9\\\\36&9&9&9\\end{pmatrix}\\in\\mathbb{R}^{3\\times4} $
%[text] に，零値拡張，周期拡張，複製拡張，対称拡張（HS・WS）を施す。ただし $ \\mathcal{N}\_\\mathrm{pad}=\\{-2,-1,\\ldots,4\\}\\times\\{-2,-1,\\ldots,5\\} $ （両側 2 点ずつ， $ 7\\times8 $ ）。 `bndpad` は教科書の式どおり $ d=1,2 $ の順に各次元を外挿する。
Xb = [18 9 9 9; 27 9 9 9; 36 9 9 9];
Pb = cell(1,5);
for k = 1:5
    Pb{k} = bndpad(Xb, [2 2], methods(k));
end
Pb{:}
%[text] `padarray` の結果（零値・周期・複製・対称（HS））と一致することを確かめる。
isequal(Pb{1}, padarray(Xb,[2 2],0), Pb{2}, padarray(Xb,[2 2],"circular")) ...
    && isequal(Pb{3}, padarray(Xb,[2 2],"replicate"), Pb{4}, padarray(Xb,[2 2],"symmetric"))
%[text] 教科書の解答と照合する（解答の配列をそのまま書き写したもの）。
Tb = cell(1,5);
Tb{1} = [0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0; 0 0 18 9 9 9 0 0; 0 0 27 9 9 9 0 0;
         0 0 36 9 9 9 0 0; 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0];
Tb{2} = [9 9 27 9 9 9 27 9; 9 9 36 9 9 9 36 9; 9 9 18 9 9 9 18 9; 9 9 27 9 9 9 27 9;
         9 9 36 9 9 9 36 9; 9 9 18 9 9 9 18 9; 9 9 27 9 9 9 27 9];
Tb{3} = [18 18 18 9 9 9 9 9; 18 18 18 9 9 9 9 9; 18 18 18 9 9 9 9 9; 27 27 27 9 9 9 9 9;
         36 36 36 9 9 9 9 9; 36 36 36 9 9 9 9 9; 36 36 36 9 9 9 9 9];
Tb{4} = [9 27 27 9 9 9 9 9; 9 18 18 9 9 9 9 9; 9 18 18 9 9 9 9 9; 9 27 27 9 9 9 9 9;
         9 36 36 9 9 9 9 9; 9 36 36 9 9 9 9 9; 9 27 27 9 9 9 9 9];
Tb{5} = [9 9 36 9 9 9 9 9; 9 9 27 9 9 9 9 9; 9 9 18 9 9 9 9 9; 9 9 27 9 9 9 9 9;
         9 9 36 9 9 9 9 9; 9 9 27 9 9 9 9 9; 9 9 18 9 9 9 9 9];
matchText = cellfun(@isequal, Pb, Tb)               % すべて true なら教科書と一致
assert(all(matchText), "例題「境界処理」の結果が教科書の解答と一致しない")
%[text] スライド用に書き出す。元の配列 $ \\mathsf{x} $ の位置（ $ \\mathcal{N}\_x=\\{0,1,2\\}\\times\\{0,1,2,3\\} $ ）の要素は太字（寒色）にする。
isOrg = false(7,8); isOrg(3:5,3:6) = true;
vie.savetex("vie-06-bp-x", vie.arr2tex(Xb,"%d"));
for k = 1:5
    vie.savetex("vie-06-bp-"+methods(k), arr2texmark(Pb{k}, isOrg, "%d"));
end
%%
%[text] ## 例題：対称拡張（WS）による有限長信号のフィルタリング
%[text] WS で拡張してから畳み込み，元の 4 点だけを取り出す（棄却・クリッピング）。出力の長さは入力と同じ 4 点。
xW = bndpad(x1, [0 1], "ws")                         % n = -1,0,...,4（両側 1 点で足りる）
yW = conv(xW, h1d, "valid")                         % n = 0,1,2,3
yZ = conv(x1, h1d, "same")                          % 零値拡張の場合（端が小さくなる）
vie.savetex("vie-06-ws-y", strjoin(compose("%g",yW),",\ "));
vie.savetex("vie-06-zp-y", strjoin(compose("%g",yZ),",\ "));
%[text] 両端の出力 $ y[0] $ と $ y[3] $ の計算式 $ y[n]=\\sum\_{m=-1}^{1}h[m]\\,x\_\\mathrm{pad}[n-m] $ （ $ m=-1,0,1 $ の順）も書き出す。
for n = [0 3]
    terms = strings(1,3);
    for m = -1:1
        terms(m+2) = frac2tex(h1d(m+2)) + "\cdot" + sprintf("%g", xW(n-m+2));   % xW(1) が n=-1
    end
    vie.savetex("vie-06-ws-y"+n, strjoin(terms,"+") + "=" + sprintf("%g", yW(n+1)));
end
%[text] 図：WS 拡張した信号（灰色が拡張した点），インパルス応答，出力。前回演習課題（6）の図（対称の中心の矢印）を参考にした。
fig = figure("Units","centimeters","Position",[2 2 11.5 3.3]);
tl = tiledlayout(fig,1,8,"TileSpacing","loose","Padding","compact");
ax = nexttile(tl,[1 3]);
stemtex(ax, -1:4, xW, [cGray; repmat(cCool,4,1); cGray], compose("%g",xW), [-1.8 4.8], [-2.1 4.8]);
hold(ax,"on")
quiver(ax, [0 3], [-2.1 -2.1], [0 0], [0.85 0.85], 0, "Color",cWarm, "LineWidth",1.2, "MaxHeadSize",0.8)
hold(ax,"off")
text(ax, 1.5, -1.7, "対称の中心", "HorizontalAlignment","center", "FontSize",7, "Color",cWarm)
title(ax, "$x_{\mathrm{pad}}[n]$", "Interpreter","latex")
ax = nexttile(tl,[1 2]);
stemtex(ax, nh1, h1d*4, cMain, ["1/4","1/2","1/4"], [-1.8 1.8], [-2.1 4.8]);
title(ax, "$h[n]$", "Interpreter","latex")
text(ax, -0.32, 0.5, "$\ast$", "Units","normalized", "Interpreter","latex", "FontSize",14, "HorizontalAlignment","center")
text(ax, 1.3, 0.5, "$=$", "Units","normalized", "Interpreter","latex", "FontSize",14, "HorizontalAlignment","center")
ax = nexttile(tl,[1 3]);
stemtex(ax, 0:3, yW, cCool, compose("%g",yW), [-1.8 4.8], [-2.1 4.8]);
title(ax, "$y[n]$", "Interpreter","latex")
exportgraphics(fig, fullfile(resfolder,"vie-06-ws-conv.png"), "Resolution", 300)
%%
%[text] ## 例題「インパルス応答の周期化」と「循環畳み込みによる線形畳み込み」（教科書 4.3.2・4.3.3 項）
%[text] $ 3\\times3 $ 矩形フィルタのインパルス応答 $ \\mathsf{h} $ （ $ \\mathcal{N}\_\\mathrm{h}=\\{-1,0,1\\}^2 $ ）を周期構造行列 $ \\boldsymbol{N}=\\mathrm{diag}(6,8) $ で周期化する：
%[text]{"align":"center"} $ h\_{\\boldsymbol{N}}[\\boldsymbol{n}]=\\sum\_{\\boldsymbol{\\ell}\\in\\mathbb{Z}^2}h[\\boldsymbol{N}\\boldsymbol{\\ell}+\\boldsymbol{n}],\\quad\\boldsymbol{n}\\in\\mathcal{N}(\\boldsymbol{N})=\\{0,\\ldots,5\\}\\times\\{0,\\ldots,7\\} $
%[text] 負の添え字の係数が反対側に回り込む。
Nper = [6 8];
hN = zeros(Nper);
for m1 = -1:1
    for m2 = -1:1
        hN(mod(m1,Nper(1))+1, mod(m2,Nper(2))+1) = hN(mod(m1,Nper(1))+1, mod(m2,Nper(2))+1) + 1/9;
    end
end
hN9 = round(9*hN)                                   % 1/9 をくくり出した整数の配列
Tper = [1 1 0 0 0 0 0 1; 1 1 0 0 0 0 0 1; zeros(3,8); 1 1 0 0 0 0 0 1];   % 教科書の解答（×9）
assert(isequal(hN9, Tper), "例題「インパルス応答の周期化」の結果が教科書と一致しない")
vie.savetex("vie-06-cc-hN", vie.arr2tex(hN9,"%d"));
%[text] 例題「矩形フィルタ」の $ \\mathsf{x} $ （ $ \\mathcal{N}(\\boldsymbol{N}) $ の残りは零）との循環畳み込み
%[text]{"align":"center"} $ y[\\boldsymbol{n}]=\\sum\_{\\boldsymbol{m}\\in\\mathcal{N}(\\boldsymbol{N})}h\_{\\boldsymbol{N}}[\\boldsymbol{m}]\\,x[((\\boldsymbol{n}-\\boldsymbol{m}))\_{\\boldsymbol{N}}] $
%[text] を定義どおりに計算し，DFT の積（ $ \\tilde{\\mathsf{y}}=\\tilde{\\mathsf{h}}\\odot\\tilde{\\mathsf{x}} $ ， `fft2` ）による結果とも比べる。
XN = zeros(Nper); XN(1:3,1:4) = Xb;
Ycc = zeros(Nper);
for n1 = 0:Nper(1)-1
    for n2 = 0:Nper(2)-1
        for m1 = 0:Nper(1)-1
            for m2 = 0:Nper(2)-1
                Ycc(n1+1,n2+1) = Ycc(n1+1,n2+1) ...
                    + hN(m1+1,m2+1)*XN(mod(n1-m1,Nper(1))+1, mod(n2-m2,Nper(2))+1);
            end
        end
    end
end
Ycc = round(Ycc, 10)
Yfft = real(ifft2(fft2(hN).*fft2(XN)));
maxdiffFFT = max(abs(Ycc - Yfft), [], "all")        % 丸め誤差程度
Tcc = [7 9 6 4 2 0 0 5; 12 15 9 6 3 0 0 9; 9 11 6 4 2 0 0 7;
       5 6 3 2 1 0 0 4; 0 0 0 0 0 0 0 0; 3 4 3 2 1 0 0 2];                  % 教科書の解答
assert(isequal(Ycc, Tcc), "例題「循環畳み込みによる線形畳み込み」の結果が教科書と一致しない")
%[text] 左上の $ 3\\times4 $ は例題「矩形フィルタ」（零値拡張の線形フィルタ）の結果と一致する。
Ybox = conv2(Xb, ones(3)/9, "same")
isequal(Ycc(1:3,1:4), round(Ybox,10))
isBox = false(Nper); isBox(1:3,1:4) = true;
vie.savetex("vie-06-cc-y", arr2texmark(Ycc, isBox, "%d"));
%%
%[text] ## 内積・ノルム・距離・コサイン類似度
%[text] 教科書 1.2.1 項の例。二つの配列の内積，ノルム，距離，コサイン類似度，二乗誤差和。教科書の値（80，10，16，14，1/2，196）と一致する。
Xa = [7 5 3; 3 2 2]; Ya6 = [-4 9 6; 7 5 7];
ip   = sum(Xa .* Ya6, "all")
nx   = norm(Xa(:)), ny = norm(Ya6(:))
dist = norm(Xa(:) - Ya6(:))
cosv = ip/(nx*ny)
sse  = dist^2
l1   = norm(Xa(:), 1)                                % 1-ノルム（絶対値和）
vals = [ip nx ny dist cosv sse l1];
tags = ["ip","nx","ny","dist","cos","sse","l1"];
for k = 1:numel(tags)
    vie.savetex("vie-06-"+tags(k), sprintf("%g",vals(k)));
end
%[text] コサイン類似度を分数で，二つの配列のなす角 $ \\theta=\\arccos(1/2) $ を $ \\pi $ の分数で書き出す。
theta = acos(cosv)
vie.savetex("vie-06-cos-frac", frac2tex(cosv));
[tn,td] = rat(theta/pi);                            % θ/π = tn/td
if tn == 1, snum = ""; else, snum = sprintf("%d", tn); end
vie.savetex("vie-06-theta", snum + "\pi/" + sprintf("%d", td));
%%
%[text] ## 移動平均・移動差分は内積
%[text] $ \\mathbb{R}^2 $ で平均 $ \\mathbf{f}=\\frac12(1\\ 1)^\\top $ ，差分 $ \\mathbf{f}=(1\\ -1)^\\top $ と $ \\mathbf{v} $ との内積 $ \\langle\\mathbf{f},\\mathbf{v}\\rangle $ をとる。内積が 0 なら直交。
V = [1 1; 1 -1; 2 1]';                              % 列が v
avg2 = [1/2 1/2]*V
dif2 = [1 -1]*V
for k = 1:3
    vie.savetex("vie-06-mavg"+k, sprintf("%g", avg2(k)));
    vie.savetex("vie-06-mdif"+k, sprintf("%g", dif2(k)));
end
%[text] $ \\mathbb{R}^{2\\times2} $ の配列 $ \\mathsf{x} $ との内積（成分毎の積の和）で，平均・水平差分・垂直差分を抽出する。
Vv = [2 2; 1 1];
Favg = ones(2)/4; Fh = [-1 1; -1 1]; Fv = [-1 -1; 1 1];
ext = [sum(Favg.*Vv,"all") sum(Fh.*Vv,"all") sum(Fv.*Vv,"all")]
vie.savetex("vie-06-ext-avg", sprintf("%g",ext(1)));
vie.savetex("vie-06-ext-h",   sprintf("%g",ext(2)));
vie.savetex("vie-06-ext-v",   sprintf("%g",ext(3)));
%%
%[text] ## 画像フィルタ
%[text] 各画素の近傍 $ 3\\times3 $ 配列とフィルタカーネルの内積を全画素で計算する。教科書のサンプル画像 msipimg04（石造りの建物，グレースケール，256×256 に縮小）に矩形フィルタ，4 近傍ラプラシアン，ソーベル（水平・垂直）を施す（境界は対称拡張。負の値を含む出力は 0.5 を中心に表示）。建物は柱（縦）と階段・軒（横）の輪郭が多いので，水平ソーベルが縦の輪郭を，垂直ソーベルが横の輪郭を取り出す違いがはっきり見える。
Cm = im2double(vie.msipimg(4, 256, "gray"));        % 石造りの建物（256×256）
masks = {ones(3)/9, [0 1 0; 1 -4 1; 0 1 0], [-1 0 1; -2 0 2; -1 0 1], [-1 -2 -1; 0 0 0; 1 2 1]};
mtag = ["avg","lap","sobh","sobv"];
figure
tiledlayout(1,4,"TileSpacing","compact","Padding","compact")
for k = 1:4
    Yk = imfilter(Cm, masks{k}, "symmetric");       % imfilter は相関（カーネルをそのまま重ねる）
    if k > 1, Yk = 0.5 + Yk/(2*max(abs(Yk(:)))); end   % 負の値を含むので 0.5 を中心に表示
    nexttile, imshow(Yk)
    imwrite(Yk, fullfile(resfolder,"vie-06-cam-"+mtag(k)+".png"))
end
imwrite(Cm, fullfile(resfolder,"vie-06-cam.png"))
%%
%[text] ## 配列の列ベクトル化
%[text] 列の順（縦方向 $ n\_1 $ が先）に並べる。 $ 2\\times2 $ の例：
Xv = [0 2; 4 6]
xv = Xv(:)'
Xback = reshape(xv, 2, 2)                           % 配列化（逆写像）
vie.savetex("vie-06-vec-x", strjoin(string(xv),",\ "));
%[text] 4K 画像（ $ 2160\\times3840 $ 画素）は約 800 万次元のベクトル：
dim4k = 2160*3840
vie.savetex("vie-06-dim4k", vie.fmtint(dim4k));
%%
%[text] ## 例「線形写像と行列表現」：循環右シフト（教科書 1.2.2 項）
%[text] $ \\mathbb{R}^{2\\times3} $ の配列を列ごとに右へ循環シフトする写像 $ \\mathsf{T} $ は線形で，行列表現 $ \\mathbf{T}\\in\\mathbb{R}^{6\\times6} $ をもつ。 $ \\mathbf{T} $ の第 $ i $ 列は，標準基底 $ \\{\\delta[\\boldsymbol{n}-\\boldsymbol{m}\_i]\\}\_{\\boldsymbol{n}} $ に対する出力を列ベクトル化したもの。
Tsh = zeros(6);
for i = 1:6
    E = zeros(2,3); E(i) = 1;                       % 標準基底（列ベクトル化の順に i 番目）
    R = circshift(E, [0 1]);                        % 循環右シフト
    Tsh(:,i) = R(:);
end
Tsh
Ttext = [0 0 0 0 1 0; 0 0 0 0 0 1; 1 0 0 0 0 0; 0 1 0 0 0 0; 0 0 1 0 0 0; 0 0 0 1 0 0];   % 教科書
assert(isequal(Tsh, Ttext), "例「線形写像と行列表現」の行列が教科書と一致しない")
vie.savetex("vie-06-sn-T", vie.arr2tex(Tsh,"%d"));
%[text] 例「スペクトルノルム」：スペクトルノルム $ \\|\\mathsf{T}\\|\_\\mathrm{S}=\\sqrt{\\lambda\_0(\\mathbf{T}^\\mathsf{H}\\mathbf{T})} $ 。循環シフトはノルムを保存する（等長）ので 1。
snShift = sqrt(max(abs(eig(Tsh'*Tsh))))
norm(Tsh)                                           % 2-ノルム（最大特異値）でも同じ
vie.savetex("vie-06-sn-shift", sprintf("%g", snShift));
%%
%[text] ## 対称畳み込みの行列表現
%[text] 前回スライドの例。 $ 2\\times3 $ 配列 $ \\mathsf{x} $ を WS 対称拡張（周期的にも延長）して $ \\mathsf{x}\_\\mathrm{pad} $ とし，インパルス応答 $ h[\\boldsymbol{m}] $ （ $ \\boldsymbol{m}\\in\\{0,1\\}^2 $ ， $ h[0,0]=h[1,0]=1,\\ h[0,1]=h[1,1]=-1 $ ）と畳み込んで $ \\mathsf{y} $ を得る。
U = [0 2 4; 1 3 5];                                 % 入力 x
Hk = [1 -1; 1 -1];                                  % 行が m1，列が m2
wsidx = @(n,N) N-1 - abs(mod(n, 2*(N-1)) - (N-1));  % WS 対称＋周期の添え字（0 始まり）
Vout = symconv(U, Hk, wsidx)                        % 出力 y
Uext = arrayfun(@(i,j) U(wsidx(i,2)+1, wsidx(j,3)+1), repmat((-1:2)',1,5), repmat(-1:3,4,1))   % 拡張の様子
%[text] このシステムは線形なので行列表現 $ \\mathbf{T} $ をもつ（ $ \\mathbf{y}=\\mathbf{T}\\mathbf{x} $ ）。 $ \\mathbf{T} $ の各列は，標準基底に対する出力を列ベクトル化したもの。
T = zeros(6);
for i = 1:6
    E = zeros(2,3); E(i) = 1;
    Vm = symconv(E, Hk, wsidx);
    T(:,i) = Vm(:);
end
T
check = isequal(T*U(:), Vout(:))                    % y = T x
vie.savetex("vie-06-sc-u",    vie.arr2tex(U,"%d"));
vie.savetex("vie-06-sc-uext", vie.arr2tex(Uext,"%d"));
vie.savetex("vie-06-sc-v",    vie.arr2tex(Vout,"%d"));
vie.savetex("vie-06-sc-T",    vie.arr2tex(T,"%d"));
vie.savetex("vie-06-sc-uvec", vie.arr2tex(U(:),"%d"));
vie.savetex("vie-06-sc-vvec", vie.arr2tex(Vout(:),"%d"));
%%
%[text] ## 例題「矩形フィルタのスペクトルノルム」（教科書 4.3.3 項）
%[text] 循環畳み込み $ \\mathsf{T}(\\cdot)=\\mathsf{h}\_{\\boldsymbol{N}}\\circledast(\\cdot) $ の行列表現は $ \\mathbf{T}=\\mathbf{W}\_{\\boldsymbol{N}}^{-1}\\boldsymbol{\\Lambda}\_\\mathrm{h}\\mathbf{W}\_{\\boldsymbol{N}} $ （ $ \\mathbf{W}\_{\\boldsymbol{N}} $ は DFT 行列， $ \\boldsymbol{\\Lambda}\_\\mathrm{h}=\\mathrm{diag}(\\mathbf{W}\_{\\boldsymbol{N}}\\mathbf{h}) $ ）なので，スペクトルノルムは DFT 係数の絶対値の最大値
%[text]{"align":"center"} $ \\|\\mathsf{T}\\|\_\\mathrm{S}=\\max\_{\\boldsymbol{k}\\in\\mathcal{N}(\\boldsymbol{N}^\\top)}|H[\\boldsymbol{k}]| $
%[text] になる。 $ 3\\times3 $ 矩形フィルタ， $ \\boldsymbol{N}=\\mathrm{diag}(6,8) $ で確かめる。
Hk68 = fft2(hN);                                    % H[k]，k ∈ {0,...,5}×{0,...,7}
[snBox, imax] = max(abs(Hk68(:)));
[k1max, k2max] = ind2sub(Nper, imax);
snBox, kmax = [k1max k2max] - 1                     % 最大は k = 0（直流）
%[text] 行列表現 $ \\mathbf{T}\\in\\mathbb{R}^{48\\times48} $ を標準基底に対する応答から作り，DFT 行列による対角化と最大特異値でも確かめる。列ベクトル化は列の順なので $ \\mathbf{W}\_{\\boldsymbol{N}}=\\mathbf{W}\_8\\otimes\\mathbf{W}\_6 $ 。
Tcc48 = zeros(prod(Nper));
for i = 1:prod(Nper)
    E = zeros(Nper); E(i) = 1;
    R = real(ifft2(fft2(hN).*fft2(E)));
    Tcc48(:,i) = R(:);
end
W6 = exp(-2i*pi*(0:5)'*(0:5)/6); W8 = exp(-2i*pi*(0:7)'*(0:7)/8);
WN = kron(W8, W6);
maxdiffDiag = max(abs(Tcc48 - WN\diag(WN*hN(:))*WN), [], "all")   % 丸め誤差程度
snBox48 = norm(Tcc48)                               % 最大特異値 = スペクトルノルム
assert(abs(snBox - 1) < 1e-12 && abs(snBox48 - 1) < 1e-12, "スペクトルノルムが教科書の値 1 と一致しない")
vie.savetex("vie-06-sn-box", sprintf("%g", round(snBox, 12)));
%[text] 振幅応答 $ |H(\\mathrm{e}^{\\mathrm{j}\\boldsymbol{\\omega}^\\top})|=\\frac19|1+2\\cos\\omega\_1|\\cdot|1+2\\cos\\omega\_2| $ と，DFT の周波数標本点 $ \\boldsymbol{\\omega}=2\\pi\\boldsymbol{N}^{-\\top}\\boldsymbol{k} $ を重ねて描く（ライブスクリプトでの確認用で，スライドには載せない）。標本の最大は $ \\boldsymbol{k}=\\mathbf{0} $ の 1。
w = linspace(0, 2*pi, 241);
[w2g, w1g] = meshgrid(w);                           % 列方向が ω2，行方向が ω1
Hmag = abs(1 + 2*cos(w1g)).*abs(1 + 2*cos(w2g))/9;
[k2g, k1g] = meshgrid(0:Nper(2)-1, 0:Nper(1)-1);
w1k = 2*pi*k1g/Nper(1); w2k = 2*pi*k2g/Nper(2);
max(abs(abs(Hk68(:)) - abs(1 + 2*cos(w1k(:))).*abs(1 + 2*cos(w2k(:)))/9))   % 標本点で一致
cmapW = interp1([0 1], [1 1 1; cMain], linspace(0,1,64));   % 白→緑
figure
imagesc(w, w, Hmag), axis("xy","image"), colormap(gca, cmapW), clim([0 1]), colorbar
set(gca, "XLim",[-0.45 2*pi+0.1], "YLim",[-0.45 2*pi+0.1], "TickDir","out")   % 原点の丸が隠れないよう余白をとる
hold on
plot(w2k(:), w1k(:), ".", "Color",cCool, "MarkerSize",12)
plot(0, 0, "o", "Color",cWarm, "MarkerSize",10, "LineWidth",1.5)
hold off
set(gca, "XTick",[0 pi 2*pi], "YTick",[0 pi 2*pi], "TickLabelInterpreter","latex", ...
    "XTickLabel",["$0$","$\pi$","$2\pi$"], "YTickLabel",["$0$","$\pi$","$2\pi$"])
xlabel("$\omega_2$", "Interpreter","latex"), ylabel("$\omega_1$", "Interpreter","latex")
title("|{\itH}(e^{j{\bf\omega}^T})| と DFT の標本点（橙：最大）", "Interpreter","tex")
%%
%[text] ## まとめ
%[text] - 畳み込みは反転したインパルス応答（フィルタカーネル）との相互相関（荷重移動平均／差分）に一致する
%[text] - 可分離システムは一次元処理の繰り返しで計算でき，演算量が少ない
%[text] - 有限長信号の畳み込みは出力が広がるので，境界処理（零値・周期・複製・対称拡張）が必要
%[text] - 周期拡張と畳み込みは循環畳み込みで，十分な周期をとれば線形畳み込みを実現できる
%[text] - 線形フィルタは内積の繰り返しであり，列ベクトル化により行列 $ \\mathbf{T} $ で表現できる（ $ \\mathbf{y}=\\mathbf{T}\\mathbf{x} $ ）。作用の大きさはスペクトルノルムで測る \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
function Xp = bndpad(X, w, method)
% 教科書 3.1.3 項の境界処理．d = 1,2 の順に各次元を両側 w(d) 点ずつ外挿する．
% method は "zero"（零値），"circ"（周期），"repl"（複製），"hs"（対称 HS），"ws"（対称 WS）．
% 外挿幅は N_d - 1 以下を想定する（教科書の式と同じ）．
Xp = X;
for d = 1:2
    N = size(Xp, d);
    n = -w(d):N-1+w(d);                             % 拡張後の添え字（0 始まり）
    m = n;                                          % 参照する元の添え字（NaN は零値）
    lo = n < 0; hi = n > N-1;
    switch method
        case "zero", m(lo | hi) = NaN;
        case "circ", m = mod(n, N);
        case "repl", m(lo) = 0;        m(hi) = N-1;
        case "hs",   m(lo) = -n(lo)-1; m(hi) = 2*N-1-n(hi);
        case "ws",   m(lo) = -n(lo);   m(hi) = 2*(N-1)-n(hi);
    end
    ok = ~isnan(m);
    if d == 1
        Y = zeros(numel(n), size(Xp,2)); Y(ok,:) = Xp(m(ok)+1,:);
    else
        Y = zeros(size(Xp,1), numel(n)); Y(:,ok) = Xp(:,m(ok)+1);
    end
    Xp = Y;
end
end

function s = arr2texmark(X, mask, fmt)
% vie.arr2tex と同じ形式で，mask が true の要素を太字（\positive{\mathbf{...}}）にする
C = string(arrayfun(@(v) sprintf(fmt, v), X, "UniformOutput", false));
C(mask) = "\positive{\mathbf{" + C(mask) + "}}";
rows = strings(size(X,1), 1);
for i = 1:size(X,1)
    rows(i) = strjoin(C(i,:), " & ");
end
s = strjoin(rows, "\\" + newline);
end

function s = arr2texshow(X, show, fmt, hl)
% vie.arr2tex と同じ形式で，show が false の要素を \phantom（幅だけ残す空欄）にし，
% hl が true の要素（省略時は show の要素）を暖色（\alert）で強調する
if nargin < 4, hl = show & ~all(show(:)); end
C = string(arrayfun(@(v) sprintf(fmt, v), X, "UniformOutput", false));
C(hl & show) = "\alert{" + C(hl & show) + "}";
C(~show) = "\phantom{" + C(~show) + "}";
rows = strings(size(X,1), 1);
for i = 1:size(X,1)
    rows(i) = strjoin(C(i,:), " & ");
end
s = strjoin(rows, "\\" + newline);
end

function s = coef2tex(c)
% 係数の LaTeX 表記（負の数は括弧で囲む）
if c < 0
    s = "(" + sprintf("%g", c) + ")";
else
    s = sprintf("%g", c);
end
end

function s = frac2tex(v)
% 有理数を \frac{p}{q} の形にする（整数ならそのまま）
[p, q] = rat(v);
if q == 1
    s = sprintf("%d", p);
else
    s = "\frac{" + sprintf("%d", p) + "}{" + sprintf("%d", q) + "}";
end
end

function stemtex(ax, n, v, c, labels, xl, yl)
% 教科書風の棒グラフ（stem）．値のラベルを棒の上に書き，縦軸は描かない．
% c は 1 色（1×3）か，棒ごとの色（numel(n)×3）．
if size(c,1) == 1, c = repmat(c, numel(n), 1); end
hold(ax, "on")
for k = 1:numel(n)
    stem(ax, n(k), v(k), "filled", "Color",c(k,:), "MarkerFaceColor",c(k,:), ...
        "MarkerSize",4, "LineWidth",1.4)
    text(ax, n(k), v(k)+0.25, labels(k), "HorizontalAlignment","center", ...
        "VerticalAlignment","bottom", "FontSize",7, "Color",c(k,:))
end
hold(ax, "off")
set(ax, "XLim",xl, "YLim",yl, "XTick",ceil(xl(1)):floor(xl(2)), "Box","off", ...
    "XAxisLocation","origin", "FontSize",7, "TickDir","both", "Color","none")
ax.YAxis.Visible = "off";
ax.XAxis.TickLength = [0.02 0.02];
end

function Y = symconv(X, H, wsidx)
% WS 対称拡張（周期的にも延長）した X とインパルス応答 H（添え字 {0,1}^2）の畳み込み
[N1, N2] = size(X);
xt = @(n1,n2) X(wsidx(n1,N1)+1, wsidx(n2,N2)+1);
Y = zeros(N1, N2);
for a = 0:N1-1
    for b = 0:N2-1
        for m1 = 0:size(H,1)-1
            for m2 = 0:size(H,2)-1
                Y(a+1,b+1) = Y(a+1,b+1) + H(m1+1,m2+1)*xt(a-m1, b-m2);
            end
        end
    end
end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
