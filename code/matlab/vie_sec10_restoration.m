%[text] # 第10回 画像復元
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第10回のスライド（vie2026-10）で使う図と数値を作る。DCT の問題点（ブロックノイズ・モスキートノイズ）と離散ウェーブレット変換（DWT），観測モデル $ \\mathbf{v}=\\mathbf{H}\\mathbf{x}+\\mathbf{w} $ ，最小二乗法と勾配降下法，スパースモデリング（合成モデル $ \\mathbf{x}=\\mathbf{D}\\mathbf{s} $ ，1-ノルム正則化），ISTA／FISTA によるボケ＋ノイズ除去を扱う。記号は教科書に合わせる。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
tmpfolder = fullfile(resfolder, "tmp"); if ~isfolder(tmpfolder), mkdir(tmpfolder); end
%%
%[text] ## DCT の問題点：ブロックノイズとモスキートノイズ
%[text] 低画質（品質 5）の JPEG で圧縮すると， $ 8\\times8 $ ブロックの境界が見える（ブロックノイズ），エッジのまわりにもやもやした揺らぎが出る（モスキートノイズ）。
Xg = im2double(imread("cameraman.tif"));
jpgfile = fullfile(tmpfolder, "cam_q5.jpg");
imwrite(Xg, jpgfile, "Quality", 5);
Xj = im2double(imread(jpgfile));
imwrite(imresize(Xj(1:64,1:64), 4, "nearest"), fullfile(resfolder,"vie-10-blocknoise.png"))       % 空の部分
imwrite(imresize(Xj(40:103,100:163), 4, "nearest"), fullfile(resfolder,"vie-10-mosquito.png"))   % 人物の輪郭付近
psnrJ = psnr(Xj, Xg)
%%
%[text] ## JPEG と JPEG2000（同程度のファイルサイズ）
%[text] kodim23 を約 12 kB になるよう JPEG と JPEG2000 で圧縮して比べる。
Xc = imread(fullfile(datfolder,"kodim23.png"));
target = 12e3;                                  % 目標ファイルサイズ [bytes]
q = 1; sz = 0;
while sz < target && q < 100                     % 品質を上げながら目標サイズを超える手前を探す
    q = q + 1; imwrite(Xc, fullfile(tmpfolder,"k23.jpg"), "Quality", q);
    d = dir(fullfile(tmpfolder,"k23.jpg")); sz = d.bytes;
end
q = q - 1; imwrite(Xc, fullfile(tmpfolder,"k23.jpg"), "Quality", q);
d = dir(fullfile(tmpfolder,"k23.jpg")); szJ = d.bytes;
cr = numel(Xc)/szJ;                             % JPEG と同じ圧縮率
imwrite(Xc, fullfile(tmpfolder,"k23.jp2"), "CompressionRatio", cr);
d = dir(fullfile(tmpfolder,"k23.jp2")); szJ2 = d.bytes;
Yj = imread(fullfile(tmpfolder,"k23.jpg")); Yj2 = imread(fullfile(tmpfolder,"k23.jp2"));
sizes = [szJ szJ2]
psnrs = [psnr(Yj, Xc) psnr(Yj2, Xc)]
imwrite(Yj(181:436, 401:656, :),  fullfile(resfolder,"vie-10-jpeg.png"))     % 256×256 の一部
imwrite(Yj2(181:436, 401:656, :), fullfile(resfolder,"vie-10-jp2.png"))
vie.savetex("vie-10-size-jpg", sprintf("%.1f", szJ/1e3));
vie.savetex("vie-10-size-jp2", sprintf("%.1f", szJ2/1e3));
vie.savetex("vie-10-psnr-jpg", sprintf("%.1f", psnrs(1)));
vie.savetex("vie-10-psnr-jp2", sprintf("%.1f", psnrs(2)));
%%
%[text] ## 2 次元 DWT（3 レベル）と DCT の周波数配置
%[text] 9/7 DWT（MATLAB の `bior4.4` ）を 3 レベル施し，係数を周波数配置で並べる（多重解像度表現）。
[A1,H1,V1,D1] = dwt2(Xg, "bior4.4", "mode", "per");
[A2,H2,V2,D2] = dwt2(A1, "bior4.4", "mode", "per");
[A3,H3,V3,D3] = dwt2(A2, "bior4.4", "mode", "per");
sc = @(c) min(abs(c)*4, 1);                     % 係数の絶対値を見やすく表示
L3 = [A3/max(A3(:)) sc(H3); sc(V3) sc(D3)];
L2 = [L3 sc(H2); sc(V2) sc(D2)];
Wdwt = [L2 sc(H1); sc(V1) sc(D1)];
imwrite(Wdwt, fullfile(resfolder,"vie-10-dwt3.png"))
%[text] 比較のため，8×8 ブロック DCT の係数を周波数ごとに集めて並べ替える（各周波数 $ (u,v) $ の係数が一枚の縮小画像になる）。
Yb = blockproc(Xg, [8 8], @(b) dct2(b.data));
Wdct = zeros(size(Xg)); nb = size(Xg,1)/8;
for u = 1:8, for v = 1:8
    sub = Yb(u:8:end, v:8:end);
    if u == 1 && v == 1, sub = sub/max(sub(:)); else, sub = sc(sub/2); end
    Wdct((u-1)*nb+(1:nb), (v-1)*nb+(1:nb)) = sub;
end, end
imwrite(Wdct, fullfile(resfolder,"vie-10-dctsub.png"))
%%
%[text] ## 9/7 DWT の基底画像
%[text] 各サブバンドの中央の係数だけを 1 にして逆変換すると，そのサブバンドの基底画像が得られる。サイズが周波数に応じて異なり，互いに重なり合う。
Nb = 64;
[c0, S] = wavedec2(zeros(Nb), 3, "bior4.4");
names = ["A3","H3","V3","D3","H2","V2","D2","H1","V1","D1"];
tiles = cell(1, numel(names));
for k = 1:numel(names)
    c = c0;
    lev = str2double(extractAfter(names(k),1)); typ = extractBefore(names(k),2);
    if typ == "A"
        idx = 1:prod(S(1,:)); sz2 = S(1,:);
    else
        row = 3 - lev + 2;                      % S の行（2 行目がレベル 3）
        nprev = prod(S(1,:)) + 3*sum(prod(S(2:row-1,:),2));
        off = find(["H","V","D"] == typ) - 1;
        sz2 = S(row,:); idx = nprev + off*prod(sz2) + (1:prod(sz2));
    end
    blk = zeros(sz2); blk(ceil(sz2(1)/2), ceil(sz2(2)/2)) = 1;
    c(idx) = blk(:);
    b = waverec2(c, S, "bior4.4");
    tiles{k} = 0.5 + b/(2*max(abs(b(:))));
end
Mos = [cat(2, tiles{1:5}); cat(2, tiles{6:10})];
imwrite(imresize(Mos, 2, "nearest"), fullfile(resfolder,"vie-10-dwtbasis.png"))
%%
%[text] ## 画像復元の概要：ボケ（点広がり関数）
%[text] 焦点ぼけなどは点広がり関数（PSF）との畳み込みで表される。PSF の例：標準偏差 $ \\sigma\_\\mathrm{g}=2 $ のガウス関数。
psf = fspecial("gaussian", 25, 2);
Hf = psf2otf(psf, size(Xg));                    % 周期境界（循環畳み込み）の周波数応答
blur = @(x) real(ifft2(Hf.*fft2(x)));
Xb = blur(Xg);
imwrite(Xb, fullfile(resfolder,"vie-10-blur.png"))
imwrite(Xg, fullfile(resfolder,"vie-10-org.png"))
dimg = zeros(64); dimg(33,33) = 1;              % インパルス
imwrite(dimg, fullfile(resfolder,"vie-10-delta.png"))
pimg = conv2(dimg, psf, "same"); imwrite(pimg/max(pimg(:)), fullfile(resfolder,"vie-10-psf.png"))
%%
%[text] ## 観測ノイズ（AWGN）
%[text] 前回スライドの例：3 段階の明るさの正方形に平均 0，分散 $ \\sigma\_\\mathrm{w}^2=0.001 $ の白色ガウスノイズを加える。ヒストグラムの各ピークが正規分布に広がる。
rng(0)
U = 0.25*ones(64); U(13:52,13:52) = 0.5; U(25:40,25:40) = 0.75;
Vn = U + sqrt(0.001)*randn(size(U));
imwrite(U, fullfile(resfolder,"vie-10-sq.png")), imwrite(min(max(Vn,0),1), fullfile(resfolder,"vie-10-sqn.png"))
clf
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, histogram(U(:), 0:0.01:1, "EdgeColor","none"), title("原画像のヒストグラム"), xlim([0 1])
nexttile, histogram(Vn(:), 0:0.01:1, "EdgeColor","none"), title("観測画像のヒストグラム"), xlim([0 1])
exportgraphics(gcf, fullfile(resfolder,"vie-10-sqhist.png"), "Resolution", 110)
%%
%[text] ## ボケ＋ノイズの観測画像
%[text] 教科書と同じ設定：ガウシアン $ \\sigma\_\\mathrm{g}=2 $ のボケと，分散 $ (10/255)^2 $ の AWGN。
rng(1)
sigw = 10/255;
Wn = sigw*randn(size(Xg));
V = blur(Xg) + Wn;
psnrV = psnr(V, Xg)
imwrite(min(max(V,0),1), fullfile(resfolder,"vie-10-obs.png"))
imwrite(min(max(0.5+Wn*4,0),1), fullfile(resfolder,"vie-10-noise.png"))
vie.savetex("vie-10-psnr-obs", sprintf("%.2f", psnrV));
%%
%[text] ## 最小二乗法の数値例
%[text] 一つの値 $ x $ を 3 回測った観測 $ \\mathbf{v}=(1.2,0.9,0.9)^\\top $ ， $ \\mathbf{H}=(1,1,1)^\\top $ 。正規方程式 $ \\mathbf{H}^\\top\\mathbf{H}x=\\mathbf{H}^\\top\\mathbf{v} $ の解は平均値。
Hm = [1;1;1]; vm = [1.2;0.9;0.9];
xls = (Hm'*Hm)\(Hm'*vm)
xpinv = pinv(Hm)*vm
vie.savetex("vie-10-ls-x", sprintf("%g", xls));
%[text] 勾配降下法 $ x^{(t+1)}=x^{(t)}-\\eta\\,\\mathbf{H}^\\top(\\mathbf{H}x^{(t)}-\\mathbf{v}) $ （ $ \\eta=0.2 $ ， $ x^{(0)}=0 $ ）でも同じ解に近づく。
eta = 0.2; xt = 0; hist = xt;
for t = 1:6
    xt = xt - eta*Hm'*(Hm*xt - vm);
    hist(end+1) = xt; %#ok<SAGROW>
end
hist
vie.savetex("vie-10-gd", strjoin(compose("%.3f", hist), ",\ "));
%%
%[text] ## ノイズと信号変換：ハール変換の詳細成分
%[text] 原画像の詳細成分はほとんどが 0 付近（疎）だが，ノイズを加えると全体に広がる（密）。
[~,Hc,Vc,Dc] = dwt2(Xg, "haar");
Xn = Xg + 20/255*randn(size(Xg));
[~,Hn,Vn2,Dn] = dwt2(Xn, "haar");
imwrite(min(abs(Hc)*4,1), fullfile(resfolder,"vie-10-detail-clean.png"))
imwrite(min(abs(Hn)*4,1), fullfile(resfolder,"vie-10-detail-noisy.png"))
imwrite(min(max(Xn,0),1), fullfile(resfolder,"vie-10-noisy.png"))
sp = [mean(abs(Hc(:)) < 0.02) mean(abs(Hn(:)) < 0.02)]
vie.savetex("vie-10-sp-clean", sprintf("%.0f", 100*sp(1)));
vie.savetex("vie-10-sp-noisy", sprintf("%.0f", 100*sp(2)));
%%
%[text] ## 画像データについての事前知識：詳細成分のヒストグラム
dcoef = [Hc(:); Vc(:); Dc(:)];
clf
histogram(dcoef, -1:0.01:1, "Normalization", "pdf", "EdgeColor","none"), hold on
b = mean(abs(dcoef));                             % ラプラス分布の尺度（平均絶対値）
ss = linspace(-1, 1, 801);
plot(ss, exp(-abs(ss)/b)/(2*b), "r", "LineWidth", 2), hold off
xlim([-0.5 0.5]), xlabel("係数の値"), ylabel("確率密度"), legend(["ハール詳細成分","ラプラス分布"])
set(gca,"FontSize",13)
exportgraphics(gca, fullfile(resfolder,"vie-10-dethist.png"), "Resolution", 110)
vie.savetex("vie-10-lap-b", sprintf("%.3f", b));
%%
%[text] ## 1-ノルム正則化：ラプラス分布とガウス分布
clf
plot(ss, exp(-abs(ss)/0.1)/0.2, "r", ss, exp(-ss.^2/(2*0.1^2))/(sqrt(2*pi)*0.1), "b--", "LineWidth", 2), grid on
legend(["ラプラス分布（尖る）","ガウス分布"]), xlim([-0.5 0.5]), xlabel("s"), ylabel("p(s)"), set(gca,"FontSize",13)
exportgraphics(gca, fullfile(resfolder,"vie-10-laplace.png"), "Resolution", 110)
%%
%[text] ## ソフト閾値処理
%[text] $ \\phi\_\\mathrm{ST}(x;\\lambda)=\\mathrm{sign}(x)\\max(|x|-\\lambda,0) $ 。数値例（ $ \\lambda=1 $ ）：
st = @(x,lam) sign(x).*max(abs(x) - lam, 0);
xs = [-3 -0.5 0.2 2];
ys = st(xs, 1)
vie.savetex("vie-10-st-x", strjoin(compose("%g",xs),",\ "));
vie.savetex("vie-10-st-y", strjoin(compose("%g",ys+0),",\ "));
xx = linspace(-3, 3, 601);
clf
plot(xx, st(xx,1), "LineWidth", 2), grid on, axis equal, xlim([-3 3]), ylim([-2.2 2.2])
xlabel("x"), ylabel("\phi_{ST}(x;\lambda)"), title("ソフト閾値処理（\lambda=1）"), set(gca,"FontSize",13)
exportgraphics(gca, fullfile(resfolder,"vie-10-soft.png"), "Resolution", 110)
%%
%[text] ## FISTA によるボケ＋ノイズ除去
%[text] 合成辞書 $ \\mathbf{D} $ に 3 段の非間引きハール DWT（パーセバルタイト枠）を用いる。周期境界の畳み込みとして周波数領域で実装する。各段のフィルタは $ \\frac12(1\\pm z^{-2^{j-1}}) $ 。
J = 3; [N1,N2] = size(Xg);
[w2,w1] = meshgrid(2*pi*(0:N2-1)/N2, 2*pi*(0:N1-1)/N1);
F = []; Lp = ones(N1,N2);                      % 各サブバンドの周波数応答（3 次元目がサブバンド）
for j = 1:J
    m = 2^(j-1);
    h0v = (1 + exp(-1j*m*w1))/2; h1v = (1 - exp(-1j*m*w1))/2;
    h0h = (1 + exp(-1j*m*w2))/2; h1h = (1 - exp(-1j*m*w2))/2;
    F = cat(3, F, Lp.*h0v.*h1h, Lp.*h1v.*h0h, Lp.*h1v.*h1h);
    Lp = Lp.*h0v.*h0h;
end
F = cat(3, F, Lp);                              % 最後が低域成分
K = size(F,3)
tight = max(abs(sum(abs(F).^2, 3) - 1), [], "all")   % Σ|F_k|^2 = 1（パーセバルタイト枠）
T  = @(x) real(ifft2(F.*fft2(x)));                   % 分析 D^T（係数は N1×N2×K）
Dm = @(c) real(ifft2(sum(conj(F).*fft2(c), 3)));     % 合成 D
HD  = @(c) blur(Dm(c));
HDt = @(r) T(real(ifft2(conj(Hf).*fft2(r))));
lambda = 1e-3; eta = 1; nIter = 20;             % 教科書と同じ設定（実験的に決めたもの）
s = zeros(N1,N2,K); y = s; a = 1;
for t = 1:nIter
    g = HDt(HD(y) - V);                         % 勾配 D^T H^T (HDy - v)
    snew = y - eta*g;                           % 勾配降下
    snew(:,:,1:K-1) = st(snew(:,:,1:K-1), lambda*eta);   % 低域成分以外をソフト閾値処理
    anew = (1 + sqrt(1 + 4*a^2))/2;
    y = snew + (a - 1)/anew*(snew - s);         % ネステロフの加速
    s = snew; a = anew;
end
Xr = min(max(Dm(s), 0), 1);
psnrR = psnr(Xr, Xg)
imwrite(Xr, fullfile(resfolder,"vie-10-rest.png"))
vie.savetex("vie-10-psnr-rest", sprintf("%.2f", psnrR));
vie.savetex("vie-10-lambda", sprintf("%g", lambda));
vie.savetex("vie-10-niter", sprintf("%d", nIter));
%%
%[text] ## 後片付け
rmdir(tmpfolder, "s");
%%
%[text] ## まとめ
%[text] - DCT のブロック処理はブロックノイズ・モスキートノイズを生む。DWT は重なりのある多重解像度の基底でこれを抑える
%[text] - 観測モデル $ \\mathbf{v}=\\mathbf{H}\\mathbf{x}+\\mathbf{w} $ から原画像を推定するのが画像復元（逆問題）
%[text] - 自然画像の変換係数は疎（ラプラス分布）で，1-ノルム正則化はこの事前知識を反映する
%[text] - ISTA／FISTA は勾配降下とソフト閾値処理を繰り返して解を求める \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
