%[text] # 第14回 パターン認識と特徴抽出
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第14回のスライド（vie2026-14）で使う図と数値を作る。特徴空間と最近傍決定則，色の特徴空間，ハリスのコーナー検出，キャニーの輪郭線検出，ハフ変換による直線検出，ニューラルネットワーク（活性化関数，誤差逆伝播法），畳み込み層とプーリング層を扱う。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
%%
%[text] ## 特徴空間と最近傍決定則
%[text] 2 次元の特徴ベクトルをもつ 3 クラスの学習データ（各 30 個）から，クラスごとの平均を代表ベクトル $ \\boldsymbol{\\mu}\_i $ とする（パターン学習）。未知の入力は最も近い代表ベクトルのクラスに識別する（最近傍決定則）。
rng(0)
mu0 = [1 1; 4 1.5; 2.5 4];                        % 真の中心
Xtr = []; ytr = [];
for i = 1:3
    Xtr = [Xtr; mu0(i,:) + 0.6*randn(30,2)]; %#ok<AGROW>
    ytr = [ytr; i*ones(30,1)]; %#ok<AGROW>
end
mu = zeros(3,2);
for i = 1:3, mu(i,:) = mean(Xtr(ytr==i,:), 1); end
mu                                              % 代表ベクトル
xq = [3 2.5];                                    % 未知入力
d = vecnorm(mu - xq, 2, 2)'                      % 各代表ベクトルまでの距離
[~, cls] = min(d)
vie.savetex("vie-14-mu", vie.arr2tex(round(mu,2), "%.2f"));
vie.savetex("vie-14-d", strjoin(compose("%.2f", d), ",\ "));
vie.savetex("vie-14-cls", sprintf("%d", cls));
%[text] 特徴空間と識別境界（各点を最も近い代表ベクトルのクラスで色分け）。
[g1, g2] = meshgrid(linspace(-1, 6, 281));
[~, lab] = min(cat(3, (g1-mu(1,1)).^2+(g2-mu(1,2)).^2, (g1-mu(2,1)).^2+(g2-mu(2,2)).^2, (g1-mu(3,1)).^2+(g2-mu(3,2)).^2), [], 3);
clf
cmapL = [0.85 0.9 1; 1 0.88 0.85; 0.88 1 0.88];
imagesc(g1(1,:), g2(:,1), lab), set(gca, "YDir", "normal"), colormap(gca, cmapL), hold on
col = [0 0.3 0.9; 0.85 0.2 0.1; 0.1 0.6 0.2];
for i = 1:3
    scatter(Xtr(ytr==i,1), Xtr(ytr==i,2), 18, col(i,:), "filled")
    plot(mu(i,1), mu(i,2), "k+", "MarkerSize", 14, "LineWidth", 2.5)
end
plot(xq(1), xq(2), "kp", "MarkerSize", 14, "MarkerFaceColor", "y")
hold off, axis equal tight, xlabel("x_1"), ylabel("x_2"), set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-14-feature-space.png"), "Resolution", 110)
%[text] 新しいテストデータ（各 30 個）での識別率。
Xte = []; yte = [];
for i = 1:3
    Xte = [Xte; mu0(i,:) + 0.6*randn(30,2)]; %#ok<AGROW>
    yte = [yte; i*ones(30,1)]; %#ok<AGROW>
end
[~, yhat] = min(pdist2(Xte, mu), [], 2);
acc = mean(yhat == yte)
vie.savetex("vie-14-acc", sprintf("%.0f", 100*acc));
%%
%[text] ## 色の特徴空間
%[text] 画像の各画素の (R, G, B) を特徴ベクトルとみなすと，RGB 空間が特徴空間になる。
Xc = im2double(imread(fullfile(datfolder,"kodim23.png")));
Xs = imresize(Xc, 1/8);
v = reshape(Xs, [], 3);
clf
scatter3(v(:,1), v(:,2), v(:,3), 8, v, "filled"), axis([0 1 0 1 0 1]), grid on
xlabel("R"), ylabel("G"), zlabel("B"), view(-40, 25), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-14-rgbspace.png"), "Resolution", 110)
imwrite(imresize(Xc, 0.25), fullfile(resfolder,"vie-14-parrot.png"))
%%
%[text] ## ハリスのコーナー検出：局所構造行列の数値例
%[text] 局所構造行列（構造テンソル） $ \\hat{\\mathbf{M}}=\\begin{pmatrix}\\hat{A}&\\hat{C}\\\\\\hat{C}&\\hat{B}\\end{pmatrix} $ ， $ A=x\_\\mathrm{v}^2,\\ B=x\_\\mathrm{h}^2,\\ C=x\_\\mathrm{v}x\_\\mathrm{h} $ （近傍で平均）と，コーナー応答 $ r=\\det\\hat{\\mathbf{M}}-k(\\mathrm{trace}\\hat{\\mathbf{M}})^2 $ （ $ k=0.04 $ ）を，平坦・エッジ・コーナーの $ 5\\times5 $ パッチで比べる。
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
%[text] 市松模様と鉄骨構造の画像（gantrycrane.png）でコーナーを検出する。
C = checkerboard(24, 3, 3) > 0.5;
C = double(C);
cc = corner(C, "Harris", 40);
Gr = im2double(rgb2gray(imread("gantrycrane.png")));
cg = corner(Gr, "Harris", 150, "SensitivityFactor", 0.04);
clf, imshow(C), hold on, plot(cc(:,1), cc(:,2), "r+", "MarkerSize", 10, "LineWidth", 2), hold off
exportgraphics(gca, fullfile(resfolder,"vie-14-harris-checker.png"), "Resolution", 110)
clf, imshow(Gr), hold on, plot(cg(:,1), cg(:,2), "r+", "MarkerSize", 6, "LineWidth", 1.5), hold off
exportgraphics(gca, fullfile(resfolder,"vie-14-harris-crane.png"), "Resolution", 110)
imwrite(C, fullfile(resfolder,"vie-14-checker.png"))
imwrite(Gr, fullfile(resfolder,"vie-14-crane.png"))
ncorner = [size(cc,1) size(cg,1)]
vie.savetex("vie-14-nc-checker", sprintf("%d", ncorner(1)));
%%
%[text] ## キャニーの輪郭線検出
%[text] ガウス平滑化 → 勾配 → 非極大抑制 → ヒステリシス閾値処理。比較としてソーベル勾配の単純な閾値処理も示す。
Ec = edge(Gr, "canny");
Es = edge(Gr, "sobel");
imwrite(~Ec, fullfile(resfolder,"vie-14-canny.png"))
imwrite(~Es, fullfile(resfolder,"vie-14-sobel.png"))
Xk = im2double(rgb2gray(imread(fullfile(datfolder,"kodim23.png"))));
Xk = imresize(Xk, 0.5);
imwrite(Xk, fullfile(resfolder,"vie-14-parrot-gray.png"))
imwrite(~edge(Xk, "canny"), fullfile(resfolder,"vie-14-parrot-canny.png"))
%%
%[text] ## ハフ変換：数値例
%[text] 一直線上の 3 点 A(0,2), B(1,1), C(2,0) は， $ \\theta=45^\\circ $ でいずれも $ \\rho=x\\cos\\theta+y\\sin\\theta=\\sqrt{2} $ となる（3 本の曲線が 1 点で交わる）。
pts = [0 2; 1 1; 2 0];
th = deg2rad(45);
rho = pts(:,1)*cos(th) + pts(:,2)*sin(th)
tt = linspace(0, pi, 361);
clf
plot(rad2deg(tt), pts(:,1)*cos(tt) + pts(:,2)*sin(tt), "LineWidth", 2), hold on
plot(45, sqrt(2), "ko", "MarkerSize", 10, "LineWidth", 2), hold off
grid on, xlabel("\theta [度]"), ylabel("\rho"), legend(["A(0,2)","B(1,1)","C(2,0)"], "Location","southwest")
xlim([0 180]), xticks(0:45:180), set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-14-hough-curves.png"), "Resolution", 110)
vie.savetex("vie-14-hough-rho", sprintf("%.3f", rho(1)));
%%
%[text] ## ハフ変換：処理例
%[text] キャニーの輪郭画像を投票し，投票度数の大きなセル（ピーク）を探索して直線を描く（逆ハフ変換）。
[Hh, T, Rr] = hough(Ec);
pk = houghpeaks(Hh, 12, "Threshold", 0.3*max(Hh(:)));
lines = houghlines(Ec, T, Rr, pk, "FillGap", 20, "MinLength", 60);
clf
imshow(rescale(log(1 + Hh)), "XData", T, "YData", Rr, "InitialMagnification", "fit"), axis on, axis normal   % 投票度数を対数表示
colormap(gca, hot(256)), xlabel("\theta [度]"), ylabel("\rho"), hold on
plot(T(pk(:,2)), Rr(pk(:,1)), "cs", "MarkerSize", 8, "LineWidth", 1.5), hold off
set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-14-hough-acc.png"), "Resolution", 110)
clf, imshow(Gr), hold on
for kk = 1:numel(lines)
    xy = [lines(kk).point1; lines(kk).point2];
    plot(xy(:,1), xy(:,2), "LineWidth", 3, "Color", "g")
end
hold off
exportgraphics(gca, fullfile(resfolder,"vie-14-hough-lines.png"), "Resolution", 110)
nlines = numel(lines)
colormap(gca, gray)
%%
%[text] ## 活性化関数とニューロンの数値例
u = linspace(-4, 4, 401);
clf
plot(u, 1./(1+exp(-u)), u, tanh(u), u, max(u,0), "LineWidth", 2), grid on, ylim([-1.2 2])
legend(["Logistic Sigmoid","Tangent Sigmoid","ReLU"], "Location","northwest"), xlabel("u"), set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-14-activation.png"), "Resolution", 110)
%[text] 入力 $ \\mathbf{x}=(2,1)^\\top $ ，重み $ \\mathbf{w}=(0.5,-1)^\\top $ ，バイアス $ b=0.2 $ のニューロン： $ u=\\mathbf{w}^\\top\\mathbf{x}+b $ 。
w = [0.5 -1]; x = [2; 1]; b = 0.2;
un = w*x + b
out = [1/(1+exp(-un)) tanh(un) max(un,0)]
vie.savetex("vie-14-neuron-u", sprintf("%.1f", un));
vie.savetex("vie-14-neuron-sig", sprintf("%.3f", out(1)));
vie.savetex("vie-14-neuron-tanh", sprintf("%.3f", out(2)));
vie.savetex("vie-14-neuron-relu", sprintf("%.1f", out(3)));
%%
%[text] ## 教師あり学習と誤差逆伝播法：XOR の学習
%[text] 入力 2，中間層 4（tanh），出力 1（シグモイド）のネットワークを，二乗誤差 $ E=\\sum\_n(\\hat{y}\_n-y\_n)^2 $ の最急降下法で学習する。勾配は出力層から入力層へ順に（誤差逆伝播法）求める。
Xx = [0 0 1 1; 0 1 0 1];                         % 入力（列が 1 事例）
yx = [0 1 1 0];                                  % 教師出力（XOR）
rng(3)
W1 = randn(4,2); b1 = zeros(4,1); W2 = randn(1,4); b2 = 0;
eta = 0.5; nEpoch = 3000; Ehist = zeros(1,nEpoch);
for ep = 1:nEpoch
    H = tanh(W1*Xx + b1);                        % 順伝播：中間層
    Y = 1./(1 + exp(-(W2*H + b2)));              % 順伝播：出力層
    Ehist(ep) = sum((Y - yx).^2);
    dY = 2*(Y - yx).*Y.*(1 - Y);                 % 逆伝播：出力層の誤差
    dH = (W2'*dY).*(1 - H.^2);                   % 逆伝播：中間層の誤差
    W2 = W2 - eta*dY*H';  b2 = b2 - eta*sum(dY); % 重み係数の更新
    W1 = W1 - eta*dH*Xx'; b1 = b1 - eta*sum(dH,2);
end
Yfinal = 1./(1 + exp(-(W2*tanh(W1*Xx + b1) + b2)))
Efinal = Ehist(end)
clf
semilogy(Ehist, "LineWidth", 2), grid on, xlabel("反復回数"), ylabel("誤差 E"), set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-14-xor-loss.png"), "Resolution", 110)
vie.savetex("vie-14-xor-y", strjoin(compose("%.2f", Yfinal), ",\ "));
vie.savetex("vie-14-xor-e0", sprintf("%.2f", Ehist(1)));
vie.savetex("vie-14-xor-e", sprintf("%.4f", Efinal));
%%
%[text] ## 畳み込み層とプーリング層
%[text] 4 種類のフィルタ（フィルタバンク）で畳み込み，ReLU を施し， $ 2\\times2 $ の最大値プーリングで縮小した特徴マップを並べる。
Xg = im2double(imread("cameraman.tif"));
imwrite(Xg, fullfile(resfolder,"vie-14-fmap-in.png"))
% 水平差分（Sobel），垂直差分（Sobel），ラプラシアン，符号反転したラプラシアン
Fk ={[-1 0 1; -2 0 2; -1 0 1], [-1 -2 -1; 0 0 0; 1 2 1], [0 1 0; 1 -4 1; 0 1 0], -[0 1 0; 1 -4 1; 0 1 0]};
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
%[text] - ニューラルネットワークは重み付け和と活性化関数の多層構造で，誤差逆伝播法で学習する。畳み込み層はフィルタバンクに相当する \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
