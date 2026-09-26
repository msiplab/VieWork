%[text] # 第5回 近傍処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第5回のスライド（vie2026-05）で使う図と数値を作る。線形フィルタ（平均値・加重平均値・ラプラシアン・アンシャープマスク），中央値フィルタ，勾配フィルタ（プレウィット・ソーベル），線形シフト不変システムと畳み込みを扱う。
%[text] 教科書の線形フィルタは局所的な積和演算
%[text]{"align":"center"} $ y[\\boldsymbol{n}] = \\sum\_{\\boldsymbol{m}\\in\\mathcal{N}\_\\mathrm{f}} f[\\boldsymbol{m}]\\, x[\\boldsymbol{n}+\\boldsymbol{m}] $
%[text] で表される（実数の場合）。MATLAB の `imfilter` は既定でこの形（相関）を計算し，周囲を零値で拡張する。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[~,resfolder] = vie.prjfolders();
%%
%[text] ## 数値例の配列
%[text] 教科書の例題と前回スライドで共通に使う $ 3\\times 4 $ 配列。周囲の値はすべて零値と仮定する。
X = [18 9 9 9; 27 9 9 9; 36 9 9 9]
vie.savetex("vie-05-x", vie.arr2tex(X,"%d"));
%%
%[text] ## 平均値（矩形）フィルタ
%[text] $ 3\\times 3 $ 矩形フィルタのカーネルは $ \\frac{1}{9}\\mathbf{1} $ 。中央の画素 $ y[1,1] $ は 9 画素の平均。
fbox = ones(3)/9;
Ybox = imfilter(X, fbox)                       % 周囲は零値（imfilter の既定）
y11 = sum(X(1:3,1:3),"all")/9
vie.savetex("vie-05-box", vie.arr2tex(Ybox,"%d"));
%%
%[text] ## 加重平均値（ガウシアン）フィルタ
%[text] 標準偏差 $ \\sigma\_\\mathrm{g}\\simeq 0.849 $ のガウシアンカーネルは $ \\frac{1}{16}\\begin{pmatrix}1&2&1\\\\2&4&2\\\\1&2&1\\end{pmatrix} $ にほぼ等しい。
fg = fspecial("gaussian", 3, 0.849)
fg16 = round(16*fg)
vie.savetex("vie-05-gauss", vie.arr2tex(fg,"%.4f"));
%%
%[text] ## 平滑化の処理例（ガウス性ノイズ）
%[text] circuit.tif に標準偏差 0.05 のガウス性ノイズを加え，平均値フィルタと加重平均値フィルタで平滑化する。
rng(0)                                         % 乱数を固定して再現性を保つ
C = im2double(imread("circuit.tif"));
Cg = imnoise(C, "gaussian", 0, 0.05^2);
Cbox = imfilter(Cg, fbox, "replicate");
Cgau = imfilter(Cg, fg16/16, "replicate");
psnrG = [psnr(Cg,C) psnr(Cbox,C) psnr(Cgau,C)]
tiledlayout(2,2,"TileSpacing","compact","Padding","compact")
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
%[text] 前回スライドの例： $ 3\\times 3 $ 領域の画素値を昇順に並べ，5 番目（中央）の値で置き換える。外れ値 100 の影響を受けない。
B = [10 20 20; 20 15 20; 20 25 100]
sorted = sort(B(:))'
med = median(B(:))
avg = mean(B(:))                               % 平均値は外れ値に引っ張られる
vie.savetex("vie-05-med-sorted", strjoin(string(sorted),",\,"));
vie.savetex("vie-05-med-avg", sprintf("%.1f",avg));
%[text] 数値例の配列 X に対する $ 3\\times3 $ 中央値フィルタ（周囲は零値）：
Ymed = medfilt2(X, [3 3], "zeros")
vie.savetex("vie-05-med", vie.arr2tex(Ymed,"%d"));
%%
%[text] ## 中央値フィルタの処理例（インパルス性ノイズ）
%[text] ノイズ密度 5% のごま塩ノイズを加え，平均値フィルタと中央値フィルタを比べる。
rng(1)
Cs = imnoise(C, "salt & pepper", 0.05);
Csbox = imfilter(Cs, fbox, "replicate");
Csmed = medfilt2(Cs, [3 3], "symmetric");
psnrS = [psnr(Cs,C) psnr(Csbox,C) psnr(Csmed,C)]
tiledlayout(2,2,"TileSpacing","compact","Padding","compact")
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
%[text] 一定区間・ランプ・ステップを含む一次元信号に，一次差分 $ x[n+1]-x[n] $ と二次差分 $ x[n+1]+x[n-1]-2x[n] $ を施す。
x1 = [6 6 6 6 5 4 3 2 1 1 1 1 1 1 6 6 6 6 6];
n1 = 0:numel(x1)-1;
d1 = [x1(2:end)-x1(1:end-1) NaN];              % 一次差分（最後は未定義）
d2 = [NaN x1(3:end)+x1(1:end-2)-2*x1(2:end-1) NaN];   % 二次差分（両端は未定義）
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, stem(n1, x1, "filled"), ylabel("x[n]"), grid on, xlim([-0.5 n1(end)+0.5])
title("ランプ（n=3〜8）とステップ（n=13→14）")
nexttile, stem(n1, d1, "filled"), ylabel("一次差分"), grid on, xlim([-0.5 n1(end)+0.5])
nexttile, stem(n1, d2, "filled"), ylabel("二次差分"), grid on, xlim([-0.5 n1(end)+0.5]), xlabel("n")
exportgraphics(gcf, fullfile(resfolder,"vie-05-diff1d.png"), "Resolution", 120)
d1
d2
%%
%[text] ## ラプラシアンフィルタ
%[text] 4 近傍と 8 近傍のカーネル。数値例の配列 X に 4 近傍ラプラシアンを施す（周囲は零値）。
flap4 = [0 1 0; 1 -4 1; 0 1 0];
flap8 = [1 1 1; 1 -8 1; 1 1 1];
Ylap = imfilter(X, flap4)
y11lap = X(1,2) + X(2,1) - 4*X(2,2) + X(2,3) + X(3,2)
vie.savetex("vie-05-lap", vie.arr2tex(Ylap,"%d"));
%%
%[text] ## ラプラシアンフィルタの処理例
%[text] moon.tif に 4 近傍・8 近傍ラプラシアンを施す。出力は負の値を含むので，表示のため $ 0.5+ y $ （バイアス処理）で示す。
Mo = im2double(imread("moon.tif"));
Mo = imresize(Mo, 0.5);
L4 = imfilter(Mo, flap4, "replicate");
L8 = imfilter(Mo, flap8, "replicate");
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
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
Yus = imfilter(X, fus4)
vie.savetex("vie-05-us", vie.arr2tex(Yus,"%d"));
U4 = imfilter(Mo, fus4, "replicate");
U8 = imfilter(Mo, fus8, "replicate");
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Mo), title("原画像")
nexttile, imshow(U4), title("4 近傍")
nexttile, imshow(U8), title("8 近傍")
imwrite(min(max(U4,0),1), fullfile(resfolder,"vie-05-moon-us4.png"))
imwrite(min(max(U8,0),1), fullfile(resfolder,"vie-05-moon-us8.png"))
%%
%[text] ## プレウィットフィルタの数値例
%[text] 垂直方向 $ f\_\\mathrm{v} $ と水平方向 $ f\_\\mathrm{h} $ のカーネルで差分画像を求め，勾配の大きさ $ \\sqrt{x\_\\mathrm{v}^2+x\_\\mathrm{h}^2} $ を計算する。
fpv = [-1 -1 -1; 0 0 0; 1 1 1];
fph = fpv';
Xv = imfilter(X, fpv)
Xh = imfilter(X, fph)
Ymag = sqrt(Xv.^2 + Xh.^2)
vie.savetex("vie-05-pv",  vie.arr2tex(Xv,"%d"));
vie.savetex("vie-05-ph",  vie.arr2tex(Xh,"%d"));
vie.savetex("vie-05-mag", vie.arr2tex(Ymag,"%.2f"));
%%
%[text] ## 勾配フィルタの処理例
%[text] coins.png にプレウィットとソーベルを施し，勾配の大きさを表示する（最大値で正規化）。
Co = im2double(imread("coins.png"));
fsv = [-1 -2 -1; 0 0 0; 1 2 1]; fsh = fsv';
Gp = hypot(imfilter(Co,fpv,"replicate"), imfilter(Co,fph,"replicate"));
Gs = hypot(imfilter(Co,fsv,"replicate"), imfilter(Co,fsh,"replicate"));
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Co), title("原画像")
nexttile, imshow(Gp/max(Gp(:))), title("プレウィット")
nexttile, imshow(Gs/max(Gs(:))), title("ソーベル")
imwrite(Co, fullfile(resfolder,"vie-05-coins.png"))
imwrite(Gp/max(Gp(:)), fullfile(resfolder,"vie-05-coins-prewitt.png"))
imwrite(Gs/max(Gs(:)), fullfile(resfolder,"vie-05-coins-sobel.png"))
%%
%[text] ## 二次元インパルス信号
%[text] $ \\delta[n\_0,n\_1]=\\delta[n\_0]\\,\\delta[n\_1] $ は原点だけが 1 の配列。
[n0,n1] = meshgrid(-3:3);
d2d = double(n0==0 & n1==0);
clf
stem3(n0, n1, d2d, "filled"), xlabel("n_0"), ylabel("n_1"), zlabel("\delta[n_0,n_1]")
set(gca,"FontSize",13), view(-35,30)
exportgraphics(gca, fullfile(resfolder,"vie-05-impulse2d.png"), "Resolution", 120)
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
isequal(sum(parts,1), yc)
vie.savetex("vie-05-conv-y", strjoin(string(yc),",\ "));
vie.savetex("vie-05-conv-parts", vie.arr2tex(parts,"%d"));
%%
%[text] ## まとめ
%[text] - 線形フィルタは局所的な積和演算。平均値・加重平均値フィルタは平滑化，ラプラシアン・アンシャープマスクは先鋭化
%[text] - 中央値フィルタは非線形で，インパルス性ノイズに強い
%[text] - 勾配フィルタは変化の強さと向きを求める
%[text] - 線形シフト不変システムはインパルス応答との畳み込みで表される \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
