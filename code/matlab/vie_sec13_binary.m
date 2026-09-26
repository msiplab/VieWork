%[text] # 第13回 二値画像処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第13回のスライド（vie2026-13）で使う図と数値を作る。閾値処理と大津法，ハーフトーニング（パターンニング，ディザリング，誤差拡散），カラー画像への応用，順序統計フィルタとモルフォロジー処理を扱う。記号は教科書に合わせる（閾値 $ \\tau $ ，度数 $ h\_x $ ，クラス間分散 $ \\sigma\_\\mathrm{B}^2 $ ）。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
X = double(imread("cameraman.tif"));            % 8 bit（0〜255）
%%
%[text] ## 閾値処理（ $ \\tau=128 $ ）
%[text] 各画素値を閾値と比較して白（1）か黒（0）にする。 $ \\tau=128 $ は 8 bit の階調の中央。
imwrite(X/255, fullfile(resfolder,"vie-13-org.png"))
imwrite(double(X >= 128), fullfile(resfolder,"vie-13-th128.png"))
%%
%[text] ## 大津法が有効な例
%[text] 暗い背景に星形の物体があるノイズを含む画像。階調の中央 $ \\tau=128 $ では物体がほとんど消えるが，大津法ではヒストグラムから適切な閾値が選ばれる。
rng(0)
N = 128;
t = linspace(0, 2*pi, 11); t = t(1:end-1);
rad = repmat([48 20], 1, 5);                     % 星の外側・内側の半径
[cc, rr] = meshgrid(1:N);
star = poly2mask(N/2 + rad.*cos(t - pi/2), N/2 + rad.*sin(t - pi/2), N, N);
S = 40 + 70*star + 18*randn(N);                  % 背景 40，物体 110，ノイズ σ=18
S = min(max(round(S), 0), 255);
tauS = 255*graythresh(uint8(S))                  % 大津法の閾値
imwrite(S/255, fullfile(resfolder,"vie-13-star.png"))
imwrite(double(S >= 128), fullfile(resfolder,"vie-13-star-th128.png"))
imwrite(double(S >= tauS), fullfile(resfolder,"vie-13-star-otsu.png"))
clf
histogram(S(:), -0.5:4:255.5, "EdgeColor","none"), hold on
xline(128, "r", "LineWidth", 2), xline(tauS, "g", "LineWidth", 2), hold off
legend(["度数","\tau=128","大津法"]), xlim([0 255]), xlabel("画素値 x"), ylabel("度数 h_x"), set(gca,"FontSize",13)
exportgraphics(gca, fullfile(resfolder,"vie-13-star-hist.png"), "Resolution", 110)
vie.savetex("vie-13-otsu-star", sprintf("%.0f", tauS));
%%
%[text] ## 大津法の例題（教科書）
%[text] $ L=8 $ の $ 6\\times8 $ 配列（第4回のヒストグラム均等化と同じ配列）に大津法を適用する。閾値 $ \\tau $ ごとに黒クラス（ $ x<\\tau $ ）と白クラス（ $ x\\ge\\tau $ ）の画素数 $ n\_i $ ，平均 $ \\mu\_i $ ，クラス間分散 $ \\sigma\_\\mathrm{B}^2(\\tau)=n\_0n\_1(\\mu\_0-\\mu\_1)^2/N^2 $ を求める。
Xe = [2 2 3 1 2 4 1 1; 3 4 4 3 2 3 4 2; 4 4 4 3 4 5 5 4; 0 4 6 4 2 3 4 2;
      2 2 2 3 5 1 3 3; 2 1 4 3 4 1 6 0];
L = 8; Ne = numel(Xe);
h = histcounts(Xe, -0.5:1:L-0.5)
n0 = zeros(1,L); n1 = zeros(1,L); mu0 = nan(1,L); mu1 = nan(1,L); sB = nan(1,L);
for tau = 0:L-1
    blk = Xe(Xe < tau); wht = Xe(Xe >= tau);
    n0(tau+1) = numel(blk); n1(tau+1) = numel(wht);
    if n0(tau+1) > 0, mu0(tau+1) = mean(blk); end
    if n1(tau+1) > 0, mu1(tau+1) = mean(wht); end
    sB(tau+1) = n0(tau+1)*n1(tau+1)*(mu0(tau+1) - mu1(tau+1))^2/Ne^2;
end
table((0:L-1)', n0', n1', mu0', mu1', sB', 'VariableNames', ["tau","n0","n1","mu0","mu1","sigmaB2"])
[~, it] = max(sB); tauE = it - 1
Ye = double(Xe >= tauE)
fmt = @(v) strjoin(arrayfun(@(a) string(sprintf("%.2f",a)), v), " & ");
vie.savetex("vie-13-otsu-n0",  strjoin(string(n0), " & "));
vie.savetex("vie-13-otsu-n1",  strjoin(string(n1), " & "));
vie.savetex("vie-13-otsu-mu0", strrep(fmt(mu0), "NaN", "--"));
vie.savetex("vie-13-otsu-mu1", strrep(fmt(mu1), "NaN", "--"));
vie.savetex("vie-13-otsu-sb",  strrep(fmt(sB),  "NaN", "--"));
vie.savetex("vie-13-otsu-tau", sprintf("%d", tauE));
vie.savetex("vie-13-otsu-x",   vie.arr2tex(Xe, "%d"));
vie.savetex("vie-13-otsu-y",   vie.arr2tex(Ye, "%d"));
%%
%[text] ## 大津法による処理画像
tauC = 255*graythresh(uint8(X))
imwrite(double(X >= tauC), fullfile(resfolder,"vie-13-otsu.png"))
vie.savetex("vie-13-otsu-cam", sprintf("%.0f", tauC));
%%
%[text] ## パターンニング
%[text] $ 4\\times4 $ の 17 種類の二値パターン（黒 0 個〜16 個）を用意し，縮小した画像の各画素を対応するパターンに置き換える。パターンは次のディザ行列の順に白を増やして作る。
Td = [0 128 32 160; 192 64 224 96; 48 176 16 144; 240 112 208 80];   % 教科書のディザ配列
ord = Td/16;                                     % 0〜15 の順位
pat = cell(1,17);
for k = 0:16
    pat{k+1} = double(ord < k);                  % 白の画素が k 個
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
%[text] ## ディザリング：前回スライドの数値例
%[text] $ 8\\times8 $ の入力をディザ行列（ $ 4\\times4 $ を並べたもの）と画素ごとに比較して二値化する（ $ x\\ge $ 閾値なら 1）。
Xin = [12 51 14 31 16 50 60 70; 30 55 23 100 13 99 79 83; 77 65 199 203 202 200 85 99;
       66 58 43 11 15 65 89 91; 87 81 64 24 98 56 80 19; 41 98 31 30 18 16 9 0;
       78 43 51 61 45 53 87 15; 64 53 41 43 61 13 71 115];
T8 = repmat(Td, 2, 2);
Yd = double(Xin >= T8)
vie.savetex("vie-13-dith-x", vie.arr2tex(Xin, "%d"));
vie.savetex("vie-13-dith-t", vie.arr2tex(T8, "%d"));
vie.savetex("vie-13-dith-y", vie.arr2tex(Yd, "%d"));
imwrite(imresize(Xin/255, 16, "nearest"), fullfile(resfolder,"vie-13-dith-xin.png"))
imwrite(imresize(Yd, 16, "nearest"), fullfile(resfolder,"vie-13-dith-yout.png"))
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
%[text] R, G, B を 3, 3, 2 bit（計 8 bpp）に減らす。線形量子化と成分ごとの誤差拡散を比べる。
Xc = im2double(imread(fullfile(datfolder,"kodim23.png")));
Xc = min(max(imresize(Xc, 0.5), 0), 1);
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
imwrite(imresize(Xlq(61:140,241:320,:), 3, "nearest"), fullfile(resfolder,"vie-13-col-lq-zoom.png"))
imwrite(imresize(Xed(61:140,241:320,:), 3, "nearest"), fullfile(resfolder,"vie-13-col-ed-zoom.png"))
%%
%[text] ## 順序統計フィルタ
%[text] 前回スライドの例：中央値・最小値・最大値。
B = [10 20 20; 20 15 20; 20 25 100];
v = sort(B(:))'
vals = [median(v) min(v) max(v)]
Bb = [0 1 1; 1 0 1; 1 1 1];                      % 二値の例
vb = sort(Bb(:))'
valsb = [min(vb) max(vb)]
vie.savetex("vie-13-os-sorted", strjoin(string(v), ",\,"));
vie.savetex("vie-13-os-sortedb", strjoin(string(vb), ",\,"));
%%
%[text] ## モルフォロジー処理
%[text] 星形の二値画像にごま塩ノイズと小さな穴を加え， $ 3\\times3 $ の正方形の構造要素でエロージョン（最小値フィルタ），ダイレーション（最大値フィルタ），オープニング，クロージングを施す。
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
%[text] 最小値フィルタ・最大値フィルタと一致することを確かめる。
same = [isequal(Aer, ordfilt2(A,1,true(3),"symmetric")|0) isequal(Adi, ordfilt2(A,9,true(3))>0)]
%[text] 残った白い点・穴の数（連結成分）を数える。
cnt = @(M) [bwconncomp(M).NumObjects bwconncomp(~M).NumObjects - 1];
counts = [cnt(A); cnt(Aop); cnt(Acl)]            % 行：原画像，オープニング，クロージング／列：白領域数，穴の数
vie.savetex("vie-13-cnt-A",  sprintf("%d", counts(1,1)));
vie.savetex("vie-13-cnt-op", sprintf("%d", counts(2,1)));
vie.savetex("vie-13-hole-A",  sprintf("%d", counts(1,2)));
vie.savetex("vie-13-hole-cl", sprintf("%d", counts(3,2)));
%%
%[text] ## まとめ
%[text] - 大津法はクラス間分散を最大にする閾値を自動で選ぶ
%[text] - ハーフトーニング（パターンニング，ディザリング，誤差拡散）は二値で階調を擬似表現する
%[text] - モルフォロジー処理のエロージョン・ダイレーションは最小値・最大値フィルタで実現でき，その組合せがオープニング・クロージング \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
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
