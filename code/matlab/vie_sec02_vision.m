%[text] # 第2回 視覚特性と画像入出力
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第2回のスライド（vie2026-02）で使う図と数値を作る。視覚特性のデモ画像，網膜像の大きさ，視力と走査線数，量子化，RGB 成分，フレームレート，ベイヤ配列を順に扱う。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] Kodak Lossless True Color Image Suite の画像を `data` フォルダに取得する（取得済みなら何もしない）。
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
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
H = 15; L = 100; f = 17;         % [m], [m], [mm]
h = f*H/L                         % 網膜像の高さ [mm]
vie.savetex("vie-02-retina", sprintf("%.2f",h));
%%
%[text] ## 視力と解像度
%[text] 視力は「隣り合うふたつの点を識別する能力」で，**視力 = 1/視角（分）**。視力 1 なら 1 分（1/60 度）の視角を見分けられる。
%[text] 画面高の 3 倍の距離からテレビを見ると，画面の上端と下端がなす視角は次のとおり。
theta = 2*atand(0.5/3)            % 視角 [度]
arcmin = theta*60                 % 視角 [分]
%[text] 視力 1 の人が 1 分ずつ見分けられるので，画面の縦方向に必要な走査線数は約 1140 本。これがハイビジョンの走査線数（1080 本）の目安になる。
vie.savetex("vie-02-acuity-deg", sprintf("%.1f",theta));
vie.savetex("vie-02-acuity-min", sprintf("%.0f",arcmin));
%%
%[text] ## 階調と量子化
%[text] 振幅を $ 2^\\beta $ 段階に離散化する。 $ \\beta $ を小さくすると，緩やかな濃淡に**擬似輪郭**が現れる。
Xg = im2double(imread("cameraman.tif"));
betas = [1 2 8];
tiledlayout(1,numel(betas),"TileSpacing","compact","Padding","compact")
for k = 1:numel(betas)
    L = 2^betas(k);                              % 階調数
    Xq = round(Xg*(L-1))/(L-1);                  % 線形量子化（0〜1 を L 段に）
    nexttile, imshow(Xq), title(sprintf("%d 階調（%d bit）",L,betas(k)))
    imwrite(Xq, fullfile(resfolder,sprintf("vie-02-quant-%d.png",betas(k))))
end
levels = 2.^betas
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
%[text] フレームレート（fps）は 1 秒あたりのフレーム数。フレーム間隔はその逆数である。
fps = [30 24];                     % テレビ，映画
interval = 1000./fps               % フレーム間隔 [ms]
vie.savetex("vie-02-fps-tv",    sprintf("%.1f",interval(1)));
vie.savetex("vie-02-fps-movie", sprintf("%.1f",interval(2)));
%%
%[text] ## カラー撮像：単板式（原色ベイヤ形）
%[text] 単板式では，感光部の前に色フィルタを市松状に並べる。ひとつの画素は R, G, B のどれか 1 色しか測れない。2×2 画素のうち G が 2 つ，R と B が 1 つずつである。
Nsens = 4000*3000;                 % 例：約 1200 万画素のセンサ
counts = Nsens*[1/4 1/2 1/4]       % R, G, B の画素数
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
%[text] - 網膜像は数 mm。視力 1 は 1 分の視角を見分ける能力で，走査線数の目安になる
%[text] - 階調が少ないと擬似輪郭が現れる
%[text] - カラー画像は R, G, B の 3 成分の組。単板式カメラは 1 画素 1 色しか測らず，残りを補間する \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
