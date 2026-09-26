%[text] # 第9回 線形変換処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第9回のスライド（vie2026-09）で使う図と数値を作る。自然画像の隣接画素の相関，信号変換 $ \\mathbf{y}=\\mathbf{A}\\mathbf{x} $ と基底ベクトル $ \\mathbf{b}\_m $ （ $ \\mathbf{B}=\\mathbf{A}^{-1} $ の列），基底画像，離散コサイン変換（DCT），ハール変換のフィルタバンク表現を扱う。
%[text] 前回スライドと同じく，ハール変換（ $ \\pi/4 $ 回転）行列
%[text]{"align":"center"} $ \\mathbf{A}=\\frac{1}{\\sqrt{2}}\\begin{pmatrix}1&1\\\\-1&1\\end{pmatrix} $
%[text] を用いる（教科書の $ \\mathbf{H}\_2 $ とは第 2 行の符号だけが異なる）。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[~,resfolder] = vie.prjfolders();
A = [1 1; -1 1]/sqrt(2)
B = inv(A)                                     % = A'（直交行列）
%%
%[text] ## 自然画像の隣接画素の散布図
%[text] cameraman.tif の水平方向の隣接画素ペア $ \\mathbf{x}=(x\_0,x\_1)^\\top $ （重ならないように 2 画素ずつ）を散布図にする。ほぼ対角線上に並ぶ：隣どうしは似た値をとる（相関が強い）。
X = im2double(imread("cameraman.tif"));
x0 = X(:,1:2:end); x1 = X(:,2:2:end);
P = [x0(:) x1(:)]';                            % 2×S の画素ペア
Sx = cov(P')                                    % 標本分散共分散行列
clf
scatter(P(1,:), P(2,:), 2, "b", "filled"), axis equal, axis([0 1 0 1]), grid on
xlabel("x_0"), ylabel("x_1"), title("隣接画素ペアの散布図"), set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-09-scatter-x.png"), "Resolution", 110)
imwrite(X, fullfile(resfolder,"vie-09-cam.png"))
%%
%[text] ## 信号変換の効果
%[text] $ \\mathbf{y}=\\mathbf{A}\\mathbf{x} $ で変換すると， $ y\_0 $ 方向に大きく広がり， $ y\_1 $ 方向の広がりは小さい。分散共分散行列は $ \\mathbf{A}\\hat{\\boldsymbol{\\Sigma}}\_\\mathcal{X}\\mathbf{A}^\\top $ となり，非対角成分（相関）がほぼ 0 になる。
Q = A*P;
Sy = cov(Q')
clf
scatter(Q(1,:), Q(2,:), 2, "b", "filled"), axis equal, axis([0 1.5 -0.75 0.75]), grid on
xlabel("y_0"), ylabel("y_1"), title("変換後の散布図"), set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-09-scatter-y.png"), "Resolution", 110)
vie.savetex("vie-09-Sx", vie.arr2tex(Sx,"%.4f"));
vie.savetex("vie-09-Sy", vie.arr2tex(Sy,"%.4f"));
%[text] $ y\_1 $ （差分）の多くは 0 付近に集まる：変換係数の絶対値が 0.02 未満の割合
ratio = mean(abs(Q(2,:)) < 0.02)
vie.savetex("vie-09-sparse-y", sprintf("%.0f", 100*ratio));
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
%[text] 基底画像 $ \\mathbf{B}\_{m\_\\mathrm{v},m\_\\mathrm{h}}=\\mathbf{b}\_{m\_\\mathrm{v}}\\mathbf{b}\_{m\_\\mathrm{h}}^\\top $ （係数を一つだけ 1 にして逆変換したもの）。画像は基底画像の重み付け和になる。
Bimg = cell(2);
for mv = 1:2, for mh = 1:2
    E = zeros(2); E(mv,mh) = 1;
    Bimg{mv,mh} = B*E*B';
    disp("B_{" + (mv-1) + "," + (mh-1) + "} ="), disp(Bimg{mv,mh})
end, end
sumcheck = Y2(1,1)*Bimg{1,1} + Y2(1,2)*Bimg{1,2} + Y2(2,1)*Bimg{2,1} + Y2(2,2)*Bimg{2,2}
%%
%[text] ## 離散コサイン変換（DCT）の数値例
%[text] 教科書の例題：4×4 配列の二次元 DCT（ $ \\mathbf{Y}=\\mathbf{C}\_4\\mathbf{X}\\mathbf{C}\_4^\\top $ ）。
C4 = dctmtx(4);
X4 = [4 4 6 4; 4 6 4 2; 6 4 2 4; 4 2 4 4];
Y4 = C4*X4*C4';
Y4(abs(Y4) < 1e-10) = 0                        % 丸め誤差の -0 を 0 に
vie.savetex("vie-09-X4", vie.arr2tex(X4,"%d"));
vie.savetex("vie-09-Y4", vie.arr2tex(round(Y4,2),"%.2f"));
%[text] エネルギー（二乗和）は保存され，直流成分 $ y[0,0] $ に集中する。
energy = [sum(X4(:).^2) sum(Y4(:).^2) Y4(1,1)^2/sum(Y4(:).^2)]
vie.savetex("vie-09-dc-ratio", sprintf("%.0f", 100*energy(3)));
%%
%[text] ## 8 点 DCT の基底ベクトルと基底画像
C8 = dctmtx(8);
tiledlayout(4,2,"TileSpacing","compact","Padding","compact")
for m = 1:8
    nexttile, stem(0:7, C8(m,:), "filled"), ylim([-0.6 0.6]), xlim([-0.5 7.5])
    title(sprintf("m=%d", m-1)), set(gca, "XTick", [], "FontSize", 9)
end
exportgraphics(gcf, fullfile(resfolder,"vie-09-dct8-vec.png"), "Resolution", 120)
%[text] 基底画像（ $ 8\\times8 $ 通り）を並べる（灰色の枠で区切る）。
Mos = 0.5*ones(8*9+1);
for mv = 1:8, for mh = 1:8
    Bm = C8(mv,:)'*C8(mh,:);                    % 基底画像 = 基底ベクトルの外積
    r = (mv-1)*9 + 2; c = (mh-1)*9 + 2;
    Mos(r:r+7, c:c+7) = 0.5 + Bm/(2*max(abs(Bm(:))));
end, end
imwrite(imresize(Mos, 4, "nearest"), fullfile(resfolder,"vie-09-dct8-img.png"))
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
%[text] - DCT は低周波にエネルギーを集中させる
%[text] - ハール変換はフィルタバンク（分析器と合成器）で実現でき，ブロック変換と等価 \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
