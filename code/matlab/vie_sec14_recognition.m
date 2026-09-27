%[text] # 第14回 パターン認識と特徴抽出
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第14回のスライド（vie2026-14）で使う図と数値を作る。特徴空間と最近傍決定則，色の特徴空間，ハリスのコーナー検出，キャニーの輪郭線検出（教科書の例題「プレウィットフィルタ」「勾配の大きさ」），ハフ変換による直線検出，ニューラルネットワーク（活性化関数，教科書 10.1.1 項の損失関数による誤差逆伝播法の学習），畳み込み層とプーリング層を扱う。記号は教科書に合わせる。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[~,resfolder] = vie.prjfolders();
%[text] 写真は教科書のサンプル画像 msipimg##.tif（512×512 のカラー）を `vie.msipimg` で読み込む。色の特徴空間には色とりどりの花束（msipimg02），コーナー・輪郭線の検出と特徴マップには縦横の縁がはっきりした石造りの建物（msipimg04），ハフ変換には斜めの直線（縞）が並ぶ路面（msipimg06），輪郭線の小さな例には丸い輪郭が並ぶマカロン（msipimg03）を使う。
%[text] 図の配色はロゴの 3 色（メインの緑 #008855，青 #2E75B6，橙 #C55A11）と灰色を基本にする。薄い色は白と混ぜて作る。
cMain = [0 136 85]/255;                          % 緑（メイン）
cCool = [46 117 182]/255;                        % 青（寒色系）
cWarm = [197 90 17]/255;                         % 橙（暖色系）
cLogo = [cMain; cCool; cWarm];
cLight = 1 - 0.18*(1 - cLogo);                   % 塗り用の薄い色
%%
%[text] ## 特徴空間とパターン学習
%[text] 2 次元の特徴ベクトル $ \\mathbf{x}=(x\_0\\ \\ x\_1)^\\top $ をもつ 3 クラス $ \\omega\_1,\\omega\_2,\\omega\_3 $ の学習データ（各 30 個）を作る。同じクラスのパターンは特徴空間上で塊（クラスタ）をなす。クラスごとの平均を代表ベクトル $ \\boldsymbol{\\mu}\_i $ とする（パターン学習）。
rng(0)
mu0 = [1 1; 4 1.5; 2.5 4];                        % 真の中心
nTrain = 30;                                     % クラスあたりの学習データ数
Xtr = []; ytr = [];
for i = 1:3
    Xtr = [Xtr; mu0(i,:) + 0.6*randn(nTrain,2)]; %#ok<AGROW>
    ytr = [ytr; i*ones(nTrain,1)]; %#ok<AGROW>
end
mu = zeros(3,2);
for i = 1:3, mu(i,:) = mean(Xtr(ytr==i,:), 1); end
mu                                              % 代表ベクトル（行が μ_i^T）
vie.savetex("vie-14-mu", vie.arr2tex(round(mu,2), "%.2f"));
%[text] 特徴空間上の学習データ（クラスごとに色分け）と代表ベクトル（＋印）。
clf
hold on
for i = 1:3
    scatter(Xtr(ytr==i,1), Xtr(ytr==i,2), 20, cLogo(i,:), "filled")
end
for i = 1:3
    plot(mu(i,1), mu(i,2), "k+", "MarkerSize", 14, "LineWidth", 2.5)
    text(mu(i,1)+0.2, mu(i,2)+0.35, sprintf("{\\bf\\mu}_%d", i), "FontSize", 14, "BackgroundColor", "w", "Margin", 0.5)
end
hold off, box on, grid on, axis equal, axis([-1 6 -1 6])
xlabel("$x_0$", "Interpreter", "latex"), ylabel("$x_1$", "Interpreter", "latex")
legend(["\omega_1","\omega_2","\omega_3"], "Location", "northeast")
set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-14-feature-space.png"), "Resolution", 150, "Width", 8, "Height", 8, "Units", "centimeters")
%%
%[text] ## パターン識別：最近傍決定則
%[text] 未知の入力 $ \\mathbf{x} $ は，最も近い代表ベクトルのクラスに識別する（最近傍決定則）。距離はユークリッド距離 $ \\|\\mathbf{x}-\\boldsymbol{\\mu}\_i\\|\_2 $ で測る。
xq = [3 2.5];                                    % 未知入力
d = vecnorm(mu - xq, 2, 2)'                      % 各代表ベクトルまでの距離
[~, cls] = min(d)
vie.savetex("vie-14-d", strjoin(compose("%.2f", d), ",\ "));
vie.savetex("vie-14-cls", sprintf("%d", cls));
%[text] 前回の演習課題（14）の図にならい，未知入力 $ \\mathbf{x} $ （☆印）から各代表ベクトルへ線分を引き，距離を添える。背景は各点を最も近い代表ベクトルのクラスで塗り分けたもの（識別境界は代表ベクトルどうしの垂直二等分線になる）。
[g1, g2] = meshgrid(linspace(0, 5, 301));
[~, lab] = min(pdist2([g1(:) g2(:)], mu), [], 2);
lab = reshape(lab, size(g1));
clf
imagesc(g1(1,:), g2(:,1), lab), set(gca, "YDir", "normal"), colormap(gca, cLight), clim([0.5 3.5])
hold on
for i = 1:3
    scatter(Xtr(ytr==i,1), Xtr(ytr==i,2), 12, cLogo(i,:), "filled", "MarkerFaceAlpha", 0.35)
end
for i = 1:3
    if i == cls, ls = "-"; lw = 3; else, ls = "--"; lw = 1.5; end
    plot([xq(1) mu(i,1)], [xq(2) mu(i,2)], ls, "Color", cLogo(i,:), "LineWidth", lw)
    text((xq(1)+mu(i,1))/2, (xq(2)+mu(i,2))/2, sprintf("%.2f", d(i)), "FontSize", 12, ...
        "BackgroundColor", "w", "Margin", 1, "HorizontalAlignment", "center", "Color", cLogo(i,:))
    plot(mu(i,1), mu(i,2), "k+", "MarkerSize", 14, "LineWidth", 2.5)
    text(mu(i,1)+0.15, mu(i,2)-0.3, sprintf("{\\bf\\mu}_%d", i), "FontSize", 14, "BackgroundColor", "w", "Margin", 0.5)
end
plot(xq(1), xq(2), "kp", "MarkerSize", 18, "MarkerFaceColor", "w", "LineWidth", 1.5)
text(xq(1)+0.2, xq(2)+0.2, "{\bfx}", "FontSize", 14)
hold off, axis equal, axis([0 5 0 5]), box on
xlabel("$x_0$", "Interpreter", "latex"), ylabel("$x_1$", "Interpreter", "latex"), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-14-nn-rule.png"), "Resolution", 150, "Width", 8, "Height", 8, "Units", "centimeters")
%[text] 新しいテストデータ（各クラス 30 個）での識別率。
Xte = []; yte = [];
for i = 1:3
    Xte = [Xte; mu0(i,:) + 0.6*randn(nTrain,2)]; %#ok<AGROW>
    yte = [yte; i*ones(nTrain,1)]; %#ok<AGROW>
end
[~, yhat] = min(pdist2(Xte, mu), [], 2);
acc = mean(yhat == yte)
vie.savetex("vie-14-acc", sprintf("%.0f", 100*acc));
vie.savetex("vie-14-nte", sprintf("%d", numel(yte)));
%%
%[text] ## 色の特徴空間
%[text] 画像の各画素の (R, G, B) を特徴ベクトルとみなすと，RGB 空間が特徴空間になる（色そのものが内容なので，点は画素の色で塗る）。色の分布が広がって見えるよう，橙・黄・赤・白・緑の花が並ぶ花束（msipimg02）を使う。
Xc = im2double(vie.msipimg(2));
Xs = imresize(Xc, 1/8);
v = reshape(Xs, [], 3);
clf
scatter3(v(:,1), v(:,2), v(:,3), 8, v, "filled"), axis([0 1 0 1 0 1]), grid on
xlabel("R"), ylabel("G"), zlabel("B"), view(-40, 25), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-14-rgbspace.png"), "Resolution", 150, "Width", 9, "Height", 6, "Units", "centimeters")
imwrite(imresize(Xc, 0.25), fullfile(resfolder,"vie-14-parrot.png"))
%%
%[text] ## ハリスのコーナー検出：局所構造行列の数値例
%[text] 構造テンソル $ \\hat{\\mathbf{M}}=\\begin{pmatrix}\\hat{A}&\\hat{C}\\\\\\hat{C}&\\hat{B}\\end{pmatrix} $ ， $ A=x\_\\mathrm{v}^2,\\ B=x\_\\mathrm{h}^2,\\ C=x\_\\mathrm{v}x\_\\mathrm{h} $ （近傍で平均）と，コーナー応答値 $ r=\\det(\\hat{\\mathbf{M}})-k(\\mathrm{trace}(\\hat{\\mathbf{M}}))^2 $ （ $ k=0.04 $ ）を，平坦・エッジ・コーナーの $ 5\\times5 $ パッチで比べる。
k = 0.04;
P = {zeros(5), [zeros(5,2) ones(5,3)], [zeros(2,5); zeros(3,2) ones(3,3)]};
names = ["平坦","エッジ","コーナー"];
fv = [-1 0 1]'; fh = [-1 0 1];                  % 中心差分
R = zeros(3,3);                                  % 列：det, trace, r
for i = 1:3
    xv = imfilter(P{i}, fv, "replicate"); xh = imfilter(P{i}, fh, "replicate");
    Ah = mean(xv(:).^2); Bh = mean(xh(:).^2); Ch = mean(xv(:).*xh(:));
    M = [Ah Ch; Ch Bh];
    R(i,:) = [det(M) trace(M) det(M) - k*trace(M)^2];
end
array2table(R, "VariableNames", ["det","trace","r"], "RowNames", names)
vie.savetex("vie-14-harris-r", strjoin(compose("%.3f", R(:,3)'), " & "));
vie.savetex("vie-14-harris-det", strjoin(compose("%.3f", R(:,1)'), " & "));
vie.savetex("vie-14-harris-tr", strjoin(compose("%.2f", R(:,2)'), " & "));
%%
%[text] ## ハリスのコーナー検出：処理結果
%[text] 市松模様と石造りの建物の画像（msipimg04 をグレースケールにして 256×256 に縮小）でコーナーを検出する。建物はアーチの頂や柱の角など，縦横の縁が交わる点がはっきりしている。コーナー点は橙の＋印で示す。
C = checkerboard(24, 3, 3) > 0.5;
C = double(C);
cc = corner(C, "Harris", 40);
Gr = im2double(vie.msipimg(4, 256, "gray"));
cg = corner(Gr, "Harris", 150, "SensitivityFactor", 0.04);
clf, imshow(C), hold on, plot(cc(:,1), cc(:,2), "+", "Color", cWarm, "MarkerSize", 10, "LineWidth", 2.5), hold off
exportgraphics(gca, fullfile(resfolder,"vie-14-harris-checker.png"), "Resolution", 150, "Width", 6, "Height", 6, "Units", "centimeters")
clf, imshow(Gr), hold on, plot(cg(:,1), cg(:,2), "+", "Color", cWarm, "MarkerSize", 7, "LineWidth", 2), hold off
exportgraphics(gca, fullfile(resfolder,"vie-14-harris-crane.png"), "Resolution", 150, "Width", 12, "Height", 12*size(Gr,1)/size(Gr,2), "Units", "centimeters")
imwrite(C, fullfile(resfolder,"vie-14-checker.png"))
imwrite(Gr, fullfile(resfolder,"vie-14-crane.png"))
ncorner = [size(cc,1) size(cg,1)]
vie.savetex("vie-14-nc-checker", sprintf("%d", ncorner(1)));
vie.savetex("vie-14-nc-crane", sprintf("%d", ncorner(2)));
%%
%[text] ## キャニーの輪郭線検出
%[text] ガウス平滑化 → 勾配 → 非極大抑制 → ヒステリシス閾値処理。比較としてソーベル勾配の単純な閾値処理も示す。
Ec = edge(Gr, "canny");
Es = edge(Gr, "sobel");
imwrite(~Ec, fullfile(resfolder,"vie-14-canny.png"))
imwrite(~Es, fullfile(resfolder,"vie-14-sobel.png"))
Xk = im2double(vie.msipimg(3, 256, "gray"));     % マカロン（丸い輪郭が並ぶ）
imwrite(Xk, fullfile(resfolder,"vie-14-parrot-gray.png"))
imwrite(~edge(Xk, "canny"), fullfile(resfolder,"vie-14-parrot-canny.png"))
%%
%[text] ## 教科書の例題「プレウィットフィルタ」「勾配の大きさ」（3.2 節）
%[text] キャニーの輪郭線検出の勾配計算の例。教科書の例題「矩形フィルタ」の配列 $ \\mathsf{x} $ にプレウィットフィルタ（垂直方向 $ f\_\\mathrm{v} $ ，水平方向 $ f\_\\mathrm{h} $ ）を施し，勾配ベクトル $ \\vec{y}\[\\boldsymbol{n}\]=(x\_\\mathrm{v}\[\\boldsymbol{n}\]\\ \\ x\_\\mathrm{h}\[\\boldsymbol{n}\])^\\top $ の大きさ $ y\_\\mathrm{mag}\[\\boldsymbol{n}\]=\\sqrt{x\_\\mathrm{v}^2\[\\boldsymbol{n}\]+x\_\\mathrm{h}^2\[\\boldsymbol{n}\]} $ を求める。周囲の値はすべて零値とする。
%[text] 教科書の線形フィルタ（式 (3.1)）は局所的な積和（相関）の形なので， `imfilter` の既定（相関，零値拡張）がそのまま使える。
xp = [18 9 9 9; 27 9 9 9; 36 9 9 9];              % 教科書の例題「矩形フィルタ」の配列
fvP = [-1 -1 -1; 0 0 0; 1 1 1];                  % プレウィットフィルタ（垂直方向）
fhP = fvP.';                                     % プレウィットフィルタ（水平方向）
Xv = imfilter(xp, fvP)                           % 垂直方向の差分 x_v
Xh = imfilter(xp, fhP)                           % 水平方向の差分 x_h
Ymag = sqrt(Xv.^2 + Xh.^2)                       % 勾配の大きさ y_mag
%[text] 教科書の解答と一致することを確かめる。
XvBook = [36 45 27 18; 18 18 0 0; -36 -45 -27 -18];
XhBook = [18 -27 0 -18; 27 -54 0 -27; 18 -45 0 -18];
YmagBook = [40.25 52.48 27.00 25.46; 32.45 56.92 0.00 27.00; 40.25 63.64 27.00 25.46];
assert(isequal(Xv, XvBook) && isequal(Xh, XhBook) && isequal(round(Ymag, 2), YmagBook), ...
    "教科書の例題の解答と一致しない")
vie.savetex("vie-14-pv", vie.arr2tex(Xv, "%d"));
vie.savetex("vie-14-ph", vie.arr2tex(Xh, "%d"));
vie.savetex("vie-14-mag", vie.arr2tex(Ymag, "%.2f"));
%%
%[text] ## ハフ変換：数値例
%[text] エッジ画素の位置 $ \\boldsymbol{q}=(q\_1\\ \\ q\_2)^\\top $ を $ \\rho=q\_1\\cos\\theta+q\_2\\sin\\theta $ で $ (\\theta,\\rho) $ 空間の曲線に写す。一直線上の 3 点 $ \\boldsymbol{q}\_\\mathrm{A}=(0\\ \\ 2)^\\top $ ， $ \\boldsymbol{q}\_\\mathrm{B}=(1\\ \\ 1)^\\top $ ， $ \\boldsymbol{q}\_\\mathrm{C}=(2\\ \\ 0)^\\top $ は， $ \\theta=45^\\circ $ でいずれも $ \\rho=\\sqrt{2} $ となる（3 本の曲線が 1 点で交わる）。
pts = [0 2; 1 1; 2 0];
th = deg2rad(45);
rho = pts(:,1)*cos(th) + pts(:,2)*sin(th)
tt = linspace(0, pi, 361);
tp = char(0x22A4);                               % 転置の記号 ⊤
clf
hold on
for i = 1:3
    plot(rad2deg(tt), pts(i,1)*cos(tt) + pts(i,2)*sin(tt), "Color", cLogo(i,:), "LineWidth", 2)
end
plot(45, sqrt(2), "ko", "MarkerSize", 10, "LineWidth", 2), hold off
box on, grid on, xlabel("\theta [度]"), ylabel("\rho")
legend("{\bf\itq}_{\rm" + ["A","B","C"] + "}=(" + string(pts(:,1)') + " " + string(pts(:,2)') + ")^{" + tp + "}", ...
    "Location", "southwest", "Interpreter", "tex")
xlim([0 180]), xticks(0:45:180), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-14-hough-curves.png"), "Resolution", 150, "Width", 10, "Height", 6.5, "Units", "centimeters")
vie.savetex("vie-14-hough-rho", sprintf("%.3f", rho(1)));
%%
%[text] ## ハフ変換：処理例
%[text] 斜めの直線（縞の縁）がはっきりした路面の画像（msipimg06 をグレースケールにして 256×256 に縮小）を使う。路面の細かな模様の輪郭を拾わないよう，キャニーのガウス平滑化の標準偏差を 3 と大きめにとる。
%[text] キャニーの輪郭画像を投票し，投票度数の大きなセル（ピーク）を探索して直線を描く（逆ハフ変換）。投票度数は見やすいよう平方根をとって白→緑→濃緑の色で表示する。選ばれたセルは橙の□印。
Gh = im2double(vie.msipimg(6, 256, "gray"));
Eh = edge(Gh, "canny", [], 3);
imwrite(Gh, fullfile(resfolder,"vie-14-hough-in.png"))
imwrite(~Eh, fullfile(resfolder,"vie-14-hough-canny.png"))
[Hh, T, Rr] = hough(Eh);
pk = houghpeaks(Hh, 12, "Threshold", 0.3*max(Hh(:)));
hl = houghlines(Eh, T, Rr, pk, "FillGap", 20, "MinLength", 60);
cmapV = interp1([0 0.5 1], [1 1 1; cMain; 0 0.2 0.12], linspace(0, 1, 256));   % 白→緑→濃緑
%[text] MATLAB の `hough` は $ \\theta\\in[-90^\\circ,90^\\circ) $ を使う。スライドの $ \\theta\\in[0,\\pi) $ ， $ \\rho\\in\\mathbb{R} $ に合わせ， $ \\theta<0 $ の列を $ (\\theta+180^\\circ,-\\rho) $ に移して表示する（同じ直線の表現）。
assert(isequal(Rr, -fliplr(Rr)))                % rho の刻みは原点に対称
neg = T < 0;
H180 = [Hh(:,~neg) flipud(Hh(:,neg))];          % theta in [0,90) と，[-90,0) を反転した [90,180)
T180 = [T(~neg) T(neg)+180];
pkT = T(pk(:,2)); pkR = Rr(pk(:,1));
pkR(pkT < 0) = -pkR(pkT < 0); pkT(pkT < 0) = pkT(pkT < 0) + 180;
clf
imshow(sqrt(rescale(H180)), "XData", T180, "YData", Rr, "InitialMagnification", "fit"), axis on, axis normal   % 投票度数（平方根）
colormap(gca, cmapV), xlabel("\theta [度]"), ylabel("\rho"), hold on
plot(pkT, pkR, "s", "Color", cWarm, "MarkerSize", 7, "LineWidth", 2), hold off
xticks(0:45:180), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-14-hough-acc.png"), "Resolution", 150, "Width", 10, "Height", 7, "Units", "centimeters")
clf, imshow(Gh), hold on
for kk = 1:numel(hl)
    xy = [hl(kk).point1; hl(kk).point2];
    plot(xy(:,1), xy(:,2), "LineWidth", 3, "Color", cMain)
end
hold off
exportgraphics(gca, fullfile(resfolder,"vie-14-hough-lines.png"), "Resolution", 150, "Width", 12, "Height", 12, "Units", "centimeters")
nlines = numel(hl)
colormap(gca, gray)
%%
%[text] ## 活性化関数
%[text] 活性化関数 $ \\phi(\\cdot) $ の例（参考資料 2 章）：シグモイド関数 $ 1/(1+\\mathrm{e}^{-au}) $ （ $ a=1 $ ，章末問題），ReLU（整流線形関数） $ \\max(0,u) $ （2.1.5 項，ヒンジ関数で $ \\lambda=0 $ としたランプ関数）。
u = linspace(-4, 4, 401);
clf
plot(u, 1./(1+exp(-u)), "Color", cMain, "LineWidth", 2), hold on
plot(u, max(u,0), "Color", cWarm, "LineWidth", 2), hold off
grid on, ylim([-0.5 2])
legend(["シグモイド 1/(1+e^{-{\itu}})", "ReLU max(0,{\itu})"], "Location", "northwest", "Interpreter", "tex")
xlabel("{\itu}"), ylabel("\phi({\itu})"), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-14-activation.png"), "Resolution", 150, "Width", 9, "Height", 6.5, "Units", "centimeters")
%%
%[text] ## 畳み込み層とプーリング層
%[text] 4 種類のフィルタ（フィルタバンク）で畳み込み，ReLU を施し， $ 2\\times2 $ の最大値プーリングで縮小した特徴マップを並べる。入力は石造りの建物（msipimg04 をグレースケールにして 256×256 に縮小）で，柱の縦の縁と階段の横の縁がそれぞれ別の特徴マップに現れ，フィルタの方向選択性が分かる。
Xg = im2double(vie.msipimg(4, 256, "gray"));
imwrite(Xg, fullfile(resfolder,"vie-14-fmap-in.png"))
% 水平差分（Sobel），垂直差分（Sobel），ラプラシアン，符号反転したラプラシアン
Fk = {[-1 0 1; -2 0 2; -1 0 1], [-1 -2 -1; 0 0 0; 1 2 1], [0 1 0; 1 -4 1; 0 1 0], -[0 1 0; 1 -4 1; 0 1 0]};
maps = cell(1,4);
for i = 1:4
    Z = max(imfilter(Xg, Fk{i}, "replicate"), 0);                        % 畳み込み＋ReLU
    Zp = max(max(Z(1:2:end,1:2:end), Z(2:2:end,1:2:end)), max(Z(1:2:end,2:2:end), Z(2:2:end,2:2:end)));  % 最大値プーリング
    maps{i} = Zp/max(Zp(:));
    imwrite(maps{i}, fullfile(resfolder,sprintf("vie-14-fmap%d.png", i)))
end
montage(maps, "Size", [1 4])
%%
%[text] ## まとめ
%[text] - パターン認識は特徴抽出と識別（識別辞書との照合）からなる。最近傍決定則は最も近い代表ベクトルのクラスを出力する
%[text] - ハリスのコーナー検出，キャニーの輪郭線検出，ハフ変換はガウシアンフィルタと勾配フィルタ（第5回）を土台にする
%[text] - ニューラルネットワークは重み付け和と活性化関数の多層構造で，損失関数（1/2 倍した平均二乗誤差）の勾配を誤差逆伝播法で求めて学習する。畳み込み層はフィルタバンクに相当する \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
