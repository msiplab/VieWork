%[text] # 第4回 画素処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第4回のスライド（vie2026-04）で使う図と数値を作る。画素処理（スカラー関数処理） $ y=\\phi(x) $ として，対比伸張・二値化閾値処理・ネガポジ変換・標準化と最小最大正規化・べき乗則変換，ヒストグラムとヒストグラム均等化，カラー画像処理（色調補正・擬似カラー）を順に扱う。記号は教科書に合わせ，度数を $ h\_x $ ，正規化度数を $ p\_x $ ，階調数を $ L $ ，閾値を $ \\tau $ とする。
%[text] 教科書の例題（「ネガポジ変換」「標準化と最小最大正規化」「ヒストグラム均等化」）は，ここで計算し直して教科書の値と照合してから，スライドに書き出す。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 写真は参考資料のサンプル画像 msipimg01〜08（512×512 のカラー）に限り，共通関数 vie.msipimg で読み込む。低対比・暗い・明るい画像など特定の性質が要る例は，これらを元にスクリプトの中で作る。図の配色は，色そのものが内容の画像を除き，ロゴの 3 色（メインの緑，青，橙）と灰色にそろえる。
[~,resfolder] = vie.prjfolders();
cMain = [0 136 85]/255;     % メイン（緑）#008855
cCool = [46 117 182]/255;   % 寒色系（青）#2E75B6
cWarm = [197 90 17]/255;    % 暖色系（橙）#C55A11
cGray = [0.5 0.5 0.5];      % 灰色
%%
%[text] ## 画素処理の数値例
%[text] 画素処理は，すべての画素に同じ関数 $ \\phi(\\cdot) $ を施す。例として 8-bit のネガポジ変換 $ y=255-x $ を $ 2\\times 3 $ の配列に施す。
x = [0 64 128; 200 250 255]
y = 255 - x
vie.savetex("vie-04-neg-x", vie.arr2tex(x,"%d"));
vie.savetex("vie-04-neg-y", vie.arr2tex(y,"%d"));
%%
%[text] ## 対比伸張と二値化閾値処理の関数
%[text] 教科書の対比伸張（ $ x\\in[0,1] $ ， $ \\gamma\\in(0,1) $ ）
%[text]{"align":"center"} $ y=\\phi(x)=\\begin{cases} \\frac{1-(1-2x)^\\gamma}{2} & x<\\frac12 \\\\ \\frac{1+(2x-1)^\\gamma}{2} & x\\geq\\frac12 \\end{cases} $
%[text] と，閾値 $ \\tau $ の二値化閾値処理を描く。 $ \\gamma\\to 0 $ の対比伸張は $ \\tau=1/2 $ の二値化閾値処理に一致する。
stretch = @(x,g) (x<0.5).*(1-abs(1-2*x).^g)/2 + (x>=0.5).*(1+abs(2*x-1).^g)/2;
xx = linspace(0,1,1001);
[fig, ax] = slidefig(3.8, 3.8);                   % スライド上の大きさに近い図
plot(ax, xx, xx, "--", "Color", cGray, "LineWidth", 1.6), hold(ax, "on")
plot(ax, xx, stretch(xx,0.3), "Color", cMain, "LineWidth", 2.4), hold(ax, "off")
grid(ax, "on"), axis(ax, "square"), xticks(ax, 0:0.5:1), yticks(ax, 0:0.5:1)
xlabel(ax, "$x$","Interpreter","latex"), ylabel(ax, "$y=\phi(x)$","Interpreter","latex")
set(ax, "FontSize", 9)
title(ax, "\gamma=0.3", "FontWeight", "normal", "FontSize", 9)
exportgraphics(fig, fullfile(resfolder,"vie-04-cs-curve.png"), "Resolution", 300)
close(fig)
%%
%[text] 二値化閾値処理（ $ \\tau=1/2 $ ）
[fig, ax] = slidefig(3.8, 3.8);
plot(ax, xx, xx, "--", "Color", cGray, "LineWidth", 1.6), hold(ax, "on")
plot(ax, xx, double(xx>=0.5), "Color", cMain, "LineWidth", 2.4), hold(ax, "off")
grid(ax, "on"), axis(ax, "square"), ylim(ax, [-0.05 1.05]), xticks(ax, 0:0.5:1), yticks(ax, 0:0.5:1)
xlabel(ax, "$x$","Interpreter","latex"), ylabel(ax, "$y=\phi(x)$","Interpreter","latex")
set(ax, "FontSize", 9)
title(ax, "\tau=0.5", "FontWeight", "normal", "FontSize", 9)
exportgraphics(fig, fullfile(resfolder,"vie-04-th-curve.png"), "Resolution", 300)
close(fig)
%%
%[text] ## 対比伸張の例
%[text] 石像の顔 msipimg05 をグレースケール（ $ 256\\times256 $ ）にし， $ 0.3x+0.35 $ で画素値を 0.35〜0.65 に押し込めた低対比画像を作る。これに対比伸張（ $ \\gamma=0.3 $ ）と二値化閾値処理（ $ \\tau=0.5 $ ）を施す。
X = 0.3*im2double(vie.msipimg(5, 256, "gray")) + 0.35;   % 低対比画像を作る
range0 = [min(X(:)) max(X(:))]
Ycs = stretch(X, 0.3);
Yth = double(X >= 0.5);
range1 = [min(Ycs(:)) max(Ycs(:))]
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(X),   title("原画像")
nexttile, imshow(Ycs), title("対比伸張")
nexttile, imshow(Yth), title("二値化閾値処理")
imwrite(X,   fullfile(resfolder,"vie-04-cs-org.png"))
imwrite(Ycs, fullfile(resfolder,"vie-04-cs-out.png"))
imwrite(Yth, fullfile(resfolder,"vie-04-th-out.png"))
%%
%[text] ## 基本的な輝度値変換
%[text] 恒等変換，ネガポジ変換 $ y=-x+1 $ ，対数変換 $ y=c\\log(1+x) $ （ $ c=1/\\log 2 $ で $ [0,1]\\to[0,1] $ ），べき乗則変換 $ y=x^\\gamma $ を比べる。
[fig, ax] = slidefig(6.4, 3.8);                   % 凡例は曲線に重ならないよう軸の右に置く
hold(ax, "on")
plot(ax, xx, xx,               "--", "Color", cGray, "LineWidth", 1.6)
plot(ax, xx, 1-xx,                   "Color", cCool, "LineWidth", 2.2)
plot(ax, xx, log(1+xx)/log(2),       "Color", cWarm, "LineWidth", 2.2)
plot(ax, xx, xx.^0.4,                "Color", cMain, "LineWidth", 2.2)
plot(ax, xx, xx.^2.5,          "-.", "Color", cMain, "LineWidth", 2.2)
hold(ax, "off")
grid(ax, "on"), box(ax, "on"), axis(ax, "square"), xticks(ax, 0:0.5:1), yticks(ax, 0:0.5:1)
xlabel(ax, "$x$","Interpreter","latex"), ylabel(ax, "$y=\phi(x)$","Interpreter","latex"), set(ax, "FontSize", 9)
lg = legend(ax, ["恒等","ネガポジ","対数","べき乗則 \gamma=0.4","べき乗則 \gamma=2.5"], ...
    "Location","eastoutside", "FontSize", 8, "Box", "off");
lg.ItemTokenSize = [16 18];
exportgraphics(fig, fullfile(resfolder,"vie-04-basic-curves.png"), "Resolution", 300)
close(fig)
%%
%[text] ## ネガポジ変換
%[text] 教科書の例題「ネガポジ変換」：0 が黒，1 が白の実数型画像 $ \\mathsf{x}\\in[0,1]^{N\_1\\times N\_2} $ には， $ a=-1 $ のスケール処理と $ b=1 $ のバイアス処理を施して
%[text]{"align":"center"} $ y=\\phi(x)=-x+1,\\quad x\\in[0,1] $
%[text] とする。整数型 $ x\\in\\{0,1,\\ldots,L-1\\} $ では，画素値を $ L-1 $ で割って $ [0,1] $ に写したものに同じ変換を施し， $ L-1 $ 倍して戻せば $ y=L-1-x $ となる。石造りの建物 msipimg04（グレースケール，8-bit， $ L=256 $ ）で両者が一致することを確かめる。暗いアーチの奥の構造がネガ画像で見やすくなる。
M = vie.msipimg(4, 256, "gray");
Mneg = 255 - M;                                   % 整数型：y = L-1-x
errNeg = max(abs(im2double(Mneg) - (-im2double(M) + 1)), [], "all")   % 実数型 y=-x+1 との差（0 になる）
assert(errNeg < 1e-12)
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(M),    title("原画像")
nexttile, imshow(Mneg), title("ネガ画像")
imwrite(M,    fullfile(resfolder,"vie-04-neg-org.png"))
imwrite(Mneg, fullfile(resfolder,"vie-04-neg-out.png"))
%[text] 8-bit（ $ L=256 $ ）での数値例：
L = 256;
xn = [0 64 200];
yn = (L-1) - xn
vie.savetex("vie-04-negpos-int", strjoin(compose("$%d\\to%d$", [xn(:) yn(:)]), "，"));
%%
%[text] ## 標準化と最小最大正規化
%[text] 教科書の例題「標準化と最小最大正規化」。 $ 4\\times 6 $ 実数配列 $ \\mathsf{x} $ の標本平均 $ \\mu $ と標本（不偏）分散 $ \\sigma^2 $ （ $ N-1 $ で割る）を求め，
%[text]{"align":"center"} $ y=\\frac{x-\\mu}{\\sigma},\\qquad y=\\frac{x-x\_\\mathrm{min}}{x\_\\mathrm{max}-x\_\\mathrm{min}} $
%[text] を施す。
xsd = [5 5 7 6 7 2; 6 2 3 2 7 2; 2 2 4 4 4 6; 4 4 4 4 1 2];
Nsd = numel(xsd)                                  % 要素数（=24）
mu = mean(xsd, "all")                             % 標本平均
sigma2 = var(xsd, 0, "all")                       % 標本（不偏）分散
ystd = (xsd - mu)/sqrt(sigma2)                    % 標準化
xmin = min(xsd, [], "all")
xmax = max(xsd, [], "all")
ymm = (xsd - xmin)/(xmax - xmin)                  % 最小最大正規化
%[text] 教科書の解答（小数点以下 4 桁）と照合する。
ystdText = [ 0.5622  0.5622  1.6416  1.1019  1.6416 -1.0569
             1.1019 -1.0569 -0.5172 -1.0569  1.6416 -1.0569
            -1.0569 -1.0569  0.0225  0.0225  0.0225  1.1019
             0.0225  0.0225  0.0225  0.0225 -1.5967 -1.0569 ];
ymmText  = [ 0.6667  0.6667  1.0000  0.8333  1.0000  0.1667
             0.8333  0.1667  0.3333  0.1667  1.0000  0.1667
             0.1667  0.1667  0.5000  0.5000  0.5000  0.8333
             0.5000  0.5000  0.5000  0.5000  0.0000  0.1667 ];
assert(abs(round(mu,4) - 3.9583) < 1e-12 && abs(round(sigma2,4) - 3.4330) < 1e-12)
assert(max(abs(round(ystd,4) - ystdText), [], "all") < 1e-12)
assert(max(abs(round(ymm,4)  - ymmText),  [], "all") < 1e-12)
assert(xmin == 1 && xmax == 7)
disp("教科書の例題「標準化と最小最大正規化」の値と一致")
vie.savetex("vie-04-std-x",   vie.arr2tex(xsd,"%d"));
vie.savetex("vie-04-std-n",   sprintf("%d",Nsd));
vie.savetex("vie-04-std-mu",  sprintf("%.4f",mu));
vie.savetex("vie-04-std-var", sprintf("%.4f",sigma2));
vie.savetex("vie-04-std-y",   vie.arr2tex(ystd,"%.4f"));
vie.savetex("vie-04-mm-min",  sprintf("%d",xmin));
vie.savetex("vie-04-mm-max",  sprintf("%d",xmax));
vie.savetex("vie-04-mm-y",    vie.arr2tex(ymm,"%.4f"));
%%
%[text] ## べき乗則変換
%[text] 実数 $ x\\in[0,1] $ では $ y=x^\\gamma $ ，整数 $ x\\in\\{0,1,\\ldots,L-1\\} $ では $ y=(L-1)\\left(\\frac{x}{L-1}\\right)^\\gamma $ 。 $ \\gamma<1 $ で明るく， $ \\gamma>1 $ で暗くなる。
%[text] （スライドでは教科書の図 2.3 を使う。この曲線群の図 vie-04-power-curves.png は参考として残す。）
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
%[text] 8-bit（ $ L=256 $ ）で $ x=64,\\ \\gamma=0.5 $ のとき（四捨五入）：
s = round(255*(64/255)^0.5)
vie.savetex("vie-04-pow-a", sprintf("%g",ypow(1)));
vie.savetex("vie-04-pow-b", sprintf("%g",ypow(2)));
vie.savetex("vie-04-pow-s", sprintf("%d",s));
%%
%[text] ## 暗い画像のべき乗則変換
%[text] 石像の顔 msipimg05（グレースケール）を $ x^3 $ で暗くした画像を用意し，べき乗則変換（ $ \\gamma=0.6,0.4,0.3 $ ）で明るくする。
S = im2double(vie.msipimg(5, 256, "gray")).^3;   % 暗い画像を作る
meanS = mean(S(:))                         % 平均画素値
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
%[text] 海岸 msipimg01（グレースケール）を $ 0.5+0.5x $ で明るく白っぽくした画像を用意し，べき乗則変換（ $ \\gamma=3,4,5 $ ）で暗くして濃淡を取り戻す。
A = im2double(vie.msipimg(1, 256, "gray"));
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
%[text] スイカ msipimg08（参考資料の図 2.5 と同じ画像．グレースケール， $ 256\\times256 $ ）から暗い・明るい・低対比・高対比の 4 種類の画像を作り，ヒストグラム（度数 $ h\_x $ ）を比べる。
C = vie.msipimg(8, 256, "gray");
Cd = im2uint8(0.45*im2double(C));                 % 暗い画像
Cb = im2uint8(0.55 + 0.45*im2double(C));          % 明るい画像
Cl = im2uint8(0.35 + 0.3*im2double(C));           % 低対比画像
Ch = histeq(C);                                   % 高対比画像
imgs = {Cd, Cb, Cl, Ch};
tags = ["dark","bright","low","high"];
hmaxAll = 6000;                                   % 縦軸をそろえる（スライド 15・18 のヒストグラム共通．最大度数 5506 を含む）
assert(max(cellfun(@(x) max(imhist(x)), [imgs {histeq(Cd,256), histeq(Cb,256)}])) <= hmaxAll)
for k = 1:4
    imwrite(imgs{k}, fullfile(resfolder,"vie-04-hist-"+tags(k)+".png"))
    h = imhist(imgs{k});
    [fig, ax] = slidefig(4.2, 3.2);               % スライド上の高さ 19 mm に近い大きさ
    histplot(ax, h, cMain, "画素値 {\itx}", "度数 {\ith}_{\itx}", hmaxAll)
    exportgraphics(fig, fullfile(resfolder,"vie-04-hist-"+tags(k)+"-h.png"), "Resolution", 300)
    close(fig)
end
%%
%[text] ## ヒストグラム均等化の例
%[text] 暗い画像と明るい画像にそれぞれヒストグラム均等化を施す。元の画像が違っても，結果のヒストグラムはどちらも一様に近く，似た画像になる。
Ed = histeq(Cd, 256); Eb = histeq(Cb, 256);
E = {Ed, Eb}; tg = ["dark","bright"];
for k = 1:2
    imwrite(E{k}, fullfile(resfolder,"vie-04-eq-"+tg(k)+".png"))
    h = imhist(E{k});
    [fig, ax] = slidefig(4.2, 3.2);
    histplot(ax, h, cMain, "画素値 {\ity}", "度数 {\ith}_{\ity}", hmaxAll)
    exportgraphics(fig, fullfile(resfolder,"vie-04-eq-"+tg(k)+"-h.png"), "Resolution", 300)
    close(fig)
end
psnrEq = psnr(Ed, Eb)                             % 均等化後の 2 枚はよく似ている
vie.savetex("vie-04-eq-psnr", sprintf("%.1f",psnrEq));
%%
%[text] ## 例題：ヒストグラム均等化
%[text] 教科書の例題「ヒストグラム均等化」。階調数 $ L=8 $ の $ 6\\times 8 $ 配列に，教科書の式
%[text]{"align":"center"} $ y=\\phi(x)=\\left\\lfloor (L-1)\\sum\_{v=0}^{x}p\_v \\right\\rceil,\\quad x\\in\\{0,1,\\ldots,L-1\\} $
%[text] でヒストグラム均等化を施す（ $ \\lfloor\\cdot\\rceil $ は小数点第 1 位の四捨五入による整数化）。手順は，(1) 度数 $ h\_x $ ，(2) 正規化度数 $ p\_x=h\_x/N $ ，(3) 参照表 $ \\phi $ ，(4) 出力配列 $ \\mathsf{y}=\\phi(\\mathsf{x}) $ の順。
xe = [2 2 3 1 2 4 1 1
      3 4 4 3 2 3 4 2
      4 4 4 3 4 5 5 4
      0 4 6 4 2 3 4 2
      2 2 2 3 5 1 3 3
      2 1 4 3 4 1 6 0];
L = 8;
N = numel(xe)                                     % 総画素数
hx = histcounts(xe, -0.5:1:L-0.5)                 % 度数 h_x（x=0,1,...,L-1）
px = hx/N                                         % 正規化度数 p_x
cum = (L-1)*cumsum(px)                            % (L-1)Σ_{v=0}^{x} p_v
phi = round(cum)                                  % 参照表 φ(x)（四捨五入）
ye = phi(xe+1)                                    % 出力配列 y=φ(x)（MATLAB の添え字は 1 始まり）
hy = histcounts(ye, -0.5:1:L-0.5)                 % 均等化後の度数
%[text] 教科書の度数分布表・画素値変換参照表・出力配列と照合する。
hText   = [2 6 11 10 14 3 2 0];
phiText = [0 1 3 4 6 7 7 7];
yText   = [3 3 4 1 3 6 1 1
           4 6 6 4 3 4 6 3
           6 6 6 4 6 7 7 6
           0 6 7 6 3 4 6 3
           3 3 3 4 7 1 4 4
           3 1 6 4 6 1 7 0];
assert(isequal(hx,hText) && isequal(phi,phiText) && isequal(ye,yText))
assert(abs(round(cum(1),4) - 0.2917) < 1e-12 && abs(round(cum(2),4) - 1.1667) < 1e-12 && abs(cum(end) - (L-1)) < 1e-12)
disp("教科書の例題「ヒストグラム均等化」の値と一致")
%[text] スライドの表に入れる数値を書き出す。正規化度数は分数で，度数が 0 のところは教科書と同じく 0 と書く。
pfrac = compose("$\\frac{%d}{%d}$", hx(:), repmat(N,L,1))';
pfrac(hx==0) = "0";
vie.savetex("vie-04-he-x",   vie.arr2tex(xe,"%d"));
vie.savetex("vie-04-he-n",   sprintf("%d\\times%d=%d", size(xe,1), size(xe,2), N));
vie.savetex("vie-04-he-h",   vie.arr2tex(hx,"%d"));
vie.savetex("vie-04-he-p",   strjoin(pfrac," & "));                 % 表の中で使うので $ で囲む
vie.savetex("vie-04-he-c",   vie.arr2tex(cum,"%.4f"));
vie.savetex("vie-04-he-phi", vie.arr2tex(phi,"%d"));
vie.savetex("vie-04-he-y",   vie.arr2tex(ye,"%d"));
vie.savetex("vie-04-he-hy",  vie.arr2tex(hy,"%d"));
%[text] 教科書の解答にある参照表の計算の途中式（ $ \\phi(0) $ ， $ \\phi(1) $ ， $ \\phi(L-1) $ ）も書き出す。
calc0 = sprintf("$\\phi(0)=\\msipround{%d\\times\\frac{%d}{%d}}=\\msipround{%.4f}=%d$", ...
    L-1, hx(1), N, cum(1), phi(1));
calc1 = sprintf("$\\phi(1)=\\msipround{%d\\times\\left(\\frac{%d}{%d}+\\frac{%d}{%d}\\right)}=\\msipround{%.4f}=%d$", ...
    L-1, hx(1), N, hx(2), N, cum(2), phi(2));
calcL = sprintf("$\\phi(%d)=\\msipround{%d\\times\\frac{%d}{%d}}=\\msipround{%.4f}=%d$", ...
    L-1, L-1, sum(hx), N, cum(end), phi(end));
vie.savetex("vie-04-he-calc", strjoin([calc0, calc1, "$\ldots$", calcL], "，\ "));
%[text] 均等化の前後の度数を棒グラフにする（縦軸をそろえる）。
hmax = 15;
[fig, ax] = slidefig(5.6, 4.0);                   % スライド上の幅 42 mm に近い大きさ
histbar(ax, 0:L-1, hx, hmax, cMain, "画素値 {\itx}", "度数 {\ith}_{\itx}")
exportgraphics(fig, fullfile(resfolder,"vie-04-he-hx.png"), "Resolution", 300)
close(fig)
[fig, ax] = slidefig(4.8, 3.6);                   % スライド上の幅 .25\textwidth に近い大きさ
histbar(ax, 0:L-1, hy, hmax, cMain, "画素値 {\ity}", "度数 {\ith}_{\ity}")
exportgraphics(fig, fullfile(resfolder,"vie-04-he-hy.png"), "Resolution", 300)
close(fig)
%%
%[text] ## カラー画像処理：明るさの調整
%[text] マカロン msipimg03（ $ 256\\times256 $ ）を明るくする。RGB 空間では R, G, B それぞれに $ \\gamma=0.4 $ のべき乗則変換を施す。HSV 空間では明度 V だけに施し，色相 H と彩度 S は保つ。
P = im2double(vie.msipimg(3, 256));
P = min(max(P, 0), 1);                        % 縮小時のオーバーシュートを [0,1] に収める
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
%[text] ## 擬似カラー
%[text] グレースケール画像の画素値 $ x\\in[0,1] $ を，位相をずらした三角波の参照表 $ \\vec{y}=(\\phi\_\\mathrm{R}(x)\\ \\ \\phi\_\\mathrm{G}(x)\\ \\ \\phi\_\\mathrm{B}(x))^\\top $ で色に対応づける（スカラー値を入力とするベクトル関数処理）。わずかな画素値の違いが色の違いとして強調される。曲線の色は R, G, B の各成分を表すので，ロゴの配色にはしない。
tri = @(x,ph) 1 - abs(2*mod(1.5*x + ph, 1) - 1);  % 周期 2/3 の三角波
[fig, ax] = slidefig(6.0, 3.9);                   % 凡例は曲線の上の余白に横並びで置く
plot(ax, xx, tri(xx,0), "Color", [0.85 0 0], "LineWidth", 2.2), hold(ax, "on")
plot(ax, xx, tri(xx,1/3), "Color", [0 0.6 0], "LineWidth", 2.2)
plot(ax, xx, tri(xx,2/3), "Color", [0 0 0.85], "LineWidth", 2.2), hold(ax, "off")
grid(ax, "on"), xlabel(ax, "画素値 {\itx}"), ylabel(ax, "出力")
ylim(ax, [0 1.42]), yticks(ax, 0:0.5:1), xticks(ax, 0:0.5:1)
set(ax, "FontSize", 9)
lg = legend(ax, ["\phi_{\rmR}({\itx})","\phi_{\rmG}({\itx})","\phi_{\rmB}({\itx})"], ...
    "Location","north", "Orientation","horizontal", "FontSize", 8);
lg.ItemTokenSize = [14 18];
exportgraphics(fig, fullfile(resfolder,"vie-04-pseudo-lut.png"), "Resolution", 300)
close(fig)
G = im2double(vie.msipimg(8, 256, "gray"));   % スイカ（グレースケール）
Yps = cat(3, tri(G,0), tri(G,1/3), tri(G,2/3));
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(G),   title("モノクロ画像")
nexttile, imshow(Yps), title("擬似カラー表示画像")
imwrite(G,   fullfile(resfolder,"vie-04-pseudo-org.png"))
imwrite(Yps, fullfile(resfolder,"vie-04-pseudo-out.png"))
%%
%[text] ## 例題：擬似カラー
%[text] $ 4\\times4 $ 配列 $ x\\in\\{0,1,2,3\\} $ を変換テーブル（R, G, B 各 2 bit）で擬似カラー表示する。変換テーブルの行が画素値 $ x=0,1,2,3 $ に対応する。
xq = [0 2 2 3; 1 1 1 2; 1 1 1 1; 1 1 1 0];
lut = [3 0 0; 0 3 0; 0 0 3; 3 0 3]                % 行 x=0,1,2,3 の (R,G,B)
lutName = ["赤","緑","青","マゼンタ"];            % 各行の色の名前
Yq = ind2rgb(uint8(xq), lut/3);                   % 配列 y（RGB，[0,1] に正規化）
%[text] 配列 $ \\mathsf{x} $ は，画素値を灰色の濃淡（0 が黒に近く，3 が白に近い）で表し，値を重ねて描く。配列 $ \\mathsf{y} $ は変換後の色で描く。
figure("Position",[100 100 300 300])
cellplot(repmat(0.1 + 0.8*xq/3, [1 1 3]), xq)
exportgraphics(gca, fullfile(resfolder,"vie-04-pseudo-ex-x.png"), "Resolution", 150)
clf
cellplot(Yq, [])
exportgraphics(gca, fullfile(resfolder,"vie-04-pseudo-ex.png"), "Resolution", 150)
close(gcf)
%[text] 変換テーブルと，各画素値の色の対応を書き出す。
nIdx = size(lut,1);                               % 画素値の種類（=4）
chName = ["R" "G" "B"];
lutRows = strings(1,3);                           % 表の行：成分名 & x=0,1,2,3 の値
for c = 1:3
    lutRows(c) = chName(c) + " & " + strjoin(string(lut(:,c))', " & ");
end
%[text] 色は教科書の記法どおり列ベクトル $ \\vec{y}=\\boldsymbol{\\phi}(x)=(y_\\mathrm{R}\\ y_\\mathrm{G}\\ y_\\mathrm{B})^\\top $ で書く。
mapItems = strings(1,nIdx);                       % 「φ(x) = (R G B)^T（色名）」
for k = 1:nIdx
    mapItems(k) = sprintf("$\\bmphi(%d)=\\tr{(%d\\ \\ %d\\ \\ %d)}$（%s）", ...
        k-1, lut(k,:), lutName(k));
end
vie.savetex("vie-04-pseudo-ex-idx", strjoin(string(0:nIdx-1), " & "));
vie.savetex("vie-04-pseudo-ex-lut", strjoin(lutRows, "\\" + newline));
vie.savetex("vie-04-pseudo-ex-map", strjoin(mapItems, "，"));
%%
%[text] ## まとめ
%[text] - 画素処理は全画素に同じスカラー関数 $ y=\\phi(x) $ を施す
%[text] - 標準化・最小最大正規化はスケール処理とバイアス処理の組み合わせ
%[text] - べき乗則変換は $ \\gamma<1 $ で明るく， $ \\gamma>1 $ で暗くする
%[text] - ヒストグラム均等化は正規化度数の累積和から参照表を自動で作る
%[text] - カラー画像は HSV（HSI）空間で明度・彩度を操作すると色あいを保てる \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
%%
%[text] ## ローカル関数
function [fig, ax] = slidefig(w, h)
%SLIDEFIG スライド上の大きさに近い物理サイズ（cm）の図と軸を作る
fig = figure(Units="centimeters", Position=[2 2 w h], Color="w");
ax = axes(fig);
end

function histplot(ax, h, color, xlab, ylab, hmax)
%HISTPLOT 256 階調のヒストグラムを棒グラフで描く（縦軸の上限 hmax を共通にして比べやすくする）
bar(ax, 0:255, h, 1, "EdgeColor","none", "FaceColor",color)
xlim(ax, [0 255]), ylim(ax, [0 hmax]), xticks(ax, [0 128 255]), yticks(ax, 0:2000:hmax)
set(ax, "FontSize", 8)
xlabel(ax, xlab), ylabel(ax, ylab)
end

function histbar(ax, v, h, hmax, color, xlab, ylab)
%HISTBAR 度数の棒グラフを，棒の上に度数を添えて描く
bar(ax, v, h, 0.7, "FaceColor", color, "EdgeColor", "none")
text(ax, v, h, string(h), "HorizontalAlignment", "center", ...
    "VerticalAlignment", "bottom", "FontSize", 9)
xlim(ax, [v(1)-0.7 v(end)+0.7]), ylim(ax, [0 hmax]), xticks(ax, v)
box(ax, "off")
xlabel(ax, xlab), ylabel(ax, ylab), set(ax, "FontSize", 9)
end

function cellplot(rgb, labels)
%CELLPLOT 配列を升目として描く（LABELS が空でなければ値を重ねる）
[nr, nc, ~] = size(rgb);
image(rgb), axis image off, hold on
for k = 0.5:nc+0.5
    plot([k k], [0.5 nr+0.5], "k", "LineWidth", 1.5)
end
for k = 0.5:nr+0.5
    plot([0.5 nc+0.5], [k k], "k", "LineWidth", 1.5)
end
if ~isempty(labels)
    for i = 1:nr
        for j = 1:nc
            txtColor = [1 1 1]*(mean(rgb(i,j,:)) < 0.5);   % 暗い升目は白字
            text(j, i, string(labels(i,j)), "HorizontalAlignment", "center", ...
                "FontSize", 30, "Color", txtColor)
        end
    end
end
hold off
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
