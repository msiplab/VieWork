%[text] # 第5回 近傍処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第5回のスライド（vie2026-05）で使う図と数値を作る。線形フィルタ（平均値・加重平均値・ラプラシアン・アンシャープマスク），中央値フィルタ，勾配フィルタ（プレウィット・ソーベル），線形シフト不変システムと畳み込みを扱う。
%[text] 教科書の線形フィルタは局所的な積和演算
%[text]{"align":"center"} $ y[\\boldsymbol{n}] = \\sum\_{\\boldsymbol{m}\\in\\mathcal{N}\_\\mathrm{f}} f[\\boldsymbol{m}]\\, x[\\boldsymbol{n}+\\boldsymbol{m}] $
%[text] で表される（実数の場合）。MATLAB の `imfilter` は既定でこの形（相関）を計算し，周囲を零値で拡張する。
%[text] 教科書（3.1〜3.3 節）の例題は，すべて同じ $ 3\\times 4 $ 配列 $ \\mathsf{x} $ を使う。各節でスクリプトの計算結果を教科書の解答と照合し（`assert`），一致を確かめてからスライド用のスニペットに書き出す。スライドの数値例（配列の値，途中の式，答え）はすべてここから来る。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図の配色はロゴの色（メインの緑，暖色系の橙）に合わせる。
[~,resfolder] = vie.prjfolders();
clrMain = [0 136 85]/255;                      % メイン（緑）
clrWarm = [197 90 17]/255;                     % 暖色系（橙）
%%
%[text] ## 数値例の配列
%[text] 教科書の例題と前回スライドで共通に使う $ 3\\times 4 $ 配列。周囲の値はすべて零値と仮定する。
X = [18 9 9 9; 27 9 9 9; 36 9 9 9]
vie.savetex("vie-05-x", vie.arr2tex(X,"%d"));
%[text] スライドでは配列を TikZ の格子で描く。格子に置く数値も手で書かず，ここから `\node at (列,-行) {$値$};` の形で書き出す（ローカル関数 `arr2nodes`，左上の要素が原点）。
vie.savetex("vie-05-x-nodes", arr2nodes(X,"%d"));
%[text] 周囲の零値拡張 $ \\mathsf{x}\_\\mathrm{pad} $ （ `padarray` ）。スライドでは枠の外側の零値を灰色で示す（外周の要素だけを書き出す）。
Xpad = padarray(X, [1 1])                      % 上下左右に 1 画素ずつ零値を付ける
vie.savetex("vie-05-xpad-nodes", arr2nodes(Xpad,"%d",1,true));
%[text] 出力画素 $ y[n\_\\mathrm{v},n\_\\mathrm{h}] $ （0 始まり）が参照する $ 3\\times 3 $ の局所領域を取り出す関数。 $ \\mathsf{x}\_\\mathrm{pad} $ では行・列の番号が 1 ずれることに注意する。
win = @(nv,nh) Xpad(nv+(1:3), nh+(1:3));
win(1,1)                                       % y[1,1] の局所領域
%%
%[text] ## 平均値（矩形）フィルタ
%[text] $ 3\\times 3 $ 矩形フィルタのカーネルは $ \\frac{1}{9}\\mathbf{1} $ 。出力は 9 画素の平均（教科書 例題「矩形フィルタ」）。
fbox = ones(3)/9;
Ybox = imfilter(X, fbox)                       % 周囲は零値（imfilter の既定）
YboxBook = [7 9 6 4; 12 15 9 6; 9 11 6 4];     % 教科書の解答
assert(max(abs(Ybox - YboxBook),[],"all") < 1e-12, "矩形フィルタ：教科書の解答と一致しない")
Ybox = round(Ybox);                            % 丸め誤差を除いて整数で書き出す
vie.savetex("vie-05-box", vie.arr2tex(Ybox,"%d"));
vie.savetex("vie-05-box-nodes", arr2nodes(Ybox,"%d"));
%[text] 教科書の解答にならって，局所領域の画素値を行ごとに左から足し（ローカル関数 `sumexpr`），9 で割る式を作る。 $ y[1,1] $ （スライドで強調する画素）と，零値拡張の効く $ y[0,0] $ ， $ y[1,0] $ 。
for p = [1 1; 0 0; 1 0]'
    W = win(p(1),p(2));
    e = "(" + sumexpr(reshape(W.',1,[])) + ")/9";
    fprintf("y[%d,%d] = %s = %g\n", p(1), p(2), e, Ybox(p(1)+1,p(2)+1))
    tag = sprintf("%d%d", p(1), p(2));
    vie.savetex("vie-05-box-e" + tag, e);
    vie.savetex("vie-05-box-y" + tag, sprintf("%d", Ybox(p(1)+1,p(2)+1)));
end
%%
%[text] ## 加重平均値（ガウシアン）フィルタ
%[text] 教科書の式 (3.3)(3.4) どおりに，距離の 2 乗 $ \\|\\boldsymbol{m}\\|\_2^2=m\_\\mathrm{v}^2+m\_\\mathrm{h}^2 $ からガウス関数 $ g[\\boldsymbol{m}] $ を求め，総和で割って正規化する。
[mh, mv] = meshgrid(-1:1);                     % m = (m_v, m_h)，行が m_v，列が m_h
gauss = @(sg) exp(-(mv.^2 + mh.^2)/(2*sg^2)) / sum(exp(-(mv.^2 + mh.^2)/(2*sg^2)),"all");
%[text] 教科書 例「ガウシアンフィルタ」： $ \\sigma\_\\mathrm{g}=0.5 $ 。中央の重みが大きく，平滑化は弱い。
fg05 = gauss(0.5)
fg05Book = [0.0113 0.0838 0.0113; 0.0838 0.6193 0.0838; 0.0113 0.0838 0.0113];
assert(max(abs(fg05 - fg05Book),[],"all") < 5e-5, "ガウシアン（σ=0.5）：教科書の値と一致しない")
vie.savetex("vie-05-gauss05", vie.arr2tex(fg05,"%.4f"));
%[text] 教科書 例題「ガウシアンフィルタ」： $ \\sigma\_\\mathrm{g}\\simeq 0.849 $ のカーネルは $ \\frac{1}{16}\\begin{pmatrix}1&2&1\\\\2&4&2\\\\1&2&1\\end{pmatrix} $ にほぼ等しい。 `fspecial` の結果とも一致する。
fg = gauss(0.849)
fgBook = [0.0625 0.1250 0.0625; 0.1250 0.2501 0.1250; 0.0625 0.1250 0.0625];
assert(max(abs(fg - fgBook),[],"all") < 5e-5, "ガウシアン（σ=0.849）：教科書の値と一致しない")
assert(max(abs(fg - fspecial("gaussian",3,0.849)),[],"all") < 1e-12)
fg16 = round(16*fg)                            % 16 倍して丸めると整数のカーネル
assert(isequal(fg16, [1 2 1; 2 4 2; 1 2 1]))
vie.savetex("vie-05-gauss", vie.arr2tex(fg,"%.4f"));
vie.savetex("vie-05-gauss16", vie.arr2tex(fg16,"%d"));
%%
%[text] ## フィルタカーネルの形状
%[text] 講義のデモ（linearfilter.m）にならい，重み係数 $ f[\\boldsymbol{m}] $ を `stem3` で立体的に示す。矩形フィルタは平ら，加重平均値フィルタは中央が高い。比べやすいよう縦軸をそろえる。
krn = {fbox, fg16/16};
kname = ["vie-05-kernel-box.png", "vie-05-kernel-gauss.png"];
for k = 1:2
    figure("Units","centimeters","Position",[2 2 4.2 3.6]);
    stem3(mh, mv, krn{k}, "filled", "Color", clrMain, "MarkerFaceColor", clrMain, ...
        "MarkerSize", 3, "LineWidth", 1.2)
    xlabel("$m_\mathrm{h}$","Interpreter","latex"), ylabel("$m_\mathrm{v}$","Interpreter","latex")
    set(gca, "FontSize", 7, "YDir", "reverse"), view(-35,30)
    xticks(-1:1), yticks(-1:1), zlim([0 0.3]), zticks(0:0.1:0.3)
    exportgraphics(gcf, fullfile(resfolder,kname(k)), "Resolution", 300)
end
%%
%[text] ## 平滑化の処理例（ガウス性ノイズ）
%[text] circuit.tif に標準偏差 0.05 のガウス性ノイズを加え，平均値フィルタと加重平均値フィルタで平滑化する。
rng(0)                                         % 乱数を固定して再現性を保つ
C = im2double(imread("circuit.tif"));
Cg = imnoise(C, "gaussian", 0, 0.05^2);
Cbox = imfilter(Cg, fbox, "replicate");
Cgau = imfilter(Cg, fg16/16, "replicate");
psnrG = [psnr(Cg,C) psnr(Cbox,C) psnr(Cgau,C)]
figure, tiledlayout(2,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(C),    title("原画像")
nexttile, imshow(Cg),   title("雑音重畳（ガウス性）")
nexttile, imshow(Cbox), title("平均値フィルタ")
nexttile, imshow(Cgau), title("加重平均値フィルタ")
imwrite(C,    fullfile(resfolder,"vie-05-org.png"))
imwrite(Cg,   fullfile(resfolder,"vie-05-gn.png"))
imwrite(Cbox, fullfile(resfolder,"vie-05-gn-box.png"))
imwrite(Cgau, fullfile(resfolder,"vie-05-gn-gauss.png"))
vie.savetex("vie-05-psnr-gn",    sprintf("%.1f",psnrG(1)));
vie.savetex("vie-05-psnr-gnbox", sprintf("%.1f",psnrG(2)));
vie.savetex("vie-05-psnr-gngau", sprintf("%.1f",psnrG(3)));
%%
%[text] ## 中央値フィルタ
%[text] 前回スライドの例： $ 3\\times 3 $ 領域の画素値を昇順に並べ，5 番目（中央， $ K=(9+1)/2 $ ）の値で置き換える。外れ値 100 の影響を受けない。
B = [10 20 20; 20 15 20; 20 25 100]
vie.savetex("vie-05-med-b-nodes", arr2nodes(B,"%d"));
sorted = sort(B(:))'
K = (numel(B)+1)/2
med = sorted(K)
assert(med == median(B(:)))
avg = mean(B(:))                               % 平均値は外れ値に引っ張られる
vie.savetex("vie-05-med-sorted", strjoin(string(sorted),",\,"));
vie.savetex("vie-05-med-ord", ordlist(sorted, K));   % K 番目に下線
vie.savetex("vie-05-med-val", sprintf("%d", med));
vie.savetex("vie-05-med-sum", sprintf("%d", sum(B(:))));
vie.savetex("vie-05-med-avg", sprintf("%.1f",avg));
%[text] 数値例の配列 $ \\mathsf{x} $ に対する $ 3\\times3 $ 中央値フィルタ（周囲は零値，教科書 例題「中央値フィルタ」）。順序統計フィルタ `ordfilt2` で $ K=5 $ としても同じ。
Ymed = medfilt2(X, [3 3], "zeros")
assert(isequal(Ymed, ordfilt2(X, 5, true(3), "zeros")))
YmedBook = [0 9 9 0; 9 9 9 9; 0 9 9 0];
assert(isequal(Ymed, YmedBook), "中央値フィルタ：教科書の解答と一致しない")
vie.savetex("vie-05-med", vie.arr2tex(Ymed,"%d"));
%[text] 教科書の解答にならって，局所領域を昇順に並べて 5 番目に下線を引いた列を作る（ $ y[1,0] $ ）。
s10 = sort(reshape(win(1,0),1,[]))
vie.savetex("vie-05-med-e10", ordlist(s10, K));
vie.savetex("vie-05-med-y10", sprintf("%d", s10(K)));
%%
%[text] ## 最大値／最小値フィルタ
%[text] 順序統計フィルタで $ K=9 $ （最大値）， $ K=1 $ （最小値）とする（教科書 例題「最大値／最小値フィルタ」）。
Ymax = ordfilt2(X, 9, true(3), "zeros")
Ymin = ordfilt2(X, 1, true(3), "zeros")
YmaxBook = [27 27 9 9; 36 36 9 9; 36 36 9 9];
YminBook = [0 0 0 0; 0 9 9 0; 0 0 0 0];
assert(isequal(Ymax, YmaxBook), "最大値フィルタ：教科書の解答と一致しない")
assert(isequal(Ymin, YminBook), "最小値フィルタ：教科書の解答と一致しない")
vie.savetex("vie-05-max", vie.arr2tex(Ymax,"%d"));
vie.savetex("vie-05-min", vie.arr2tex(Ymin,"%d"));
%%
%[text] ## 中央値フィルタの処理例（インパルス性ノイズ）
%[text] ノイズ密度 5% のごま塩ノイズを加え，平均値フィルタと中央値フィルタを比べる。
rng(1)
Cs = imnoise(C, "salt & pepper", 0.05);
Csbox = imfilter(Cs, fbox, "replicate");
Csmed = medfilt2(Cs, [3 3], "symmetric");
psnrS = [psnr(Cs,C) psnr(Csbox,C) psnr(Csmed,C)]
figure, tiledlayout(2,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(C),     title("原画像")
nexttile, imshow(Cs),    title("雑音重畳（インパルス性）")
nexttile, imshow(Csbox), title("平均値フィルタ")
nexttile, imshow(Csmed), title("中央値フィルタ")
imwrite(Cs,    fullfile(resfolder,"vie-05-sp.png"))
imwrite(Csbox, fullfile(resfolder,"vie-05-sp-box.png"))
imwrite(Csmed, fullfile(resfolder,"vie-05-sp-med.png"))
vie.savetex("vie-05-psnr-sp",    sprintf("%.1f",psnrS(1)));
vie.savetex("vie-05-psnr-spbox", sprintf("%.1f",psnrS(2)));
vie.savetex("vie-05-psnr-spmed", sprintf("%.1f",psnrS(3)));
%%
%[text] ## 一次微分と二次微分（差分）
%[text] 一定区間・ランプ・ステップを含む一次元信号 $ x[n] $ に，一次差分 $ x[n+1]-x[n] $ （カーネル $ (-1\\ \\ 1)^\\top $ ）と二次差分 $ x[n+1]-2x[n]+x[n-1] $ （カーネル $ (1\\ \\ {-2}\\ \\ 1)^\\top $ ）を施す。
x1 = [6 6 6 6 5 4 3 2 1 1 1 1 1 1 6 6 6 6 6];
n1 = 0:numel(x1)-1;
d1 = [x1(2:end)-x1(1:end-1) NaN];              % 一次差分（最後は未定義）
d2 = [NaN x1(3:end)+x1(1:end-2)-2*x1(2:end-1) NaN];   % 二次差分（両端は未定義）
%[text] スライドでは幅 5 cm ほどで表示するので，図の大きさを cm で指定して文字が潰れないようにする。各段の題に差分の式（教科書の記法）を書き，入力の段にはランプとステップの位置を注記する。
figure("Units","centimeters","Position",[2 2 7 8.4]);
tiledlayout(3,1,"TileSpacing","tight","Padding","compact")
lbl = ["$x[n]$", "$x[n+1]-x[n]$", "$x[n+1]-2x[n]+x[n-1]$"];
sig = {x1, d1, d2};
yl = {[0 7.5], [-2 6], [-6 6]};                % 各段の縦軸の範囲
for k = 1:3
    nexttile
    stem(n1, sig{k}, "filled", "Color", clrMain, "MarkerFaceColor", clrMain, ...
        "MarkerSize", 3, "LineWidth", 1)
    title(lbl(k), "Interpreter", "latex", "FontSize", 9)
    grid on, xlim([-0.5 n1(end)+0.5]), xticks(0:2:18), ylim(yl{k})
    set(gca, "FontSize", 7)
    if k == 1
        text(6.6, 5.0, "ランプ", "Color", clrWarm, "FontSize", 8, "HorizontalAlignment", "center")
        text(11.2, 3.5, "ステップ", "Color", clrWarm, "FontSize", 8, "HorizontalAlignment", "center")
    end
end
xlabel("$n$", "Interpreter", "latex", "FontSize", 9)
exportgraphics(gcf, fullfile(resfolder,"vie-05-diff1d.png"), "Resolution", 300)
d1
d2
%%
%[text] ## ラプラシアンフィルタ
%[text] 4 近傍と 8 近傍のカーネル。8 近傍は教科書の一般形 $ c\\left((1-\\alpha)\\,\\cdot\\,+\\alpha\\,\\cdot\\right) $ で $ \\alpha=1/2 $ ， $ c=2 $ とした場合に当たる。
flap4 = [0 1 0; 1 -4 1; 0 1 0];
flapx = [1 0 1; 0 -4 0; 1 0 1];                % 対角方向の 4 近傍
flap8 = [1 1 1; 1 -8 1; 1 1 1];
alpha = 1/2; c = 2;
assert(isequal(c*((1-alpha)*flap4 + alpha*flapx), flap8))
%[text] 数値例の配列 $ \\mathsf{x} $ に 4 近傍ラプラシアンを施す（周囲は零値，教科書 例題「4近傍ラプラシアン」）。
Ylap = imfilter(X, flap4)
YlapBook = [-36 0 -9 -18; -45 18 0 -9; -108 18 -9 -18];
assert(isequal(Ylap, YlapBook), "4近傍ラプラシアン：教科書の解答と一致しない")
vie.savetex("vie-05-lap", vie.arr2tex(Ylap,"%d"));
vie.savetex("vie-05-lap-nodes", arr2nodes(Ylap,"%d"));
%[text] $ y[1,1] $ の積和を，係数と画素値の積を行ごとに並べて示す（ローカル関数 `prodexpr`）。
e = prodexpr(flap4, win(1,1))
assert(sum(flap4.*win(1,1),"all") == Ylap(2,2))
vie.savetex("vie-05-lap-e11", e);
vie.savetex("vie-05-lap-y11", sprintf("%d", Ylap(2,2)));
%%
%[text] ## ラプラシアンフィルタの処理例
%[text] moon.tif に 4 近傍・8 近傍ラプラシアンを施す。出力は負の値を含むので，表示のため $ 0.5+ y $ （バイアス処理）で示す。
Mo = im2double(imread("moon.tif"));
Mo = imresize(Mo, 0.5);
L4 = imfilter(Mo, flap4, "replicate");
L8 = imfilter(Mo, flap8, "replicate");
figure, tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Mo), title("原画像")
nexttile, imshow(0.5 + L4), title("4 近傍")
nexttile, imshow(0.5 + L8), title("8 近傍")
imwrite(Mo, fullfile(resfolder,"vie-05-moon.png"))
imwrite(min(max(0.5 + 2*L4,0),1), fullfile(resfolder,"vie-05-moon-lap4.png"))   % 見やすいよう 2 倍
imwrite(min(max(0.5 + 2*L8,0),1), fullfile(resfolder,"vie-05-moon-lap8.png"))
%%
%[text] ## 高域強調（アンシャープマスク）
%[text] $ \\mathsf{y}=\\mathsf{x}-\\nabla^2\\mathsf{x} $ 。カーネルは恒等変換からラプラシアンを引いたもの。
fus4 = [0 0 0; 0 1 0; 0 0 0] - flap4
fus8 = [0 0 0; 0 1 0; 0 0 0] - flap8
%[text] 前回の演習で使った `fspecial("unsharp",0)` は 4 近傍のカーネルに一致する。
assert(isequal(fus4, fspecial("unsharp",0)))
%[text] 数値例の配列 $ \\mathsf{x} $ に 4 近傍アンシャープマスクを施す（教科書 例題「4近傍アンシャープマスク」）。入力から例題「4近傍ラプラシアン」の結果を引いても，カーネル `fus4` で近傍処理しても同じ。
Yus = imfilter(X, fus4)
assert(isequal(Yus, X - Ylap))
YusBook = [54 9 18 27; 72 -9 9 18; 144 -9 18 27];
assert(isequal(Yus, YusBook), "4近傍アンシャープマスク：教科書の解答と一致しない")
vie.savetex("vie-05-us", vie.arr2tex(Yus,"%d"));
%[text] 前回の演習課題（5-2）の解答にならい，画素毎に「中央の 5 倍から上・左・右・下の 4 近傍の和を引く」形で $ y[1,1] $ を示す。
W = win(1,1);
e = sprintf("%d\\cdot%s", fus4(2,2), numtex(W(2,2))) + "-(" + sumexpr([W(1,2) W(2,1) W(2,3) W(3,2)]) + ")"
vie.savetex("vie-05-us-e11", e);
vie.savetex("vie-05-us-y11", sprintf("%d", Yus(2,2)));
U4 = imfilter(Mo, fus4, "replicate");
U8 = imfilter(Mo, fus8, "replicate");
figure, tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Mo), title("原画像")
nexttile, imshow(U4), title("4 近傍")
nexttile, imshow(U8), title("8 近傍")
imwrite(min(max(U4,0),1), fullfile(resfolder,"vie-05-moon-us4.png"))
imwrite(min(max(U8,0),1), fullfile(resfolder,"vie-05-moon-us8.png"))
%%
%[text] ## プレウィットフィルタの数値例
%[text] 垂直方向 $ f\_\\mathrm{v} $ と水平方向 $ f\_\\mathrm{h} $ のカーネルで差分画像 $ \\mathsf{x}\_\\mathrm{v} $ ， $ \\mathsf{x}\_\\mathrm{h} $ を求める（教科書 例題「プレウィットフィルタ」）。
fpv = [-1 -1 -1; 0 0 0; 1 1 1];
fph = fpv';
Xv = imfilter(X, fpv)
Xh = imfilter(X, fph)
XvBook = [36 45 27 18; 18 18 0 0; -36 -45 -27 -18];
XhBook = [18 -27 0 -18; 27 -54 0 -27; 18 -45 0 -18];
assert(isequal(Xv, XvBook) && isequal(Xh, XhBook), "プレウィットフィルタ：教科書の解答と一致しない")
vie.savetex("vie-05-pv",  vie.arr2tex(Xv,"%d"));
vie.savetex("vie-05-ph",  vie.arr2tex(Xh,"%d"));
%[text] $ x\_\\mathrm{v}[1,1] $ は「下の行の和 − 上の行の和」， $ x\_\\mathrm{h}[1,1] $ は「右の列の和 − 左の列の和」。
W = win(1,1);
ev = "-(" + sumexpr(W(1,:)) + ")+(" + sumexpr(W(3,:)) + ")"
eh = "-(" + sumexpr(W(:,1)') + ")+(" + sumexpr(W(:,3)') + ")"
assert(sum(W(3,:)) - sum(W(1,:)) == Xv(2,2) && sum(W(:,3)) - sum(W(:,1)) == Xh(2,2))
vie.savetex("vie-05-pv-e11", ev);
vie.savetex("vie-05-pv-y11", sprintf("%d", Xv(2,2)));
vie.savetex("vie-05-ph-e11", eh);
vie.savetex("vie-05-ph-y11", sprintf("%d", Xh(2,2)));
%[text] 勾配の大きさ $ y\_\\mathrm{mag}[\\boldsymbol{n}]=\\sqrt{x\_\\mathrm{v}^2[\\boldsymbol{n}]+x\_\\mathrm{h}^2[\\boldsymbol{n}]} $ （教科書 例題「勾配の大きさ」，小数第 2 位まで）。
Ymag = sqrt(Xv.^2 + Xh.^2)
YmagBook = [40.25 52.48 27.00 25.46; 32.45 56.92 0.00 27.00; 40.25 63.64 27.00 25.46];
assert(isequal(round(Ymag,2), YmagBook), "勾配の大きさ：教科書の解答と一致しない")
vie.savetex("vie-05-mag", vie.arr2tex(Ymag,"%.2f"));
em = sprintf("\\sqrt{%s^2+%s^2}", numtex(Xv(2,2)), numtex(Xh(2,2)))
vie.savetex("vie-05-mag-e11", em);
vie.savetex("vie-05-mag-y11", sprintf("%.2f", Ymag(2,2)));
%%
%[text] ## 勾配フィルタの処理例
%[text] coins.png にプレウィットとソーベルを施し，勾配の大きさを表示する（最大値で正規化）。
Co = im2double(imread("coins.png"));
fsv = [-1 -2 -1; 0 0 0; 1 2 1]; fsh = fsv';
Gp = hypot(imfilter(Co,fpv,"replicate"), imfilter(Co,fph,"replicate"));
Gs = hypot(imfilter(Co,fsv,"replicate"), imfilter(Co,fsh,"replicate"));
figure, tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Co), title("原画像")
nexttile, imshow(Gp/max(Gp(:))), title("プレウィット")
nexttile, imshow(Gs/max(Gs(:))), title("ソーベル")
imwrite(Co, fullfile(resfolder,"vie-05-coins.png"))
imwrite(Gp/max(Gp(:)), fullfile(resfolder,"vie-05-coins-prewitt.png"))
imwrite(Gs/max(Gs(:)), fullfile(resfolder,"vie-05-coins-sobel.png"))
%%
%[text] ## 教科書の例題との照合（まとめ）
%[text] ここまでの `assert` をすべて通過した。各例題の結果を一覧にする。
agree = [isequal(Ybox, YboxBook)
    max(abs([fg05 - fg05Book, fg - fgBook]),[],"all") < 5e-5    % 教科書は小数第 4 位まで
    isequal(Ylap, YlapBook)
    isequal(Yus, YusBook)
    isequal(Xv, XvBook) && isequal(Xh, XhBook)
    isequal(round(Ymag,2), YmagBook)                            % 教科書は小数第 2 位まで
    isequal(Ymed, YmedBook)
    isequal(Ymax, YmaxBook) && isequal(Ymin, YminBook)];
chk = table(["矩形フィルタ";"ガウシアンフィルタ（σ=0.5，σ≃0.849）";"4近傍ラプラシアン";"4近傍アンシャープマスク"; ...
    "プレウィットフィルタ";"勾配の大きさ";"中央値フィルタ";"最大値／最小値フィルタ"], agree, ...
    'VariableNames', ["例題" "教科書と一致"])
%%
%[text] ## 二次元インパルス信号
%[text] $ \\delta[n\_1,n\_2]=\\delta[n\_1]\\,\\delta[n\_2] $ は原点だけが 1 の配列（教科書の記法：次元の添え字は 1 始まり）。
[n1g,n2g] = meshgrid(-3:3);
d2d = double(n1g==0 & n2g==0);
figure("Units","centimeters","Position",[2 2 7 5.2]);
stem3(n1g, n2g, d2d, "filled", "Color", clrMain, "MarkerFaceColor", clrMain, ...
    "MarkerSize", 3, "LineWidth", 1.2)
xlabel("$n_1$","Interpreter","latex"), ylabel("$n_2$","Interpreter","latex")
zlabel("$\delta[n_1,n_2]$","Interpreter","latex")
set(gca,"FontSize",8), view(-35,30), zticks(0:0.5:1)
exportgraphics(gcf, fullfile(resfolder,"vie-05-impulse2d.png"), "Resolution", 300)
%%
%[text] ## 畳み込みの数値例
%[text] 一次元の入力 $ x[n]=(1,2,3,2) $ とインパルス応答 $ h[n]=(1,2,1) $ の畳み込み $ y[n]=\\sum\_k x[k]h[n-k] $ 。入力をインパルスの重み付け和とみなし，各インパルスの応答を足し合わせる。
xc = [1 2 3 2]; hc = [1 2 1];
yc = conv(xc, hc)
parts = zeros(numel(xc), numel(yc));
for k = 1:numel(xc)
    parts(k, k:k+numel(hc)-1) = xc(k)*hc;      % x[k] h[n-k]
end
parts
assert(isequal(sum(parts,1), yc))
vie.savetex("vie-05-conv-x", strjoin(string(xc),","));
vie.savetex("vie-05-conv-h", strjoin(string(hc),","));
vie.savetex("vie-05-conv-y", strjoin(string(yc),",\ "));
vie.savetex("vie-05-conv-parts", vie.arr2tex(parts,"%d"));
%[text] スライドの表（行： $ x[k]h[n-k] $ ，列： $ n $ ）の本体を書き出す。インパルス応答の台の外は空欄にする。最後の行には `\\` を付けない（スライド側で付ける）。
rows = strings(numel(xc),1);
for k = 0:numel(xc)-1
    cells = strings(1, numel(yc));
    cells(k+(1:numel(hc))) = string(parts(k+1, k+(1:numel(hc))));
    if k == 0
        lab = "$x[0]h[n]$";
    else
        lab = sprintf("$x[%d]h[n-%d]$", k, k);
    end
    rows(k+1) = lab + " & " + strjoin(cells, " & ");
end
vie.savetex("vie-05-conv-n", strjoin(string(0:numel(yc)-1), " & "));
vie.savetex("vie-05-conv-rows", strjoin(rows, "\\" + newline));
vie.savetex("vie-05-conv-yrow", strjoin(string(yc), " & "));
%%
%[text] ## まとめ
%[text] - 線形フィルタは局所的な積和演算。平均値・加重平均値フィルタは平滑化，ラプラシアン・アンシャープマスクは先鋭化
%[text] - 中央値フィルタは非線形で，インパルス性ノイズに強い
%[text] - 勾配フィルタは変化の強さと向きを求める
%[text] - 線形シフト不変システムはインパルス応答との畳み込みで表される \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
%%
%[text] ## ローカル関数
function s = arr2nodes(A, fmt, offset, borderOnly)
% ARR2NODES 配列の各要素を TikZ のノード "\node at (列,-行) {$値$};" に変換する
%   左上の要素を (0,0) に置き，右へ列，下へ行が進む。OFFSET だけ左上にずらす
%   （零値拡張した配列の外周を元の配列の座標に合わせる）。BORDERONLY が true なら外周だけ。
arguments
    A (:,:) {mustBeNumeric}
    fmt (1,1) string = "%g"
    offset (1,1) double = 0
    borderOnly (1,1) logical = false
end
[nr, nc] = size(A);
lines = strings(0,1);
for r = 1:nr
    for c = 1:nc
        if borderOnly && r > 1 && r < nr && c > 1 && c < nc
            continue
        end
        lines(end+1) = sprintf("\\node at (%d,%d) {$" + fmt + "$};", ...
            c-1-offset, offset-(r-1), A(r,c)); %#ok<AGROW>
    end
end
s = strjoin(lines, newline);
end

function s = numtex(v)
% NUMTEX 数値を LaTeX の文字列にする（負の値は括弧で囲む）
s = string(sprintf("%g", v));
if v < 0
    s = "(" + s + ")";
end
end

function s = sumexpr(v)
% SUMEXPR 数値の並びを "a+b+c" の形の式にする（負の値は括弧で囲む）
s = strjoin(arrayfun(@numtex, v), "+");
end

function s = prodexpr(f, w)
% PRODEXPR 係数 f と画素値 w の積和を行ごとに "f1\cdot w1+f2\cdot w2+..." の形の式にする
f = reshape(f.', 1, []);
w = reshape(w.', 1, []);
s = "";
for k = 1:numel(f)
    t = sprintf("%g\\cdot", abs(f(k))) + numtex(w(k));
    if f(k) < 0
        s = s + "-" + t;
    elseif k > 1
        s = s + "+" + t;
    else
        s = t;
    end
end
end

function s = ordlist(v, K)
% ORDLIST 昇順に並べた値を "a,b,\underline{c},..." の形にする（K 番目に下線）
t = arrayfun(@(x) string(sprintf("%g", x)), v);
t(K) = "\underline{" + t(K) + "}";
s = strjoin(t, ",");
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
