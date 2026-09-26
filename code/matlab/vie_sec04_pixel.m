%[text] # 第4回 画素処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第4回のスライド（vie2026-04）で使う図と数値を作る。画素処理（スカラー関数処理） $ y=\\phi(x) $ として，対比伸張・閾値処理・ネガ変換・べき乗則変換，ヒストグラムとヒストグラム均等化，カラー画像処理（色調補正・擬似色）を順に扱う。記号は教科書に合わせ，度数を $ h\_x $ ，正規化度数を $ p\_x $ ，階調数を $ L $ とする。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 画像は MATLAB 付属のものを使う（ダウンロード不要）。
[~,resfolder] = vie.prjfolders();
%%
%[text] ## 画素処理の数値例
%[text] 画素処理は，すべての画素に同じ関数 $ \\phi(\\cdot) $ を施す。例として 8-bit のネガ変換 $ y=255-x $ を $ 2\\times 3 $ の配列に施す。
x = [0 64 128; 200 250 255]
y = 255 - x
vie.savetex("vie-04-neg-x", vie.arr2tex(x,"%d"));
vie.savetex("vie-04-neg-y", vie.arr2tex(y,"%d"));
%%
%[text] ## 対比伸張と閾値処理の関数
%[text] 教科書の対比伸張（ $ x\\in[0,1] $ ， $ \\gamma\\in(0,1) $ ）
%[text]{"align":"center"} $ y=\\phi(x)=\\begin{cases} \\frac{1-(1-2x)^\\gamma}{2} & x<\\frac12 \\\\ \\frac{1+(2x-1)^\\gamma}{2} & x\\geq\\frac12 \\end{cases} $
%[text] と，閾値 $ \\tau $ の二値化閾値処理を描く。 $ \\gamma\\to 0 $ の対比伸張は $ \\tau=1/2 $ の閾値処理に一致する。
stretch = @(x,g) (x<0.5).*(1-abs(1-2*x).^g)/2 + (x>=0.5).*(1+abs(2*x-1).^g)/2;
xx = linspace(0,1,1001);
clf
plot(xx, stretch(xx,0.3), "LineWidth", 2), grid on, axis square
xlabel("x"), ylabel("y=\phi(x)"), title("対比伸張（\gamma=0.3）"), set(gca,"FontSize",14)
exportgraphics(gca, fullfile(resfolder,"vie-04-cs-curve.png"), "Resolution", 150)
%%
%[text] 閾値処理（ $ \\tau=1/2 $ ）
clf
plot(xx, double(xx>=0.5), "LineWidth", 2), grid on, axis square, ylim([-0.05 1.05])
xlabel("x"), ylabel("y=\phi(x)"), title("閾値処理（\tau=0.5）"), set(gca,"FontSize",14)
exportgraphics(gca, fullfile(resfolder,"vie-04-th-curve.png"), "Resolution", 150)
%%
%[text] ## 対比伸張の例
%[text] 低コントラスト画像 pout.tif（画素値がおよそ 0.32〜0.58 に集中）に対比伸張（ $ \\gamma=0.3 $ ）と閾値処理（ $ \\tau=0.45 $ ）を施す。
X = im2double(imread("pout.tif"));
range0 = [min(X(:)) max(X(:))]
Ycs = stretch(X, 0.3);
Yth = double(X >= 0.45);
range1 = [min(Ycs(:)) max(Ycs(:))]
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(X),   title("原画像")
nexttile, imshow(Ycs), title("対比伸張")
nexttile, imshow(Yth), title("閾値処理")
imwrite(X,   fullfile(resfolder,"vie-04-cs-org.png"))
imwrite(Ycs, fullfile(resfolder,"vie-04-cs-out.png"))
imwrite(Yth, fullfile(resfolder,"vie-04-th-out.png"))
%%
%[text] ## 基本的な輝度値変換
%[text] 恒等変換，ネガ変換 $ y=1-x $ ，対数変換 $ y=c\\log(1+x) $ （ $ c=1/\\log 2 $ で $ [0,1]\\to[0,1] $ ），べき乗則変換 $ y=x^\\gamma $ を比べる。
clf
plot(xx, xx, xx, 1-xx, xx, log(1+xx)/log(2), xx, xx.^0.4, xx, xx.^2.5, "LineWidth", 2)
grid on, axis square
legend(["恒等","ネガ","対数","べき乗 \gamma=0.4","べき乗 \gamma=2.5"], "Location","southeast")
xlabel("x"), ylabel("y=\phi(x)"), set(gca,"FontSize",13)
exportgraphics(gca, fullfile(resfolder,"vie-04-basic-curves.png"), "Resolution", 150)
%%
%[text] ## ネガ画像
%[text] 実数 $ x\\in[0,1] $ なら $ y=1-x $ ，整数 $ x\\in\\{0,\\dots,L-1\\} $ なら $ y=L-1-x $ 。MRI 画像で確かめる。
M = imread("mri.tif");
Mneg = 255 - M;
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(M),    title("原画像")
nexttile, imshow(Mneg), title("ネガ画像")
imwrite(M,    fullfile(resfolder,"vie-04-neg-org.png"))
imwrite(Mneg, fullfile(resfolder,"vie-04-neg-out.png"))
%%
%[text] ## べき乗則変換
%[text] 実数 $ x\\in[0,1] $ では $ y=x^\\gamma $ ，整数 $ r\\in\\{0,\\dots,L-1\\} $ では $ s=(L-1)\\left(\\frac{r}{L-1}\\right)^\\gamma $ 。 $ \\gamma<1 $ で明るく， $ \\gamma>1 $ で暗くなる。
gammas = [0.04 0.1 0.2 0.4 0.67 1 1.5 2.5 5 10 25];
clf
plot(xx, xx'.^gammas, "LineWidth", 1.5)   % 各列が一つの γ に対応
colororder(gca, turbo(numel(gammas)))
grid on, axis square
xlabel("x"), ylabel("y=x^\gamma"), set(gca,"FontSize",13)
legend(compose("\\gamma=%g",gammas), "Location", "southeast", "NumColumns", 2, "FontSize", 9)
exportgraphics(gca, fullfile(resfolder,"vie-04-power-curves.png"), "Resolution", 150)
%[text] 数値例： $ x=0.25 $ のとき
xp = 0.25;
ypow = xp.^[0.5 2]                        % γ=0.5 と γ=2
%[text] 8-bit（ $ L=256 $ ）で $ r=64,\\ \\gamma=0.5 $ のとき（四捨五入）：
s = round(255*(64/255)^0.5)
vie.savetex("vie-04-pow-a", sprintf("%g",ypow(1)));
vie.savetex("vie-04-pow-b", sprintf("%g",ypow(2)));
vie.savetex("vie-04-pow-s", sprintf("%d",s));
%%
%[text] ## 暗い画像のべき乗則変換
%[text] 暗い X 線画像 spine.tif（平均画素値が約 0.06）を最小最大正規化して，べき乗則変換（ $ \\gamma=0.6,0.4,0.3 $ ）で明るくする。
S0 = im2double(imread("spine.tif"));
meanS = mean(S0(:))                        % 正規化前の平均画素値
S = mat2gray(S0);                          % 最小最大正規化
gd = [0.6 0.4 0.3];
tiledlayout(1,4,"TileSpacing","compact","Padding","compact")
nexttile, imshow(S), title("原画像")
for k = 1:3
    nexttile, imshow(S.^gd(k)), title(sprintf("\\gamma=%g",gd(k)))
    imwrite(S.^gd(k), fullfile(resfolder,sprintf("vie-04-dark-g%02d.png",round(10*gd(k)))))
end
imwrite(S, fullfile(resfolder,"vie-04-dark-org.png"))
vie.savetex("vie-04-dark-mean", sprintf("%.2f",meanS));
%%
%[text] ## 明るい画像のべき乗則変換
%[text] 航空写真 westconcordorthophoto.png を $ 0.5+0.5x $ で明るく白っぽくした画像を用意し，べき乗則変換（ $ \\gamma=3,4,5 $ ）で暗くして濃淡を取り戻す。
A = im2double(imread("westconcordorthophoto.png"));
B = 0.5 + 0.5*A;                           % 白っぽい（明るい）画像を作る
meanB = mean(B(:))
gb = [3 4 5];
tiledlayout(1,4,"TileSpacing","compact","Padding","compact")
nexttile, imshow(B), title("原画像")
for k = 1:3
    nexttile, imshow(B.^gb(k)), title(sprintf("\\gamma=%g",gb(k)))
    imwrite(B.^gb(k), fullfile(resfolder,sprintf("vie-04-bright-g%d.png",gb(k))))
end
imwrite(B, fullfile(resfolder,"vie-04-bright-org.png"))
vie.savetex("vie-04-bright-mean", sprintf("%.2f",meanB));
%%
%[text] ## ヒストグラムの例
%[text] cameraman.tif から暗い・明るい・低対比・高対比の 4 種類の画像を作り，ヒストグラム（度数 $ h\_x $ ）を比べる。
C = imread("cameraman.tif");
Cd = im2uint8(0.45*im2double(C));                 % 暗い画像
Cb = im2uint8(0.55 + 0.45*im2double(C));          % 明るい画像
Cl = im2uint8(0.35 + 0.3*im2double(C));           % 低対比画像
Ch = histeq(C);                                   % 高対比画像
imgs = {Cd, Cb, Cl, Ch};
tags = ["dark","bright","low","high"];
for k = 1:4
    imwrite(imgs{k}, fullfile(resfolder,"vie-04-hist-"+tags(k)+".png"))
    clf
    h = imhist(imgs{k});
    bar(0:255, h, 1, "EdgeColor","none"), xlim([0 255]), ylim([0 max(h)*1.05])
    xlabel("画素値 x"), ylabel("度数 h_x"), set(gca,"FontSize",16)
    exportgraphics(gca, fullfile(resfolder,"vie-04-hist-"+tags(k)+"-h.png"), "Resolution", 100)
end
%%
%[text] ## ヒストグラム均等化の例
%[text] 暗い画像と明るい画像にそれぞれヒストグラム均等化を施す。元の画像が違っても，結果のヒストグラムはどちらも一様に近く，似た画像になる。
Ed = histeq(Cd, 256); Eb = histeq(Cb, 256);
for k = 1:2
    E = {Ed, Eb}; tg = ["dark","bright"];
    imwrite(E{k}, fullfile(resfolder,"vie-04-eq-"+tg(k)+".png"))
    clf
    h = imhist(E{k});
    bar(0:255, h, 1, "EdgeColor","none"), xlim([0 255]), ylim([0 max(h)*1.05])
    xlabel("画素値 y"), ylabel("度数 h_y"), set(gca,"FontSize",16)
    exportgraphics(gca, fullfile(resfolder,"vie-04-eq-"+tg(k)+"-h.png"), "Resolution", 100)
end
psnrEq = psnr(Ed, Eb)                             % 均等化後の 2 枚はよく似ている
vie.savetex("vie-04-eq-psnr", sprintf("%.1f",psnrEq));
%%
%[text] ## 例題：ヒストグラム均等化
%[text] 前回スライドの例題。 $ L=4 $ の $ 4\\times4 $ 配列に，教科書の式
%[text]{"align":"center"} $ y=\\phi(x)=\\left\\lfloor (L-1)\\sum\_{v=0}^{x}p\_v \\right\\rceil $
%[text] でヒストグラム均等化を施す（ $ \\lfloor\\cdot\\rceil $ は四捨五入）。
xe = [3 1 2 1; 3 1 2 1; 1 2 1 1; 0 1 0 2];
L = 4;
N = numel(xe)                                     % 総画素数
hx = histcounts(xe, -0.5:1:L-0.5)                 % 度数 h_x（x=0,1,2,3）
px = hx/N                                         % 正規化度数 p_x
cum = (L-1)*cumsum(px)                            % (L-1)Σp_v
phi = round(cum)                                  % 参照表 φ(x)
ye = phi(xe+1)                                    % 出力配列
hy = histcounts(ye, -0.5:1:L-0.5)                 % 均等化後の度数
vie.savetex("vie-04-he-x",   vie.arr2tex(xe,"%d"));
vie.savetex("vie-04-he-h",   vie.arr2tex(hx,"%d"));
vie.savetex("vie-04-he-p",   strjoin(compose("$\\frac{%d}{16}$",hx)," & "));           % 表の中で使うので $ で囲む
vie.savetex("vie-04-he-c",   strjoin(compose("$\\frac{%d}{16}$",round(cum*16))," & "));
vie.savetex("vie-04-he-phi", vie.arr2tex(phi,"%d"));
vie.savetex("vie-04-he-y",   vie.arr2tex(ye,"%d"));
vie.savetex("vie-04-he-hy",  vie.arr2tex(hy,"%d"));
%%
%[text] ## カラー画像処理：明るさの調整
%[text] peppers.png を明るくする。RGB 空間では R, G, B それぞれに $ \\gamma=0.4 $ のべき乗則変換を施す。HSV 空間では明度 V だけに施し，色相 H と彩度 S は保つ（前回スライドの HSI 空間処理に相当）。
P = im2double(imread("peppers.png"));
P = min(max(imresize(P, 0.5), 0), 1);         % 縮小時のオーバーシュートを [0,1] に収める
Prgb = P.^0.4;
Phsv = rgb2hsv(P); Phsv(:,:,3) = Phsv(:,:,3).^0.4; Phsv = hsv2rgb(Phsv);
satRGB = mean(reshape(rgb2hsv(Prgb),[],3)*[0;1;0]);   % 平均彩度（RGB 空間処理）
satHSV = mean(reshape(rgb2hsv(Phsv),[],3)*[0;1;0]);   % 平均彩度（HSV 空間処理）
sat = [mean(reshape(rgb2hsv(P),[],3)*[0;1;0]) satRGB satHSV]
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(P),    title("原画像")
nexttile, imshow(Prgb), title("RGB 空間処理")
nexttile, imshow(Phsv), title("HSV 空間処理")
imwrite(P,    fullfile(resfolder,"vie-04-col-org.png"))
imwrite(Prgb, fullfile(resfolder,"vie-04-col-bri-rgb.png"))
imwrite(Phsv, fullfile(resfolder,"vie-04-col-bri-hsv.png"))
vie.savetex("vie-04-sat-org", sprintf("%.2f",sat(1)));
vie.savetex("vie-04-sat-rgb", sprintf("%.2f",sat(2)));
vie.savetex("vie-04-sat-hsv", sprintf("%.2f",sat(3)));
%%
%[text] ## カラー画像処理：彩度の調整
%[text] RGB 空間で R と G だけを 1.3 倍すると，色あい（色相）まで変わる。HSV 空間で彩度 S だけを 1.3 倍すれば，色あいは保たれる。
Psat_rgb = P; Psat_rgb(:,:,1:2) = min(1, 1.3*P(:,:,1:2));
Q = rgb2hsv(P); Q(:,:,2) = min(1, 1.3*Q(:,:,2)); Psat_hsv = hsv2rgb(Q);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(P),        title("原画像")
nexttile, imshow(Psat_rgb), title("RGB 空間処理")
nexttile, imshow(Psat_hsv), title("HSV 空間処理")
imwrite(Psat_rgb, fullfile(resfolder,"vie-04-col-sat-rgb.png"))
imwrite(Psat_hsv, fullfile(resfolder,"vie-04-col-sat-hsv.png"))
%%
%[text] ## カラー画像処理：ヒストグラム均等化
%[text] R, G, B それぞれに均等化すると色あいが変わる。V（明度）だけに均等化すると色あいは保たれる。
Peq_rgb = P;
for c = 1:3, Peq_rgb(:,:,c) = histeq(P(:,:,c)); end
Q = rgb2hsv(P); Q(:,:,3) = histeq(Q(:,:,3)); Peq_hsv = hsv2rgb(Q);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(P),       title("原画像")
nexttile, imshow(Peq_rgb), title("R,G,B に適用")
nexttile, imshow(Peq_hsv), title("V のみに適用")
imwrite(Peq_rgb, fullfile(resfolder,"vie-04-col-eq-rgb.png"))
imwrite(Peq_hsv, fullfile(resfolder,"vie-04-col-eq-hsv.png"))
%%
%[text] ## 擬似色
%[text] グレースケール画像の画素値 $ x\\in[0,1] $ を，位相をずらした三角波の参照表 $ \\vec{y}=(T\_\\mathrm{R}(x),T\_\\mathrm{G}(x),T\_\\mathrm{B}(x)) $ で色に対応づける。わずかな画素値の違いが色の違いとして強調される。
tri = @(x,ph) 1 - abs(2*mod(1.5*x + ph, 1) - 1);  % 周期 2/3 の三角波
clf
plot(xx, tri(xx,0), "r", xx, tri(xx,1/3), "g", xx, tri(xx,2/3), "b", "LineWidth", 2)
grid on, xlabel("画素値 x"), ylabel("出力"), legend(["T_R","T_G","T_B"],"Location","eastoutside")
set(gca,"FontSize",14)
exportgraphics(gca, fullfile(resfolder,"vie-04-pseudo-lut.png"), "Resolution", 150)
G = im2double(imread("circuit.tif"));
Yps = cat(3, tri(G,0), tri(G,1/3), tri(G,2/3));
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(G),   title("モノクロ画像")
nexttile, imshow(Yps), title("擬似色表示画像")
imwrite(G,   fullfile(resfolder,"vie-04-pseudo-org.png"))
imwrite(Yps, fullfile(resfolder,"vie-04-pseudo-out.png"))
%%
%[text] ## 例題：擬似色
%[text] 前回スライドの例題。 $ 4\\times4 $ 配列 $ x\\in\\{0,1,2,3\\} $ を変換テーブル（R, G, B 各 2 bit）で擬似色表示する。
xq = [0 2 2 3; 1 1 1 2; 1 1 1 1; 1 1 1 0];
lut = [3 0 0; 0 3 0; 0 0 3; 3 0 3]                % 行 r=0,1,2,3 の (R,G,B)
Yq = ind2rgb(uint8(xq), lut/3);
imshow(imresize(Yq, 40, "nearest"))
imwrite(imresize(Yq, 40, "nearest"), fullfile(resfolder,"vie-04-pseudo-ex.png"))
%%
%[text] ## まとめ
%[text] - 画素処理は全画素に同じスカラー関数 $ y=\\phi(x) $ を施す
%[text] - べき乗則変換は $ \\gamma<1 $ で明るく， $ \\gamma>1 $ で暗くする
%[text] - ヒストグラム均等化は正規化度数の累積和から参照表を自動で作る
%[text] - カラー画像は HSV（HSI）空間で明度・彩度を操作すると色あいを保てる \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
