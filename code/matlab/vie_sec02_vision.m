%[text] # 第2回 視覚特性と画像入出力
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第2回のスライド（vie2026-02）で使う図と数値を作る。視覚特性のデモ画像，網膜像の大きさ，視力と走査線数，量子化，RGB 成分，フレームレートとビットレート，アレイセンサによる標本化，ベイヤ配列を順に扱う。
%[text] 記号は教科書（村松正吾『多次元信号・画像処理の基礎と展開』）に合わせる。図の配色は MSIP Lab のロゴの 3 色（緑 #008855，青 #2E75B6，橙 #C55A11）と灰色を使う（色そのものが内容の画像は除く）。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] Kodak Lossless True Color Image Suite の画像を `data` フォルダに取得する（取得済みなら何もしない）。
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
%[text] 図に使うロゴの 3 色と，それを白と混ぜた淡い色を用意する。
cMain = [0 136 85]/255;            % メイン（緑）
cCool = [46 117 182]/255;          % 寒色系（青）
cWarm = [197 90 17]/255;           % 暖色系（橙）
cCoolLight = 0.35*cCool + 0.65;    % 寒色系の塗り
%%
%[text] ## 視覚特性のデモ：明度対比
%[text] 背景の明るさだけを変え，中央の正方形は**同じ画素値**にする。同じ明るさなのに，背景が暗いほど明るく見える。
bg  = [0 0.4 0.8];          % 背景の明るさ（黒・灰・明るい灰）
fg  = 0.55;                 % 中央の正方形の明るさ（3 枚とも同じ）
sz  = 120; w = 50;
panels = cell(1,numel(bg));
for k = 1:numel(bg)
    P = bg(k)*ones(sz);
    P((sz-w)/2+1:(sz+w)/2, (sz-w)/2+1:(sz+w)/2) = fg;
    panels{k} = P;
end
C = [panels{1} ones(sz,20) panels{2} ones(sz,20) panels{3}];
imshow(C)
%[text] 中央の画素値を確かめると，3 枚ともまったく同じである。
centers = cellfun(@(P) P(sz/2,sz/2), panels)
imwrite(C, fullfile(resfolder,"vie-02-contrast.png"))
vie.savetex("vie-02-contrast-fg", sprintf("%.2f",fg));
%%
%[text] ## 視覚特性のデモ：色順応
%[text] 左に青みがかった画像，右に黄みがかった画像を並べ，間に白い点を置く。白い点をしばらく見つめると，目が色に順応する。
X = im2double(imread(fullfile(datfolder,"kodim04.png")));
X = imresize(X, 0.5);
tintB = X .* reshape([0.55 0.65 1.00],1,1,3);    % 青みがかった画像
tintY = X .* reshape([1.00 0.90 0.45],1,1,3);    % 黄みがかった画像
gap = zeros(size(X,1), 24, 3);
D = [tintB gap tintY];
r = round(size(D,1)/2); c = size(X,2) + 12;       % 白い点の位置（中央）
[cc,rr] = meshgrid(1:size(D,2), 1:size(D,1));
D(repmat((cc-c).^2 + (rr-r).^2 <= 16, [1 1 3])) = 1;
imshow(D)
imwrite(D, fullfile(resfolder,"vie-02-adapt.png"))
%%
%[text] ## 網膜像の大きさ
%[text] 100 m 先にある高さ 15 m の木を見るとき，水晶体の中心から網膜までを約 17 mm とすると，網膜像の高さ $ h $ は相似な三角形から求まる。
%[text]{"align":"center"} $ \\frac{15}{100} = \\frac{h}{17} $
treeH = 15; treeDist = 100; lensToRetina = 17;   % [m], [m], [mm]
h = lensToRetina*treeH/treeDist                  % 網膜像の高さ [mm]
vie.savetex("vie-02-retina", sprintf("%.2f",h));
%%
%[text] ## 視力と解像度
%[text] **視力**は，隣接する 2 点を弁別できる最小視角の逆数である（視力 = 1/視角〔分〕）。視力 $ V $ の人は $ 1/V $ 分（1 分 = 1/60 度）の視角を見分けられる。
%[text] 画面の高さを $ h $ とし，画面高の 3 倍の距離 $ d=3h $ からテレビを見る（2025 年度の演習課題（2）-2 と同じ設定）。画面の上端と下端が目につくる視角 $ \\theta $ は，直角三角形 2 つに分けて
%[text]{"align":"center"} $ \\theta = 2\\tan^{-1}\\frac{h/2}{d} = 2\\tan^{-1}\\frac{h/2}{3h} = 2\\tan^{-1}\\frac{1}{6} $
dh = 3;                           % 視距離と画面高の比 d/h
theta = 2*atand(0.5/dh)           % 視角 [度]
arcmin = theta*60                 % 視角 [分]
%[text] 視力 $ V $ の人は $ 1/V $ 分ずつ見分けられるので，画面の縦方向に必要な走査線の数は，視角 $ \\theta $〔分〕を $ 1/V $〔分〕で割った値が目安になる。
V = 1;                            % 視力
nlines = arcmin/(1/V)             % 走査線数の目安 [本]
%[text] 視力 1 なら約 1135 本。ハイビジョン（有効走査線数 1080 本）の走査線数の目安になる。
vie.savetex("vie-02-acuity-deg",   sprintf("%.1f",theta));
vie.savetex("vie-02-acuity-min",   sprintf("%.0f",arcmin));
vie.savetex("vie-02-acuity-lines", sprintf("%.0f",nlines));
%[text] 位置関係を縮尺どおりに描く（2025 年度の演習課題（2）-2 の図を参考）。画面の高さを $ h=1 $ とし，目の節点（光線が交わる点）を画面から $ d=3h $ の位置に置く。
figure("Position",[100 100 600 230],"Color","w")
hold on
th = theta*pi/180;                            % 視角 [rad]
node = [dh 0];                                % 目の節点
% 画面（高さ h）
patch([-0.07 0 0 -0.07], [-0.5 -0.5 0.5 0.5], cCoolLight, "EdgeColor",cCool, "LineWidth",1.5)
% 眼球と水晶体
tt = linspace(0,2*pi,200);
plot(dh+0.30+0.42*cos(tt), 0.42*sin(tt), "Color",cMain, "LineWidth",3)
plot(dh-0.10+0.055*cos(tt), 0.17*sin(tt), "Color",cMain, "LineWidth",2)
% 画面の上端・下端から節点を通って網膜へ向かう光線
xe = dh + 0.62;
plot([0 xe], [0.5 0.5-xe/(2*dh)], "Color",[0.3 0.3 0.3], "LineWidth",1)
plot([0 xe], [-0.5 -0.5+xe/(2*dh)], "Color",[0.3 0.3 0.3], "LineWidth",1)
plot(node(1), node(2), "o", "MarkerSize",6, "MarkerFaceColor",cMain, "MarkerEdgeColor",cMain)
% 視角 θ の円弧
ra = 1.0;
ta = linspace(pi-th/2, pi+th/2, 50);
plot(node(1)+ra*cos(ta), node(2)+ra*sin(ta), "Color",cWarm, "LineWidth",2.5)
text(node(1)-ra-0.08, 0, "$\theta$", "Interpreter","latex", "FontSize",28, ...
    "Color",cWarm, "HorizontalAlignment","right")
% 寸法線 h と d = 3h
plot([-0.45 -0.1], [0.5 0.5], "Color",[0.5 0.5 0.5]), plot([-0.45 -0.1], [-0.5 -0.5], "Color",[0.5 0.5 0.5])
dimarrow([-0.32 -0.5], [-0.32 0.5], "k")
text(-0.40, 0, "$h$", "Interpreter","latex", "FontSize",28, "HorizontalAlignment","right")
plot([0 0], [-0.55 -0.85], "Color",[0.5 0.5 0.5]), plot([dh dh], [-0.1 -0.85], "Color",[0.5 0.5 0.5])
dimarrow([0 -0.75], [dh -0.75], "k")
text(dh/2, -0.75, "$d=3h$", "Interpreter","latex", "FontSize",28, ...
    "HorizontalAlignment","center", "VerticalAlignment","middle", "BackgroundColor","w")
hold off
axis equal off
xlim([-0.75 3.85]), ylim([-0.95 0.6])
exportgraphics(gcf, fullfile(resfolder,"vie-02-acuity-geom.png"), "Resolution",200)
%%
%[text] ## 階調と量子化
%[text] 量子化は振幅の離散化である。教科書 2.1.6 項の**線形量子化**は，量子化ステップ $ Q $ を用いて
%[text]{"align":"center"} $ y=\\phi(x)=\\lfloor x/Q \\rceil,\\quad \\check{x}=Qy $
%[text] と表される（ $ \\lfloor\\cdot\\rceil $ は四捨五入， $ \\check{x} $ は逆量子化の結果）。画素値 $ x\\in[0,1] $ を $ L=2^\\beta $ 階調で表すときは $ Q=(2^\\beta-1)^{-1} $ とする。 $ \\beta $ を小さくすると，緩やかな濃淡に**擬似輪郭**が現れる。
Xg = im2double(imread("cameraman.tif"));
betas = [1 2 8];                                 % 1 画素あたりのビット数 β
emax = zeros(size(betas));
tiledlayout(2,numel(betas),"TileSpacing","compact","Padding","compact")
for k = 1:numel(betas)
    L = 2^betas(k);                              % 階調数
    Q = 1/(L-1);                                 % 量子化ステップ
    y = round(Xg/Q);                             % 線形量子化（整数 0,1,…,L-1）
    Xq = Q*y;                                    % 逆量子化
    e = Xg - Xq;                                 % 量子化誤差
    emax(k) = max(abs(e(:)));
    nexttile(k), imshow(Xq), title(sprintf("%d 階調（%d bit）",L,betas(k)))
    nexttile(k+numel(betas)), imshow(abs(e)/(Q/2)), title("|誤差|（Q/2 で正規化）")
    imwrite(Xq, fullfile(resfolder,sprintf("vie-02-quant-%d.png",betas(k))))
end
levels = 2.^betas
%[text] 四捨五入なので，量子化誤差の大きさは $ Q/2 $ を超えない。
table(betas', levels', 1./(levels'-1), emax', 'VariableNames',["β","階調数","Q","max|e|"])
%[text] 量子化特性（入力 $ x $ と逆量子化の結果 $ \\check{x} $ の関係）を $ \\beta=2 $（4 階調）について描くと階段状になる。破線は $ \\check{x}=x $。
figure("Position",[100 100 330 300],"Color","w")
beta2 = 2; Q2 = 1/(2^beta2-1);
xx = linspace(0,1,3001);
plot(xx, xx, "--", "Color",[0.55 0.55 0.55], "LineWidth",1.2)
hold on
plot(xx, Q2*round(xx/Q2), "Color",cMain, "LineWidth",3)
% 量子化ステップ Q を示す矢印（破線と交わらない位置に置く）
dimarrow([0.76 Q2], [0.76 2*Q2], cWarm, 0.045, 0.018)
text(0.73, 1.5*Q2, "$Q$", "Interpreter","latex", "FontSize",22, ...
    "Color",cWarm, "HorizontalAlignment","right")
hold off
axis square, grid on, box on
xlim([0 1]), ylim([0 1])
tk = (0:2^beta2-1)*Q2;
set(gca, "XTick",tk, "YTick",tk, "TickLabelInterpreter","latex", "FontSize",18, ...
    "XTickLabel",["$0$","$Q$","$2Q$","$3Q$"], "YTickLabel",["$0$","$Q$","$2Q$","$3Q$"])
xlabel("$x$", "Interpreter","latex", "FontSize",22)
ylabel("$\check{x}=Q\lfloor x/Q\rceil$", "Interpreter","latex", "FontSize",22)
exportgraphics(gcf, fullfile(resfolder,"vie-02-quant-curve.png"), "Resolution",200)
%%
%[text] ## 色の表し方：RGB 表色系
%[text] 色 $ C $ を 3 原色の単位ベクトル $ \\mathbf{e}\_\\mathrm{r},\\mathbf{e}\_\\mathrm{g},\\mathbf{e}\_\\mathrm{b} $ のベクトル和で表す。
%[text]{"align":"center"} $ C = R\\,\\mathbf{e}\_\\mathrm{r} + G\\,\\mathbf{e}\_\\mathrm{g} + B\\,\\mathbf{e}\_\\mathrm{b} $
Y = im2double(imread(fullfile(datfolder,"kodim23.png")));
Y = imresize(Y, 0.5);
Z = zeros(size(Y,1),size(Y,2));
Yr = cat(3,Y(:,:,1),Z,Z); Yg = cat(3,Z,Y(:,:,2),Z); Yb = cat(3,Z,Z,Y(:,:,3));
tiledlayout(1,4,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Y),  title("フルカラー")
nexttile, imshow(Yr), title("R")
nexttile, imshow(Yg), title("G")
nexttile, imshow(Yb), title("B")
imwrite(Y,  fullfile(resfolder,"vie-02-rgb-full.png"))
imwrite(Yr, fullfile(resfolder,"vie-02-rgb-r.png"))
imwrite(Yg, fullfile(resfolder,"vie-02-rgb-g.png"))
imwrite(Yb, fullfile(resfolder,"vie-02-rgb-b.png"))
%[text] ひとつの画素を取り出すと，3 つの数の組になっている。
pr = 170; pc = 280;                % 右のオウムの赤い胸のあたり
rgb = squeeze(Y(pr,pc,:))'
vie.savetex("vie-02-rgb-pix", sprintf("R=%.2f,\\ G=%.2f,\\ B=%.2f", rgb));
%%
%[text] ## フレームレート
%[text] フレームレート $ \\Delta\_\\mathrm{t}^{-1} $（fps）は 1 秒あたりのフレーム数。フレーム間隔 $ \\Delta\_\\mathrm{t} $ はその逆数である。
fps = [30 24];                     % テレビ，映画
interval = 1000./fps               % フレーム間隔 [ms]
vie.savetex("vie-02-fps-tv",    sprintf("%.1f",interval(1)));
vie.savetex("vie-02-fps-movie", sprintf("%.1f",interval(2)));
%%
%[text] ## 動画像のビットレート（教科書 1.1.2 項の例題）
%[text] 画素数 $ N\_1\\times N\_2=4320\\times 7680 $，フレーム間隔 $ \\Delta\_\\mathrm{t}=1/60 $ s，一配列要素あたり $ \\beta=8 $ bits の RGB カラー動画像のビットレート $ R $ を求める。1 フレームあたりのビット数は
%[text]{"align":"center"} $ B=3\\beta N\_1N\_2 $
%[text] で，これにフレームレート $ \\Delta\_\\mathrm{t}^{-1} $ を掛けると $ R=B\\Delta\_\\mathrm{t}^{-1} $ [bps] になる。
N1 = 4320; N2 = 7680;              % 画素数（8K）
nbits = 8;                         % β（組み込み関数 beta と区別するため変数名は nbits）
frameRate = 60;                    % フレームレート 1/Δt [1/s]
bpp = 3*nbits                      % 1 画素あたりのビット数 [bpp]
Npix = N1*N2                       % 1 フレームあたりの画素数
Bframe = 3*nbits*N1*N2             % 1 フレームあたりのビット数 [bits/frame]
Rbps = Bframe*frameRate            % ビットレート [bps]
RGbps = Rbps/1e9                   % [Gbps]
%[text] 教科書の解答（ $ B=796262400 $ bits/frame， $ R=47775744000 $ bps $ \\simeq 48 $ Gbps）と一致することを確かめる。
assert(Bframe == 796262400 && Rbps == 47775744000, "教科書の値と一致しない")
vie.savetex("vie-02-rate-B",  vie.fmtint(Bframe));
vie.savetex("vie-02-rate-R",  vie.fmtint(Rbps));
vie.savetex("vie-02-rate-RG", sprintf("%.0f",RGbps));
%%
%[text] ## 画像の取得：アレイセンサによる標本化
%[text] 教科書 1.4.1 項の例「アレイセンサ」では，センサ上に結像した光の強度分布 $ u(q\_\\mathrm{v},q\_\\mathrm{h}) $ から，撮像装置の点光源応答 $ \\breve{\\varphi} $ を介して，標本間隔 $ \\Delta\_\\mathrm{v},\\Delta\_\\mathrm{h} $ ごとに配列の要素を得る。
%[text]{"align":"center"} $ x[n\_\\mathrm{v},n\_\\mathrm{h}]=\\iint\_{\\mathbb{R}^2}\\breve{\\varphi}(\\Delta\_\\mathrm{v}n\_\\mathrm{v}-q\_\\mathrm{v},\\Delta\_\\mathrm{h}n\_\\mathrm{h}-q\_\\mathrm{h})\\,u(q\_\\mathrm{v},q\_\\mathrm{h})\\,\\mathrm{d}q\_\\mathrm{v}\\mathrm{d}q\_\\mathrm{h} $
%[text] ここでは高解像度の画像を連続な強度分布とみなし， $ \\breve{\\varphi} $ を一辺 $ \\Delta $ 画素の矩形（受光面の中で光を平均する）として，標本間隔 $ \\Delta=\\Delta\_\\mathrm{v}=\\Delta\_\\mathrm{h} $ を広げたときの観測をまねる。標本間隔が広いほど細部が失われる。
Xs = rgb2gray(im2double(imread(fullfile(datfolder,"kodim23.png"))));
deltas = [1 4 8];                                % 標本間隔 Δ（元の画素単位）
tiledlayout(1,numel(deltas),"TileSpacing","compact","Padding","compact")
for k = 1:numel(deltas)
    dlt = deltas(k);
    nv = floor(size(Xs,1)/dlt); nh = floor(size(Xs,2)/dlt);
    blocks = reshape(Xs(1:nv*dlt,1:nh*dlt), dlt, nv, dlt, nh);
    Xa = squeeze(mean(blocks,[1 3]));            % Δ×Δ の受光面で平均して標本化
    nexttile, imshow(imresize(Xa, dlt, "nearest"))
    title(sprintf("Δ = %d（%d×%d 画素）", dlt, nv, nh))
end
%%
%[text] ## カラー撮像：単板式（原色ベイヤ形）
%[text] 単板式では，感光部の前に色フィルタを市松状に並べる。ひとつの画素は R, G, B のどれか 1 色しか測れない。2×2 画素のうち G が 2 つ，R と B が 1 つずつである。
Nsens = 4000*3000;                 % 例：約 1200 万画素のセンサ
counts = Nsens*[1/4 1/2 1/4]       % R, G, B の画素数
vie.savetex("vie-02-bayer-n", sprintf("%d", Nsens/1e4));
vie.savetex("vie-02-bayer-r", sprintf("%d", counts(1)/1e4));
vie.savetex("vie-02-bayer-g", sprintf("%d", counts(2)/1e4));
%[text] 欠けた色は周囲から補間する（デモザイキング）。原画像からベイヤ配列の観測を作り，MATLAB の `demosaic` で戻してみる。
crop = im2uint8(Y(41:120, 61:140, :));            % 一部を切り出す
mosaic = zeros(size(crop,1),size(crop,2),"uint8");
mosaic(1:2:end,1:2:end) = crop(1:2:end,1:2:end,1);    % R
mosaic(1:2:end,2:2:end) = crop(1:2:end,2:2:end,2);    % G
mosaic(2:2:end,1:2:end) = crop(2:2:end,1:2:end,2);    % G
mosaic(2:2:end,2:2:end) = crop(2:2:end,2:2:end,3);    % B
recon = demosaic(mosaic, "rggb");
%[text] 観測されたベイヤ配列を色つきで表示するため，各画素をその色のチャネルにだけ置く。
bayerRGB = zeros(size(crop),"uint8");
bayerRGB(1:2:end,1:2:end,1) = mosaic(1:2:end,1:2:end);
bayerRGB(1:2:end,2:2:end,2) = mosaic(1:2:end,2:2:end);
bayerRGB(2:2:end,1:2:end,2) = mosaic(2:2:end,1:2:end);
bayerRGB(2:2:end,2:2:end,3) = mosaic(2:2:end,2:2:end);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(crop),     title("原画像")
nexttile, imshow(bayerRGB), title("ベイヤ配列の観測")
nexttile, imshow(recon),    title("デモザイキング後")
imwrite(imresize(crop,3,"nearest"),     fullfile(resfolder,"vie-02-bayer-org.png"))
imwrite(imresize(bayerRGB,3,"nearest"), fullfile(resfolder,"vie-02-bayer-obs.png"))
imwrite(imresize(recon,3,"nearest"),    fullfile(resfolder,"vie-02-bayer-rec.png"))
psnrBayer = psnr(recon, crop)
vie.savetex("vie-02-bayer-psnr", sprintf("%.1f",psnrBayer));
%%
%[text] ## まとめ
%[text] - 明るさの知覚は周囲の影響を受ける（明度対比）。同じ画素値でも同じに見えるとは限らない
%[text] - 網膜像は数 mm。視力 1 は 1 分の視角を見分ける能力で，画面高の 3 倍の距離なら走査線数の目安は約 1135 本
%[text] - 線形量子化 $ y=\\lfloor x/Q\\rceil $ の階調が少ないと擬似輪郭が現れる
%[text] - 動画像のビットレートは $ R=3\\beta N\_1N\_2\\Delta\_\\mathrm{t}^{-1} $。8K・60 fps・8 bits なら約 48 Gbps
%[text] - カラー画像は R, G, B の 3 成分の組。単板式カメラは 1 画素 1 色しか測らず，残りを補間する \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
%%
%[text] ## ローカル関数
function dimarrow(p1,p2,col,hl,hw)
%DIMARROW 両端に矢じりのある寸法線を p1 から p2 へ描く（データ座標）
%   hl, hw は矢じりの長さと半幅（データ単位，省略時 0.07 と 0.03）
arguments
    p1 (1,2) double
    p2 (1,2) double
    col
    hl (1,1) double = 0.07
    hw (1,1) double = 0.03
end
u = (p2-p1)/norm(p2-p1);          % 向き
nv = [-u(2) u(1)];                % 法線
plot([p1(1) p2(1)], [p1(2) p2(2)], "Color",col, "LineWidth",1.2)
tip = [p1; p2]; dirs = [-u; u];
for k = 1:2
    base = tip(k,:) - hl*dirs(k,:);
    v = [tip(k,:); base+hw*nv; base-hw*nv];
    patch(v(:,1), v(:,2), col, "EdgeColor",col)
end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
