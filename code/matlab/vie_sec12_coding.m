%[text] # 第12回 画像・映像符号化
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第12回のスライド（vie2026-12）で使う図と数値を作る。ハフマン符号化，線形 PCM（線形再量子化），PSNR，予測符号化（DPCM），動き補償予測，色差サブサンプリング，変換符号化（符号化利得，JPEG の量子化テーブル），ジグザグスキャンを扱う。記号は教科書に合わせる（量子化ステップ $ Q $ ，予測 $ \\hat{x} $ ，予測誤差 $ d $ ）。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
X8 = double(imread("cameraman.tif"));          % 8 bit（0〜255）
[N1,N2] = size(X8);
%%
%[text] ## ハフマン符号化（教科書の例題）
%[text] シンボル $ \\{0,1,2,3\\} $ の出現確率 $ (0.6,0.25,0.1,0.05) $ に対し，符号語 $ (0,10,110,111) $ 。平均符号長とエントロピー（圧縮の下限）を求める。
p = [0.6 0.25 0.1 0.05];
len = [1 2 3 3];
Lavg = sum(p.*len)                              % 平均符号長
H = -sum(p.*log2(p))                            % エントロピー
vie.savetex("vie-12-huff-L", sprintf("%.2f", Lavg));
vie.savetex("vie-12-huff-H", sprintf("%.2f", H));
%[text] シンボル列を 2 進数（2 bit 固定長）とハフマン符号語で表す。
seq = [0 3 1 0 0 0 0 0 1 2 1 0 0 0 1 1 0 0 0 2];
code = ["0","10","110","111"];
bin  = ["00","01","10","11"];
sHuff = strjoin(code(seq+1), "");
sBin  = strjoin(bin(seq+1), "");
nbits = [strlength(sBin) strlength(sHuff)]
vie.savetex("vie-12-huff-bin",  sBin);
vie.savetex("vie-12-huff-code", sHuff);
vie.savetex("vie-12-huff-nbin",  sprintf("%d", nbits(1)));
vie.savetex("vie-12-huff-ncode", sprintf("%d", nbits(2)));
%%
%[text] ## 線形 PCM 符号化（線形再量子化）
%[text] 8 bit の画素値を量子化ステップ $ Q $ で $ s[\\boldsymbol{n}]=\\lfloor x[\\boldsymbol{n}]/Q \\rfloor $ と量子化し， $ \\hat{x}[\\boldsymbol{n}]=Q\\,s[\\boldsymbol{n}]+Q/2 $ で戻す（区間の中央）。 $ Q=8,16 $ で比べる。
Qs = [8 16];
psnrPCM = zeros(size(Qs));
for i = 1:numel(Qs)
    Q = Qs(i);
    s = floor(X8/Q);
    Xh = Q*s + Q/2;
    psnrPCM(i) = psnr(Xh, X8, 255);
    imwrite(uint8(Xh), fullfile(resfolder,sprintf("vie-12-pcm-q%02d.png", Q)))
    vie.savetex(sprintf("vie-12-pcm-psnr%02d", Q), sprintf("%.2f", psnrPCM(i)));
end
psnrPCM
imwrite(uint8(X8), fullfile(resfolder,"vie-12-org.png"))
%[text] 1 bit 減らすごとに PSNR は約 6 dB 下がる（教科書 7.3.1 項 例題）。
dPSNR = psnrPCM(1) - psnrPCM(2)
%%
%[text] ## PSNR の数値例（前回スライドの例題）
%[text] 2 bit（ピーク値 $ 2^2-1=3 $ ）の $ 4\\times4 $ 配列どうしの PSNR。
Xa = [0 1 1 0; 1 2 3 1; 1 3 2 1; 0 1 1 0];
Xb = [0 1 1 1; 1 3 0 1; 1 2 2 1; 2 1 1 0];
mse = mean((Xa(:) - Xb(:)).^2)
psnrEx = 10*log10(3^2/mse)
vie.savetex("vie-12-psnr-a", vie.arr2tex(Xa,"%d"));
vie.savetex("vie-12-psnr-b", vie.arr2tex(Xb,"%d"));
vie.savetex("vie-12-psnr-mse", sprintf("%g", mse));
vie.savetex("vie-12-psnr-val", sprintf("%.2f", psnrEx));
%%
%[text] ## 予測符号化（DPCM）
%[text] 水平方向の一つ前の復号済み画素から $ \\hat{x}[n]=\\rho\\,\\check{x}[n-1] $ （ $ \\rho=0.95 $ ）と予測し，予測誤差 $ d=x-\\hat{x} $ を $ Q=16 $ で量子化する（四捨五入）。符号化器の中に復号器を持つので，量子化誤差は伝播しない。
rho = 0.95; Q = 16;
Xd = zeros(N1,N2); S = zeros(N1,N2); D = zeros(N1,N2);
for r = 1:N1
    prev = 128;                                  % 各行の先頭は 128 から予測
    for c = 1:N2
        xhat = rho*prev;                         % 予測
        D(r,c) = X8(r,c) - xhat;                 % 予測誤差
        S(r,c) = round(D(r,c)/Q);                % 量子化
        Xd(r,c) = Q*S(r,c) + xhat;               % 局所復号
        prev = Xd(r,c);
    end
end
Xd = min(max(Xd,0),255);
psnrDPCM = psnr(Xd, X8, 255)
imwrite(uint8(Xd), fullfile(resfolder,"vie-12-dpcm.png"))
vie.savetex("vie-12-dpcm-psnr", sprintf("%.2f", psnrDPCM));
%%
%[text] ## 予測前後のヒストグラムとエントロピー
%[text] 原画像の画素値，PCM の量子化インデックス，DPCM の量子化インデックスのエントロピー [bits/pixel] を比べる。DPCM のインデックスは 0 付近に集中するので，エントロピー符号化の効果が大きい。
ent = @(v) -sum(nonzeros(histcounts(v(:), [unique(v(:)); inf]')/numel(v)).*log2(nonzeros(histcounts(v(:), [unique(v(:)); inf]')/numel(v))));
Spcm = floor(X8/16);
Hs = [ent(X8) ent(Spcm) ent(S)]
vie.savetex("vie-12-ent-org",  sprintf("%.2f", Hs(1)));
vie.savetex("vie-12-ent-pcm",  sprintf("%.2f", Hs(2)));
vie.savetex("vie-12-ent-dpcm", sprintf("%.2f", Hs(3)));
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, histogram(X8(:), -0.5:1:255.5, "EdgeColor","none"), title(sprintf("原画像（%.2f bits/pixel）", Hs(1))), xlim([-1 256])
nexttile, histogram(Spcm(:), -0.5:1:15.5, "EdgeColor","none"), title(sprintf("PCM Q=16 のインデックス（%.2f bits/pixel）", Hs(2))), xlim([-8.5 16.5])
nexttile, histogram(S(:), -8.5:1:16.5, "EdgeColor","none"), title(sprintf("DPCM Q=16 のインデックス（%.2f bits/pixel）", Hs(3))), xlim([-8.5 16.5])
exportgraphics(gcf, fullfile(resfolder,"vie-12-hist.png"), "Resolution", 110)
%%
%[text] ## 動き補償予測の効果
%[text] 前フレームを $ (2,1) $ 画素ずらした現フレームを作り，単純なフレーム差分と，動き（ずれ）を補償した予測誤差を比べる。
rng(0)
F0 = X8(21:236, 21:236) + 3*randn(216);          % 前フレーム（撮像ノイズ σ=3 を含む）
F1 = X8(20:235, 19:234) + 3*randn(216);          % 現フレーム（1 行 2 列ずれ）
dNoMC = F1 - F0;                                 % フレーム差分
dMC = F1(2:end, 3:end) - F0(1:end-1, 1:end-2);   % 動き補償（ずれを戻して差分）
varMC = [var(dNoMC(:)) var(dMC(:))]
imwrite(uint8(F1), fullfile(resfolder,"vie-12-mc-frame.png"))
imwrite(uint8(128 + dNoMC/2), fullfile(resfolder,"vie-12-mc-diff.png"))
imwrite(uint8(128 + dMC/2), fullfile(resfolder,"vie-12-mc-res.png"))
vie.savetex("vie-12-var-nomc", sprintf("%.0f", varMC(1)));
vie.savetex("vie-12-var-mc",   sprintf("%.0f", varMC(2)));
%%
%[text] ## 色差サブサンプリング（4:2:0）
%[text] kodim23 の Y, Cb, Cr を 4:2:0 の大きさで並べる。
Xc = im2double(imread(fullfile(datfolder,"kodim23.png")));
Xc = min(max(imresize(Xc, 0.5), 0), 1);
Ycc = rgb2ycbcr(Xc);
imwrite(Ycc(:,:,1), fullfile(resfolder,"vie-12-y.png"))
imwrite(imresize(Ycc(:,:,2), 0.5), fullfile(resfolder,"vie-12-cb.png"))
imwrite(imresize(Ycc(:,:,3), 0.5), fullfile(resfolder,"vie-12-cr.png"))
X420 = ycbcr2rgb(cat(3, Ycc(:,:,1), imresize(imresize(Ycc(:,:,2),0.5),2), imresize(imresize(Ycc(:,:,3),0.5),2)));
imwrite(min(max(X420,0),1), fullfile(resfolder,"vie-12-420.png"))
ratio = [(1+0.5+0.5)/3 (1+0.25+0.25)/3]         % 4:2:2 と 4:2:0 のデータ量の比
%%
%[text] ## 符号化利得（教科書の例題）
%[text] 相関係数 $ \\rho=0.95 $ の AR(1) 過程に 4 点 DCT を施したときの係数の分散と符号化利得 $ G $ 。
M = 4; rho = 0.95;
Rx = toeplitz(rho.^(0:M-1));
C4 = dctmtx(M);
Sy = C4*Rx*C4';
vy = diag(Sy)'
G = mean(vy)/prod(vy)^(1/M);
GdB = 10*log10(G)
vie.savetex("vie-12-cg-var", strjoin(compose("%.4f", vy), ",\ "));
vie.savetex("vie-12-cg-db", sprintf("%.2f", GdB));
%%
%[text] ## JPEG の量子化テーブル
%[text] 輝度用 $ Q\_\\mathrm{L} $ と色差用 $ Q\_\\mathrm{C} $ （JPEG 規格の参考値）。
QL = [16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69 56; 14 17 22 29 51 87 80 62;
      18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92; 49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
QC = 99*ones(8); QC(1:4,1:4) = [17 18 24 47; 18 21 26 66; 24 26 56 99; 47 66 99 99];
vie.savetex("vie-12-QL", vie.arr2tex(QL,"%d"));
vie.savetex("vie-12-QC", vie.arr2tex(QC,"%d"));
%%
%[text] ## DCT による変換符号化の処理例
%[text] $ 8\\times8 $ ブロック DCT の係数を $ K Q\_\\mathrm{L} $ で割って四捨五入し（ $ K $ ：スケーリングファクター），逆量子化・逆 DCT で戻す。0 でない係数の割合も調べる。
Ks = [1 8];
for i = 1:numel(Ks)
    K = Ks(i);
    Yq = blockproc(X8 - 128, [8 8], @(b) round(dct2(b.data)./(K*QL)));
    Xr = blockproc(Yq, [8 8], @(b) idct2(b.data.*(K*QL))) + 128;
    Xr = min(max(Xr,0),255);
    ps = psnr(Xr, X8, 255);
    nz = mean(Yq(:) ~= 0);
    fprintf("K=%d: PSNR=%.2f dB, 非零係数 %.1f%%\n", K, ps, 100*nz);
    imwrite(uint8(Xr), fullfile(resfolder,sprintf("vie-12-dct-k%d.png", K)))
    vie.savetex(sprintf("vie-12-dct-psnr-k%d", K), sprintf("%.2f", ps));
    vie.savetex(sprintf("vie-12-dct-nz-k%d", K), sprintf("%.1f", 100*nz));
end
%%
%[text] ## ジグザグスキャン
%[text] 低周波から高周波へ斜めに往復しながら 64 個の係数を並べる順序。
zz = zeros(8); k = 1;
for sdiag = 0:14
    idx = [];
    for r = 0:7
        c = sdiag - r;
        if c >= 0 && c <= 7, idx(end+1,:) = [r c]; end %#ok<SAGROW>
    end
    if mod(sdiag,2) == 0, idx = flipud(idx); end   % 偶数番目の斜めは下から上へ
    for j = 1:size(idx,1)
        zz(idx(j,1)+1, idx(j,2)+1) = k; k = k + 1;
    end
end
zz
vie.savetex("vie-12-zigzag", vie.arr2tex(zz,"%d"));
%%
%[text] ## まとめ
%[text] - エントロピー符号化（ハフマン符号化）は出現確率の高い値に短い符号を割り当てる可逆な符号化
%[text] - 線形 PCM は 1 bit 減らすごとに PSNR が約 6 dB 下がる。予測符号化は予測誤差を量子化してエントロピーを下げる
%[text] - 変換符号化は係数の分散の偏り（符号化利得）を利用し，視覚特性に合わせて係数ごとに量子化する
%[text] - JPEG は DCT＋量子化＋ハフマン符号化，MPEG は動き補償予測と DCT のハイブリッド符号化 \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
