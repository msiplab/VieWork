%[text] # 第3回 画像表現と色空間
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第3回のスライド（vie2026-03）で使う図と数値を作る。量子化，データ量（静止画像・映像），RGB カラー方式，色空間（RGB, XYZ, YCbCr, CMY, CMYK, HSV），インデックス方式を順に扱う。記号は教科書に合わせ，一画素当たりのビット数を $ \\beta $ ，総ビット数を $ B $ ，ビットレートを $ R $ ，量子化ステップを $ Q $ ，フレーム間隔を $ \\Delta\_\\mathrm{t} $ とする。
%[text] スライドに載せる数値は，すべてこの中で計算して `vie.savetex` で書き出す（スライドは `\viesnippet{}` で読み込む）。教科書の例・例題の数値は，ここで計算し直して教科書の値と一致することを確かめる。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 写真は教科書（参考資料）のサンプル画像 msipimg02（花束，512×512 画素）を使う。色とりどりの花が写っていて，RGB の各成分，HSV の各成分，減色の効果がはっきり見える。スライドの図の配置に合わせて，中央付近の $ 342\\times 512 $ 画素（行 140〜481）を切り出して横長にし， $ 256\\times 384 $ 画素に縮小する。
[~,resfolder] = vie.prjfolders();
Xrgb = im2double(vie.msipimg(2));             % 花束（RGB，512×512）
Xrgb = Xrgb(140:481,:,:);                     % 横長（縦:横 = 2:3）に切り出す
Xrgb = imresize(Xrgb, [256 384]);             % 256×384 画素に縮小（スライド用）
[N1,N2,~] = size(Xrgb)
%[text] 図の線や点の色は，スライドのロゴの 3 色（メインの緑，青，橙）にそろえる。色そのものが内容の図（成分画像，色空間の図）は除く。
cMain = [0 136 85]/255;                       % メイン（緑）#008855
cCool = [46 117 182]/255;                     % 寒色系（青）#2E75B6
cWarm = [197 90 17]/255;                      % 暖色系（橙）#C55A11
%%
%[text] ## 画像の量子化：輝度値の離散化
%[text] 8-bit の輝度値 $ x\\in\\{0,1,\\dots,255\\} $ を量子化ステップ $ Q $ で離散化する。小数点以下切り捨てを用いる（教科書の線形量子化では四捨五入 $ \\lfloor \\cdot \\rceil $ も使える）。
%[text]{"align":"center"} $ y = \\left\\lfloor \\frac{x}{Q} \\right\\rfloor $
%[text] 階調数を $ L $ とすると $ Q = 256/L $ である。まず簡単な数値で確かめる。 $ L=4 $ なら $ Q=64 $ 。
L = 4; Q = 256/L
x = [37 100 200 255]
y = floor(x/Q)
vie.savetex("vie-03-q-Q", sprintf("%d",Q));
vie.savetex("vie-03-q-x", strjoin(string(x),",\ "));
vie.savetex("vie-03-q-y", strjoin(string(y),",\ "));
%[text] 入出力の関係（量子化特性）は階段状になる。数値例はスライドの例の枠に書くので，図には重ねない。スライドでは幅 4 cm 程度で表示するので，図の大きさを 8 cm 幅にして文字が読めるようにする。
xx = 0:255;
fig = newfig(8, 6);
stairs(xx, floor(xx/Q), "Color", cMain, "LineWidth", 1.5)
grid on, xlim([0 256]), ylim([-0.2 L-0.8])
xticks(0:Q:256), yticks(0:L-1)
xlabel("$x$", "Interpreter", "latex")
ylabel("$y=\lfloor x/Q\rfloor$", "Interpreter", "latex")
set(gca, "FontSize", 12, "TickLabelInterpreter", "latex")
exportgraphics(gca, fullfile(resfolder,"vie-03-qstair.png"), "Resolution", 300)
close(fig)
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
%[text] ## ディジタル画像のデータ量（グレースケール）
%[text] 階調数 $ L $ を表すのに必要な一画素当たりのビット数は $ \\beta = \\lceil \\log\_2 L \\rceil $ 。計算の都合上， $ L $ は通常 2 のべき乗に選ぶ。階調数とビット数の対応表をそのままスライドの表にする。
Ls = [2 4 256];
betaL = ceil(log2(Ls))
vie.savetex("vie-03-beta-table", ...
    "\begin{tabular}{c|" + strjoin(repmat("c",1,numel(Ls)),"") + "}" + newline + ...
    "階調数 $L$ & " + strjoin(string(Ls)," & ") + "\\ \hline" + newline + ...
    "$\beta$ [bpp] & " + strjoin(string(betaL)," & ") + newline + ...
    "\end{tabular}");
%[text] $ N\_1\\times N\_2 $ 画素の総ビット数は $ B=\\beta N\_1 N\_2 $ 。例として $ 1080\\times 1920 $ 画素， $ L=256 $ 階調（ $ \\beta=8 $ ）の場合：
Nv = 1080; Nh = 1920; betaPx = 8;
Npix = Nv*Nh                                  % 総画素数 N1 N2
Bgray = betaPx*Npix                           % [bits]
Bbytes = Bgray/8                              % [bytes]
vie.savetex("vie-03-N-hd",     vie.fmtint(Npix));
vie.savetex("vie-03-B-gray",   vie.fmtint(Bgray));
vie.savetex("vie-03-B-grayMB", sprintf("%.1f", Bbytes/1e6));
%%
%[text] ## 教科書の例「静止画像のデータ量」
%[text] $ N\_1\\times N\_2=2304\\times 3456 $ 画素（約 800 万画素）の二種類の画像の総ビット数を計算する。
%[text] - 8-bit 符号なし整数型（ $ \\beta=8 $ bits）のグレースケール画像： $ B=\\beta N\_1N\_2 $
%[text] - 倍精度実数型（ $ \\beta=64 $ bits）の RGB カラー画像： $ B=3\\beta N\_1N\_2 $ \
%[text] MB は $ 10^6 $ bytes，1 byte = 8 bits として換算する。
N1s = 2304; N2s = 3456;
Bs8  = 8*N1s*N2s                              % グレースケール（uint8）[bits]
Bs64 = (3*64)*N1s*N2s                         % RGB（double）[bits]
MBs  = [Bs8 Bs64]/8/1e6                       % [MB]
ratioS = Bs64/Bs8                             % 後者は前者の何倍か
isequal([Bs8 Bs64], [63700992 1528823808])    % 教科書の値と一致するか
vie.savetex("vie-03-still-B-gray",    vie.fmtint(Bs8));
vie.savetex("vie-03-still-B-grayMB",  sprintf("%.0f", MBs(1)));
vie.savetex("vie-03-still-B-rgb64",   vie.fmtint(Bs64));
vie.savetex("vie-03-still-B-rgb64MB", sprintf("%.0f", MBs(2)));
vie.savetex("vie-03-still-ratio",     sprintf("%d", ratioS));
%[text] 実際の画像配列の大きさ（バイト数）は `whos` で確かめられる（講義のデモ dataamount と同じ）。8-bit の RGB 画像なら $ 3N\_1N\_2 $ bytes になる。
X8bit = im2uint8(Xrgb);
info = whos("X8bit");
isequal(info.bytes, 3*N1*N2)
%%
%[text] ## ディジタル映像のデータ量（グレースケール）
%[text] フレーム間隔を $ \\Delta\_\\mathrm{t} $ とすると，ビットレートは $ R = \\beta N\_1 N\_2 \\Delta\_\\mathrm{t}^{-1} $ [bps]。 $ \\Delta\_\\mathrm{t} = 1/30 $ s の場合：
Dt = 1/30;
Rgray = betaPx*Nv*Nh/Dt                       % [bps]
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
vie.savetex("vie-03-ncolors-1bit", sprintf("%d", ncolors(1)));
vie.savetex("vie-03-ncolors",      vie.fmtint(ncolors(2)));
%[text] 画素の色を RGB 空間 $ [0,1]^3 $ の点として描く（講義のデモ rgbcolordemo と同じ見せ方）。各成分 1 bit の画像では，画素は立方体の 8 つの頂点にしか現れない。各成分 8 bit の画像では，画素が立方体の中に雲のように広がる。点の色はその画素の色である。
fig = newfig(5.5, 5.5);
plotrgbcloud(X8, 40)
exportgraphics(gca, fullfile(resfolder,"vie-03-rgbcloud-8.png"), "Resolution", 300)
close(fig)
fig = newfig(5.5, 5.5);
plotrgbcloud(Xrgb, 2)
exportgraphics(gca, fullfile(resfolder,"vie-03-rgbcloud-full.png"), "Resolution", 300)
close(fig)
%%
%[text] ## 【例】ディジタル映像のデータ量（RGB）
%[text] $ 1080\\times 1920 $ 画素，各フレーム RGB（ $ \\beta\_\\mathrm{R}=\\beta\_\\mathrm{G}=\\beta\_\\mathrm{B}=8 $ ）， $ \\Delta\_\\mathrm{t}=1/30 $ s のビットレート（教科書の章末問題と同じ設定）：
Rrgb = (8+8+8)*Nv*Nh/Dt                       % [bps]
vie.savetex("vie-03-R-rgb",  vie.fmtint(Rrgb));
vie.savetex("vie-03-R-rgbG", sprintf("%.3f", Rrgb/1e9));
%%
%[text] ## 教科書の例題「動画像のビットレート」
%[text] RGB カラー動画像， $ N\_1\\times N\_2=4320\\times 7680 $ 画素， $ \\Delta\_\\mathrm{t}=1/60 $ s， $ \\beta=8 $ bits。一画素当たり $ 3\\beta $ bpp，1 フレーム当たり $ B=3\\beta N\_1N\_2 $ bits，ビットレートは $ R=B\\Delta\_\\mathrm{t}^{-1} $ 。
N1u = 4320; N2u = 7680; fru = 60; betaU = 8;  % fru はフレームレート 1/Δt
Nu = N1u*N2u                                  % 1 フレームの画素数
bppU = 3*betaU                                % [bpp]
Bu = bppU*Nu                                  % [bits/frame]
Ru = Bu*fru                                   % [bps]
isequal([Nu Bu Ru], [33177600 796262400 47775744000])   % 教科書の値と一致するか
vie.savetex("vie-03-uhd-bpp", sprintf("%d", bppU));
vie.savetex("vie-03-uhd-N",   vie.fmtint(Nu));
vie.savetex("vie-03-uhd-B",   vie.fmtint(Bu));
vie.savetex("vie-03-uhd-R",   vie.fmtint(Ru));
vie.savetex("vie-03-uhd-RG",  sprintf("%.0f", Ru/1e9));
%%
%[text] ## RGB 空間
%[text] RGB の各成分を座標軸にとると，色は単位立方体 $ [0,1]^3 $ の中の点になる。黒 (0,0,0) と白 (1,1,1) を結ぶ対角線がグレースケール。
V = [0 0 0;1 0 0;1 1 0;0 1 0;0 0 1;1 0 1;1 1 1;0 1 1];   % 頂点の座標＝色
F = [1 2 3 4;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8];
fig = newfig(5, 5);                           % 図の大きさを固定して，環境によらず同じ画像にする
patch("Vertices",V,"Faces",F,"FaceVertexCData",V,"FaceColor","interp","EdgeColor","k")
view([1 0.8 0.9]), axis equal off
exportgraphics(gca, fullfile(resfolder,"vie-03-rgbcube.png"), "Resolution", 200)
close(fig)
%[text] グレースケール変換（BT.601）の係数 $ a\_0=0.299,\\ a\_1=0.587,\\ a\_2=0.114 $ は和が 1 になる。
a601 = [0.299 0.587 0.114];
sum(a601)
%%
%[text] ## xy 色度図
%[text] CIE の XYZ 空間から $ x=X/S,\\ y=Y/S\\ (S=X+Y+Z) $ として得た xy 色度図。三角形は sRGB の三原色で表せる色の範囲。
fig = newfig(6, 6);                           % スライドでは幅 2.5 cm 程度で表示する
plotChromaticity
hold on
prim = [0.64 0.33; 0.30 0.60; 0.15 0.06];     % sRGB の R, G, B 原色の xy
plot(prim([1:3 1],1), prim([1:3 1],2), "k-", "LineWidth", 1.5)
hold off
xlabel("$x$", "Interpreter", "latex"), ylabel("$y$", "Interpreter", "latex")
xticks(0:0.2:0.8), yticks(0:0.2:0.8)
set(gca, "FontSize", 11, "TickLabelInterpreter", "latex")
exportgraphics(gca, fullfile(resfolder,"vie-03-xy.png"), "Resolution", 300)
close(fig)
%%
%[text] ## XYZ 空間（教科書の例「XYZ空間」）
%[text] 線形 RGB 空間の画素 $ \\vec{x}=(x\_\\mathrm{R}\\ x\_\\mathrm{G}\\ x\_\\mathrm{B})^\\top $ から XYZ 画素 $ \\vec{y}=(y\_\\mathrm{X}\\ y\_\\mathrm{Y}\\ y\_\\mathrm{Z})^\\top $ への線形変換 $ \\vec{y}=\\boldsymbol{A}\\vec{x} $ の行列を，sRGB の三原色の色度と白色点 D65 の色度 $ (0.3127,\\ 0.3290) $ から求める。
%[text] 色度 $ (x,y) $ の色の XYZ は $ (x/y,\\ 1,\\ (1-x-y)/y) $ の定数倍である。原色 R, G, B の XYZ をこの形の列ベクトルの $ s\_k $ 倍とし，白 $ \\vec{x}=(1\\ 1\\ 1)^\\top $ が D65 の XYZ（ $ Y=1 $ ）に写るように倍率 $ s\_k $ を決める。
wD65 = [0.3127 0.3290];                       % D65 の色度 (x, y)
xyz2col = @(c) [c(:,1)./c(:,2), ones(size(c,1),1), (1-c(:,1)-c(:,2))./c(:,2)].';
Cp = xyz2col(prim);                           % 列が原色の XYZ（Y=1 に正規化）
w  = xyz2col(wD65);                           % D65 の XYZ（Y=1）
s  = Cp\w;                                    % 各原色の倍率
Axyz = Cp*diag(s)
%[text] 小数第 4 位に丸めると教科書の行列と一致する。2 行目（Y 成分）の和は 1 で，白の輝度が 1 になる。
Axyz4 = round(Axyz,4)
Axyz_book = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];
isequal(Axyz4, Axyz_book)                     % 教科書の値と一致するか
vie.savetex("vie-03-xyz-A", vie.arr2tex(Axyz4,"%.4f"));
%%
%[text] ## YCbCr 空間（BT.601）
%[text] 教科書の例「YCbCr空間」は，ガンマ補正済みの $ x\_\\mathrm{R'},x\_\\mathrm{G'},x\_\\mathrm{B'}\\in[0,1] $ から
%[text]{"align":"center"} $ \\begin{pmatrix} y\_\\mathrm{Y'} \\\\ y\_\\mathrm{Cb} \\\\ y\_\\mathrm{Cr} \\end{pmatrix} \\simeq \\frac{1}{256}\\begin{pmatrix} 65.7380 & 129.0570 & 25.0640 \\\\ -37.9450 & -74.4940 & 112.4390 \\\\ 112.4390 & -94.1540 & -18.2850 \\end{pmatrix}\\begin{pmatrix} x\_\\mathrm{R'} \\\\ x\_\\mathrm{G'} \\\\ x\_\\mathrm{B'} \\end{pmatrix} + \\begin{pmatrix} 16/255 \\\\ 128/255 \\\\ 128/255 \\end{pmatrix} $
%[text] とする。全体を 255 倍すると，8-bit（0〜255）の R'G'B' から 8-bit の Y'CbCr への変換になる（行列は同じで，オフセットが $ (16\\ 128\\ 128)^\\top $ ）。スライドの行列もここから書き出す。
Mycc = [65.738 129.057 25.064; -37.945 -74.494 112.439; 112.439 -94.154 -18.285];
A = Mycc/256;
b = [16;128;128];
vie.savetex("vie-03-ycc-M", vie.arr2tex(Mycc,"%.4f"));
%[text] 1 行目を $ 255/219 $ 倍すると BT.601 の輝度の係数 $ (0.299\\ 0.587\\ 0.114) $ に戻る（Y' の範囲が 16〜235 の 219 段階であるため）。
A(1,:)*255/219
A3 = round(A,3)                               % 係数（小数第 3 位）
vie.savetex("vie-03-ycc-A", vie.arr2tex(A3,"%.3f"));
%[text] 代表的な色で確かめる。列は赤，緑，青，白，黒。MATLAB の `rgb2ycbcr` の結果とも一致する。
names = ["赤" "緑" "青" "白" "黒"];
P = [255 0 0; 0 255 0; 0 0 255; 255 255 255; 0 0 0]';
Yp = round(A*P + b)
check = double(rgb2ycbcr(uint8(reshape(P',[],1,3))));   % MATLAB 関数と一致するか
isequal(squeeze(check)', Yp)
vie.savetex("vie-03-ycc-P", vie.arr2tex(P,"%d"));
vie.savetex("vie-03-ycc-Y", vie.arr2tex(Yp,"%d"));
%[text] スライドの表（代表的な色の変換）は，この結果から表全体を書き出す。無彩色（ $ x\_\\mathrm{R'}=x\_\\mathrm{G'}=x\_\\mathrm{B'} $ ）は色差が $ 128 $ （零に相当）になるので強調する。白と黒は輝度の範囲の両端 235 と 16 になる。
isAchrom = all(P == P(1,:), 1);               % 無彩色の列
strP = compose("(%d,%d,%d)", P.');
strY = compose("(%d,%d,%d)", Yp.');
strY(isAchrom) = "\positive{" + strY(isAchrom) + "}";
vie.savetex("vie-03-ycc-table", ...
    "\begin{tabular}{r|" + strjoin(repmat("c",1,numel(names)),"") + "}" + newline + ...
    " & " + strjoin(names," & ") + "\\ \hline" + newline + ...
    "$(x_\mathrm{R'},x_\mathrm{G'},x_\mathrm{B'})$ & " + strjoin(strP.'," & ") + "\\" + newline + ...
    "$(y_\mathrm{Y'},y_\mathrm{Cb},y_\mathrm{Cr})$ & " + strjoin(strY.'," & ") + newline + ...
    "\end{tabular}");
%[text] 逆変換（Y'CbCr $ \\to $ R'G'B'）の行列は $ \\boldsymbol{A}^{-1} $ として計算できる。小数第 4 位に丸めると教科書の逆変換の行列と一致する（ 0 の成分は丸め誤差程度の小さな値になる）。
Ainv = inv(A)
Ainv4 = round(Ainv,4); Ainv4(Ainv4 == 0) = 0; % -0 を 0 にする
Ainv_book = [1.1644 0 1.5960; 1.1644 -0.3918 -0.8130; 1.1644 2.0172 0];
isequal(Ainv4, Ainv_book)                     % 教科書の値と一致するか
vie.savetex("vie-03-ycc-Minv", arr2texz(Ainv4,"%.4f"));
Ainv3 = round(Ainv,3); Ainv3(Ainv3 == 0) = 0;
vie.savetex("vie-03-ycc-Ainv", vie.arr2tex(Ainv3,"%.3f"));
%[text] 逆変換で元に戻ることも確かめる。
Pr = round(Ainv*(Yp - b))                     %#ok<MINV> 逆変換の行列をそのまま使う
%[text] Y'CbCr を 8-bit 整数に丸めているため，±1 程度の誤差が残ることがある（0〜255 の範囲外に出ることもあるので，実際にはクリッピングする）。
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
%[text] 一画素当たりのビット数とビットレート（ $ 1080\\times1920 $ 画素， $ \\Delta\_\\mathrm{t}=1/30 $ s，各成分 8 bit）。4:2:0 形式では $ R=\\Delta\_\\mathrm{t}^{-1}N\_1N\_2(\\beta\_\\mathrm{Y}+\\beta\_\\mathrm{Cb}/4+\\beta\_\\mathrm{Cr}/4) $ 。4:2:0 は SMPTE295M の 4:2:0 形式（約 746 Mbps）と同じ値になる。
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
%[text] 各成分を 0〜1 に正規化すると，CMY は RGB の補色： $ \\vec{y} = \\vec{1}-\\vec{x} $ （教科書の例題「CMY空間」）。オレンジ色の画素 $ \\vec{x}=(1\\ 0.5\\ 0)^\\top $ で確かめる。成分は教科書の記法（転置した行ベクトル）に合わせて \\quad 区切りで書き出す。
xo = [1 0.5 0];
ycmy = 1 - xo
vie.savetex("vie-03-cmy-x", strjoin(compose("%g",xo),"\quad "));
vie.savetex("vie-03-cmy-y", strjoin(compose("%g",ycmy),"\quad "));
%%
%[text] ## CMYK 空間
%[text] まず RGB の補色 $ (1-x\_\\mathrm{R},1-x\_\\mathrm{G},1-x\_\\mathrm{B}) $ の最小値として $ y\_\\mathrm{K} $ を求め，K で補正した CMY を $ \\vec{1} - \\vec{x}/(1-y\_\\mathrm{K}) $ で求める。途中の値（補色と $ 1-y\_\\mathrm{K} $ ）もスライドに書き出す。
xk = [0.2 0.4 0.6];
xkc = 1 - xk                                  % RGB の補色
yK = min(xkc)
yCMY = 1 - xk/(1 - yK)
xback = (1 - yK)*(1 - yCMY)                   % 逆変換（教科書の例題の解答）で元に戻る
vie.savetex("vie-03-cmyk-x",   strjoin(compose("%.1f",xk),"\quad "));
vie.savetex("vie-03-cmyk-1mx", strjoin(compose("%.1f",xkc),",\ "));
vie.savetex("vie-03-cmyk-K",   sprintf("%.1f",yK));
vie.savetex("vie-03-cmyk-1mK", sprintf("%.1f",1-yK));
vie.savetex("vie-03-cmyk-cmy", strjoin(compose("%.3f",yCMY),"\quad "));
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
%[text] 教科書の HSV 変換（MATLAB の `rgb2hsv` と同じ）で成分画像を作る（講義のデモ hsidemo と同じ見せ方）。
Xhsv = rgb2hsv(Xrgb);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Xhsv(:,:,1)), title("H")
nexttile, imshow(Xhsv(:,:,2)), title("S")
nexttile, imshow(Xhsv(:,:,3)), title("V")
imwrite(Xhsv(:,:,1), fullfile(resfolder,"vie-03-hsv-h.png"))
imwrite(Xhsv(:,:,2), fullfile(resfolder,"vie-03-hsv-s.png"))
imwrite(Xhsv(:,:,3), fullfile(resfolder,"vie-03-hsv-v.png"))
%[text] 数値例：オレンジ $ \\vec{x}=(1\\ 0.5\\ 0)^\\top $ 。教科書の式どおりに計算する。 $ x\_\\mathrm{max}=1,\\ x\_\\mathrm{min}=0 $ より $ y\_\\mathrm{V}=x\_\\mathrm{max}=1,\\ y\_\\mathrm{S}=(x\_\\mathrm{max}-x\_\\mathrm{min})/x\_\\mathrm{max}=1 $ 。R が最大で G が最小でないので $ y\_\\mathrm{H} = (60^\\circ - 60^\\circ\\cdot(x\_\\mathrm{max}-x\_\\mathrm{G})/(x\_\\mathrm{max}-x\_\\mathrm{min}))/360^\\circ = 30^\\circ/360^\\circ $ 。
xmx = max(xo), xmn = min(xo)
yV = xmx
yS = (xmx - xmn)/xmx
Hdeg = 60 - 60*(xmx - xo(2))/(xmx - xmn)      % [度]
hsvo = rgb2hsv(xo)                            % MATLAB 関数と一致するか
max(abs(hsvo - [Hdeg/360 yS yV])) < 1e-12
vie.savetex("vie-03-hsv-x",    strjoin(compose("%g",xo),"\quad "));
vie.savetex("vie-03-hsv-xmax", sprintf("%g",xmx));
vie.savetex("vie-03-hsv-xmin", sprintf("%g",xmn));
vie.savetex("vie-03-hsv-V",    sprintf("%g",yV));
vie.savetex("vie-03-hsv-S",    sprintf("%g",yS));
vie.savetex("vie-03-hsv-H",    sprintf("%.0f",Hdeg));
%%
%[text] ## インデックス方式
%[text] $ 4\\times4 $ 画素，4 色（ $ \\beta\_\\mathrm{I}=2 $ bit），カラーマップの各色は RGB 各 2 bit（計 6 bit）。
idx = [0 0 0 0; 0 1 1 2; 3 1 1 1; 3 3 3 3]
map6 = ["001111"; "111100"; "110101"; "110011"];          % RGB 各 2 bit
cmap = [bin2dec(char(extractBetween(map6,1,2))) bin2dec(char(extractBetween(map6,3,4))) ...
        bin2dec(char(extractBetween(map6,5,6)))]/3
Xidx = ind2rgb(uint8(idx), cmap);             % uint8 ならインデックス 0 がマップの 1 行目
clf
imshow(imresize(Xidx, 40, "nearest"))
imwrite(imresize(Xidx, 40, "nearest"), fullfile(resfolder,"vie-03-idx4x4.png"))
%[text] 総ビット数を比べる。インデックス方式は $ B=\\beta\_\\mathrm{I}N\_1N\_2 + 2^{\\beta\_\\mathrm{I}}(\\beta\_\\mathrm{R}+\\beta\_\\mathrm{G}+\\beta\_\\mathrm{B}) $ （第 2 項はカラーマップ分）。
betaI = 2; bitsMap = 6; [N1e,N2e] = size(idx);
Bidx1 = betaI*N1e*N2e                         % インデックス配列の分
Bidx2 = 2^betaI*bitsMap                       % カラーマップの分
Bidx = Bidx1 + Bidx2
Brgb44 = bitsMap*N1e*N2e                      % RGB カラー方式
vie.savetex("vie-03-idx-B1", sprintf("%d",Bidx1));
vie.savetex("vie-03-idx-B2", sprintf("%d",Bidx2));
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
%[text] - XYZ への変換行列は三原色と白色点の色度から決まる。YCbCr は輝度と色差に分け，色差サブサンプリングでデータ量を減らせる
%[text] - CMY は RGB の補色，CMYK は黒を加えた 4 成分，HSV は色相・彩度・明度
%[text] - インデックス方式は色を限定する代わりに一画素のビット数を減らす \
%%
%[text] ## 【関数定義】
function plotrgbcloud(X, msz)
% 画像 X（N1×N2×3，値は 0〜1）の画素の色を RGB 空間の点として描く。
% 点の色はその画素の色。重なる色は 1 点にまとめ，多すぎるときは間引く。
c = unique(reshape(X, [], 3), "rows");
if size(c,1) > 8000
    c = c(round(linspace(1, size(c,1), 8000)), :);
end
V = [0 0 0;1 0 0;1 1 0;0 1 0;0 0 1;1 0 1;1 1 1;0 1 1];   % 立方体の頂点
E = [1 2;2 3;3 4;4 1;5 6;6 7;7 8;8 5;1 5;2 6;3 7;4 8];   % 立方体の辺
hold on
for k = 1:size(E,1)
    plot3(V(E(k,:),1), V(E(k,:),2), V(E(k,:),3), "Color", [0.6 0.6 0.6])
end
plot3([0 1], [0 1], [0 1], "--", "Color", [0.6 0.6 0.6])   % 黒と白を結ぶ対角線（グレースケール）
Ax = eye(3);                                  % 黒から出る 3 辺を R, G, B の座標軸として濃く描く
for k = 1:3
    plot3([0 Ax(k,1)], [0 Ax(k,2)], [0 Ax(k,3)], "Color", [0.2 0.2 0.2], "LineWidth", 1)
end
if msz > 20
    edgecolor = [0.4 0.4 0.4];                % 大きな点は縁取り（白い点も見えるように）
else
    edgecolor = "none";
end
scatter3(c(:,1), c(:,2), c(:,3), msz, c, "filled", "MarkerEdgeColor", edgecolor)
hold off
axis equal off
xlim([-0.06 1.06]), ylim([-0.06 1.06]), zlim([-0.06 1.06])   % 頂点の点が切れないよう少し広げる
view(-37.5, 25)
text(0.55, -0.12, -0.06, "$x_\mathrm{R}$", "Interpreter", "latex", "FontSize", 14, ...
    "HorizontalAlignment", "left", "VerticalAlignment", "top")
text(-0.12, 0.55, -0.06, "$x_\mathrm{G}$", "Interpreter", "latex", "FontSize", 14, ...
    "HorizontalAlignment", "right", "VerticalAlignment", "top")
text(-0.08, -0.08, 0.5, "$x_\mathrm{B}$", "Interpreter", "latex", "FontSize", 14, ...
    "HorizontalAlignment", "right")
end

function fig = newfig(wcm, hcm)
% 図を書き出すための新しい figure を幅 wcm，高さ hcm [cm] で作る
fig = figure("Units", "centimeters", "Position", [2 2 wcm hcm], "Color", "w");
end

function s = arr2texz(X, format)
% vie.arr2tex と同じだが，ちょうど 0 の成分は "0" と書く（教科書の行列の表記）
[rows,~] = size(X);
lines = strings(rows,1);
for i = 1:rows
    e = compose(format, X(i,:));
    e(X(i,:) == 0) = "0";
    lines(i) = strjoin(e, " & ");
end
s = strjoin(lines, "\\" + newline);
end
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
