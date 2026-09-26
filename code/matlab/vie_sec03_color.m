%[text] # 第3回 画像表現と色空間
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第3回のスライド（vie2026-03）で使う図と数値を作る。量子化，データ量（静止画像・映像），RGB カラー方式，色空間（RGB, XYZ, YCbCr, CMY, CMYK, HSV），インデックス方式を順に扱う。記号は教科書に合わせ，一画素当たりのビット数を $ \\beta $ ，総ビット数を $ B $ ，ビットレートを $ R $ ，量子化ステップを $ Q $ とする。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] Kodak Lossless True Color Image Suite の画像を `data` フォルダに取得する（取得済みなら何もしない）。この回では主に kodim03（帽子）を使う。
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
Xrgb = im2double(imread(fullfile(datfolder,"kodim03.png")));
Xrgb = imresize(Xrgb, 0.5);                   % 256×384 画素に縮小（スライド用）
[N1,N2,~] = size(Xrgb)
%%
%[text] ## 画像の量子化：輝度値の離散化
%[text] 8-bit の輝度値 $ x\\in\\{0,1,\\dots,255\\} $ を量子化ステップ $ Q $ で離散化する。前回スライドと同じく小数点以下切り捨てを用いる（教科書の線形量子化では四捨五入 $ \\lfloor \\cdot \\rceil $ も使える）。
%[text]{"align":"center"} $ y = \\left\\lfloor \\frac{x}{Q} \\right\\rfloor $
%[text] 階調数を $ L $ とすると $ Q = 256/L $ である。まず簡単な数値で確かめる。 $ L=4 $ なら $ Q=64 $ 。
L = 4; Q = 256/L
x = [37 100 200 255]
y = floor(x/Q)
vie.savetex("vie-03-q-Q", sprintf("%d",Q));
vie.savetex("vie-03-q-x", strjoin(string(x),",\ "));
vie.savetex("vie-03-q-y", strjoin(string(y),",\ "));
%[text] 入出力の関係（量子化特性）は階段状になる。
xx = 0:255;
clf
stairs(xx, floor(xx/Q), "LineWidth", 2)
grid on, xlim([0 256]), ylim([-0.2 L-0.8])
xticks(0:Q:256), yticks(0:L-1)
xlabel("入力 x"), ylabel("出力 y")
set(gca,"FontSize",14)
exportgraphics(gca, fullfile(resfolder,"vie-03-qstair.png"), "Resolution", 150)
%%
%[text] ## 階調数を変えた画像
%[text] グレースケール画像を $ L=2,4,256 $ 階調に量子化する。表示のため $ y/(L-1) $ で 0〜1 に戻す。階調が少ないと擬似輪郭が目立つ。
Xg = im2uint8(rgb2gray(Xrgb));
for L = [2 4 256]
    Q = 256/L;
    Yq = floor(double(Xg)/Q);                 % 量子化インデックス 0〜L-1
    imwrite(Yq/(L-1), fullfile(resfolder,sprintf("vie-03-quant-%d.png",L)))
end
clf
montage({imread(fullfile(resfolder,"vie-03-quant-2.png")), ...
         imread(fullfile(resfolder,"vie-03-quant-4.png")), ...
         imread(fullfile(resfolder,"vie-03-quant-256.png"))}, "Size", [1 3])
%%
%[text] ## デジタル画像のデータ量（モノクロ）
%[text] 階調数 $ L $ を表すのに必要な一画素当たりのビット数は $ \\beta = \\lceil \\log\_2 L \\rceil $ 。計算の都合上， $ L $ は通常 2 のべき乗に選ぶ。
L = [2 4 256];
beta = ceil(log2(L))
%[text] $ N\_1\\times N\_2 $ 画素の総ビット数は $ B=\\beta N\_1 N\_2 $ 。例として $ 1080\\times 1920 $ 画素， $ L=256 $ 階調の場合：
Nv = 1080; Nh = 1920; beta = 8;
Bgray = beta*Nv*Nh                            % [bits]
Bbytes = Bgray/8                              % [bytes]
vie.savetex("vie-03-B-gray",   vie.fmtint(Bgray));
vie.savetex("vie-03-B-grayMB", sprintf("%.1f", Bbytes/1e6));
%%
%[text] ## デジタル映像のデータ量（モノクロ）
%[text] フレーム間隔を $ \\Delta\_\\mathrm{t} $ とすると，ビットレートは $ R = \\beta N\_1 N\_2 \\Delta\_\\mathrm{t}^{-1} $ [bps]。 $ \\Delta\_\\mathrm{t} = 1/30 $ s の場合：
Dt = 1/30;
Rgray = beta*Nv*Nh/Dt                         % [bps]
vie.savetex("vie-03-R-gray",  vie.fmtint(Rgray));
vie.savetex("vie-03-R-grayM", sprintf("%.1f", Rgray/1e6));
%%
%[text] ## RGB カラー方式
%[text] 各成分（R, G, B）をそれぞれ配列で表す。総ビット数は $ B=(\\beta\_\\mathrm{R}+\\beta\_\\mathrm{G}+\\beta\_\\mathrm{B})N\_1N\_2 $ 。
Z = zeros(N1,N2);
tiledlayout(1,4,"TileSpacing","compact","Padding","compact")
nexttile, imshow(cat(3,Xrgb(:,:,1),Z,Z)), title("R")
nexttile, imshow(cat(3,Z,Xrgb(:,:,2),Z)), title("G")
nexttile, imshow(cat(3,Z,Z,Xrgb(:,:,3))), title("B")
nexttile, imshow(Xrgb), title("カラー")
imwrite(cat(3,Xrgb(:,:,1),Z,Z), fullfile(resfolder,"vie-03-rgb-r.png"))
imwrite(cat(3,Z,Xrgb(:,:,2),Z), fullfile(resfolder,"vie-03-rgb-g.png"))
imwrite(cat(3,Z,Z,Xrgb(:,:,3)), fullfile(resfolder,"vie-03-rgb-b.png"))
imwrite(Xrgb,                   fullfile(resfolder,"vie-03-rgb-full.png"))
%[text] この画像（ $ 256\\times 384 $ 画素，各成分 8 bit）の総ビット数：
Brgb = (8+8+8)*N1*N2
vie.savetex("vie-03-B-rgb", vie.fmtint(Brgb));
vie.savetex("vie-03-size",  sprintf("%d\\times %d", N1, N2));
%%
%[text] ## RGB カラー方式と量子化
%[text] 各成分を 1 bit にすると表せる色は $ 2^3=8 $ 色，8 bit なら $ 256^3 $ 色。
ncolors = [2^3, 256^3]
X8 = double(Xrgb >= 0.5);                     % 各成分を 1 bit に量子化
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(X8),   title("8 色")
nexttile, imshow(Xrgb), title("16,777,216 色")
imwrite(X8, fullfile(resfolder,"vie-03-rgb-8colors.png"))
vie.savetex("vie-03-ncolors", vie.fmtint(ncolors(2)));
%%
%[text] ## 【例】デジタル映像のデータ量（RGB）
%[text] $ 1080\\times 1920 $ 画素，各フレーム RGB（ $ \\beta\_\\mathrm{R}=\\beta\_\\mathrm{G}=\\beta\_\\mathrm{B}=8 $ ）， $ \\Delta\_\\mathrm{t}=1/30 $ s のビットレート：
Rrgb = (8+8+8)*Nv*Nh/Dt                       % [bps]
vie.savetex("vie-03-R-rgb",  vie.fmtint(Rrgb));
vie.savetex("vie-03-R-rgbG", sprintf("%.3f", Rrgb/1e9));
%%
%[text] ## RGB 空間
%[text] RGB の各成分を座標軸にとると，色は単位立方体 $ [0,1]^3 $ の中の点になる。黒 (0,0,0) と白 (1,1,1) を結ぶ対角線がグレースケール。
V = [0 0 0;1 0 0;1 1 0;0 1 0;0 0 1;1 0 1;1 1 1;0 1 1];   % 頂点の座標＝色
F = [1 2 3 4;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8];
clf
patch("Vertices",V,"Faces",F,"FaceVertexCData",V,"FaceColor","interp","EdgeColor","k")
view([1 0.8 0.9]), axis equal off
exportgraphics(gca, fullfile(resfolder,"vie-03-rgbcube.png"), "Resolution", 150)
%%
%[text] ## xy 色度図
%[text] CIE の XYZ 空間から $ x=X/S,\\ y=Y/S\\ (S=X+Y+Z) $ として得た xy 色度図。三角形は sRGB の三原色で表せる色の範囲。
clf
plotChromaticity
hold on
prim = [0.64 0.33; 0.30 0.60; 0.15 0.06];     % sRGB の R, G, B 原色の xy
plot(prim([1:3 1],1), prim([1:3 1],2), "k-", "LineWidth", 2)
hold off
set(gca,"FontSize",13)
exportgraphics(gca, fullfile(resfolder,"vie-03-xy.png"), "Resolution", 150)
%%
%[text] ## YCbCr 空間（BT.601）
%[text] 8-bit の R'G'B'（0〜255）から Y'CbCr（8-bit）への変換（教科書の式を 255 倍して 8-bit にしたもの）：
%[text]{"align":"center"} $ \\begin{pmatrix} y\_\\mathrm{Y} \\\\ y\_\\mathrm{Cb} \\\\ y\_\\mathrm{Cr} \\end{pmatrix} = \\frac{1}{256}\\begin{pmatrix} 65.738 & 129.057 & 25.064 \\\\ -37.945 & -74.494 & 112.439 \\\\ 112.439 & -94.154 & -18.285 \\end{pmatrix}\\begin{pmatrix} x\_\\mathrm{R} \\\\ x\_\\mathrm{G} \\\\ x\_\\mathrm{B} \\end{pmatrix} + \\begin{pmatrix} 16 \\\\ 128 \\\\ 128 \\end{pmatrix} $
A = [65.738 129.057 25.064; -37.945 -74.494 112.439; 112.439 -94.154 -18.285]/256;
b = [16;128;128];
A3 = round(A,3)                               % 前回スライドの係数（小数第 3 位）
%[text] 代表的な色で確かめる。列は赤，緑，青，白，黒。
P = [255 0 0; 0 255 0; 0 0 255; 255 255 255; 0 0 0]';
Yp = round(A*P + b)
check = double(rgb2ycbcr(uint8(reshape(P',[],1,3))));   % MATLAB 関数と一致するか
isequal(squeeze(check)', Yp)
vie.savetex("vie-03-ycc-A", vie.arr2tex(A3,"%.3f"));
vie.savetex("vie-03-ycc-P", vie.arr2tex(P,"%d"));
vie.savetex("vie-03-ycc-Y", vie.arr2tex(Yp,"%d"));
%[text] 逆変換（教科書の行列）で元に戻ることも確かめる。
Ainv = [1.1644 0 1.5960; 1.1644 -0.3918 -0.8130; 1.1644 2.0172 0];
Pr = round(Ainv*(Yp - b))
%[text] Y'CbCr を 8-bit 整数に丸めているため，±1 程度の誤差が残る（0〜255 の範囲外に出ることもあるので，実際にはクリッピングする）。
vie.savetex("vie-03-ycc-Ainv", vie.arr2tex(round(Ainv,3),"%.3f"));
%%
%[text] ## YCbCr の成分画像
%[text] Y は明るさ（ほぼグレースケール画像），Cb と Cr は色の差だけを持つ。色差成分は変化が緩やかである。
Ycc = rgb2ycbcr(Xrgb);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Ycc(:,:,1)), title("Y")
nexttile, imshow(Ycc(:,:,2)), title("Cb")
nexttile, imshow(Ycc(:,:,3)), title("Cr")
imwrite(Ycc(:,:,1), fullfile(resfolder,"vie-03-ycc-y.png"))
imwrite(Ycc(:,:,2), fullfile(resfolder,"vie-03-ycc-cb.png"))
imwrite(Ycc(:,:,3), fullfile(resfolder,"vie-03-ycc-cr.png"))
%%
%[text] ## 色差サブサンプリング
%[text] 人の眼は輝度より色の変化に鈍感なので，色差の標本化間隔を広げてデータ量を減らす。4:2:0 形式では Cb, Cr を縦横 1/2 に間引く。
Cb = imresize(imresize(Ycc(:,:,2),0.5,"bilinear"), [N1 N2], "bilinear");
Cr = imresize(imresize(Ycc(:,:,3),0.5,"bilinear"), [N1 N2], "bilinear");
X420 = ycbcr2rgb(cat(3, Ycc(:,:,1), Cb, Cr));
psnr420 = psnr(X420, Xrgb)
imwrite(X420, fullfile(resfolder,"vie-03-sub420.png"))
vie.savetex("vie-03-sub420-psnr", sprintf("%.1f", psnr420));
%[text] 一画素当たりのビット数とビットレート（ $ 1080\\times1920 $ 画素， $ \\Delta\_\\mathrm{t}=1/30 $ s，各成分 8 bit）。4:2:0 形式では $ R=\\Delta\_\\mathrm{t}^{-1}N\_1N\_2(\\beta\_\\mathrm{Y}+\\beta\_\\mathrm{Cb}/4+\\beta\_\\mathrm{Cr}/4) $ 。
fmt = ["4:4:4"; "4:2:2"; "4:2:0"];
bpp = [8+8+8; 8+8/2+8/2; 8+8/4+8/4];
Rfmt = bpp*Nv*Nh/Dt;
table(fmt, bpp, Rfmt/1e6, 'VariableNames', ["形式","bpp","R [Mbps]"])
vie.savetex("vie-03-bpp-444", sprintf("%d",bpp(1)));
vie.savetex("vie-03-bpp-422", sprintf("%d",bpp(2)));
vie.savetex("vie-03-bpp-420", sprintf("%d",bpp(3)));
vie.savetex("vie-03-R-444", sprintf("%.0f",Rfmt(1)/1e6));
vie.savetex("vie-03-R-422", sprintf("%.0f",Rfmt(2)/1e6));
vie.savetex("vie-03-R-420", sprintf("%.0f",Rfmt(3)/1e6));
%%
%[text] ## CMY 空間
%[text] 各成分を 0〜1 に正規化すると，CMY は RGB の補色： $ (y\_\\mathrm{C},y\_\\mathrm{M},y\_\\mathrm{Y}) = (1-x\_\\mathrm{R},1-x\_\\mathrm{G},1-x\_\\mathrm{B}) $ 。オレンジ色の画素で確かめる。
xo = [1 0.5 0];
ycmy = 1 - xo
vie.savetex("vie-03-cmy-x", strjoin(compose("%g",xo),",\ "));
vie.savetex("vie-03-cmy-y", strjoin(compose("%g",ycmy),",\ "));
%%
%[text] ## CMYK 空間
%[text] まず $ y\_\\mathrm{K}=\\min(1-x\_\\mathrm{R},1-x\_\\mathrm{G},1-x\_\\mathrm{B}) $ を求め，K で補正した CMY を $ 1 - \\vec{x}/(1-y\_\\mathrm{K}) $ で求める。
xk = [0.2 0.4 0.6];
yK = min(1 - xk)
yCMY = 1 - xk/(1 - yK)
xback = (1 - yK)*(1 - yCMY)                   % 逆変換で元に戻る
vie.savetex("vie-03-cmyk-x",   strjoin(compose("%.1f",xk),",\ "));
vie.savetex("vie-03-cmyk-K",   sprintf("%.1f",yK));
vie.savetex("vie-03-cmyk-cmy", strjoin(compose("%.3f",yCMY),",\ "));
%%
%[text] ## HS 系：色相環
%[text] 色相（H）を角度，彩度（S）を中心からの距離で表す。赤 0°，緑 120°，青 240°。明度 V=1 の断面を描く。
n = 301; c0 = (n+1)/2;
[cc,rr] = meshgrid(1:n,1:n);
dx = (cc-c0)/(c0-1); dy = -(rr-c0)/(c0-1);    % 上向きを正にする
H = mod(atan2(dy,dx)/(2*pi), 1);
S = min(hypot(dx,dy), 1);
W = hsv2rgb(cat(3,H,S,ones(n)));
W(repmat(hypot(dx,dy) > 1,[1 1 3])) = 1;      % 円の外は白
clf
imshow(W)
imwrite(W, fullfile(resfolder,"vie-03-huewheel.png"))
%%
%[text] ## RGB 各成分と HSV 各成分
%[text] 教科書の HSV 変換（MATLAB の `rgb2hsv` と同じ）で成分画像を作る。
Xhsv = rgb2hsv(Xrgb);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Xhsv(:,:,1)), title("H")
nexttile, imshow(Xhsv(:,:,2)), title("S")
nexttile, imshow(Xhsv(:,:,3)), title("V")
imwrite(Xhsv(:,:,1), fullfile(resfolder,"vie-03-hsv-h.png"))
imwrite(Xhsv(:,:,2), fullfile(resfolder,"vie-03-hsv-s.png"))
imwrite(Xhsv(:,:,3), fullfile(resfolder,"vie-03-hsv-v.png"))
%[text] 数値例：オレンジ $ (1,0.5,0) $ 。 $ x\_\\mathrm{max}=1,\\ x\_\\mathrm{min}=0 $ より $ V=1,\\ S=1 $ 。R が最大で G が最小でないので $ H = 60^\\circ - 60^\\circ\\cdot(1-0.5)/1 = 30^\\circ $ 。
hsvo = rgb2hsv(xo)
Hdeg = hsvo(1)*360
vie.savetex("vie-03-hsv-H", sprintf("%.0f",Hdeg));
%%
%[text] ## インデックス方式
%[text] 前回スライドの例： $ 4\\times4 $ 画素，4 色（ $ \\beta\_\\mathrm{I}=2 $ bit），カラーマップの各色は RGB 各 2 bit（計 6 bit）。
idx = [0 0 0 0; 0 1 1 2; 3 1 1 1; 3 3 3 3]
map6 = ["001111"; "111100"; "110101"; "110011"];          % RGB 各 2 bit
map = [bin2dec(char(extractBetween(map6,1,2))) bin2dec(char(extractBetween(map6,3,4))) ...
       bin2dec(char(extractBetween(map6,5,6)))]/3
Xidx = ind2rgb(uint8(idx), map);              % uint8 ならインデックス 0 がマップの 1 行目
clf
imshow(imresize(Xidx, 40, "nearest"))
imwrite(imresize(Xidx, 40, "nearest"), fullfile(resfolder,"vie-03-idx4x4.png"))
%[text] 総ビット数を比べる。インデックス方式は $ B=\\beta\_\\mathrm{I}N\_1N\_2 + 2^{\\beta\_\\mathrm{I}}(\\beta\_\\mathrm{R}+\\beta\_\\mathrm{G}+\\beta\_\\mathrm{B}) $ （第 2 項はカラーマップ分）。
Bidx = 2*4*4 + 2^2*6
Brgb44 = 6*4*4
vie.savetex("vie-03-idx-B",  sprintf("%d",Bidx));
vie.savetex("vie-03-rgb-B",  sprintf("%d",Brgb44));
%%
%[text] ## インデックス方式の実画像例
%[text] 写真を 8 色（ $ \\beta\_\\mathrm{I}=3 $ ）に減色する。色数は限られるが，一画素 3 bit で済む。
[I8, map8] = rgb2ind(Xrgb, 8, "nodither");
X8i = ind2rgb(I8, map8);
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(X8i), title("8 色（インデックス）")
nexttile, imshow(permute(map8,[3 1 2])), title("カラーマップ")
imwrite(X8i, fullfile(resfolder,"vie-03-ind8.png"))
imwrite(imresize(permute(map8,[1 3 2]), [8*20 40], "nearest"), fullfile(resfolder,"vie-03-ind8-map.png"))
Bind8 = 3*N1*N2 + 2^3*24
ratio = Brgb/Bind8
vie.savetex("vie-03-B-ind8", vie.fmtint(Bind8));
vie.savetex("vie-03-ind8-ratio", sprintf("%.1f",ratio));
%%
%[text] ## まとめ
%[text] - 量子化 $ y=\\lfloor x/Q \\rfloor $ で輝度値を離散化する。階調が少ないと擬似輪郭が現れる
%[text] - データ量は $ B=\\beta N\_1N\_2 $ [bits]，映像なら $ R=\\beta N\_1N\_2\\Delta\_\\mathrm{t}^{-1} $ [bps]
%[text] - YCbCr は輝度と色差に分け，色差サブサンプリングでデータ量を減らせる
%[text] - CMY は RGB の補色，CMYK は黒を加えた 4 成分，HSV は色相・彩度・明度
%[text] - インデックス方式は色を限定する代わりに一画素のビット数を減らす \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
