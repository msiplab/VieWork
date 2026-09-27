%[text] # 第9回 線形変換処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第9回のスライド（vie2026-09）で使う図と数値を作る。自然画像の隣接画素の相関，信号変換 $ \\mathbf{y}=\\mathbf{A}\\mathbf{x} $ と基底ベクトル $ \\mathbf{b}\_m $ （ $ \\mathbf{B}=\\mathbf{A}^{-1} $ の列），基底画像，離散コサイン変換（DCT），離散ハール変換（DHT），ブロック処理，ハール変換のフィルタバンク表現を扱う。
%[text] 記号は教科書（村松正吾『多次元信号・画像処理の基礎と展開』）に合わせる。教科書の例・例題（例「分散共分散行列」，例題「二次元DCT」「二次元DHT」「ブロック処理」）は，ここで計算し直して教科書の解答と一致することを確かめてから，スライドに書き出す。図の配色は MSIP Lab のロゴの 3 色（緑 #008855，青 #2E75B6，橙 #C55A11）と灰色を使う。
%[text] $ 2\\times2 $ の数値例では，前回スライドと同じくハール変換（ $ \\pi/4 $ 回転）行列
%[text]{"align":"center"} $ \\mathbf{A}=\\frac{1}{\\sqrt{2}}\\begin{pmatrix}1&1\\\\-1&1\\end{pmatrix} $
%[text] を用いる（教科書の $ \\mathbf{H}\_2=\\mathbf{C}\_2 $ とは第 2 行の符号だけが異なる）。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[~,resfolder] = vie.prjfolders();
cmain = [0 136 85]/255;     % メイン（緑）#008855：図の主役
ccool = [46 117 182]/255;   % 寒色系（青）#2E75B6：入力・データ側
cgray = [0.5 0.5 0.5];      % 補助線
A = [1 1; -1 1]/sqrt(2)
B = inv(A)                                     % = A'（直交行列）
%%
%[text] ## 自然画像の隣接画素の散布図
%[text] cameraman.tif の水平方向の隣接画素ペア $ \\mathbf{x}^{[i]}=(x\_0\\ x\_1)^\\top $ （重ならないように 2 画素ずつ）を散布図にする。添え字は第09回全体で 0 始まりに揃える（教科書の図 6.1 は 1 始まり）。ほぼ対角線上に並ぶ：隣どうしは似た値をとる（相関が強い）。
X = im2double(imread("cameraman.tif"));
x1 = X(:,1:2:end); x2 = X(:,2:2:end);
P = [x1(:) x2(:)]';                            % 2×S の画素ペア
S = size(P,2)
%[text] 標本分散共分散行列は教科書の式どおり $ 1/S $ で正規化する（ `cov` の第 2 引数を 1 にする）。
%[text]{"align":"center"} $ \\hat{\\boldsymbol{\\Sigma}}\_\\mathcal{X}=\\frac{1}{S}\\sum\_{i=1}^{S}\\underline{\\mathbf{x}}^{[i]}(\\underline{\\mathbf{x}}^{[i]})^\\top,\\quad \\underline{\\mathbf{x}}^{[i]}=\\mathbf{x}^{[i]}-\\hat{\\boldsymbol{\\mu}}\_\\mathcal{X} $
Sx = cov(P', 1)
clf
scatter(P(1,:), P(2,:), 6, ccool, "filled", "MarkerFaceAlpha", 0.3, "MarkerEdgeColor", "none")
axis square, axis([0 1 0 1]), grid on, box on
xlabel("$x_0$", "Interpreter", "latex"), ylabel("$x_1$", "Interpreter", "latex")
set(gca, "FontSize", 18, "XTick", 0:0.2:1, "YTick", 0:0.2:1)
exportgraphics(gca, fullfile(resfolder,"vie-09-scatter-x.png"), "Resolution", 110)
imwrite(X, fullfile(resfolder,"vie-09-cam.png"))
%%
%[text] ## 信号変換の効果
%[text] 教科書の例「分散共分散行列」と同じ変換行列（ $ \\mathbf{C}\_2=\\mathbf{H}\_2 $ ，2 点のユニタリ DFT 行列 $ \\mathbf{W}\_2/\\sqrt{2} $ と一致）
%[text]{"align":"center"} $ \\mathbf{A}\_\\mathrm{ex}=\\frac{1}{\\sqrt{2}}\\begin{pmatrix}1&1\\\\1&-1\\end{pmatrix} $
%[text] で $ \\mathbf{y}^{[i]}=\\mathbf{A}\_\\mathrm{ex}\\mathbf{x}^{[i]} $ と変換すると， $ y\_0 $ （和）の方向に大きく広がり， $ y\_1 $ （差）の方向の広がりは小さい。分散共分散行列は $ \\mathbf{A}\_\\mathrm{ex}\\hat{\\boldsymbol{\\Sigma}}\_\\mathcal{X}\\mathbf{A}\_\\mathrm{ex}^\\top $ となり，非対角成分（相関）がほぼ 0 になる。
Aex = [1 1; 1 -1]/sqrt(2);
Q = Aex*P;
Sy = cov(Q', 1)
Sy_check = Aex*Sx*Aex'                          % 同じ値になる
clf
scatter(Q(1,:), Q(2,:), 6, ccool, "filled", "MarkerFaceAlpha", 0.3, "MarkerEdgeColor", "none")
axis equal, axis([0 1.5 -0.75 0.75]), grid on, box on
xlabel("$y_0$", "Interpreter", "latex"), ylabel("$y_1$", "Interpreter", "latex")
set(gca, "FontSize", 18, "XTick", 0:0.5:1.5, "YTick", -0.5:0.5:0.5)
exportgraphics(gca, fullfile(resfolder,"vie-09-scatter-y.png"), "Resolution", 110)
vie.savetex("vie-09-Sx", arr2texz(Sx, "%.4f", "0.0000"));
vie.savetex("vie-09-Sy", arr2texz(Sy, "%.4f", "0.0000"));
%[text] $ y\_1 $ （差分）の多くは 0 付近に集まる：変換係数の絶対値が 0.02 未満の割合
ratio = mean(abs(Q(2,:)) < 0.02)
vie.savetex("vie-09-sparse-y", sprintf("%.0f", 100*ratio));
%%
%[text] ### 教科書の例「分散共分散行列」を再現する
%[text] 教科書の図 6.1 は，図 1.2 (a) の画像（MsipWorkM の msipimg01.tif を $ 96\\times96 $ 画素に縮小したもの）の水平隣接画素ペアから作られている。同じ手順で計算し，教科書の $ \\hat{\\boldsymbol{\\Sigma}}\_\\mathcal{X} $ ， $ \\hat{\\boldsymbol{\\Sigma}}\_\\mathcal{Y} $ と一致することを確かめる。画像は VieWork の data フォルダ，隣に置いた MsipWorkM の data フォルダ，GitHub の順に探す（末尾のローカル関数 `msipimgfile` ）。
I96 = imresize(im2double(rgb2gray(imread(msipimgfile("msipimg01.tif")))), [96 96], "bilinear");
Xp = reshape(I96.', 2, []).';                  % S×2：各行が水平隣接画素ペア (x_0, x_1)
exSx = cov(Xp, 1)
exSy = cov(Xp*Aex.', 1)
txtSx = [0.0320 0.0277; 0.0277 0.0322];        % 教科書の値（図 6.1 の説明）
txtSy = [0.0597 -0.0001; -0.0001 0.0044];
match_cov = isequal(round(exSx,4), txtSx) && isequal(round(exSy,4), txtSy)
if ~match_cov, warning("例「分散共分散行列」の値が教科書と一致しません"), end
vie.savetex("vie-09-ex-Sx", arr2texz(exSx, "%.4f", "0.0000"));
vie.savetex("vie-09-ex-Sy", arr2texz(exSy, "%.4f", "0.0000"));
%%
%[text] ## 基底ベクトルと座標
%[text] $ \\mathbf{B}=\\mathbf{A}^{-1} $ の列 $ \\mathbf{b}\_0,\\mathbf{b}\_1 $ が基底ベクトル。係数 $ \\mathbf{y} $ は新しい軸（基底ベクトルの方向）での座標。
xs = [sqrt(2) sqrt(2); sqrt(2) 2*sqrt(2); 2*sqrt(2) sqrt(2)]'   % 列が x
ys = A*xs                                       % 列が係数
recon = B*ys                                    % 元に戻る
vie.savetex("vie-09-coord-y", vie.arr2tex(round(ys),"%d"));
%[text] 基底ベクトルの調べ方：係数を一つだけ 1，残りを 0 として逆変換する。
b0 = B*[1;0], b1 = B*[0;1]
%%
%[text] ## 基底画像（2×2 のハール変換）
%[text] 分離処理では，順変換 $ \\mathbf{Y}=\\mathbf{A}\\mathbf{X}\\mathbf{A}^\\top $ ，逆変換 $ \\mathbf{X}=\\mathbf{B}\\mathbf{Y}\\mathbf{B}^\\top $ 。
X2 = [0 2; 4 6];
Y2 = A*X2*A'
X2r = B*Y2*B'
vie.savetex("vie-09-X2", vie.arr2tex(X2,"%d"));
vie.savetex("vie-09-Y2", vie.arr2tex(round(Y2),"%d"));
%[text] 基底画像 $ \\mathsf{b}\_{m\_\\mathrm{v},m\_\\mathrm{h}}=\\mathbf{b}\_{m\_\\mathrm{v}}\\mathbf{b}\_{m\_\\mathrm{h}}^\\top $ （係数を一つだけ 1 にして逆変換したもの）。画像は基底画像の重み付け和になる。
Bimg = cell(2);
for mv = 1:2, for mh = 1:2
    E = zeros(2); E(mv,mh) = 1;
    Bimg{mv,mh} = B*E*B';
    disp("b_{" + (mv-1) + "," + (mh-1) + "} ="), disp(Bimg{mv,mh})
end, end
sumcheck = Y2(1,1)*Bimg{1,1} + Y2(1,2)*Bimg{1,2} + Y2(2,1)*Bimg{2,1} + Y2(2,2)*Bimg{2,2}
%%
%[text] ## 例題「二次元DCT」
%[text] DCT 行列 $ \\mathbf{C}\_M $ を教科書の定義どおりに作る。
%[text]{"align":"center"} $ [\\mathbf{C}\_M]\_{m,n}=\\alpha\_m\\cos\\frac{m(2n+1)\\pi}{2M},\\quad \\alpha\_0=1/\\sqrt{M},\\ \\alpha\_m=\\sqrt{2/M}\\ (m\\neq0) $
%[text] MATLAB の `dctmtx` と一致する。
M = 4;
[mm, nn] = ndgrid(0:M-1);
am = [1/sqrt(M); sqrt(2/M)*ones(M-1,1)];        % α_m
C4 = am .* cos(mm.*(2*nn+1)*pi/(2*M))
err_dctmtx = norm(C4 - dctmtx(M))
%[text] 教科書の例題： $ 4\\times4 $ 配列の二次元 DCT（分離処理 $ \\mathbf{Y}=\\mathbf{C}\_4\\mathbf{X}\\mathbf{C}\_4^\\top $ ）。縦方向に $ \\mathbf{U}=\\mathbf{C}\_4\\mathbf{X} $ ，続いて横方向に $ \\mathbf{Y}=\\mathbf{U}\\mathbf{C}\_4^\\top $ と 2 段階で計算してもよい（前回の演習課題の解説と同じ手順）。
X4 = [4 4 6 4; 4 6 4 2; 6 4 2 4; 4 2 4 4];
U4 = C4*X4;                                     % 縦方向の変換
Y4 = U4*C4.'
txtY4 = [16.0000 1.3066 0 0.5412; 1.3066 0 -2.3890 0; 0 -2.3890 0 2.0719; 0.5412 0 2.0719 0];
match_dct = isequal(round(Y4,4), txtY4)          % 教科書の解答と一致するか
if ~match_dct, warning("例題「二次元DCT」の値が教科書と一致しません"), end
vie.savetex("vie-09-X4", vie.arr2tex(X4,"%d"));
vie.savetex("vie-09-Y4", arr2texz(Y4,"%.4f"));
%[text] エネルギー（二乗和）は保存され，直流成分 $ y[0,0] $ に集中する。
energy = [sum(X4(:).^2) sum(Y4(:).^2) Y4(1,1)^2/sum(Y4(:).^2)]
vie.savetex("vie-09-dc-ratio", sprintf("%.0f", 100*energy(3)));
%%
%[text] ## 基底画像による展開の図
%[text] 例題の配列 $ \\mathsf{x} $ を，DCT の基底画像 $ \\mathsf{b}\_{m\_\\mathrm{v},m\_\\mathrm{h}}=\\mathbf{b}\_{m\_\\mathrm{v}}\\mathbf{b}\_{m\_\\mathrm{h}}^\\top $ （ $ \\mathbf{b}\_m=[\\mathbf{C}\_4^\\top]\_{:,m} $ ）の線形結合
%[text]{"align":"center"} $ \\mathsf{x}=\\sum\_{m\_\\mathrm{v}=0}^{3}\\sum\_{m\_\\mathrm{h}=0}^{3}y[m\_\\mathrm{v},m\_\\mathrm{h}]\\,\\mathsf{b}\_{m\_\\mathrm{v},m\_\\mathrm{h}} $
%[text] で表す。スライドの「画像変換の基礎」で使う横一列の図を作る：左から $ \\mathsf{x} $ ， $ \\mathsf{b}\_{0,0} $ ， $ \\mathsf{b}\_{0,1} $ ， $ \\mathsf{b}\_{0,2} $ ， $ \\mathsf{b}\_{3,3} $ ，係数配列 $ \\mathsf{y} $ （絶対値を対数で強調）。基底画像は 0 を灰色，正を白，負を黒で表す。記号はスライド側（TikZ）で付けるので，各タイルの左端の位置 `left` はスライドと合わせてある。
Bc = C4.';                                          % 列が基底ベクトル b_m
bimg = @(mv,mh) Bc(:,mv+1)*Bc(:,mh+1).';            % 基底画像 b_{mv,mh}
togray = @(b) 0.5 + b/(2*max(abs(b(:))));           % 0 を灰色，正を白，負を黒に
recon4 = zeros(M);
for mv = 0:M-1, for mh = 0:M-1
    recon4 = recon4 + Y4(mv+1,mh+1)*bimg(mv,mh);    % 基底画像の重み付け和
end, end
err_expand = max(abs(recon4 - X4), [], "all")       % 元の配列に戻る
tiles = {X4/max(X4(:)), togray(bimg(0,0)), togray(bimg(0,1)), togray(bimg(0,2)), ...
    togray(bimg(3,3)), mat2gray(log(1 + abs(Y4)))};
left = [0 108 216 324 472 620];                     % 各タイルの左端（画素）
tw = 68;                                            % タイルの幅（64 画素＋枠 2 画素×2）
canvas = ones(tw, left(end) + tw);
for k = 1:numel(tiles)
    t = padarray(kron(tiles{k}, ones(16)), [2 2], 0.3);   % 4×4 → 64×64，濃い灰色の枠
    canvas(:, left(k) + (1:tw)) = t;
end
imwrite(canvas, fullfile(resfolder,"vie-09-expand.png"))
imshow(canvas)
%%
%[text] ## 8 点 DCT の基底ベクトルと基底画像
%[text] 基底ベクトル $ \\mathbf{b}\_m=[\\mathbf{C}\_8^\\top]\_{:,m} $ （ $ \\mathbf{C}\_8 $ の $ m $ 行目）を教科書の図 6.2 (a)（ $ M=4 $ ）と同じ体裁で描く。
C8 = dctmtx(8);
fig8 = figure("WindowStyle", "normal", "Position", [100 100 560 520]);   % 図の縦横比を固定する
tl = tiledlayout(fig8, 4, 2, "TileSpacing", "compact", "Padding", "compact");
for m = 0:7
    nexttile
    hs = stem(0:7, C8(m+1,:), "filled", "Color", cmain, "MarkerSize", 4);
    hs.BaseLine.Color = cgray;
    ylim([-0.6 0.6]), xlim([-0.5 7.5])
    title("$\mathbf{b}_{" + m + "}$", "Interpreter", "latex")
    set(gca, "XTick", 0:7, "YTick", [-0.5 0 0.5], "FontSize", 10)
end
xlabel(tl, "$n$", "Interpreter", "latex", "FontSize", 13)
exportgraphics(fig8, fullfile(resfolder,"vie-09-dct8-vec.png"), "Resolution", 150)
%[text] 基底画像（ $ 8\\times8 $ 通り）を並べる（灰色の枠で区切る）。
Mos = 0.5*ones(8*9+1);
for mv = 1:8, for mh = 1:8
    Bm = C8(mv,:)'*C8(mh,:);                    % 基底画像 = 基底ベクトルの外積
    r = (mv-1)*9 + 2; c = (mh-1)*9 + 2;
    Mos(r:r+7, c:c+7) = 0.5 + Bm/(2*max(abs(Bm(:))));
end, end
imwrite(imresize(Mos, 4, "nearest"), fullfile(resfolder,"vie-09-dct8-img.png"))
%%
%[text] ## 例題「二次元DHT」
%[text] DHT 行列を教科書の定義（クロネッカー積による再帰）どおりに作る（末尾のローカル関数 `dhtmtx` ）。
%[text]{"align":"center"} $ \\mathbf{H}\_{2^J}=\\frac{1}{\\sqrt{2}}\\begin{pmatrix}\\mathbf{H}\_{2^{J-1}}\\otimes(1\\ \\ 1)\\\\\\mathbf{I}\_{2^{J-1}}\\otimes(1\\ -1)\\end{pmatrix},\\quad \\mathbf{H}\_1=1 $
H4 = dhtmtx(2)
H4txt = [1 1 1 1; 1 1 -1 -1; sqrt(2) -sqrt(2) 0 0; 0 0 sqrt(2) -sqrt(2)]/2;   % 教科書の解答の H_4
err_H4 = norm(H4 - H4txt)
orth_H4 = norm(H4*H4.' - eye(4))                % 正規直交
%[text] 例題「二次元DCT」と同じ配列に，分離処理 $ \\mathbf{Y}=\\mathbf{H}\_4\\mathbf{X}\\mathbf{H}\_4^\\top $ を適用する。
Y4dht = H4*X4*H4.'
txtY4dht = [16.0000 1.0000 0.7071 0.7071; 1.0000 0 -2.1213 2.1213; 0.7071 -2.1213 1.0000 0; 0.7071 2.1213 0 -1.0000];
match_dht = isequal(round(Y4dht,4), txtY4dht)
if ~match_dht, warning("例題「二次元DHT」の値が教科書と一致しません"), end
vie.savetex("vie-09-dht-H4", sqrt2tex(2*H4));   % スライドでは 1/2 (…) の中身として使う
vie.savetex("vie-09-dht-Y4", arr2texz(Y4dht,"%.4f"));
%%
%[text] ## 例題「ブロック処理」
%[text] 教科書の例題「標準化と最小最大正規化」の $ 4\\times6 $ 配列 $ \\mathsf{x} $ を $ 2\\times2 $ のブロックに分け，各ブロック $ \\mathbf{X}\_b $ に二次元 DCT $ \\mathbf{C}\_2\\mathbf{X}\_b\\mathbf{C}\_2^\\top $ を施す。逆変換 $ \\mathbf{C}\_2^\\top\\mathbf{Y}\_b\\mathbf{C}\_2 $ で元に戻る。
xblk = [5 5 7 6 7 2; 6 2 3 2 7 2; 2 2 4 4 4 6; 4 4 4 4 1 2];
C2 = dctmtx(2)                                  % = [1 1; 1 -1]/sqrt(2) = H_2
yblk = blockproc(xblk, [2 2], @(b) C2*b.data*C2.')
txtyblk = [9 2 9 1 9 5; 1 -2 4 0 0 0; 6 0 8 0 6.5 -1.5; -2 0 0 0 3.5 -0.5];
match_blk = isequal(round(yblk,4), txtyblk)
if ~match_blk, warning("例題「ブロック処理」の値が教科書と一致しません"), end
xblk_r = blockproc(yblk, [2 2], @(b) C2.'*b.data*C2);
err_blk = max(abs(xblk_r - xblk), [], "all")    % 元に戻る
vie.savetex("vie-09-blk-x", vie.arr2tex(xblk,"%d"));
vie.savetex("vie-09-blk-y", arr2texz(yblk,"%.1f"));
%%
%[text] ## 画像の 8×8 ブロック DCT
%[text] 各ブロックの係数（絶対値の対数）を表示すると，各ブロックの左上（低周波）に大きな値が集まる。
Yb = blockproc(X, [8 8], @(b) dct2(b.data));
imwrite(mat2gray(log(1 + 50*abs(Yb))), fullfile(resfolder,"vie-09-bdct.png"))   % 小さな係数も見えるよう強調
%[text] 係数を大きい順に並べると，エネルギーの 99% は何 % の係数で表せるか。
e = sort(Yb(:).^2, "descend");
k99 = find(cumsum(e) >= 0.99*sum(e), 1) / numel(e)
vie.savetex("vie-09-k99", sprintf("%.1f", 100*k99));
%[text] 各ブロックで大きい係数だけ（全体の 10%）残して逆変換してみる。
thr = prctile(abs(Yb(:)), 90);
Yk = Yb .* (abs(Yb) >= thr);
Xk = blockproc(Yk, [8 8], @(b) idct2(b.data));
psnr10 = psnr(min(max(Xk,0),1), X)
imwrite(min(max(Xk,0),1), fullfile(resfolder,"vie-09-bdct-rec.png"))
vie.savetex("vie-09-psnr10", sprintf("%.1f", psnr10));
%%
%[text] ## ハール変換による信号の解析と合成
%[text] 前回スライドの例。 $ x[n]=(3,1,3,1,5,3) $ に対し，隣同士を足して 1/2 倍（縮小近似成分），左隣を引いて 1/2 倍（縮小詳細成分），2 点に 1 点を残す。
x = [3 1 3 1 5 3];
s = x(2:end) + x(1:end-1)                       % 隣同士を足す
d = x(2:end) - x(1:end-1)                       % 左隣を引く
a  = s(1:2:end)/2                               % 縮小近似成分
dd = d(1:2:end)/2                               % 縮小詳細成分
vie.savetex("vie-09-haar-x", strjoin(string(x),",\ "));
vie.savetex("vie-09-haar-s", strjoin(string(s),",\ "));
vie.savetex("vie-09-haar-d", strjoin(string(d),",\ "));
vie.savetex("vie-09-haar-a", strjoin(string(a),",\ "));
vie.savetex("vie-09-haar-dd", strjoin(string(dd),",\ "));
%[text] 合成：近似成分は右隣にコピー（最近傍補間），詳細成分は符号反転して左隣にコピーして足す。
up_a = kron(a, [1 1])
up_d = kron(dd, [-1 1])
xr = up_a + up_d
isequal(xr, x)
vie.savetex("vie-09-haar-upa", strjoin(string(up_a),",\ "));
vie.savetex("vie-09-haar-upd", strjoin(string(up_d),",\ "));
%%
%[text] ## フィルタバンク表現
%[text] 分析器 $ H\_0(z)=\\frac12(1+z^{-1}) $ ， $ H\_1(z)=\\frac12(1-z^{-1}) $ とダウンサンプラ，アップサンプラと合成器 $ F\_0(z)=1+z^{-1} $ ， $ F\_1(z)=-1+z^{-1} $ で構成する。出力は入力を 1 サンプル遅らせたものに一致する（完全再構成）。
xf = [x 0 0];                                   % 最後の出力を見るため零を足す
v0 = filter([1 1]/2, 1, xf); v1 = filter([1 -1]/2, 1, xf);
y0 = v0(2:2:end)                                % ↓2（奇数番目を残す）：縮小近似成分
y1 = v1(2:2:end)                                % 縮小詳細成分
u0 = zeros(size(xf)); u0(2:2:end) = y0;         % ↑2
u1 = zeros(size(xf)); u1(2:2:end) = y1;
w = filter([1 1], 1, u0) + filter([-1 1], 1, u1)   % = [0 x]（1 サンプル遅延）
vie.savetex("vie-09-fb-w", strjoin(string(w(1:7)),",\ "));
%%
%[text] ## 多相行列表現（等価変換）
%[text] 偶数番目 $ x\_0=x[2m] $ と奇数番目 $ x\_1=x[2m+1] $ の組に対する分析器 $ \\mathbf{E} $ と合成器 $ \\mathbf{R} $ 。 $ \\mathbf{R}\\mathbf{E}=\\mathbf{I} $ で完全に元に戻る。
E = [1 1; -1 1]/2
R = [1 -1; 1 1]
RE = R*E
coef = E*reshape(x, 2, [])                      % 列が (y0, y1)
%%
%[text] ## まとめ
%[text] - 自然画像は隣接画素の相関が強い。信号変換で相関を減らし，係数を疎（スパース）にできる
%[text] - 信号は基底ベクトル（ $ \\mathbf{A}^{-1} $ の列）の線形結合，画像は基底画像の線形結合で表せる
%[text] - DCT は低周波にエネルギーを集中させる。DHT は加減算で計算でき，ブロック処理で大きな画像にも適用できる
%[text] - ハール変換はフィルタバンク（分析器と合成器）で実現でき，ブロック変換と等価 \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
function y = arr2texz(x, format, zerostr)
% 行列を LaTeX の行列本体に変換する（vie.arr2tex と同じ形式）。
% 書式 format で 0 になる要素（-0.0000 など）は zerostr（既定 "0"）で書く。
arguments
    x (:,:) {mustBeNumeric}
    format (1,1) string = "%g"
    zerostr (1,1) string = "0"
end
lines = strings(size(x,1), 1);
for i = 1:size(x,1)
    c = strings(1, size(x,2));
    for j = 1:size(x,2)
        c(j) = sprintf(format, x(i,j));
        if str2double(c(j)) == 0
            c(j) = zerostr;
        end
    end
    lines(i) = strjoin(c, " & ");
end
y = strjoin(lines, "\\" + newline);
end

function y = sqrt2tex(x)
% 要素が整数か整数×√2 の行列を LaTeX の行列本体に変換する（√2 は \sqrt{2} と書く）。
lines = strings(size(x,1), 1);
for i = 1:size(x,1)
    c = strings(1, size(x,2));
    for j = 1:size(x,2)
        v = x(i,j);
        k = round(v/sqrt(2));
        if abs(v - round(v)) < 1e-12
            c(j) = sprintf("%d", round(v));
        elseif abs(v - k*sqrt(2)) < 1e-12
            if k == 1
                c(j) = "\sqrt{2}";
            elseif k == -1
                c(j) = "-\sqrt{2}";
            else
                c(j) = sprintf("%d", k) + "\sqrt{2}";
            end
        else
            error("整数でも整数×√2 でもない要素があります")
        end
    end
    lines(i) = strjoin(c, " & ");
end
y = strjoin(lines, "\\" + newline);
end

function H = dhtmtx(J)
% 教科書の定義「離散ハール変換（DHT）」の行列 H_{2^J} を再帰で作る。
if J == 0
    H = 1;                                      % H_1 = 1
else
    Hp = dhtmtx(J-1);
    H = [kron(Hp, [1 1]); kron(eye(2^(J-1)), [1 -1])]/sqrt(2);
end
end

function imgfile = msipimgfile(fname)
% 教科書のサンプル画像（MsipWorkM の data フォルダ）の場所を返す。
% VieWork の data フォルダ → 隣に置いた MsipWorkM の data フォルダ → GitHub から取得，の順に探す。
[datfolder,~,prjroot] = vie.prjfolders();
imgfile = fullfile(datfolder, fname);
if isfile(imgfile), return, end
sibling = fullfile(fileparts(prjroot), "MsipWorkM", "data", fname);
if isfile(sibling), imgfile = sibling; return, end
websave(imgfile, "https://raw.githubusercontent.com/msiplab/MsipWorkM/master/data/" + fname);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
