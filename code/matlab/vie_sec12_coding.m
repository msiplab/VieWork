%[text] # 第12回 画像・映像符号化
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第12回のスライド（vie2026-12）で使う図と数値を作る。データ量とビットレート，ハフマン符号化，線形 PCM（線形再量子化），PSNR，予測符号化（DPCM），動き補償予測（ブロックマッチング），色差サブサンプリング，変換符号化（符号化利得，JPEG の量子化テーブル），ジグザグスキャンを扱う。
%[text] 記号は教科書（村松正吾『多次元信号・画像処理の基礎と展開』7.3 節）に合わせる。量子化ステップ $ Q $ ，量子化インデックス（シンボル） $ \\check{y} $ ，復号値 $ \\check{x} $ ，予測 $ \\hat{x} $ ，予測誤差 $ d $ ，動きベクトル $ \\boldsymbol{m}=(m\_\\mathrm{v}\\ m\_\\mathrm{h})^\\top $ 。
%[text] 教科書の例題の数値は，ここで計算し直して教科書の解答と一致することを確かめてから書き出す。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図の配色はスライドのロゴの 3 色（メインの緑，寒色系の青，暖色系の橙）と灰色にそろえる。
[~,resfolder] = vie.prjfolders();
%[text] 写真は教科書のサンプル画像 msipimg05（石像の顔，アンコール）をグレースケールにし， $ 256\\times256 $ 画素に縮小して使う。空のなめらかな階調に PCM の擬似輪郭や DCT のブロックひずみがはっきり現れ，石像の細かな模様は動き補償のブロックマッチングの手がかりになる。
X8 = double(vie.msipimg(5, 256, "gray"));      % 8 bit（0〜255），256×256
[N1,N2] = size(X8);
cMain = [0 136 85]/255;                        % メイン（緑）
cCool = [46 117 182]/255;                      % 寒色系（青）
cWarm = [197 90 17]/255;                       % 暖色系（橙）
cGray = [0.45 0.45 0.45];
%[text] 図の軸ラベルの記号も教科書の組版（ $ x[\\boldsymbol{n}] $ の添え字ベクトルは太字イタリック）に合わせる。MATLAB の LaTeX インタープリターは `\\boldsymbol` を扱えないので，TeX インタープリターで Times の太字イタリックを使う（ $ \\check{y} $ は結合文字のキャロン U+030C）。
lbN = "[{\fontname{Times}\bf\itn}]";                   % [n]（n は太字イタリック）
lbX = "{\fontname{Times}\itx}" + lbN;                  % x[n]
lbY = "{\fontname{Times}\ity" + char(780) + "}" + lbN;  % y̌[n]
lbQ = "{\fontname{Times}\itQ}";                        % Q
%%
%[text] ## データ量とビットレート（教科書の例題「動画像のビットレート」）
%[text] 画素数 $ N\_1\\times N\_2=4320\\times 7680 $ ，フレーム間隔 $ \\Delta\_\\mathrm{t}=1/60 $ s，一配列要素当たり $ \\beta=8 $ bits の RGB カラー動画像。1 フレーム当たりのビット数は $ B=3\\beta N\_1N\_2 $ ，ビットレートは $ R=B(\\Delta\_\\mathrm{t})^{-1} $ である。
Nv = 4320; Nh = 7680; dt = 1/60; betaBits = 8;
B = 3*betaBits*Nv*Nh                               % bits/frame
R = B/dt                                       % bps
assert(B == 796262400 && R == 47775744000)     % 教科書の解答と一致
vie.savetex("vie-12-rate-B", sprintf("%d", B));
vie.savetex("vie-12-rate-Gbps", sprintf("%.0f", R/1e9));
%%
%[text] ## JPEG 符号化の圧縮率（教科書の例「JPEG符号化」）
%[text] $ 96\\times 96 $ 画素，8 bit のグレースケール画像（教科書 図 1.3 (a)）のデータ量と，JPEG で符号化したファイルのデータ量 1066 bytes（教科書の値）から，1 画素当たりのビット数を求める。
B0 = 96*96*8/8                                 % 原画像のデータ量 [bytes]
B1 = 1066;                                     % JPEG ファイルのデータ量 [bytes]（教科書の値）
bpp = 8*B1/(96*96)                             % [bits/pixel]
assert(B1/B0 < 1/8)                            % 1/8 以下に削減
vie.savetex("vie-12-jpeg-B0", sprintf("%d", B0));
vie.savetex("vie-12-jpeg-bpp", sprintf("%.2f", bpp));
%%
%[text] ## ハフマン符号化（教科書の例題「ハフマン符号化」）
%[text] シンボル $ \\check{y}\\in\\{0,1,2,3\\} $ の出現確率 $ P[\\check{y}]=(0.6,0.25,0.1,0.05) $ から，確率の小さい 2 つを順に併合してハフマンツリーを作り，符号語 $ B\_{\\check{y}} $ を決める（末尾のローカル関数 `huffmancode`）。併合のたびに，確率の大きい枝に 0，小さい枝に 1 を割り当てる。
p = [0.6 0.25 0.1 0.05];
code = huffmancode(p)
assert(isequal(code, ["0","10","110","111"]))  % 教科書 図 7.11 (a) の符号語と一致
binrep = string(dec2bin(0:3, 2))';             % 2 bit 固定長の 2 進数表現
trow = strings(1,numel(p));
for k = 1:numel(p)
    trow(k) = sprintf("%d & %s & %.2f & %s", k-1, binrep(k), p(k), code(k));
end
vie.savetex("vie-12-huff-table", join(trow, "\\" + newline));
%[text] 平均符号長 $ \\ell=\\sum\_{\\check{y}}P[\\check{y}]\\ell\_{\\check{y}} $ （ $ \\ell\_{\\check{y}} $ ：符号語の語長）と，エントロピー $ H=-\\sum\_{\\check{y}}P[\\check{y}]\\log\_2P[\\check{y}] $ （平均符号長の下限）を求める。
len = strlength(code);
Lavg = sum(p.*len)                              % 平均符号長
H = -sum(p.*log2(p))                            % エントロピー
assert(abs(Lavg - 1.55) < 1e-12)                % 教科書の解答と一致
vie.savetex("vie-12-huff-Lexpr", join(compose("%g\\times%d", [p; len]'), "+"));
vie.savetex("vie-12-huff-L", sprintf("%.2f", Lavg));
vie.savetex("vie-12-huff-H", sprintf("%.2f", H));
%[text] シンボル列を 2 進数（2 bit 固定長）とハフマン符号語で表し，ビット数を比べる。ハフマン符号は語頭符号（どの符号語も他の符号語の頭にならない）なので，区切りがなくても一意に復号できる。
seq = [0 3 1 0 0 0 0 0 1 2 1 0 0 0 1 1 0 0 0 2];
sBin  = join(binrep(seq+1), "");
sHuff = join(code(seq+1), "");
nbits = [strlength(sBin) strlength(sHuff)]
assert(isequal(nbits, [40 31]))                 % 教科書の解答（40 bit と 31 bit）と一致
assert(isequal(prefixdecode(sHuff, code), seq)) % 区切りなしで復号できる
vie.savetex("vie-12-huff-seq",  join(string(seq), "\,"));
vie.savetex("vie-12-huff-bin",  join(binrep(seq+1), "\,"));
vie.savetex("vie-12-huff-code", join(code(seq+1), "\,"));
vie.savetex("vie-12-huff-nbin",  sprintf("%d", nbits(1)));
vie.savetex("vie-12-huff-ncode", sprintf("%d", nbits(2)));
%%
%[text] ## 線形再量子化の PSNR（教科書の例題「線形再量子化」）
%[text] 量子化誤差 $ e $ が $ [-Q/2,Q/2] $ の一様分布なら，分散は $ \\sigma\_\\mathrm{e}^2=Q^2/12 $ 。ピーク値 1 に対する PSNR は $ 10\\log\_{10}\\sigma\_\\mathrm{e}^{-2}=10\\log\_{10}12-20\\log\_{10}Q $ [dB]。 $ Q\_\\alpha=(2^{\\alpha}-1)^{-1} $ とすると，1 bit 減らすごとに約 $ 20\\log\_{10}2\\simeq 6.02 $ dB 下がる。
c12 = 10*log10(12)                             % 10 log10 12 [dB]
d1 = 20*log10(2)                               % 1 bit 当たりの差 [dB]
psnrTh = @(a) c12 - 20*log10(1/(2^a - 1));     % α bit の理論値 [dB]
thPSNR = [psnrTh(4) psnrTh(6)]                 % 4 bpp と 6 bpp
dTh = thPSNR(2) - thPSNR(1)                    % = 20 log10(63/15)
vie.savetex("vie-12-lrq-c",   sprintf("%.2f", c12));
vie.savetex("vie-12-lrq-6db", sprintf("%.2f", d1));
vie.savetex("vie-12-lrq-th4", sprintf("%.2f", thPSNR(1)));
vie.savetex("vie-12-lrq-th6", sprintf("%.2f", thPSNR(2)));
vie.savetex("vie-12-lrq-dth", sprintf("%.2f", dTh));
%[text] 一様乱数で仮定を確かめる。 $ [0,1] $ の一様分布に従う値を四捨五入で再量子化すると，PSNR は理論値にほぼ一致する。教科書 図 7.9 の実画像（34.40 dB，46.79 dB）では，画素値の分布が一様でないため少しずれる。
rng(0)
u = rand(1e6,1);
simPSNR = zeros(1,2); al = [4 6];
for i = 1:2
    Qa = 1/(2^al(i) - 1);
    simPSNR(i) = psnr(Qa*round(u/Qa), u, 1);
end
simPSNR
%%
%[text] ## 線形 PCM 符号化の処理例（msipimg05）
%[text] 8 bit の画素値を量子化ステップ $ Q $ で $ \\check{y}[\\boldsymbol{n}]=\\lfloor x[\\boldsymbol{n}]/Q \\rfloor $ と量子化し， $ \\check{x}[\\boldsymbol{n}]=Q\\,\\check{y}[\\boldsymbol{n}]+Q/2 $ で戻す（区間の中央）。 $ Q=8 $ （5 bpp）と $ Q=16 $ （4 bpp）で比べる。
Qs = [8 16];
psnrPCM = zeros(size(Qs));
for i = 1:numel(Qs)
    Q = Qs(i);
    yq = floor(X8/Q);
    Xh = Q*yq + Q/2;
    psnrPCM(i) = psnr(Xh, X8, 255);
    imwrite(uint8(Xh), fullfile(resfolder,sprintf("vie-12-pcm-q%02d.png", Q)))
    vie.savetex(sprintf("vie-12-pcm-psnr%02d", Q), sprintf("%.2f", psnrPCM(i)));
end
psnrPCM
imwrite(uint8(X8), fullfile(resfolder,"vie-12-org.png"))
%[text] 1 bit 減らすと PSNR は約 6 dB 下がる（2 桁に丸めた値の差）。
dPSNR = round(psnrPCM(1),2) - round(psnrPCM(2),2)
vie.savetex("vie-12-pcm-dpsnr", sprintf("%.2f", dPSNR));
%%
%[text] ## PSNR の数値例（前回スライドの例題）
%[text] 2 bit（ピーク値 $ 2^2-1=3 $ ）の $ 4\\times4 $ 配列どうしの PSNR。差の二乗のうち零でないものを，行ごとに左から並べて示す。
Xa = [0 1 1 0; 1 2 3 1; 1 3 2 1; 0 1 1 0];
Xb = [0 1 1 1; 1 3 0 1; 1 2 2 1; 2 1 1 0];
sq = (Xa - Xb).'.^2;                            % 転置して行ごとの順に並べる
sq = sq(sq ~= 0)'
mse = mean((Xa(:) - Xb(:)).^2)
psnrEx = 10*log10(3^2/mse)
vie.savetex("vie-12-psnr-a", vie.arr2tex(Xa,"%d"));
vie.savetex("vie-12-psnr-b", vie.arr2tex(Xb,"%d"));
vie.savetex("vie-12-psnr-sq", join(string(sq), "+"));
vie.savetex("vie-12-psnr-N", sprintf("%d", numel(Xa)));
vie.savetex("vie-12-psnr-mse", sprintf("%g", mse));
vie.savetex("vie-12-psnr-val", sprintf("%.2f", psnrEx));
%%
%[text] ## 予測符号化（DPCM）
%[text] 水平方向の一つ前の復号済み画素から $ \\hat{x}[n\_\\mathrm{v},n\_\\mathrm{h}]=\\rho\\,\\check{x}[n\_\\mathrm{v},n\_\\mathrm{h}-1] $ （ $ \\rho=0.95 $ ）と予測し，予測誤差 $ d=x-\\hat{x} $ を $ Q=16 $ で量子化する（四捨五入）。符号化器の中に局所復号器を持つので，量子化誤差は伝播しない。
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
%[text] 原画像の画素値，PCM の量子化インデックス，DPCM の量子化インデックスのエントロピー [bits/pixel] を比べる（末尾のローカル関数 `entbits`）。DPCM のインデックスは 0 付近に集中するので，エントロピー符号化の効果が大きい。
Spcm = floor(X8/16);
Hs = [entbits(X8) entbits(Spcm) entbits(S)]
vie.savetex("vie-12-ent-org",  sprintf("%.2f", Hs(1)));
vie.savetex("vie-12-ent-pcm",  sprintf("%.2f", Hs(2)));
vie.savetex("vie-12-ent-dpcm", sprintf("%.2f", Hs(3)));
fig = figure(Units="centimeters", Position=[2 2 11 7], DefaultAxesFontSize=6.5);   % スライドでの表示幅（約 7 cm）に近い大きさ
tiledlayout(fig,3,1,"TileSpacing","tight","Padding","compact")
nexttile, histogram(X8(:), -0.5:1:255.5, "EdgeColor","none", "FaceColor",cGray, "FaceAlpha",1)
title(sprintf("原画像（%.2f bits/pixel）", Hs(1))), xlim([-1 256])
xlabel(lbX)
nexttile, histogram(Spcm(:), -0.5:1:15.5, "EdgeColor","none", "FaceColor",cCool, "FaceAlpha",1)
title("PCM " + lbQ + sprintf("=16 のインデックス（%.2f bits/pixel）", Hs(2))), xlim([-8.5 16.5])
xlabel(lbY)
nexttile, histogram(S(:), -8.5:1:16.5, "EdgeColor","none", "FaceColor",cMain, "FaceAlpha",1)
title("DPCM " + lbQ + sprintf("=16 のインデックス（%.2f bits/pixel）", Hs(3))), xlim([-8.5 16.5])
xlabel(lbY)
exportgraphics(fig, fullfile(resfolder,"vie-12-hist.png"), "Resolution", 300)
close(fig)
%%
%[text] ## 動き補償予測の効果（ブロックマッチングによる動き推定）
%[text] 実際の動画の連続する 2 フレームを使う（前回スライドの映像。スライドの動画 anim-11-motion-a と同じもので，VieWork の data に置いた）。カメラが横に動いているので，内容は水平に動き，手前の木と奥の家では動きの大きさが違う。
%[text] 前フレームを復号済み参照フレーム $ \\check{\\msiptensor{x}}\_{m\_\\mathrm{t}} $ とみなし，現フレーム $ \\msiptensor{x}\_{n\_\\mathrm{t}} $ から探索範囲の余白を除いた $ 304\\times464 $ 画素を処理する。
datfolder = vie.prjfolders();
Xref = double(rgb2gray(imread(fullfile(datfolder, "anim-11-motion-a-f0.jpg"))));   % 前フレーム（参照フレーム）
Xcur = double(rgb2gray(imread(fullfile(datfolder, "anim-11-motion-a-f1.jpg"))));   % 現フレーム
rr = 9:312; cc = 9:472;                          % 処理する範囲（16 の倍数，周囲に探索範囲の余白 8 画素）
F0 = Xref(rr, cc);                               % 前フレームの同じ範囲
F1 = Xcur(rr, cc);                               % 現フレーム
%[text] $ 16\\times16 $ 画素のブロック $ b $ ごとに，探索範囲 $ \\mathcal{N}\_\\mathrm{w}=\\{-8,\\ldots,8\\}^2 $ の全探索で SAD
%[text] $ \\mathrm{SAD}(\\boldsymbol{m};b)=\\sum\_{\\boldsymbol{n}\\in\\mathcal{N}\_b}|x[\\boldsymbol{n}]-\\check{x}[\\boldsymbol{n}+\\boldsymbol{m}]| $ を最小にする $ \\hat{\\boldsymbol{m}}\_b $ を求め，参照フレームの $ \\boldsymbol{n}+\\hat{\\boldsymbol{m}}\_b $ の画素で予測する（動き補償）。
Bs = 16; w = 8;
[Hf,Wf] = size(F1);
P = zeros(Hf,Wf);                                % 動き補償予測
mhat = zeros(Hf/Bs, Wf/Bs, 2);                   % ブロックごとの動きベクトル (m_v, m_h)
sadmaps = zeros(2*w+1, 2*w+1, Hf/Bs, Wf/Bs);
for bi = 1:Hf/Bs
    for bj = 1:Wf/Bs
        ib = (bi-1)*Bs + (1:Bs); jb = (bj-1)*Bs + (1:Bs);
        blk = F1(ib, jb);
        for mv = -w:w
            for mh = -w:w
                ref = Xref(rr(ib)+mv, cc(jb)+mh);
                sadmaps(mv+w+1, mh+w+1, bi, bj) = sum(abs(blk - ref), "all");
            end
        end
        [~, imin] = min(reshape(sadmaps(:,:,bi,bj), [], 1));
        [iv, ih] = ind2sub([2*w+1 2*w+1], imin);
        m = [iv ih] - (w+1);
        mhat(bi,bj,:) = m;
        P(ib, jb) = Xref(rr(ib)+m(1), cc(jb)+m(2));
    end
end
mvHist = groupcounts(reshape(mhat(:,:,2),[],1))  % 水平成分の分布（手前と奥で違う）
%[text] 単純なフレーム差分と，動き補償後の予測誤差の分散を比べる。
dNoMC = F1 - F0;                                 % フレーム差分
dMC = F1 - P;                                    % 動き補償後の予測誤差
varMC = [var(dNoMC(:)) var(dMC(:))]
vie.savetex("vie-12-var-nomc", sprintf("%.0f", varMC(1)));
vie.savetex("vie-12-var-mc",   sprintf("%.0f", varMC(2)));
%[text] 模様のはっきりしたブロック（画素値の分散が最大のブロック）を一つ選び，SAD の分布と推定した動きベクトルを図にする。現フレームには選んだブロックを橙の枠で示す。
bvar = zeros(Hf/Bs, Wf/Bs);
for bi = 1:Hf/Bs
    for bj = 1:Wf/Bs
        blk = F1((bi-1)*Bs + (1:Bs), (bj-1)*Bs + (1:Bs));
        bvar(bi,bj) = var(blk(:));
    end
end
[~, isel] = max(bvar(:)); [bsv, bsh] = ind2sub(size(bvar), isel);
msel = squeeze(mhat(bsv,bsh,:))'
vie.savetex("vie-12-mc-mhat", sprintf("%d\\ \\ %d", msel));
Irgb = repmat(min(max(F1,0),255)/255, [1 1 3]);
ib = (bsv-1)*Bs + (1:Bs); jb = (bsh-1)*Bs + (1:Bs);
r1 = max(ib(1)-1,1); r2 = min(ib(end)+1,Hf); c1 = max(jb(1)-1,1); c2 = min(jb(end)+1,Wf);
edgeMask = false(Hf,Wf);
edgeMask(r1:r2, c1:c2) = true;
edgeMask(r1+2:r2-2, c1+2:c2-2) = false;          % 幅 2 画素の枠だけ残す
for ch = 1:3
    plane = Irgb(:,:,ch); plane(edgeMask) = cWarm(ch); Irgb(:,:,ch) = plane;
end
imwrite(Irgb, fullfile(resfolder,"vie-12-mc-frame.png"))
imwrite(uint8(128 + dNoMC/2), fullfile(resfolder,"vie-12-mc-diff.png"))
imwrite(uint8(128 + dMC/2), fullfile(resfolder,"vie-12-mc-res.png"))
fig = figure(Units="centimeters", Position=[2 2 2.6 2.6]);       % スライドにほぼ原寸で載せる
ax = axes(fig);
imagesc(ax, -w:w, -w:w, sadmaps(:,:,bsv,bsh)), axis(ax, "image")
colormap(ax, flipud(gray(256)))
hold(ax, "on")
plot(ax, msel(2), msel(1), "o", "MarkerSize",5, "LineWidth",1.2, "Color",cWarm)
plot(ax, 0, 0, "+", "MarkerSize",5, "LineWidth",1, "Color",cCool)
hold(ax, "off")
set(ax, "XTick",-w:w:w, "YTick",-w:w:w, "FontSize",5.5, "TickLength",[0.02 0.02])
xlabel(ax, "$m_\mathrm{h}$", "Interpreter","latex", "FontSize",7.5)
ylabel(ax, "$m_\mathrm{v}$", "Interpreter","latex", "FontSize",7.5)
exportgraphics(fig, fullfile(resfolder,"vie-12-mc-sad.png"), "Resolution", 600)
close(fig)
%%
%[text] ## 色差サブサンプリング（4:2:0）
%[text] msipimg02（花束）の Y, Cb, Cr を 4:2:0 の大きさで並べる。色とりどりの花で色差 Cb, Cr の模様がはっきりしている。上下を切り出した $ 384\\times512 $ 画素を $ 192\\times256 $ 画素に縮小する。
Xc = im2double(vie.msipimg(2));
Xc = min(max(imresize(Xc(65:448,:,:), 0.5), 0), 1);
Ycc = rgb2ycbcr(Xc);
imwrite(Ycc(:,:,1), fullfile(resfolder,"vie-12-y.png"))
imwrite(imresize(Ycc(:,:,2), 0.5), fullfile(resfolder,"vie-12-cb.png"))
imwrite(imresize(Ycc(:,:,3), 0.5), fullfile(resfolder,"vie-12-cr.png"))
X420 = ycbcr2rgb(cat(3, Ycc(:,:,1), imresize(imresize(Ycc(:,:,2),0.5),2), imresize(imresize(Ycc(:,:,3),0.5),2)));
imwrite(min(max(X420,0),1), fullfile(resfolder,"vie-12-420.png"))
%[text] 4:4:4 形式に対するデータ量の比。色差 Cb, Cr の画素数は，間引き率 $ M\_\\mathrm{v}\\times M\_\\mathrm{h} $ で割った数になる。
Mvh = [1 2; 2 2; 1 4];                           % 4:2:2，4:2:0，4:1:1 の (M_v, M_h)
ratio = (1 + 2./prod(Mvh,2))/3                   % Y と Cb, Cr の合計 / 4:4:4
[rn, rd] = rat(ratio);
fmts = ["422" "420" "411"];
for i = 1:3
    vie.savetex("vie-12-ratio-" + fmts(i), sprintf("%d/%d", rn(i), rd(i)));
end
%%
%[text] ## 符号化利得（教科書の例題「符号化利得」）
%[text] 相関係数 $ \\rho=0.95 $ の AR(1) 過程に 4 点 DCT を施したときの係数の分散 $ \\sigma\_{\\mathrm{y}\_p}^2/\\sigma\_\\mathrm{x}^2 $ と符号化利得 $ G $ （相加平均 / 相乗平均）。
M = 4; rho = 0.95;
Rx = toeplitz(rho.^(0:M-1));
C4 = dctmtx(M);
Sy = C4*Rx*C4';
vy = diag(Sy)'
G = mean(vy)/prod(vy)^(1/M);
GdB = 10*log10(G)
assert(all(abs(vy - [3.7562 0.1626 0.0512 0.0300]) < 5e-5) && abs(GdB - 7.57) < 5e-3)   % 教科書の解答と一致
vie.savetex("vie-12-cg-var", join(compose("%.4f", vy), ",\ "));
vie.savetex("vie-12-cg-db", sprintf("%.2f", GdB));
%[text] 相関がない $ \\rho=0 $ の場合は分散に偏りがなく， $ 10\\log\_{10}G=0 $ dB になる。
vy0 = diag(C4*eye(M)*C4')';
GdB0 = 10*log10(mean(vy0)/prod(vy0)^(1/M))
vie.savetex("vie-12-cg-db0", sprintf("%g", round(GdB0,2) + 0));   % + 0 で -0 を 0 にする
%%
%[text] ## JPEG の量子化テーブル
%[text] 輝度用 $ Q\_\\mathrm{L} $ と色差用 $ Q\_\\mathrm{C} $ （JPEG 規格の参考値）。左上（低周波）ほど細かく，右下（高周波）ほど粗く量子化する。値の大小を色の濃さで示す。
QL = [16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69 56; 14 17 22 29 51 87 80 62;
      18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92; 49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
QC = 99*ones(8); QC(1:4,1:4) = [17 18 24 47; 18 21 26 66; 24 26 56 99; 47 66 99 99];
vie.savetex("vie-12-QL", vie.arr2tex(QL,"%d"));
vie.savetex("vie-12-QC", vie.arr2tex(QC,"%d"));
cmapG = [linspace(1,cMain(1)*0.75,256)' linspace(1,cMain(2)*0.75,256)' linspace(1,cMain(3)*0.75,256)'];   % 白→濃い緑
%[text] スライドに原寸（幅約 7.6 cm）で載せるので，図の大きさと文字の大きさ（pt）をその寸法で決める。
fig = figure(Units="centimeters", Position=[2 2 7.6 3.95]);
tl = tiledlayout(fig,1,2,"TileSpacing","compact","Padding","tight");
tabs = {QL, QC};
ttl = "輝度成分用 " + lbQ + "_{\fontname{Times}L}";
ttl(2) = "色差成分用 " + lbQ + "_{\fontname{Times}C}";
for i = 1:2
    ax = nexttile(tl);
    Qt = tabs{i};
    imagesc(ax, 0:7, 0:7, Qt), axis(ax, "image"), clim(ax, [0 125]), colormap(ax, cmapG)
    for r = 1:8
        for c = 1:8
            if Qt(r,c) > 70, tc = "w"; else, tc = "k"; end
            text(ax, c-1, r-1, sprintf("%d", Qt(r,c)), "HorizontalAlignment","center", ...
                "FontSize",5.2, "Color",tc)
        end
    end
    set(ax, "XTick",0:7, "YTick",0:7, "TickLength",[0 0], "FontSize",5.5, "XAxisLocation","top")
    xlabel(ax, "水平周波数 →", "FontSize",5.5), ylabel(ax, "← 垂直周波数", "FontSize",5.5)
    title(ax, ttl(i), "FontSize",7, "FontWeight","normal")
end
exportgraphics(fig, fullfile(resfolder,"vie-12-qtable.png"), "Resolution", 400)
close(fig)
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
%[text] - エントロピー符号化（ハフマン符号化）は出現確率の高い値に短い符号を割り当てる可逆な符号化。平均符号長はエントロピー以上
%[text] - 線形 PCM は 1 bit 減らすごとに PSNR が約 6 dB 下がる。予測符号化は予測誤差を量子化してエントロピーを下げる
%[text] - 動き補償予測は，ブロックマッチングで求めた動きベクトルで参照フレームをずらして予測し，予測誤差を小さくする
%[text] - 変換符号化は係数の分散の偏り（符号化利得）を利用し，視覚特性に合わせて係数ごとに量子化する
%[text] - JPEG は DCT＋量子化＋ハフマン符号化，MPEG は動き補償予測と DCT のハイブリッド符号化 \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
function code = huffmancode(p)
% HUFFMANCODE 出現確率 p からハフマン符号の符号語（string 配列）を作る
%   確率の小さい 2 つのノードを併合することを繰り返す。併合のたびに，
%   確率の大きい方の枝に 0，小さい方の枝に 1 を符号語の先頭に付け加える。
code = strings(1, numel(p));
nodes = num2cell(1:numel(p));                    % 各ノードに含まれるシンボル
prob = p;
while numel(prob) > 1
    [prob, idx] = sort(prob, "descend");
    nodes = nodes(idx);
    hi = nodes{end-1}; lo = nodes{end};          % 確率の小さい 2 つ
    code(hi) = "0" + code(hi);
    code(lo) = "1" + code(lo);
    nodes = [nodes(1:end-2), {[hi lo]}];
    prob = [prob(1:end-2), prob(end-1) + prob(end)];
end
end

function seq = prefixdecode(bits, code)
% PREFIXDECODE 語頭符号のビット列 bits を先頭から読み，符号語 code に一致したらシンボルを出力する
seq = [];
buf = "";
for b = char(bits)
    buf = buf + b;
    k = find(code == buf, 1);
    if ~isempty(k)
        seq(end+1) = k - 1; %#ok<AGROW>
        buf = "";
    end
end
end

function H = entbits(v)
% ENTBITS 配列 v の値の出現頻度から求めたエントロピー [bits/要素]
[~, ~, ic] = unique(v(:));
pr = accumarray(ic, 1)/numel(v);
H = -sum(pr.*log2(pr));
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
