%[text] # 第8回 幾何処理（拡大縮小）
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第8回のスライド（vie2026-08）で使う図と数値を作る。間引き・平均による縮小，最近傍・双線形補間による拡大，標本化と周波数スペクトル，ダウン／アップサンプラ，デシメーションとインタポレーション（エイリアシングとイメージング）を扱う。記号は教科書に合わせ，再標本化行列（一次元では間引き率・補間率）を $ M $ とする。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
%[text] 柵の細かい縞をもつ kodim19（灯台）をグレースケールにして使う。
X = im2double(rgb2gray(imread(fullfile(datfolder,"kodim19.png"))));
X = X(301:556, 1:256);                       % 柵を含む 256×256 の領域
size(X)
imwrite(X, fullfile(resfolder,"vie-08-org.png"))
%%
%[text] ## 間引きによる縮小
%[text] 垂直・水平とも偶数番目の画素だけを残す（ $ y[\\boldsymbol{n}]=x[2\\boldsymbol{n}] $ ）。柵の縞が別の模様に化ける（エリアシング）。
Yd = X(1:2:end, 1:2:end);
imwrite(Yd, fullfile(resfolder,"vie-08-dec.png"))
%%
%[text] ## 平均による縮小
%[text] 前回スライドの例： $ 2\\times2 $ ブロックの平均値を出力する。
x4 = [0 2 4 4; 4 6 4 4; 0 6 4 4; 2 4 6 6]
y2 = (x4(1:2:end,1:2:end) + x4(2:2:end,1:2:end) + x4(1:2:end,2:2:end) + x4(2:2:end,2:2:end))/4
vie.savetex("vie-08-x4",  vie.arr2tex(x4,"%d"));
vie.savetex("vie-08-avg", vie.arr2tex(y2,"%g"));
Ya = (X(1:2:end,1:2:end) + X(2:2:end,1:2:end) + X(1:2:end,2:2:end) + X(2:2:end,2:2:end))/4;
imwrite(Ya, fullfile(resfolder,"vie-08-avg.png"))
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(X),  title("原画像")
nexttile, imshow(Yd), title("間引き")
nexttile, imshow(Ya), title("ブロック平均")
%%
%[text] ## 最近傍補間による拡大
%[text] 各画素を $ 2\\times2 $ ブロックに複製する。
y8nn = kron(x4, ones(2))
vie.savetex("vie-08-nn", vie.arr2tex(y8nn,"%d"));
Znn = kron(Ya, ones(2));                     % 縮小画像を 2×2 倍に拡大
imwrite(Znn, fullfile(resfolder,"vie-08-nn.png"))
%%
%[text] ## 双線形補間による拡大
%[text] 零値挿入の後，線形補間フィルタ $ f[n]=(\\frac12,1,\\frac12) $ を垂直・水平に施す（周囲は零値）。元の画素はそのまま残り，間は隣どうしの平均で埋まる。
fl = [1/2 1 1/2];
u8 = zeros(8); u8(1:2:end,1:2:end) = x4;     % 零値挿入
y8bl = conv2(fl, fl, u8, "full");
y8bl = y8bl(2:9, 2:9)                        % 元の画素が偶数番目に来るように切り出す
vie.savetex("vie-08-bl", vie.arr2tex(y8bl,"%g"));
%[text] 画像にも施す（境界は複製拡張）。
Ub = zeros(2*size(Ya)); Ub(1:2:end,1:2:end) = Ya;
Zbl = imfilter(Ub, fl'*fl, "replicate");
Zbl(:,end) = Zbl(:,end-1); Zbl(end,:) = Zbl(end-1,:);   % 右端・下端は複製で補う
imwrite(Zbl, fullfile(resfolder,"vie-08-bl.png"))
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Znn), title("最近傍補間")
nexttile, imshow(Zbl), title("双線形補間")
%[text] 拡大部分（右下）を比べる。
imwrite(imresize(Znn(129:192,129:192), 3, "nearest"), fullfile(resfolder,"vie-08-nn-zoom.png"))
imwrite(imresize(Zbl(129:192,129:192), 3, "nearest"), fullfile(resfolder,"vie-08-bl-zoom.png"))
%%
%[text] ## 一次元の標本化とスペクトル
%[text] 帯域が $ |\\nu|<\\nu\_\\mathrm{max} $ の信号を間隔 $ T $ で標本化すると，スペクトルは $ \\nu\_\\mathrm{s}=2\\pi/T $ ごとに周期化される（振幅は $ 1/T $ 倍）。 $ T $ が大きい（ $ \\nu\_\\mathrm{s}<2\\nu\_\\mathrm{max} $ ）と重なってエリアシングが生じる。
nuv = linspace(-5, 5, 2001);                 % 単位は ν_max
tri = @(v) max(1 - abs(v), 0);               % 三角形のスペクトル
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, plot(nuv, tri(nuv), "k", "LineWidth", 2), title("原信号のスペクトル X(\nu)（帯域 \nu_{max}）"), ylim([0 1.3]), grid on
for nus = [3 1.4]                            % 標本化角周波数 ν_s（ν_max の倍数）
    S = zeros(size(nuv)); nexttile, hold on
    for k = -5:5
        plot(nuv, tri(nuv - k*nus), ":", "Color", [0.5 0.5 0.5])
        S = S + tri(nuv - k*nus);
    end
    plot(nuv, S, "b", "LineWidth", 2), hold off, ylim([0 1.3]), grid on
    if nus > 2, title("\nu_s = 3\nu_{max}（T 小）：重ならない"), else, title("\nu_s = 1.4\nu_{max}（T 大）：重なる → エリアシング"), end
end
xlabel("\nu / \nu_{max}")
exportgraphics(gcf, fullfile(resfolder,"vie-08-sampling.png"), "Resolution", 120)
%%
%[text] ## ダウンサンプラとアップサンプラ
%[text] 間引き $ y[m]=x[Mm] $ と零値挿入（各サンプルの間に $ M-1 $ 個の零を挿入）。 $ M=2 $ の例：
xd = [2 2 4 2 2 4];
yds = xd(1:2:end)
xu = [2 2 4];
yus = zeros(1, 2*numel(xu)); yus(1:2:end) = xu
vie.savetex("vie-08-ds-x", strjoin(string(xd),",\ "));
vie.savetex("vie-08-ds-y", strjoin(string(yds),",\ "));
vie.savetex("vie-08-us-x", strjoin(string(xu),",\ "));
vie.savetex("vie-08-us-y", strjoin(string(yus),",\ "));
%%
%[text] ## レート変換器（デシメータ・インタポレータ）の数値例
%[text] デシメータ：平均フィルタ $ h[n]=(\\frac12,\\frac12) $ （ $ n=0,1 $ ）の後に 2 対 1 の間引き。
v = filter([1/2 1/2], 1, xd)                 % v[n] = (x[n]+x[n-1])/2（x[-1]=0）
ydec = v(2:2:end)                            % 平均が揃う奇数番目を出力（位相の選択）
vie.savetex("vie-08-dec-v", strjoin(compose("%g",v),",\ "));
vie.savetex("vie-08-dec-y", strjoin(compose("%g",ydec),",\ "));
%[text] インタポレータ：零値挿入の後，最近傍補間フィルタ $ f[m]=(1,1) $ （ $ m=0,1 $ ）。
yint = filter([1 1], 1, yus)
vie.savetex("vie-08-int-y", strjoin(string(yint),",\ "));
%%
%[text] ## エリアシング（間引き率 2）
%[text] 間引き後のスペクトルは $ Y(e^{j\\omega})=\\frac12\\left\\{X(e^{j\\omega/2})+X(e^{j(\\omega-2\\pi)/2})\\right\\} $ 。帯域 $ 0.7\\pi $ の信号では，引き伸ばされた成分が重なる。
w = linspace(-pi, 3*pi, 2001);
Xw = @(om) max(1 - abs(mod(om+pi, 2*pi) - pi)/(0.7*pi), 0);   % 周期 2π，帯域 0.7π
Y1 = 0.5*(Xw(w/2) + Xw((w - 2*pi)/2));
Hid = @(om) double(abs(mod(om+pi, 2*pi) - pi) < pi/2);        % 理想低域通過（π/2）
Vw = @(om) Hid(om).*Xw(om);
Y2 = 0.5*(Vw(w/2) + Vw((w - 2*pi)/2));
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, plot(w, Xw(w), "k", "LineWidth", 2), title("X(e^{j\omega})"), grid on, ylim([0 1.2])
nexttile, plot(w, 0.5*Xw(w/2), "b--", w, 0.5*Xw((w-2*pi)/2), "m--", w, Y1, "r", "LineWidth", 2)
title("フィルタなしで間引き：2 つの成分（破線）が重なる（エリアシング）"), grid on, ylim([0 1.2])
nexttile, plot(w, 0.5*Vw(w/2), "b--", w, 0.5*Vw((w-2*pi)/2), "m--", "LineWidth", 2)
title("π/2 の低域通過フィルタの後に間引き：重ならない"), grid on, ylim([0 1.2])
for k = 1:3, nexttile(k), xticks(-pi:pi:3*pi), xticklabels(["-\pi","0","\pi","2\pi","3\pi"]), end
xlabel("\omega")
exportgraphics(gcf, fullfile(resfolder,"vie-08-alias.png"), "Resolution", 120)
%%
%[text] ## イメージング（補間率 2）
%[text] 零値挿入後のスペクトルは $ Y(e^{j\\omega})=X(e^{j2\\omega}) $ 。 $ \\omega=\\pi $ のまわりに余分な成分（イメージング）が現れる。補間フィルタ（理想低域通過，利得 2）で取り除く。
Xw2 = @(om) max(1 - abs(mod(om+pi, 2*pi) - pi)/(0.8*pi), 0);
Yi = Xw2(2*w);
Fi = 2*Hid(w);
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, plot(w, Xw2(w), "k", "LineWidth", 2), title("X(e^{j\omega})"), grid on, ylim([0 2.2])
nexttile, plot(w, Yi, "r", "LineWidth", 2), title("零値挿入後 Y(e^{j\omega})=X(e^{j2\omega})：イメージングが生じる"), grid on, ylim([0 2.2])
nexttile, plot(w, Fi.*Yi, "b", "LineWidth", 2), title("補間フィルタ（利得 2）の後：イメージング除去"), grid on, ylim([0 2.2])
for k = 1:3, nexttile(k), xticks(-pi:pi:3*pi), xticklabels(["-\pi","0","\pi","2\pi","3\pi"]), end
xlabel("\omega")
exportgraphics(gcf, fullfile(resfolder,"vie-08-imaging.png"), "Resolution", 120)
%%
%[text] ## デシメーションフィルタと補間フィルタの振幅応答
%[text] 平均フィルタ $ (\\frac12,\\frac12) $ ： $ |H|=|\\cos(\\omega/2)| $ 。最近傍補間フィルタ $ (1,1) $ ： $ |F|=2|\\cos(\\omega/2)| $ 。線形補間フィルタ $ (\\frac12,1,\\frac12) $ ： $ F=1+\\cos\\omega $ 。
wp = linspace(0, pi, 501);
clf
plot(wp, double(wp < pi/2), "k--", wp, abs(cos(wp/2)), "b", "LineWidth", 2), grid on
legend(["理想特性","平均フィルタ (1/2,1/2)"], "Location","southwest"), xlim([0 pi]), ylim([0 1.1])
xticks([0 pi/2 pi]), xticklabels(["0","\pi/2","\pi"]), xlabel("\omega"), ylabel("|H(e^{j\omega})|"), set(gca,"FontSize",13)
exportgraphics(gca, fullfile(resfolder,"vie-08-decfilt.png"), "Resolution", 120)
clf
plot(wp, 2*double(wp < pi/2), "k--", wp, 2*abs(cos(wp/2)), "b", wp, 1 + cos(wp), "r", "LineWidth", 2), grid on
legend(["理想特性（利得 2）","最近傍 (1,1)","線形 (1/2,1,1/2)"], "Location","southwest"), xlim([0 pi]), ylim([0 2.2])
xticks([0 pi/2 pi]), xticklabels(["0","\pi/2","\pi"]), xlabel("\omega"), ylabel("|F(e^{j\omega})|"), set(gca,"FontSize",13)
exportgraphics(gca, fullfile(resfolder,"vie-08-intfilt.png"), "Resolution", 120)
%[text] $ \\omega=\\pi $ （イメージングの中心）での値：最近傍は 0，線形も 0。 $ \\omega=3\\pi/4 $ では
vals = [2*abs(cos(3*pi/8)) 1 + cos(3*pi/4)]
vie.savetex("vie-08-f34-nn", sprintf("%.2f",vals(1)));
vie.savetex("vie-08-f34-bl", sprintf("%.2f",vals(2)));
%%
%[text] ## 画像の縮小（分離処理）
%[text] 垂直・水平とも間引き率 2。フィルタなし，平均 $ (\\frac12,\\frac12) $ ， $ (\\frac14,\\frac12,\\frac14) $ を比べる。
h2 = [1/2 1/2]; h3 = [1/4 1/2 1/4];
D0 = X(1:2:end,1:2:end);
D1 = imfilter(X, h2'*h2, "replicate"); D1 = D1(1:2:end,1:2:end);
D2 = imfilter(X, h3'*h3, "replicate"); D2 = D2(1:2:end,1:2:end);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(D0), title("フィルタなし")
nexttile, imshow(D1), title("(1/2,1/2)")
nexttile, imshow(D2), title("(1/4,1/2,1/4)")
imwrite(D1, fullfile(resfolder,"vie-08-dec-h2.png"))
imwrite(D2, fullfile(resfolder,"vie-08-dec-h3.png"))
%%
%[text] ## まとめ
%[text] - 標本化は周波数スペクトルを周期化する。間隔が粗いとエリアシングが生じる
%[text] - 縮小は「低域通過フィルタ＋間引き」（デシメーション），拡大は「零値挿入＋補間フィルタ」（インタポレーション）
%[text] - 平均による縮小と双線形補間による拡大は，それぞれエリアシングとイメージングを抑える \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
