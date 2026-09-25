%[text] # 第2回 視覚と工学：解像度と階調
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2025b
%[text]
%[text] 視覚特性が画像の設計をどう縛るかを，二つの軸で確かめる．
%[text] **空間解像度**を落とすと形が失われ，**階調（量子化ビット数）**を落とすと
%[text] 滑らかな濃淡に\_擬似輪郭\_（false contour）が現れる．
%[text] スライド（vie2026-02）の図を生成する．
%[text] ## 準備
[datfolder,resfolder] = vie.prjfolders();
myfilename = "vie_sec02_resolution";

imgname = "kodim19";        % Kodak Lossless True Color Image Suite
vie.download_img(false)
%%
%[text] ## 画像データの読込
%[text] グレースケール化して $256\times 256$ に整える．
X = im2double(rgb2gray(imread(fullfile(datfolder,imgname+".png"))));
X = imresize(X(1:512,1:512),[256 256],"bilinear");
figure(1), imshow(X), title("原画像 256×256, 8 bits")
imwrite(X,fullfile(resfolder,"vie-02-org.png"))
%%
%[text] ## 空間解像度を落とす
%[text] 標本化間隔を $2^k$ 倍に広げて間引き，表示のために最近傍補間で元の大きさに戻す．
%[text] 間引く前に平滑化していないので，細部は\_エイリアシング\_を伴って失われる（第8回）．
szOrg = size(X);
decFactors = [2 8 32];
figure(2)
for idx = 1:numel(decFactors)
    M = decFactors(idx);
    Xd = X(1:M:end,1:M:end);                       % 間引き処理
    Xr = imresize(Xd,szOrg,"nearest");             % 表示用に拡大
    subplot(1,numel(decFactors),idx)
    imshow(Xr)
    title(sprintf("%d×%d",size(Xd,1),size(Xd,2)))
    imwrite(Xr,fullfile(resfolder, ...
        sprintf("vie-02-resolution-%c.png",'a'+idx-1)))
end
%%
%[text] ## 階調を落とす
%[text] 一画素あたりのビット数 $\beta$ で線形量子化する．
%[text]  $x_Q = \Delta\left\lfloor x/\Delta \right\rfloor$， $\Delta = 2^{-\beta}$
%[text] $\beta$ が小さいほど段差が粗くなり，空や壁のような緩やかな濃淡で擬似輪郭が目立つ．
betas = [4 3 2];
figure(3)
for idx = 1:numel(betas)
    beta = betas(idx);
    delta = 2^(-beta);
    Xq = min(floor(X/delta)*delta + delta/2, 1);   % 線形量子化＋復号
    subplot(1,numel(betas),idx)
    imshow(Xq)
    title(sprintf("%d bits (%d 階調)",beta,2^beta))
    imwrite(Xq,fullfile(resfolder, ...
        sprintf("vie-02-quantization-%c.png",'a'+idx-1)))
end
%%
%[text] ## 擬似輪郭を見やすくする
%[text] 一様な傾斜（ランプ）を量子化すると，擬似輪郭が最もはっきり出る．
%[text] スライドに横長で載せるため，帯を積み重ねた1枚の画像として書き出す
%[text] （図の枠や余白が入らないよう imwrite を使う．見出しはスライド側で付ける）．
ramp = repmat(linspace(0,1,512),40,1);
sep  = ones(3,512);                                % 帯の区切り（白線）
strips = ramp;
for beta = [5 4 3]
    delta = 2^(-beta);
    strips = [strips; sep; min(floor(ramp/delta)*delta + delta/2, 1)]; %#ok<AGROW>
end
figure(4), imshow(strips)
title("上から 連続階調 / 5 / 4 / 3 bits")
imwrite(strips,fullfile(resfolder,"vie-02-falsecontour.png"))
fprintf("擬似輪郭の図: %s\n", mat2str(size(strips)));
%%
%[text] ## 出力の確認
disp(string({dir(fullfile(resfolder,"vie-02-*.png")).name}'))
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
