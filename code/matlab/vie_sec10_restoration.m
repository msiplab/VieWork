%[text] # 第10回 画像復元
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第10回のスライド（vie2026-10）で使う図と数値を作る。DCT の問題点（ブロックノイズ・モスキートノイズ）と離散ウェーブレット変換（DWT），観測モデル $ \\mathbf{v}=\\mathbf{H}\\mathbf{x}+\\mathbf{w} $ ，最小二乗法と勾配降下法（GD 法），スパースモデリング（合成モデル $ \\mathbf{x}=\\mathbf{D}\\mathbf{s} $ ，1-ノルム正則化），ISTA／FISTA によるボケ＋ノイズ除去を扱う。記号は教科書に合わせる（ステップサイズ $ \\eta $ ，閾値 $ \\tau $ ，評価関数 $ \\mathfrak{J} $ ）。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図の配色はロゴの 3 色（メインの緑，寒色系の青，暖色系の橙）と灰色を使う。
[~,resfolder] = vie.prjfolders();
tmpfolder = fullfile(resfolder, "tmp"); if ~isfolder(tmpfolder), mkdir(tmpfolder); end
cMain = [0 136 85]/255;                         % メイン（緑 #008855）
cCool = [46 117 182]/255;                       % 寒色系（青 #2E75B6）
cWarm = [197 90 17]/255;                        % 暖色系（橙 #C55A11）
cGray = 0.55*[1 1 1];                           % 灰色
%%
%[text] ## DCT の問題点：ブロックノイズとモスキートノイズ
%[text] 低画質（品質 5）の JPEG で圧縮すると， $ 8\\times8 $ ブロックの境界が見える（ブロックノイズ），エッジのまわりにもやもやした揺らぎが出る（モスキートノイズ）。
%[text] 画像は教科書のサンプル画像 msipimg01.tif（海岸）を $ 256\\times256 $ 画素のグレースケールに縮小して使う（共通関数 `vie.msipimg` ）。なめらかな空ではブロックの階段状の境界が，水平線と桟橋の輪郭の上下には縞状の揺らぎがはっきり見える（石像の顔 msipimg05，建物 msipimg04，路面 msipimg06 などと比べて選んだ）。
X1 = im2double(vie.msipimg(1, 256, "gray"));   % 海岸（256×256）
jpgfile = fullfile(tmpfolder, "beach_q5.jpg");
imwrite(X1, jpgfile, "Quality", 5);
Xj = im2double(imread(jpgfile));
imwrite(imresize(Xj(1:64,129:192), 4, "nearest"), fullfile(resfolder,"vie-10-blocknoise.png"))   % 空の部分
imwrite(imresize(Xj(33:96,65:128), 4, "nearest"), fullfile(resfolder,"vie-10-mosquito.png"))     % 水平線と桟橋の輪郭付近
psnrJ = psnr(Xj, X1)
%%
%[text] ## JPEG と JPEG2000（同程度のファイルサイズ）
%[text] msipimg03.tif（マカロン，カラー $ 512\\times512 $ 画素）を約 12 kB になるよう JPEG と JPEG2000 で圧縮して比べる。なめらかなマカロンの表面で JPEG のブロックノイズが目立つ（花束 msipimg02，石像の顔 msipimg05 と比べて選んだ）。
Xc = vie.msipimg(3);                            % マカロン（カラー，512×512）
target = 12e3;                                  % 目標ファイルサイズ [bytes]
q = 1; sz = 0;
while sz < target && q < 100                     % 品質を上げながら目標サイズを超える手前を探す
    q = q + 1; imwrite(Xc, fullfile(tmpfolder,"mac.jpg"), "Quality", q);
    d = dir(fullfile(tmpfolder,"mac.jpg")); sz = d.bytes;
end
q = q - 1; imwrite(Xc, fullfile(tmpfolder,"mac.jpg"), "Quality", q);
d = dir(fullfile(tmpfolder,"mac.jpg")); szJ = d.bytes;
cr = numel(Xc)/szJ;                             % JPEG と同じ圧縮率
imwrite(Xc, fullfile(tmpfolder,"mac.jp2"), "CompressionRatio", cr);
d = dir(fullfile(tmpfolder,"mac.jp2")); szJ2 = d.bytes;
Yj = imread(fullfile(tmpfolder,"mac.jpg")); Yj2 = imread(fullfile(tmpfolder,"mac.jp2"));
sizes = [szJ szJ2]
psnrs = [psnr(Yj, Xc) psnr(Yj2, Xc)]
imwrite(Yj(129:384, 129:384, :),  fullfile(resfolder,"vie-10-jpeg.png"))   % 中央の 256×256
imwrite(Yj2(129:384, 129:384, :), fullfile(resfolder,"vie-10-jp2.png"))
vie.savetex("vie-10-size-jpg", sprintf("%.1f", szJ/1e3));
vie.savetex("vie-10-size-jp2", sprintf("%.1f", szJ2/1e3));
vie.savetex("vie-10-psnr-jpg", sprintf("%.1f", psnrs(1)));
vie.savetex("vie-10-psnr-jp2", sprintf("%.1f", psnrs(2)));
%%
%[text] ## 2 次元 DWT（3 レベル）と DCT の周波数配置
%[text] 9/7 DWT（MATLAB の `bior4.4` ）を 3 レベル施し，係数を周波数配置で並べる（多重解像度表現）。画像は第9回の vie-09-bdct と同じ msipimg04.tif（石造りの建物，256×256 のグレースケール）とし，第12回のスライドで並べたときに対応が分かるようにする。暗い空が平坦なので，係数の疎な様子が見やすい。
Xs = im2double(vie.msipimg(4, 256, "gray"));   % 石造りの建物（256×256）
[A1,H1,V1,D1] = dwt2(Xs, "bior4.4", "mode", "per");
[A2,H2,V2,D2] = dwt2(A1, "bior4.4", "mode", "per");
[A3,H3,V3,D3] = dwt2(A2, "bior4.4", "mode", "per");
sc = @(c) min(abs(c)*4, 1);                     % 係数の絶対値を見やすく表示
L3 = [A3/max(A3(:)) sc(H3); sc(V3) sc(D3)];
L2 = [L3 sc(H2); sc(V2) sc(D2)];
Wdwt = [L2 sc(H1); sc(V1) sc(D1)];
imwrite(Wdwt, fullfile(resfolder,"vie-10-dwt3.png"))
%[text] 比較のため，8×8 ブロック DCT の係数を周波数ごとに集めて並べ替える（各周波数 $ (u,v) $ の係数が一枚の縮小画像になる）。
Yb = blockproc(Xs, [8 8], @(b) dct2(b.data));
Wdct = zeros(size(Xs)); nb = size(Xs,1)/8;
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
%[text] 以降の画像復元の例では，教科書のサンプル画像 msipimg05.tif（石像の顔）を $ 256\\times256 $ 画素のグレースケールに縮小した画像を原画像 $ \\mathbf{x} $ とする。顔の輪郭や石の細かな模様があり，ボケとその除去の効果が見やすい。
Xg = im2double(vie.msipimg(5, 256, "gray"));   % 石像の顔（256×256）
%[text] 焦点ぼけなどは点広がり関数（PSF）との畳み込みで表される。PSF の例：標準偏差 $ \\sigma\_\\mathrm{g}=2 $ のガウス関数。周期境界（循環畳み込み）とし，測定行列 $ \\mathbf{H} $ の積と随伴 $ \\mathbf{H}^\\top $ の積を周波数領域で計算する（ $ \\mathbf{H}^\\top $ は相関，周波数応答の複素共役）。
psf = fspecial("gaussian", 25, 2);
Hf = psf2otf(psf, size(Xg));                    % 周期境界（循環畳み込み）の周波数応答
blur  = @(x) real(ifft2(Hf.*fft2(x)));          % H x
blurT = @(x) real(ifft2(conj(Hf).*fft2(x)));    % H^T x
Xb = blur(Xg);
imwrite(Xb, fullfile(resfolder,"vie-10-blur.png"))
imwrite(Xg, fullfile(resfolder,"vie-10-org.png"))
dimg = zeros(64); dimg(33,33) = 1;              % インパルス
imwrite(dimg, fullfile(resfolder,"vie-10-delta.png"))
pimg = conv2(dimg, psf, "same"); imwrite(pimg/max(pimg(:)), fullfile(resfolder,"vie-10-psf.png"))
%%
%[text] ## 観測ノイズ（AWGN）
%[text] 前回スライドの例：3 段階の明るさの正方形に平均 0，分散 $ \\sigma\_\\mathrm{w}^2=0.001 $ の白色ガウスノイズを加える。ヒストグラムの各ピークが正規分布に広がる。（スライドでは教科書の図 8.1 を使うので，この 3 枚の出力は現在使っていない。）
rng(0)
U = 0.25*ones(64); U(13:52,13:52) = 0.5; U(25:40,25:40) = 0.75;
Vn = U + sqrt(0.001)*randn(size(U));
imwrite(U, fullfile(resfolder,"vie-10-sq.png")), imwrite(min(max(Vn,0),1), fullfile(resfolder,"vie-10-sqn.png"))
fig = newfig(12, 4.5);
tiledlayout(fig, 1, 2, "TileSpacing","compact", "Padding","compact")
nexttile, histogram(U(:), 0:0.01:1, "EdgeColor","none", "FaceColor",cCool, "FaceAlpha",1), title("原画像のヒストグラム"), xlim([0 1])
nexttile, histogram(Vn(:), 0:0.01:1, "EdgeColor","none", "FaceColor",cCool, "FaceAlpha",1), title("観測画像のヒストグラム"), xlim([0 1])
savepng(fig, fullfile(resfolder,"vie-10-sqhist.png"), 200)
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
HtH = Hm'*Hm                                    % H^T H
Htv = Hm'*vm                                    % H^T v
xls = HtH\Htv
xpinv = pinv(Hm)*vm                             % ムーア・ペンローズ擬似逆行列でも同じ
vie.savetex("vie-10-ls-H", vie.arr2tex(Hm, "%g"));
vie.savetex("vie-10-ls-v", vie.arr2tex(vm, "%.1f"));
vie.savetex("vie-10-ls-hth", sprintf("%g", HtH));
vie.savetex("vie-10-ls-htv", sprintf("%.1f", Htv));
vie.savetex("vie-10-ls-x", sprintf("%g", xls));
%%
%[text] ## 勾配降下法（GD 法）の数値例
%[text] 同じ例に GD 法 $ x^{(t+1)}=x^{(t)}-\\eta\\,\\mathbf{H}^\\top(\\mathbf{H}x^{(t)}-\\mathbf{v}) $ （ $ \\lambda=0 $ ， $ \\eta=0.2 $ ， $ x^{(0)}=0 $ ）を適用する。評価関数 $ \\mathfrak{J}(x)=\\frac12\\|\\mathbf{v}-\\mathbf{H}x\\|\_2^2 $ は反復ごとに減少し，最小値解 $ \\hat{x}=1 $ に近づく。
%[text] ステップサイズの条件は $ \\eta\\in(0,2/\\|\\mathbf{H}\\|\_\\mathrm{S}^2) $ 。この例では $ \\|\\mathbf{H}\\|\_\\mathrm{S}^2=\\mathbf{H}^\\top\\mathbf{H}=3 $ なので $ \\eta<2/3 $ 。誤差 $ x^{(t)}-\\hat{x} $ は 1 回の反復で $ 1-\\eta\\mathbf{H}^\\top\\mathbf{H} $ 倍になる。
etaLs = 0.2; nStep = 6;
Jls = @(x) 0.5*sum((vm - Hm*x).^2);             % 評価関数 J(x)
xgd = zeros(1, nStep+1);                        % x^(0), x^(1), ..., x^(nStep)
for t = 1:nStep
    xgd(t+1) = xgd(t) - etaLs*Hm'*(Hm*xgd(t) - vm);
end
xgd
Jgd1 = arrayfun(Jls, xgd)                       % 評価関数の値（単調に減少）
Jmin = Jls(xls)
hs2 = norm(Hm)^2                                % スペクトルノルムの二乗 ||H||_S^2
rho = 1 - etaLs*HtH                             % 誤差が 1 回で何倍になるか
vie.savetex("vie-10-gd", strjoin(compose("%.3f", xgd(1:5)), ",\ "));        % x^(0), ..., x^(4)
vie.savetex("vie-10-gd-J", strjoin(compose("%.3f", Jgd1(1:5)), ",\ "));     % J(x^(0)), ..., J(x^(4))
vie.savetex("vie-10-gd-Jmin", sprintf("%.3f", Jmin));
vie.savetex("vie-10-gd-eta", sprintf("%g", etaLs));
vie.savetex("vie-10-gd-hs2", sprintf("%g", hs2));
%[text] 反復の様子を評価関数のグラフ上に描く（前回スライドの手描きの図を踏襲）。
fig = newfig(4.0, 2.6);
xx = linspace(-0.15, 1.25, 200);
plot(xx, arrayfun(Jls, xx), "Color", cMain, "LineWidth", 1.5), hold on
nShow = 3;                                      % 矢印で示す反復の数
plot(xgd(1:nShow+1), Jgd1(1:nShow+1), "o", "MarkerSize", 4, "MarkerFaceColor", cWarm, "MarkerEdgeColor", cWarm)
plot(xls, Jmin, "o", "MarkerSize", 4, "MarkerFaceColor", cCool, "MarkerEdgeColor", cCool)
text(xgd(1)+0.05, Jgd1(1)+0.10, "$x^{(0)}$", "Interpreter","latex", "FontSize", 9)
text(xgd(2)-0.06, Jgd1(2)-0.12, "$x^{(1)}$", "Interpreter","latex", "FontSize", 9, "HorizontalAlignment","right")
text(xls+0.06, Jmin+0.20, "$\hat{x}$", "Interpreter","latex", "FontSize", 9, "Color", cCool)
hold off, box off
xlim([-0.15 1.25]), ylim([0 1.9]), xticks([0 0.5 1])
xlabel("$x$", "Interpreter","latex"), set(gca, "FontSize", 8, "TickLabelInterpreter","latex")
for t = 1:nShow                                 % x^(t-1) から x^(t) への矢印
    dataarrow(gca, xgd(t:t+1), Jgd1(t:t+1), cWarm)
end
savepng(fig, fullfile(resfolder,"vie-10-gd-path.png"), 300)
%%
%[text] ## GD 法によるボケ除去（評価関数の減少）
%[text] 2025 年度の演習（ `gdstep` ）にならい，ボケ＋ノイズの観測画像 $ \\mathbf{v} $ に GD 法を適用する。ガウシアンフィルタは係数が非負で総和 1 なので $ \\|\\mathbf{H}\\|\_\\mathrm{S}=\\max|H[\\boldsymbol{k}]|=1 $ となり， $ \\eta=1\\in(0,2) $ とする。
%[text] $ \\lambda=0 $ （LS 法）と $ \\lambda=10^{-2} $ ， $ \\mathbf{L}=\\mathbf{I} $ （リッジ正則化）を比べる。どちらも評価関数 $ \\mathfrak{J}(\\mathbf{x}^{(t)}) $ は単調に減少する。LS 法は途中で PSNR が最大になったあと低下する（ノイズの増幅．不良設定問題）。リッジ正則化では推定が安定する。
etaGd = 1; nGd = 300; lams = [0 1e-2];
Jimg = zeros(nGd+1, numel(lams)); Pimg = Jimg;   % 評価関数と PSNR の履歴
for k = 1:numel(lams)
    lam = lams(k); x = zeros(size(V));          % 初期値 x^(0) = 0
    for t = 0:nGd
        if t > 0
            g = blurT(blur(x) - V) + lam*x;     % 勾配 (H^T H + λI)x - H^T v
            x = x - etaGd*g;                    % 勾配降下
        end
        Jimg(t+1,k) = 0.5*norm(V - blur(x), "fro")^2 + lam/2*norm(x, "fro")^2;
        Pimg(t+1,k) = psnr(x, Xg);
    end
end
assert(all(diff(Jimg) <= 1e-9, "all"), "評価関数が増加した")
[psnrPeak, iPeak] = max(Pimg(:,1)); tPeak = iPeak - 1
psnrEnd = Pimg(end,:)
fig = newfig(5.2, 4.6);
tiledlayout(fig, 2, 1, "TileSpacing","tight", "Padding","compact");
tt = 1:nGd;
nexttile
semilogy(tt, Jimg(tt+1,1), "Color", cWarm, "LineWidth", 1.5), hold on
semilogy(tt, Jimg(tt+1,2), "Color", cMain, "LineWidth", 1.5), hold off
xlim([0 nGd]), ylim([30 200]), yticks([50 100 200]), grid on, set(gca, "FontSize", 9, "XTickLabel", [])
ylabel("評価関数", "FontSize", 8)                % 凡例はスライド側に書く（橙：λ=0，緑：λ=10^{-2}）
nexttile
plot(tt, Pimg(tt+1,1), "Color", cWarm, "LineWidth", 1.5), hold on
plot(tt, Pimg(tt+1,2), "Color", cMain, "LineWidth", 1.5)
yline(psnrV, ":", "Color", cGray, "LineWidth", 1)
plot(tPeak, psnrPeak, "o", "MarkerSize", 4, "MarkerFaceColor", cWarm, "MarkerEdgeColor", cWarm), hold off
text(tPeak+8, psnrPeak+0.4, "\itt\rm=" + tPeak, "FontSize", 8, "Color", cWarm)
text(nGd-5, psnrV+0.4, "観測", "FontSize", 8, "Color", cGray, "HorizontalAlignment", "right")
xlim([0 nGd]), ylim([17 21.5]), grid on, set(gca, "FontSize", 9)
ylabel("PSNR [dB]", "FontSize", 8), xlabel("反復回数 \itt", "FontSize", 8)
savepng(fig, fullfile(resfolder,"vie-10-gd-deblur.png"), 300)
vie.savetex("vie-10-gd-etaimg", sprintf("%g", etaGd));
vie.savetex("vie-10-gd-lam", sprintf("10^{%d}", round(log10(lams(2)))));
%%
%[text] ## ノイズと信号変換：ハール変換の詳細成分
%[text] 原画像の詳細成分はほとんどが 0 付近（疎）だが，ノイズを加えると全体に広がる（密）。絶対値が閾値 0.02 未満の係数の割合で比べる。
%[text] この節（と次の節のヒストグラム）の画像は msipimg04.tif（石造りの建物，256×256 のグレースケール）とする。暗い空などの平坦な領域が広く，ノイズの有無による疎・密の違いがはっきり出る（8 枚の中で疎な係数の割合が最も大きい。石像の顔 msipimg05 では差が小さい）。
Xs = im2double(vie.msipimg(4, 256, "gray"));   % 石造りの建物（256×256）
[~,Hc,Vc,Dc] = dwt2(Xs, "haar");
Xn = Xs + 20/255*randn(size(Xs));
[~,Hn,Vn2,Dn] = dwt2(Xn, "haar");
imwrite(Xs, fullfile(resfolder,"vie-10-sp-org.png"))
imwrite(min(abs(Hc)*4,1), fullfile(resfolder,"vie-10-detail-clean.png"))
imwrite(min(abs(Hn)*4,1), fullfile(resfolder,"vie-10-detail-noisy.png"))
imwrite(min(max(Xn,0),1), fullfile(resfolder,"vie-10-noisy.png"))
thSp = 0.02;
sp = [mean(abs(Hc(:)) < thSp) mean(abs(Hn(:)) < thSp)]
vie.savetex("vie-10-sp-th", sprintf("%g", thSp));
vie.savetex("vie-10-sp-clean", sprintf("%.0f", 100*sp(1)));
vie.savetex("vie-10-sp-noisy", sprintf("%.0f", 100*sp(2)));
%%
%[text] ## 画像データについての事前知識：詳細成分のヒストグラム
%[text] ラプラス分布 $ \\mathcal{L}(s;0,b)=(2b)^{-1}\\exp(-|s|/b) $ の尺度 $ b $ を平均絶対値（最尤推定）で求めて重ねる。
dcoef = [Hc(:); Vc(:); Dc(:)];
b = mean(abs(dcoef))                            % ラプラス分布の尺度（平均絶対値）
ss = linspace(-1, 1, 801);
fig = newfig(6.0, 4.2);
histogram(dcoef, -1:0.005:1, "Normalization", "pdf", "EdgeColor","none", "FaceColor", cCool, "FaceAlpha", 0.55), hold on
plot(ss, exp(-abs(ss)/b)/(2*b), "Color", cWarm, "LineWidth", 1.5), hold off
xlim([-0.2 0.2]), xlabel("$s$", "Interpreter","latex"), ylabel("確率密度")
legend(["ハール詳細成分","ラプラス分布"], "FontSize", 8), box off
set(gca, "FontSize", 9)
savepng(fig, fullfile(resfolder,"vie-10-dethist.png"), 300)
vie.savetex("vie-10-lap-b", sprintf("%.3f", b));
%%
%[text] ## 1-ノルム正則化：ラプラス分布とガウス分布
%[text] 同じ分散 $ 2b^2 $ （ $ b=0.1 $ ）のラプラス分布とガウス分布を比べる。ラプラス分布は零の近くで尖り，裾が重い。
bL = 0.1; sgG = sqrt(2)*bL;
fig = newfig(6.4, 4.6);
plot(ss, exp(-abs(ss)/bL)/(2*bL), "Color", cWarm, "LineWidth", 1.5), hold on
plot(ss, exp(-ss.^2/(2*sgG^2))/(sqrt(2*pi)*sgG), "--", "Color", cCool, "LineWidth", 1.5), hold off
grid on, xlim([-0.5 0.5]), ylim([0 6.5])
legend(["ラプラス分布（尖る）","ガウス分布（同じ分散）"], "FontSize", 8, "Location", "northeast")
xlabel("$s$", "Interpreter","latex"), ylabel("$p(s)$", "Interpreter","latex"), set(gca, "FontSize", 9)
savepng(fig, fullfile(resfolder,"vie-10-laplace.png"), 300)
%%
%[text] ## ソフト閾値処理
%[text] $ \\phi\_\\mathrm{ST}(x;\\tau)=\\mathrm{sign}(x)\\max(|x|-\\tau,0) $ 。数値例（ $ \\tau=1 $ ）：
st = @(x,tau) sign(x).*max(abs(x) - tau, 0);
xs = [-3 -0.5 0.2 2];
ys = st(xs, 1)
vie.savetex("vie-10-st-x", strjoin(compose("%g",xs),",\ "));
vie.savetex("vie-10-st-y", strjoin(compose("%g",ys+0),",\ "));
%[text] グラフには数値例の 4 点（橙）と恒等写像 $ y=x $ （点線）も描く。 $ |x|\\leq\\tau $ は 0 に，それ以外は $ \\tau $ だけ原点に近づく。
xx = linspace(-3, 3, 601);
fig = newfig(4.0, 3.1);
plot(xx, xx, ":", "Color", cGray, "LineWidth", 1), hold on
plot(xx, st(xx,1), "Color", cMain, "LineWidth", 1.8)
plot(xs, ys, "o", "MarkerSize", 4, "MarkerFaceColor", cWarm, "MarkerEdgeColor", cWarm), hold off
grid on, axis equal, xlim([-3 3]), ylim([-2.2 2.2]), xticks([-3 -1 0 1 3]), yticks([-2 -1 0 1 2])
xlabel("$x$", "Interpreter","latex"), ylabel("$\phi_\mathrm{ST}(x;\tau)$", "Interpreter","latex")
set(gca, "FontSize", 8, "TickLabelInterpreter","latex")
savepng(fig, fullfile(resfolder,"vie-10-soft.png"), 300)
%%
%[text] ## FISTA によるボケ＋ノイズ除去
%[text] 合成辞書 $ \\mathbf{D} $ に 3 段の非間引きハール DWT（パーセバルタイト枠）を用いる。周期境界の畳み込みとして周波数領域で実装する。各段のフィルタは $ \\frac12(1\\pm z^{-2^{j-1}}) $ 。（スライドの「ボケ＋ノイズ除去の例」は教科書の図 1.4 を使うので，この節の出力 vie-10-rest，vie-10-psnr-rest，vie-10-lambda，vie-10-niter は現在使っていない。）
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
%[text] 例題「ステップサイズ条件」の数値確認。周期境界の畳み込み $ \\mathbf{H} $ のスペクトルノルムは周波数振幅応答の最大値 $ \\max\_{\\boldsymbol{k}}|H[\\boldsymbol{k}]| $ 。 $ \\mathbf{H}\\mathbf{D}\\mathbf{D}^\\top\\mathbf{H}^\\top $ も巡回行列で，その周波数応答は $ |H[\\boldsymbol{k}]|^2\\sum\_p|F\_p[\\boldsymbol{k}]|^2=|H[\\boldsymbol{k}]|^2 $ なので $ \\|\\mathbf{H}\\mathbf{D}\\|\_\\mathrm{S}^2=\\|\\mathbf{H}\\|\_\\mathrm{S}^2 $ 。ガウシアンフィルタは直流で最大値 1 をとる。
normH = max(abs(Hf), [], "all")                 % ||H||_S
normHD2 = max(abs(Hf).^2.*sum(abs(F).^2, 3), [], "all")   % ||HD||_S^2
vie.savetex("vie-10-normH", sprintf("%.3f", normH));
vie.savetex("vie-10-normHD2", sprintf("%.3f", normHD2));
T  = @(x) real(ifft2(F.*fft2(x)));                   % 分析 D^T（係数は N1×N2×K）
Dm = @(c) real(ifft2(sum(conj(F).*fft2(c), 3)));     % 合成 D
HD  = @(c) blur(Dm(c));
HDt = @(r) T(blurT(r));
lambda = 1e-3; eta = 1; nIter = 20;             % 教科書と同じ設定（実験的に決めたもの）．η = 1 ≤ 1/||HD||_S^2
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
%[text] - GD 法は評価関数を単調に減少させる。LS 法（ $ \\lambda=0 $ ）はノイズを増幅するので，正則化で推定を安定させる
%[text] - 自然画像の変換係数は疎（ラプラス分布）で，1-ノルム正則化はこの事前知識を反映する
%[text] - ISTA／FISTA は勾配降下とソフト閾値処理を繰り返して解を求める \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
%%
%[text] ## 関数定義
%[text] 図を指定の大きさ（cm）で新しく用意する。書き出した図をスライドで縮小しても文字が読めるよう，表示の大きさに近い寸法で描く。既存の図の大きさを変えると，ウィンドウの大きさの反映が書き出しに間に合わないことがあるので，毎回新しい図を作る。
function fig = newfig(w, h)
fig = figure("WindowStyle", "normal", "Color", "w", ...
    "Units", "centimeters", "Position", [2 2 w h]);
drawnow
end
%[text] データ座標の 2 点 $ (x\_1,y\_1)\\to(x\_2,y\_2) $ を結ぶ矢印を描く（両端を少し縮めて点の印と重ならないようにする）。
function dataarrow(ax, x, y, color)
drawnow
shrink = 0.12;                                  % 両端を縮める割合
xs = x(1) + [shrink 1-shrink]*(x(2) - x(1));
ys = y(1) + [shrink 1-shrink]*(y(2) - y(1));
ax.Units = "normalized"; pos = ax.Position;
nx = pos(1) + (xs - ax.XLim(1))/diff(ax.XLim)*pos(3);
ny = pos(2) + (ys - ax.YLim(1))/diff(ax.YLim)*pos(4);
annotation(ax.Parent, "arrow", nx, ny, "Color", color, "LineWidth", 1, ...
    "HeadLength", 4, "HeadWidth", 4);
end
%[text] 図を PNG で書き出して閉じる。
function savepng(fig, filename, res)
drawnow
exportgraphics(fig, filename, "Resolution", res)
close(fig)
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
