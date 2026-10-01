%[text] # 第13回 二値画像処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第13回のスライド（vie2026-13）で使う図と数値を作る。閾値処理と大津法，ハーフトーニング（パターンニング，ディザリング，誤差拡散），カラー画像への応用，順序統計フィルタとモルフォロジー処理を扱う。記号は教科書に合わせる（閾値 $ \\tau $ ，度数 $ h\_x $ ，クラス間分散 $ \\sigma\_\\mathrm{B}^2 $ ，構造化要素 $ \\mathsf{h} $ ）。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[~,resfolder] = vie.prjfolders();
%[text] 写真は参考資料のサンプル画像 msipimg08（スイカ，参考資料の図 2.5 と同じ画像）をグレースケールにし， $ 256\\times256 $ に縮小して使う。縞模様のスイカが暗い背景の中にあり，閾値の選び方の違い（階調の中央と大津法）がはっきり見える。
X = double(vie.msipimg(8, 256, "gray"));        % 8 bit（0〜255），256×256
%[text] 図の配色はロゴの 3 色（メインの緑 #008855，青 #2E75B6，橙 #C55A11）と灰色にそろえる。
cMain = [0 136 85]/255;                          % 緑（メイン）
cCool = [46 117 182]/255;                        % 青（寒色系）：データ
cWarm = [197 90 17]/255;                         % 橙（暖色系）：注目
cGray = 0.5*[1 1 1];
%%
%[text] ## 閾値処理（ $ \\tau=128 $ ）
%[text] 各画素値を閾値と比較して白（1）か黒（0）にする。 $ \\tau=128 $ は 8 bit の階調の中央。画素値が整数なので，教科書の例「二値化閾値処理」の $ \\tau=x\_\\mathrm{max}/2=127.5 $ と同じ結果になる。
imwrite(X/255, fullfile(resfolder,"vie-13-org.png"))
imwrite(double(X >= 128), fullfile(resfolder,"vie-13-th128.png"))
isequal(X >= 128, X >= 127.5)
%%
%[text] ## 大津法の手順（教科書 2.2.3 項）
%[text] 大津法は，黒クラス（ $ i=0 $ ， $ x<\\tau $ ）と白クラス（ $ i=1 $ ， $ x\\geq\\tau $ ）のクラス間分散
%[text] $ \\sigma\_\\mathrm{B}^2(\\tau)=\\frac{1}{N^2}n\_0(\\tau)n\_1(\\tau)\\bigl(\\mu\_0(\\tau)-\\mu\_1(\\tau)\\bigr)^2 $
%[text] を最大にする閾値 $ \\tau^\\star $ を選ぶ。スクリプト末尾のローカル関数 `otsu` は，教科書の手順どおり度数 $ h\_x $ から画素数 $ n\_i(\\tau) $ と画素値の累積和 $ c\_i(\\tau) $ を $ \\tau=1,2,\\ldots,L-1 $ の順に更新し， $ n\_i(\\tau)=0 $ のときの平均値 $ \\mu\_i(\\tau) $ を NaN（数値として定義できない値）とする。
%[text] 注意：MATLAB の `graythresh` が返す閾値（ $ [0,1] $ に正規化）は黒クラスに含まれる最大の画素値を表す。教科書の $ \\tau^\\star $ （白クラスに含まれる最小の画素値）とは $ \\tau^\\star=255\\times\\texttt{graythresh}+1 $ の関係にある。
%%
%[text] ## 大津法が有効な例
%[text] 暗い背景に星形の物体があるノイズを含む画像（背景 40，物体 110，ノイズの標準偏差 18）。階調の中央 $ \\tau=128 $ では物体がほとんど消えるが，大津法ではヒストグラムから適切な閾値が選ばれる。
rng(0)
N = 128;
t = linspace(0, 2*pi, 11); t = t(1:end-1);
rad = repmat([48 20], 1, 5);                     % 星の外側・内側の半径
star = poly2mask(N/2 + rad.*cos(t - pi/2), N/2 + rad.*sin(t - pi/2), N, N);
S = 40 + 70*star + 18*randn(N);                  % 背景 40，物体 110，ノイズ σ=18
S = min(max(round(S), 0), 255);
tauS = otsu(S, 256)                              % 大津法の閾値 τ*
[tauS 255*graythresh(uint8(S))+1]                % graythresh との関係を確認
imwrite(S/255, fullfile(resfolder,"vie-13-star.png"))
imwrite(double(S >= 128), fullfile(resfolder,"vie-13-star-th128.png"))
imwrite(double(S >= tauS), fullfile(resfolder,"vie-13-star-otsu.png"))
vie.savetex("vie-13-otsu-star", sprintf("%d", tauS));
%[text] 度数分布 $ h\_x $ と 2 つの閾値。大津法の閾値 $ \\tau^\\star $ は背景と物体の 2 つの山の間に置かれる。
fig = figure("WindowStyle","normal","Color","w","Position",[100 100 440 270]);
histogram(S(:), -0.5:1:255.5, "EdgeColor","none", "FaceColor",cCool, "FaceAlpha",1), hold on
xline(128, "--", "Color",cGray, "LineWidth",2, "Alpha",1)
xline(tauS, "-", "Color",cWarm, "LineWidth",2.5, "Alpha",1), hold off
legend(["$h_x$", "$\tau=128$", sprintf("$\\tau^\\star=%d$", tauS)], "Interpreter","latex", "Location","northeast")
xlim([0 255]), xlabel("$x$","Interpreter","latex"), ylabel("$h_x$","Interpreter","latex")
set(gca, "FontSize",15, "TickLabelInterpreter","latex", "Box","off")
exportgraphics(fig, fullfile(resfolder,"vie-13-star-hist.png"), "Resolution",300)
close(fig)
%%
%[text] ## 大津法の例題（教科書）
%[text] $ L=8 $ の $ 6\\times8 $ 配列（教科書の例題「ヒストグラム均等化」の配列，第4回と同じ）に大津法を適用する。教科書の表（クラス間分散）と一致し， $ \\tau^\\star=3 $ となる。
Xe = [2 2 3 1 2 4 1 1; 3 4 4 3 2 3 4 2; 4 4 4 3 4 5 5 4; 0 4 6 4 2 3 4 2;
      2 2 2 3 5 1 3 3; 2 1 4 3 4 1 6 0];
L = 8; Ne = numel(Xe);
[tauE, tbl] = otsu(Xe, L)
%[text] 定義どおりに（黒・白クラスの画素を直接取り出して）計算しても同じ値になることを確かめる。
sBdirect = nan(1,L);
for tau = 1:L-1
    blk = Xe(Xe < tau); wht = Xe(Xe >= tau);
    sBdirect(tau+1) = numel(blk)*numel(wht)*(mean(blk) - mean(wht))^2/Ne^2;
end
isequaln(round(sBdirect,12), round(tbl.sigmaB2',12))
Ye = double(Xe >= tauE)
%[text] 表のスニペット。未定義の値は教科書どおり NaN と表示し，最大のクラス間分散を太字にする。
fmt2 = @(v) arrayfun(@(a) string(sprintf("%.2f",a)), v);   % sprintf は NaN を "NaN" と書く
sBstr = fmt2(tbl.sigmaB2');
sBstr(tauE+1) = "\textbf{" + sBstr(tauE+1) + "}";
vie.savetex("vie-13-otsu-n0",  strjoin(string(tbl.n0'), " & "));
vie.savetex("vie-13-otsu-n1",  strjoin(string(tbl.n1'), " & "));
vie.savetex("vie-13-otsu-mu0", strjoin(fmt2(tbl.mu0'), " & "));
vie.savetex("vie-13-otsu-mu1", strjoin(fmt2(tbl.mu1'), " & "));
vie.savetex("vie-13-otsu-sb",  strjoin(sBstr, " & "));
vie.savetex("vie-13-otsu-tau", sprintf("%d", tauE));
vie.savetex("vie-13-otsu-x",   vie.arr2tex(Xe, "%d"));
vie.savetex("vie-13-otsu-y",   vie.arr2tex(Ye, "%d"));
%%
%[text] ## 大津法による処理画像
%[text] 教科書の図 2.7(b) は教科書の画像（ $ 96\\times96 $ ）で $ \\tau^\\star=84 $ 。ここでは同じ画像 msipimg08 を $ 256\\times256 $ に縮小したものに同じ手順を適用する（縮小のため閾値は少し異なる）。
tauC = otsu(X, 256)
imwrite(double(X >= tauC), fullfile(resfolder,"vie-13-otsu.png"))
vie.savetex("vie-13-otsu-cam", sprintf("%d", tauC));
%%
%[text] ## パターンニング
%[text] $ 4\\times4 $ の 17 種類の二値パターン（白 0 個〜16 個）を用意し，縮小した画像の各画素を対応するパターンに置き換える。パターンは次のディザ配列の順に白を増やして作る。
Td = [0 128 32 160; 192 64 224 96; 48 176 16 144; 240 112 208 80];   % 教科書のディザ配列
rnk = Td/16;                                     % 0〜15 の順位
pat = cell(1,17);
for k = 0:16
    pat{k+1} = double(rnk < k);                  % 白の画素が k 個
end
tiles = ones(4*2+1, (4+1)*17+1);                 % パターン一覧（灰色の枠）
for k = 0:16
    tiles(2:5, 5*k+2:5*k+5) = pat{k+1};
end
imwrite(imresize(tiles, 8, "nearest"), fullfile(resfolder,"vie-13-patterns.png"))
Xs = imresize(X, 1/4, "box");                    % 64×64 に縮小
lev = round(Xs/255*16);                          % 0〜16 のレベル
P = zeros(size(X));
for r = 1:size(Xs,1), for c = 1:size(Xs,2)
    P(4*r-3:4*r, 4*c-3:4*c) = pat{lev(r,c)+1};
end, end
imwrite(P, fullfile(resfolder,"vie-13-pattern.png"))
%%
%[text] ## ディザリングの数値例
%[text] $ 8\\times8 $ の入力をディザ配列（ $ 4\\times4 $ を並べたもの）と画素ごとに比較して二値化する（ $ x\\ge $ 閾値なら 1）。
Xin = [12 51 14 31 16 50 60 70; 30 55 23 100 13 99 79 83; 77 65 199 203 202 200 85 99;
       66 58 43 11 15 65 89 91; 87 81 64 24 98 56 80 19; 41 98 31 30 18 16 9 0;
       78 43 51 61 45 53 87 15; 64 53 41 43 61 13 71 115];
T8 = repmat(Td, 2, 2);
Yd = double(Xin >= T8)
vie.savetex("vie-13-dith-x", vie.arr2tex(Xin, "%d"));
vie.savetex("vie-13-dith-t", vie.arr2tex(T8, "%d"));
vie.savetex("vie-13-dith-td", vie.arr2tex(Td, "%d"));  % ディザ配列そのもの（教科書の T）
vie.savetex("vie-13-dith-y", vie.arr2tex(Yd, "%d"));
imwrite(imresize(Xin/255, 16, "nearest"), fullfile(resfolder,"vie-13-dith-xin.png"))
imwrite(imresize(Yd, 16, "nearest"), fullfile(resfolder,"vie-13-dith-yout.png"))
%[text] スライドの説明に使う 2 画素（左上とその右）の比較。
rel = ["<" "\geq"];
for k = 1:2
    vie.savetex("vie-13-dith-c"+k, sprintf("%d%s%d", Xin(1,k), rel(Yd(1,k)+1), T8(1,k)));
    vie.savetex("vie-13-dith-y"+k, sprintf("%d", Yd(1,k)));
end
%%
%[text] ## ディザリングの処理画像
Tfull = repmat(Td, size(X)/4);
Dth = double(X >= Tfull);
imwrite(Dth, fullfile(resfolder,"vie-13-dither.png"))
%%
%[text] ## 誤差拡散（Floyd & Steinberg）
%[text] 左上から右へ（ラスタ走査）二値化し，量子化誤差 $ e $ を右 7/16，左下 3/16，下 5/16，右下 1/16 の割合で未処理の画素に配る。
ed = @(x) floydsteinberg(x);
E = ed(X/255);
imwrite(E, fullfile(resfolder,"vie-13-errdiff.png"))
%[text] 局所的な白画素の割合は元の明るさに近い（ $ 8\\times8 $ 平均の比較）。
loc = [mean(abs(imresize(E,1/8,"box") - imresize(X/255,1/8,"box")), "all") ...
       mean(abs(imresize(Dth,1/8,"box") - imresize(X/255,1/8,"box")), "all") ...
       mean(abs(imresize(double(X>=128),1/8,"box") - imresize(X/255,1/8,"box")), "all")]
vie.savetex("vie-13-loc-ed", sprintf("%.3f", loc(1)));
vie.savetex("vie-13-loc-di", sprintf("%.3f", loc(2)));
vie.savetex("vie-13-loc-th", sprintf("%.3f", loc(3)));
%[text] 数値例：一様な明るさ 0.25 の $ 8\\times8 $ 画像では，白画素の割合がほぼ 1/4 になる（端では誤差を配りきれないので少しずれる）。
E25 = ed(0.25*ones(8))
frac = mean(E25(:))
vie.savetex("vie-13-ed25-n", sprintf("%d", sum(E25(:))));
vie.savetex("vie-13-ed25", vie.arr2tex(E25, "%d"));
%%
%[text] ## カラー画像への応用：24 bpp → 8 bpp
%[text] R, G, B を 3, 3, 2 bit（計 8 bpp）に減らす。線形量子化と成分ごとの誤差拡散を比べる。写真は msipimg01（海岸， $ 256\\times256 $ に縮小）。空のなめらかな階調で，線形量子化の擬似輪郭と誤差拡散の効果がはっきり見える。
Xc = im2double(vie.msipimg(1, 256));
bits = [3 3 2];
Xlq = zeros(size(Xc)); Xed = zeros(size(Xc));
for k = 1:3
    Lk = 2^bits(k) - 1;
    Xlq(:,:,k) = round(Xc(:,:,k)*Lk)/Lk;                     % 線形量子化
    Xed(:,:,k) = floydsteinberg(Xc(:,:,k), Lk);              % 多値の誤差拡散
end
imwrite(Xc,  fullfile(resfolder,"vie-13-col-org.png"))
imwrite(Xlq, fullfile(resfolder,"vie-13-col-lq.png"))
imwrite(Xed, fullfile(resfolder,"vie-13-col-ed.png"))
imwrite(imresize(Xlq(1:60,141:200,:), 4, "nearest"), fullfile(resfolder,"vie-13-col-lq-zoom.png"))
imwrite(imresize(Xed(1:60,141:200,:), 4, "nearest"), fullfile(resfolder,"vie-13-col-ed-zoom.png"))
%%
%[text] ## 順序統計フィルタ
%[text] 近傍領域 $ \\mathcal{N}\_\\mathrm{f} $ （ $ 3\\times3 $ ）の画素値を昇順に並べ， $ K $ 番目の値を出力する（教科書 3.3 節）。中央値（ $ K=(|\\mathcal{N}\_\\mathrm{f}|+1)/2=5 $ ），最小値（ $ K=1 $ ），最大値（ $ K=|\\mathcal{N}\_\\mathrm{f}|=9 $ ）を求める。
B = [10 20 20; 20 15 20; 20 25 100];
v = sort(B(:))'
K = [(numel(v)+1)/2 1 numel(v)];                 % 中央値，最小値，最大値の順位
vals = v(K)                                      % ord(・,K)
isequal(vals, [median(B(:)) min(B(:)) max(B(:))])
vie.savetex("vie-13-os-sorted", strjoin(string(v), ",\,"));
vie.savetex("vie-13-os-med", sprintf("%d", vals(1)));
vie.savetex("vie-13-os-min", sprintf("%d", vals(2)));
vie.savetex("vie-13-os-max", sprintf("%d", vals(3)));
%[text] 二値の例。二値画像では，最小値フィルタは近傍の論理積，最大値フィルタは近傍の論理和になる。昇順に並べた列の $ K $ 番目に下線を付けて書き出す（教科書の例題「中央値フィルタ」の解答と同じ表記）。
Bb = [0 1 1; 1 0 1; 1 1 1];
vb = sort(Bb(:))'
valsb = [vb(1) vb(end)]
isequal(valsb, [all(Bb(:)) any(Bb(:))])
vie.savetex("vie-13-os-sortedb", strjoin(string(vb), ",\,"));
vie.savetex("vie-13-os-sortedb-min", ordlist(vb, 1));
vie.savetex("vie-13-os-sortedb-max", ordlist(vb, numel(vb)));
vie.savetex("vie-13-os-minb", sprintf("%d", valsb(1)));
vie.savetex("vie-13-os-maxb", sprintf("%d", valsb(2)));
%[text] 2 つの配列を，ます目と数値で描く。中央の対象画素を橙で示す。
ctr = false(3); ctr(2,2) = true;
drawgrid(B,  ctr, fullfile(resfolder,"vie-13-os-grid.png"),  0.3*cWarm + 0.7)
drawgrid(Bb, ctr, fullfile(resfolder,"vie-13-os-gridb.png"), 0.3*cWarm + 0.7)
%%
%[text] ## 例題「最大値／最小値フィルタ」（教科書 3.3.2 項）
%[text] 教科書の例題「矩形フィルタ」の配列 $ \\mathsf{x} $ に $ 3\\times3 $ の最大値フィルタと最小値フィルタを施す。周囲の値はすべて零値とする（ `ordfilt2` の既定の境界処理）。教科書の解答と一致する。
Xm = [18 9 9 9; 27 9 9 9; 36 9 9 9];
Tmax = ordfilt2(Xm, 9, ones(3))                  % K=|N_f|=9
Tmin = ordfilt2(Xm, 1, ones(3))                  % K=1
Tmed = ordfilt2(Xm, 5, ones(3))                  % 参考：例題「中央値フィルタ」（K=5）
isequal(Tmax, [27 27 9 9; 36 36 9 9; 36 36 9 9]) && isequal(Tmin, [0 0 0 0; 0 9 9 0; 0 0 0 0]) ...
    && isequal(Tmed, [0 9 9 0; 9 9 9 9; 0 9 9 0])
vie.savetex("vie-13-mm-x",   vie.arr2tex(Xm, "%d"));
vie.savetex("vie-13-mm-max", vie.arr2tex(Tmax, "%d"));
vie.savetex("vie-13-mm-min", vie.arr2tex(Tmin, "%d"));
%%
%[text] ## モルフォロジー処理
%[text] 星形の二値画像にごま塩ノイズと小さな穴を加え， $ 3\\times3 $ の平坦な正方形の構造化要素 $ \\mathsf{h} $ で収縮（最小値フィルタ），膨張（最大値フィルタ），オープニング（収縮の後に膨張），クロージング（膨張の後に収縮）を施す。
rng(2)
A = star;
A(rand(N) < 0.02) = 1;                           % 背景の白い点（ごま）
A(star & rand(N) < 0.03) = 0;                    % 物体の中の黒い穴（しお）
se = strel("square", 3);
Aer = imerode(A, se); Adi = imdilate(A, se);
Aop = imopen(A, se);  Acl = imclose(A, se);
names = ["A","erode","dilate","open","close"];
imgs = {A, Aer, Adi, Aop, Acl};
for k = 1:5
    imwrite(double(imgs{k}), fullfile(resfolder,"vie-13-morph-"+names(k)+".png"))
end
%[text] 最小値フィルタ・最大値フィルタと一致することを確かめる。教科書どおり，収縮では周囲に $ +\\infty $ （二値では 1），膨張では $ -\\infty $ （二値では 0）を仮定する。
Amin = ordfilt2(padarray(A, [1 1], true), 1, true(3));  Amin = Amin(2:end-1, 2:end-1);
Amax = ordfilt2(padarray(A, [1 1], false), 9, true(3)); Amax = Amax(2:end-1, 2:end-1);
same = [isequal(Aer, Amin) isequal(Adi, Amax)]
%[text] 残った白い点・穴の数（連結成分）を数える。
cnt = @(M) [bwconncomp(M).NumObjects bwconncomp(~M).NumObjects - 1];
counts = [cnt(A); cnt(Aop); cnt(Acl)]            % 行：原画像，オープニング，クロージング／列：白領域数，穴の数
vie.savetex("vie-13-cnt-A",  sprintf("%d", counts(1,1)));
vie.savetex("vie-13-cnt-op", sprintf("%d", counts(2,1)));
vie.savetex("vie-13-hole-A",  sprintf("%d", counts(1,2)));
vie.savetex("vie-13-hole-cl", sprintf("%d", counts(3,2)));
%%
%[text] ## まとめ
%[text] - 大津法はクラス間分散を最大にする閾値を自動で選ぶ（未定義の平均値は NaN）
%[text] - ハーフトーニング（パターンニング，ディザリング，誤差拡散）は二値で階調を擬似表現する
%[text] - モルフォロジー処理の収縮・膨張は最小値・最大値フィルタで実現でき，その組合せがオープニング・クロージング \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
function [tauStar, tbl] = otsu(x, L)
% OTSU 教科書 2.2.3 項の手順による大津法（x は 0〜L-1 の整数）
%   tauStar : クラス間分散を最大にする閾値（x < tauStar が黒，x >= tauStar が白）
%   tbl     : τ=0,1,...,L-1 に対する h_τ, n0, n1, mu0, mu1, sigmaB2（未定義は NaN）
N = numel(x);
h = histcounts(x(:), -0.5:1:L-0.5);             % 手順 1：度数 h_x（h(k) が h_{k-1}）
n0 = zeros(1,L); n1 = zeros(1,L); c0 = zeros(1,L); c1 = zeros(1,L);
mu0 = nan(1,L); mu1 = nan(1,L); sB = nan(1,L);   % μ0(0)，σB²(0) は NaN
n1(1) = N; c1(1) = (0:L-1)*h(:);                 % 手順 2：τ=0 の初期化
mu1(1) = c1(1)/n1(1);
for tau = 1:L-1                                  % 手順 3：τ=1,2,...,L-1
    k = tau + 1;                                 % 配列の添え字は τ+1
    n0(k) = n0(k-1) + h(tau);                    % h(tau) = h_{τ-1}
    n1(k) = n1(k-1) - h(tau);
    c0(k) = c0(k-1) + (tau-1)*h(tau);
    c1(k) = c1(k-1) - (tau-1)*h(tau);
    if n0(k) ~= 0, mu0(k) = c0(k)/n0(k); end
    if n1(k) ~= 0, mu1(k) = c1(k)/n1(k); end
    sB(k) = n0(k)*n1(k)*(mu0(k) - mu1(k))^2/N^2; % 平均が NaN なら NaN
end
[~, kmax] = max(sB);                             % 手順 4（max は NaN を無視する）
tauStar = kmax - 1;
tbl = table((0:L-1)', h', n0', n1', mu0', mu1', sB', ...
    'VariableNames', ["tau","h","n0","n1","mu0","mu1","sigmaB2"]);
end

function s = ordlist(v, K)
% ORDLIST 昇順に並べた列 v を「,\,」区切りの文字列にし，K 番目に下線を付ける
c = string(v);
c(K) = "\underline{" + c(K) + "}";
s = strjoin(c, ",\,");
end

function drawgrid(A, mask, fname, fc)
% DRAWGRID 配列 A をます目と数値で描いて保存する（mask の画素は色 fc で塗る）
[nr, nc] = size(A);
fig = figure("WindowStyle","normal","Color","w","Position",[100 100 64*nc 60*nr]);
ax = axes(fig, "Position",[0 0 1 1]); hold(ax, "on")
for r = 1:nr
    for c = 1:nc
        face = [1 1 1];
        if mask(r,c), face = fc; end
        rectangle(ax, "Position",[c-1, nr-r, 1, 1], "FaceColor",face, "EdgeColor","k", "LineWidth",1.2)
        text(ax, c-0.5, nr-r+0.5, string(A(r,c)), "HorizontalAlignment","center", ...
            "VerticalAlignment","middle", "FontSize",20)
    end
end
hold(ax, "off"), axis(ax, "equal"), axis(ax, "off")
xlim(ax, [-0.03 nc+0.03]), ylim(ax, [-0.03 nr+0.03])
exportgraphics(ax, fname, "Resolution",300, "BackgroundColor","white")
close(fig)
end

function y = floydsteinberg(x, L)
% FLOYDSTEINBERG フロイド・スタインバーグの誤差拡散（x は 0〜1，L+1 階調に量子化，既定は二値）
if nargin < 2, L = 1; end
[nr, nc] = size(x);
w = [x zeros(nr,1)]; w = [w; zeros(1,nc+1)]; w = [zeros(nr+1,1) w];   % 右・下・左に余白
y = zeros(nr, nc);
for r = 1:nr
    for c = 1:nc
        v = w(r, c+1);                          % 誤差を加えた値
        q = min(max(round(v*L), 0), L)/L;       % 量子化（二値なら閾値 0.5）
        y(r,c) = q;
        e = v - q;                              % 量子化誤差
        w(r,   c+2) = w(r,   c+2) + e*7/16;
        w(r+1, c  ) = w(r+1, c  ) + e*3/16;
        w(r+1, c+1) = w(r+1, c+1) + e*5/16;
        w(r+1, c+2) = w(r+1, c+2) + e*1/16;
    end
end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
