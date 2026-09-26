%[text] # 第7回 フーリエ解析
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第7回のスライド（vie2026-07）で使う図と数値を作る。多次元信号の周波数，フーリエ解析（FT, DSFT, DFT），DFT と DSFT の関係，FFT の演算量，周波数応答，位相応答の重要性を扱う。記号は教科書に合わせ，連続変数の角周波数を $ \\boldsymbol{\\nu} $ ，離散変数の正規化角周波数を $ \\boldsymbol{\\omega} $ とする。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[~,resfolder] = vie.prjfolders();
%%
%[text] ## 一次元余弦波の角周波数
%[text] $ x(t)=\\cos(\\nu t) $ の角周波数 $ \\nu $ は位相 $ \\nu t $ の時間微分。単位時間に 3 周期の波なら $ \\nu = 2\\pi\\times 3 = 6\\pi $ [rad/s]。
t = linspace(0, 1, 1001);
nu = 2*pi*3
clf
plot(t, cos(nu*t), "LineWidth", 2), grid on
xlabel("t"), ylabel("x(t)"), title("x(t)=cos(6\pi t)（単位時間に 3 周期）")
set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-07-cos1d.png"), "Resolution", 120)
%%
%[text] ## 信号は正弦波の足し合わせ
%[text] 3 つの余弦波（1, 3, 7 周期／単位時間，振幅 1, 0.5, 0.25）の和と，その振幅スペクトル（周波数分布）。
f = [1 3 7]; A = [1 0.5 0.25];
comps = A'.*cos(2*pi*f'*t);
xsum = sum(comps, 1);
tiledlayout(4,1,"TileSpacing","compact","Padding","compact")
for k = 1:3
    nexttile, plot(t, comps(k,:), "LineWidth", 1.5), ylim([-1.1 1.1]), axis off
end
nexttile, plot(t, xsum, "k", "LineWidth", 2), axis off, title("和 x(t)")
exportgraphics(gcf, fullfile(resfolder,"vie-07-sumsin.png"), "Resolution", 120)
clf
stem(2*pi*f, A, "filled", "LineWidth", 2), grid on, xlim([0 2*pi*8])
xticks(2*pi*f), xticklabels(["2\pi","6\pi","14\pi"])
xlabel("角周波数 \nu"), ylabel("振幅"), title("周波数スペクトル（最大角周波数 14\pi）")
set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-07-spec1d.png"), "Resolution", 120)
%%
%[text] ## 例題：二次元配列の DSFT と DFT
%[text] 前回スライドの例題。 $ x[0,0]=x[1,0]=x[0,1]=x[1,1]=1 $ ，その他 0。DSFT は
%[text]{"align":"center"} $ X(e^{j\\boldsymbol{\\omega}^\\top})=(1+e^{-j\\omega\_0})(1+e^{-j\\omega\_1})=4\\cos\\frac{\\omega\_0}{2}\\cos\\frac{\\omega\_1}{2}e^{-j(\\omega\_0+\\omega\_1)/2} $
%[text] 各軸の周期 2 の DFT は DSFT を $ \\omega\_d=\\pi k\_d $ で標本化したもの。
x22 = ones(2);
X22 = fft2(x22)
dsft = @(w0,w1) 4*cos(w0/2).*cos(w1/2).*exp(-1j*(w0+w1)/2);
Xs = [dsft(0,0) dsft(0,pi); dsft(pi,0) dsft(pi,pi)];
maxerr = max(abs(Xs - X22), [], "all")        % 一致を確認（丸め誤差程度）
vie.savetex("vie-07-ex-X", vie.arr2tex(real(X22),"%g"));
%%
%[text] ## DFT は DSFT の周波数標本
%[text] 一次元 $ x[n]=(2,2) $ の DSFT $ X(e^{j\\omega})=2+2e^{-j\\omega}=4\\cos(\\omega/2)e^{-j\\omega/2} $ と， $ N $ 点 DFT（ $ \\omega=2\\pi k/N $ の標本）を比べる。
w = linspace(0, 2*pi, 721);
Xw = 2 + 2*exp(-1j*w);
X2 = fft([2 2])                               % N = 2
X8 = fft([2 2], 8);                           % N = 8（零値を追加）
k8 = 0:7;
clf
plot(w, real(Xw), "b", w, imag(Xw), "r", "LineWidth", 1.5), hold on
plot(2*pi*k8/8, real(X8), "bo", 2*pi*k8/8, imag(X8), "ro", "MarkerSize", 7, "LineWidth", 1.5)
plot(2*pi*(0:1)/2, real(X2), "gs", "MarkerSize", 12, "LineWidth", 2)
hold off, grid on, xlim([0 2*pi])
xticks(0:pi/2:2*pi), xticklabels(["0","\pi/2","\pi","3\pi/2","2\pi"])
legend(["Re X(e^{j\omega})","Im X(e^{j\omega})","Re X[k] (N=8)","Im X[k] (N=8)","X[k] (N=2)"], "Location","southwest")
xlabel("\omega"), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-07-dftsample.png"), "Resolution", 120)
vie.savetex("vie-07-X2", strjoin(compose("%g",real(X2)),",\ "));
%%
%[text] ## FFT の演算量
%[text] $ N $ 点 DFT を行列演算で計算すると複素乗算は $ N^2 $ 回，周波数間引き FFT では $ \\frac{N}{2}\\log\_2 N $ 回。
N = 2.^(1:10);
mulMat = N.^2;
mulFFT = N/2.*log2(N);
clf
semilogy(N, mulMat, "o-", N, mulFFT, "s-", "LineWidth", 1.5), grid on
legend(["行列演算 N^2","FFT (N/2)log_2N"], "Location","northwest")
xlabel("N"), ylabel("複素乗算回数"), set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-07-fftcount.png"), "Resolution", 120)
n1024 = [mulMat(end) mulFFT(end) mulMat(end)/mulFFT(end)]
vie.savetex("vie-07-fft-mat",   vie.fmtint(mulMat(end)));
vie.savetex("vie-07-fft-fft",   vie.fmtint(mulFFT(end)));
vie.savetex("vie-07-fft-ratio", sprintf("%.0f", n1024(3)));
%%
%[text] ## 9 点移動平均の周波数応答
%[text] 教科書の例題。 $ 3\\times3 $ 矩形フィルタ（中心が $ h[0,0] $ ）の周波数応答は
%[text]{"align":"center"} $ H(e^{j\\boldsymbol{\\omega}^\\top})=\\frac19(1+2\\cos\\omega\_0)(1+2\\cos\\omega\_1) $
[w0, w1] = meshgrid(linspace(-pi, pi, 61));
Hbox = (1 + 2*cos(w0)).*(1 + 2*cos(w1))/9;
Hval = [1 (1+2*cos(pi))^2/9 (1+2*cos(2*pi/3))]  % ω=(0,0), (π,π), ω0=2π/3 のとき
vie.savetex("vie-07-Hpi", sprintf("%.3f", Hval(2)));
%[text] 4 種類のカーネルの振幅応答 $ |H(e^{j\\boldsymbol{\\omega}^\\top})| $ を DSFT の定義に従って計算する。
kers = {ones(3)/9, [1 2 1; 2 4 2; 1 2 1]/16, [0 1 0; 1 -4 1; 0 1 0], [0 -1 0; -1 5 -1; 0 -1 0]};
tags = ["box","gauss","lap","us"];
ttl  = ["平均（矩形）","加重平均","4 近傍ラプラシアン","アンシャープマスク"];
[m0, m1] = meshgrid(-1:1);                    % カーネルの添え字（中心が原点）
for k = 1:4
    H = zeros(size(w0));
    for i = 1:9
        H = H + kers{k}(i)*exp(-1j*(w0*m0(i) + w1*m1(i)));
    end
    clf
    mesh(w0, w1, abs(H)), axis tight, view(-35, 30)
    xlabel("\omega_1"), ylabel("\omega_0"), zlabel("|H|"), title(ttl(k))
    xticks([-pi 0 pi]), xticklabels(["-\pi","0","\pi"]), yticks([-pi 0 pi]), yticklabels(["-\pi","0","\pi"])
    set(gca, "FontSize", 13)
    exportgraphics(gca, fullfile(resfolder,"vie-07-freq-"+tags(k)+".png"), "Resolution", 110)
end
%%
%[text] ## 直線位相の必要性
%[text] 2 つの周波数成分からなるパルスを，直線位相のシステム（純粋な遅延 $ h[n]=\\delta[n-5] $ ）と非直線位相のシステム（全域通過フィルタ）に通す。どちらも振幅応答は 1 だが，非直線位相では成分ごとに遅れが異なり波形がひずむ。
n = 0:79;
env = exp(-((n-25)/7).^2);
xin = env.*(sin(0.25*pi*n) + sin(0.6*pi*n));
ylin = [zeros(1,5) xin(1:end-5)];              % 直線位相（遅延）
a = 0.8;
ynl = filter([-a 1], [1 -a], xin);             % 全域通過（|H|=1，非直線位相）
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, plot(n, xin, "k", "LineWidth", 1.5), title("入力"), axis tight
nexttile, plot(n, ylin, "b", "LineWidth", 1.5), title("直線位相の出力（同じ形）"), axis tight
nexttile, plot(n, ynl, "r", "LineWidth", 1.5), title("非直線位相の出力（ひずむ）"), axis tight, xlabel("n")
exportgraphics(gcf, fullfile(resfolder,"vie-07-phase-demo.png"), "Resolution", 120)
%[text] 位相応答を比べる。直線位相は $ \\theta(\\omega)=-5\\omega $ の直線，全域通過フィルタは曲線。
wl = linspace(0, pi, 256);
[Hn, ~] = freqz([-a 1], [1 -a], wl);
clf
plot(wl, -5*wl, "b", wl, unwrap(angle(Hn)), "r", "LineWidth", 2), grid on
legend(["直線位相（傾き -5）","非直線位相"], "Location","southwest")
xlabel("\omega"), ylabel("\theta(\omega)"), xlim([0 pi]), set(gca, "FontSize", 13)
xticks([0 pi/2 pi]), xticklabels(["0","\pi/2","\pi"])
exportgraphics(gca, fullfile(resfolder,"vie-07-phase-resp.png"), "Resolution", 120)
%%
%[text] ## 画像信号の振幅スペクトルと位相スペクトル
%[text] cameraman.tif の DFT を求め，振幅スペクトル（対数表示，原点を中央に移動）と位相スペクトルを表示する。
Xc = im2double(imread("cameraman.tif"));
Fc = fft2(Xc);
magS = log(1 + abs(fftshift(Fc)));
phaS = angle(fftshift(Fc));
imwrite(Xc, fullfile(resfolder,"vie-07-img.png"))
imwrite(magS/max(magS(:)), fullfile(resfolder,"vie-07-img-mag.png"))
imwrite((phaS+pi)/(2*pi), fullfile(resfolder,"vie-07-img-pha.png"))
%[text] 振幅だけ（位相 0）と位相だけ（振幅 1）から IDFT で再構成する。位相だけからの再構成の方が輪郭の面影を残す。
Ymag = real(ifft2(abs(Fc)));                   % 位相 0
Ypha = real(ifft2(exp(1j*angle(Fc))));         % 振幅 1
Ymag = fftshift(Ymag);                         % 原点付近に集まるので中央へ移動して表示
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(log(1+abs(Ymag)), []), title("振幅スペクトルのみ")
nexttile, imshow(Ypha, []), title("位相スペクトルのみ")
imwrite(mat2gray(log(1+abs(Ymag))), fullfile(resfolder,"vie-07-img-magonly.png"))
imwrite(mat2gray(Ypha), fullfile(resfolder,"vie-07-img-phaonly.png"))
%%
%[text] ## 直線位相と対称性
%[text] 偶対称なインパルス応答 $ h=(1,3,3,1)/8 $ （中心 1.5）は直線位相 $ \\theta(\\omega)=-1.5\\omega $ 。非対称な $ h=(4,2,1,1)/8 $ は非直線位相。
hs = [1 3 3 1]/8; hn = [4 2 1 1]/8;
[Hs, ~] = freqz(hs, 1, wl); [Hnn, ~] = freqz(hn, 1, wl);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, stem(0:3, hs, "filled", "LineWidth", 1.5), hold on, stem(0:3, hn, "LineWidth", 1.5), hold off
xlim([-0.5 3.5]), legend(["偶対称","非対称"]), title("インパルス応答")
nexttile([1 2]), plot(wl, unwrap(angle(Hs)), "b", wl, unwrap(angle(Hnn)), "r", "LineWidth", 2), grid on
legend(["偶対称：直線位相","非対称：非直線位相"], "Location","southwest"), xlim([0 pi])
xlabel("\omega"), ylabel("\theta(\omega)"), title("位相応答")
exportgraphics(gcf, fullfile(resfolder,"vie-07-sym-phase.png"), "Resolution", 120)
slope = mean(diff(unwrap(angle(Hs(1:200))))./diff(wl(1:200)))   % 傾き ≈ -1.5
vie.savetex("vie-07-sym-slope", sprintf("%.1f", slope));
%%
%[text] ## まとめ
%[text] - 二次元余弦波の角周波数は位相の各方向の偏微分で与えられる
%[text] - DFT は DSFT の周波数標本で，各次元の一次元 DFT（FFT）に分離できる
%[text] - 畳み込みは周波数領域では積になる（周波数応答）
%[text] - 画像では位相スペクトルが重要で，対称なインパルス応答は直線位相をもつ \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
