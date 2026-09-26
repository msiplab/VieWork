%[text] # 第7回 フーリエ解析
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第7回のスライド（vie2026-07）で使う図と数値を作る。多次元信号の周波数，多次元周期信号と周期構造行列，フーリエ解析（FT, DSFT, DFT），DFT と DSFT の関係，DFT の分離処理と行列表現，FFT の演算量，周波数スペクトル，周波数応答，位相応答の重要性を扱う。
%[text] 記号は教科書に合わせる。連続変数の角周波数ベクトルを $ \\boldsymbol{\\nu} $ ，離散変数の正規化角周波数ベクトルを $ \\boldsymbol{\\omega}=(\\omega\_1\\ \\omega\_2)^\\top $ ，周期構造行列を $ \\boldsymbol{N} $ ，標本化行列を $ \\boldsymbol{L} $ とし，DSFT を $ X(\\mathrm{e}^{\\mathrm{j}\\boldsymbol{\\omega}^\\top}) $ と書く。次元の添え字は 1 始まりで，第 1 次元（ $ n\_1 $ ， $ \\omega\_1 $ ）が垂直，第 2 次元（ $ n\_2 $ ， $ \\omega\_2 $ ）が水平。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図の配色はロゴの 3 色（メインの緑，寒色系の青，暖色系の橙）と灰色にそろえる。振幅の曲面には淡い緑から濃い緑への色図を使う。
[~,resfolder] = vie.prjfolders();
cMain = [0 136 85]/255;                        % メイン（緑）
cCool = [46 117 182]/255;                      % 寒色系（青）
cWarm = [197 90 17]/255;                       % 暖色系（橙）
cGray = [0.45 0.45 0.45];                      % 灰色
cmapMain = interp1([0 0.5 1], [1-0.35*(1-cMain); cMain; 0.6*cMain], linspace(0,1,256));   % 淡い緑→緑→濃い緑
%%
%[text] ## 一次元余弦波の角周波数
%[text] $ x(t)=\\cos(\\nu t) $ の角周波数 $ \\nu $ は位相 $ \\nu t $ の時間微分。単位時間に 3 周期の波なら $ \\nu = 2\\pi\\times 3 = 6\\pi $ [rad/s]，周期は $ 2\\pi/\\nu=1/3 $ 。
t = linspace(0, 1, 1001);
nu = 2*pi*3
T1 = 2*pi/nu
vie.savetex("vie-07-nu1d", pistr(nu));        % 6\pi
vie.savetex("vie-07-T1d", fracstr(T1));       % 1/3
clf
plot(t, cos(nu*t), "Color", cMain, "LineWidth", 2), grid on
xlabel("$t$", "Interpreter","latex"), ylabel("$x(t)$", "Interpreter","latex")
title("{\itx}({\itt}) = cos(6\pi{\itt})（単位時間に 3 周期）")
set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-07-cos1d.png"), "Resolution", 120, "Padding", 10)
%%
%[text] ## 信号は正弦波の足し合わせ
%[text] 3 つの余弦波（1, 3, 7 周期／単位時間，振幅 1, 0.5, 0.25）の和と，その振幅スペクトル（周波数分布）。
f = [1 3 7]; A = [1 0.5 0.25];
comps = A'.*cos(2*pi*f'*t);
xsum = sum(comps, 1);
compColors = [cCool; cMain; cWarm];
tiledlayout(4,1,"TileSpacing","compact","Padding","compact")
for k = 1:3
    nexttile, plot(t, comps(k,:), "Color", compColors(k,:), "LineWidth", 1.5), ylim([-1.1 1.1]), axis off
end
nexttile, plot(t, xsum, "k", "LineWidth", 2), axis off, title("和 {\itx}({\itt})")
exportgraphics(gcf, fullfile(resfolder,"vie-07-sumsin.png"), "Resolution", 120, "Padding", 10)
clf
stem(2*pi*f, A, "filled", "Color", cMain, "LineWidth", 2), grid on, xlim([0 2*pi*8])
xticks(2*pi*f), xticklabels(["2\pi","6\pi","14\pi"])
xlabel("角周波数 {\it\nu}"), ylabel("振幅"), title("周波数スペクトル（最大角周波数 14\pi）")
set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-07-spec1d.png"), "Resolution", 120, "Padding", 10)
%%
%[text] ## 例題：多次元余弦波の標本化
%[text] 教科書の例題。 $ D $ 次元余弦波 $ u(\\boldsymbol{q})=\\cos(\\boldsymbol{\\nu}^\\top\\boldsymbol{q}) $ をディラックのデルタで，標本化行列 $ \\boldsymbol{L}=\\mathrm{diag}(\\Delta\_1,\\ldots,\\Delta\_D) $ の格子上で標本化すると
%[text]{"align":"center"} $ x[\\boldsymbol{n}]=\\cos(\\boldsymbol{\\nu}^\\top\\boldsymbol{L}\\boldsymbol{n})=\\cos(\\boldsymbol{\\omega}^\\top\\boldsymbol{n}),\\quad \\boldsymbol{\\omega}=\\boldsymbol{L}^\\top\\boldsymbol{\\nu} $
%[text] すなわち $ \\omega\_d=\\Delta\_d\\nu\_d=\\nu\_d/F\_d $ （ $ F\_d=\\Delta\_d^{-1} $ ：標本化周波数）。数値例として，教科書 図 4.2 (c) の $ \\boldsymbol{\\nu}=(4\\pi\\ 2\\pi)^\\top $ を $ \\Delta\_1=\\Delta\_2=1/8 $ （ $ F\_d=8 $ ）で標本化する。
nuS = [4*pi; 2*pi];                            % 角周波数ベクトル ν（図 4.2 (c)）
L = diag([1/8 1/8]);                           % 標本化行列 L
omegaS = L.'*nuS                               % 正規化角周波数ベクトル ω = L^T ν
[n2g, n1g] = meshgrid(0:15);                   % 標本点の添え字 n = (n1 n2)^T
nS = [n1g(:) n2g(:)].';
errS = max(abs(cos(nuS.'*L*nS) - cos(omegaS.'*nS)))   % 両者が一致することを確認
vie.savetex("vie-07-samp-nu",    strjoin(arrayfun(@pistr, nuS.'), "\ \ "));
vie.savetex("vie-07-samp-L",     strjoin(arrayfun(@fracstr, diag(L).'), ","));
vie.savetex("vie-07-samp-omega", strjoin(arrayfun(@pistr, omegaS.'), "\ \ "));
%%
%[text] ## 例題：非長方周期構造と基本周期内の整数ベクトル
%[text] 教科書の例題（図 4.3）。基本周期（灰色の平行四辺形）の辺 $ \\boldsymbol{n}\_1=[2\\ 0]^\\top $ ， $ \\boldsymbol{n}\_2=[1\\ 2]^\\top $ を列に並べると周期構造行列 $ \\boldsymbol{N}=[\\boldsymbol{n}\_1\\ \\boldsymbol{n}\_2] $ が得られる。
n1v = [2; 0];
n2v = [1; 2];
Nmat = [n1v n2v]                               % 周期構造行列 N
detN = det(Nmat)
vie.savetex("vie-07-N", vie.arr2tex(Nmat, "%d"));
%[text] 基本周期 $ \\mathrm{FPD}(\\boldsymbol{N})=\\{\\boldsymbol{N}\\boldsymbol{r}\\mid\\boldsymbol{r}\\in[0,1)^2\\} $ に含まれる整数ベクトルの集合 $ \\mathcal{N}(\\boldsymbol{N}) $ を，平行四辺形を囲む長方形内の整数ベクトル $ \\boldsymbol{n} $ について $ \\boldsymbol{r}=\\boldsymbol{N}^{-1}\\boldsymbol{n}\\in[0,1)^2 $ を調べて求める。要素数は $ |\\det(\\boldsymbol{N})| $ に一致する。
corners = Nmat*[0 1 0 1; 0 0 1 1];             % 平行四辺形の 4 頂点
[c2, c1] = meshgrid(floor(min(corners(2,:))):ceil(max(corners(2,:))), ...
                    floor(min(corners(1,:))):ceil(max(corners(1,:))));
cand = [c1(:) c2(:)].';                        % 候補の整数ベクトル
r = Nmat\cand;                                 % r = N^{-1} n
tol = 1e-12;
inFPD = all(r > -tol & r < 1 - tol, 1);
setN = sortrows(cand(:, inFPD).').'            % 基本周期内の整数ベクトル（列）
cardN = size(setN, 2)                          % 要素数 |N(N)|
assert(cardN == round(abs(detN)))             % |N(N)| = |det(N)| を確認
cols = strings(1, cardN);
for k = 1:cardN
    cols(k) = "\begin{bmatrix}" + vie.arr2tex(setN(:,k), "%d") + "\end{bmatrix}";
end
vie.savetex("vie-07-NN-set",  strjoin(cols, ","));
vie.savetex("vie-07-NN-card", sprintf("%d", cardN));
%%
%[text] ## 例題：二次元配列の DSFT と DFT
%[text] 前回スライドの例題。 $ x[0,0]=x[1,0]=x[0,1]=x[1,1]=1 $ ，その他 0。DSFT は
%[text]{"align":"center"} $ X(\\mathrm{e}^{\\mathrm{j}\\boldsymbol{\\omega}^\\top})=(1+\\mathrm{e}^{-\\mathrm{j}\\omega\_1})(1+\\mathrm{e}^{-\\mathrm{j}\\omega\_2})=4\\cos\\frac{\\omega\_1}{2}\\cos\\frac{\\omega\_2}{2}\\mathrm{e}^{-\\mathrm{j}(\\omega\_1+\\omega\_2)/2} $
%[text] 周期構造行列 $ \\boldsymbol{N}=\\mathrm{diag}(2,2) $ の DFT は DSFT を $ \\omega\_d=\\pi k\_d $ で標本化したもの。行の添え字が $ k\_1 $ ，列の添え字が $ k\_2 $ 。
x22 = ones(2);
X22 = fft2(x22)
dsft = @(w1,w2) 4*cos(w1/2).*cos(w2/2).*exp(-1j*(w1+w2)/2);
Xs = [dsft(0,0) dsft(0,pi); dsft(pi,0) dsft(pi,pi)];
maxerr = max(abs(Xs - X22), [], "all")        % 一致を確認（丸め誤差程度）
vie.savetex("vie-07-ex-x", vie.arr2tex(x22,"%g"));
vie.savetex("vie-07-ex-X", vie.arr2tex(real(X22),"%g"));
%[text] DSFT の閉じた形を，定義の和と任意の周波数で比べておく。
wt = 2*pi*rand(2,5) - pi;
[n2e, n1e] = meshgrid(0:1);
Xdef = arrayfun(@(k) sum(x22(:).*exp(-1j*(wt(1,k)*n1e(:) + wt(2,k)*n2e(:)))), 1:5);
errDSFT = max(abs(Xdef - dsft(wt(1,:), wt(2,:))))
%[text] **分離処理**：対角の周期構造行列では，まず第 1 次元（ $ n\_1 $ 方向：各列）に一次元 DFT を施して $ X^{\\{1\\}}[k\_1;n\_2] $ を求め，次に第 2 次元（ $ n\_2 $ 方向：各行）に一次元 DFT を施す。
X1sep = fft(x22, [], 1)                        % X^{1}[k1; n2]（各列の DFT）
Xsep  = fft(X1sep, [], 2)                      % X[k1, k2]（各行の DFT）
assert(max(abs(Xsep - X22), [], "all") < 1e-12)
vie.savetex("vie-07-ex-X1", vie.arr2tex(real(X1sep),"%g"));
%[text] 振幅スペクトル $ |X(\\mathrm{e}^{\\mathrm{j}\\boldsymbol{\\omega}^\\top})| $ の曲面と，DFT の標本 $ |X[k\_1,k\_2]| $ （ $ \\boldsymbol{\\omega}=\\pi\\boldsymbol{k} $ ）を重ねて描く（2023 年度の演習の `fmesh` の図を参考）。
[W2, W1] = meshgrid(linspace(-pi, pi, 41));    % 横軸 ω2，縦軸 ω1
figMag = figure("Position", [100 100 440 360]);   % 小さく貼るので専用の図にする
mesh(W2, W1, abs(dsft(W1, W2)), "FaceColor", "none"), hold on
colormap(gca, cmapMain)
[K2, K1] = meshgrid(0:1);
stem3(pi*K2(:), pi*K1(:), abs(X22(:)), "filled", "Color", cWarm, "LineWidth", 2.5, "MarkerSize", 9)
hold off, axis tight, view(-35, 30)
xlabel("$\omega_2$", "Interpreter","latex"), ylabel("$\omega_1$", "Interpreter","latex")
zlabel("$|X(\mathrm{e}^{\mathrm{j}{\bf\omega}^\top})|$", "Interpreter","latex")
xticks([-pi 0 pi]), xticklabels(["-\pi","0","\pi"]), yticks([-pi 0 pi]), yticklabels(["-\pi","0","\pi"])
set(gca, "FontSize", 16)
exportgraphics(gca, fullfile(resfolder,"vie-07-ex-mag.png"), "Resolution", 110, "Padding", 10)
close(figMag)
%%
%[text] ## DFT は DSFT の周波数標本（一次元 DFT の行列表現）
%[text] 一次元 $ x[n]=(2,2) $ の DSFT $ X(\\mathrm{e}^{\\mathrm{j}\\omega})=2+2\\mathrm{e}^{-\\mathrm{j}\\omega}=4\\cos(\\omega/2)\\mathrm{e}^{-\\mathrm{j}\\omega/2} $ と， $ N $ 点 DFT（ $ \\omega=2\\pi k/N $ の標本）を比べる。
w = linspace(0, 2*pi, 721);
Xw = 2 + 2*exp(-1j*w);
X2 = fft([2 2])                               % N = 2
X8 = fft([2 2], 8);                           % N = 8（零値を追加）
k8 = 0:7;
clf
plot(w, real(Xw), "Color", cCool, "LineWidth", 1.5), hold on
plot(w, imag(Xw), "Color", cWarm, "LineWidth", 1.5)
plot(2*pi*k8/8, real(X8), "o", "Color", cCool, "MarkerSize", 7, "LineWidth", 1.5)
plot(2*pi*k8/8, imag(X8), "o", "Color", cWarm, "MarkerSize", 7, "LineWidth", 1.5)
plot(2*pi*(0:1)/2, real(X2), "s", "Color", cMain, "MarkerSize", 13, "LineWidth", 2.5)
hold off, grid on, xlim([0 2*pi]), ylim([-2.6 5.4])
xticks(0:pi/2:2*pi), xticklabels(["0","\pi/2","\pi","3\pi/2","2\pi"])
legend(["$\mathrm{Re}\,X(\mathrm{e}^{\mathrm{j}\omega})$","$\mathrm{Im}\,X(\mathrm{e}^{\mathrm{j}\omega})$", ...
        "$\mathrm{Re}\,X[k]\ (N=8)$","$\mathrm{Im}\,X[k]\ (N=8)$","$X[k]\ (N=2)$"], ...
       "Interpreter","latex", "Location","north", "NumColumns",2, "FontSize",11)
xlabel("$\omega$", "Interpreter","latex"), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-07-dftsample.png"), "Resolution", 120, "Padding", 10)
vie.savetex("vie-07-X2", strjoin(compose("%g",real(X2)),",\ "));
%[text] 教科書の例「一次元 DFT の行列表現」。回転子 $ W\_N=\\mathrm{e}^{-\\mathrm{j}2\\pi/N} $ を並べた $ \\mathbf{W}\_N=(W\_N^{kn}) $ により $ \\tilde{\\mathbf{x}}=\\mathbf{W}\_N\\mathbf{x} $ 。IDFT は $ \\mathbf{W}\_N^{-1}=\\mathbf{W}\_N^{\\mathsf{H}}/N $ 。 $ N=2 $ で確かめる。
Nd = 2;
[kk, nn] = ndgrid(0:Nd-1);
WN = exp(-1j*2*pi/Nd).^(kk.*nn)               % DFT 行列 W_2
xv = [2; 2];
Xv = WN*xv                                     % W_2 x
assert(max(abs(Xv - fft(xv))) < 1e-12)
assert(max(abs(inv(WN) - WN'/Nd), [], "all") < 1e-12)   % W^{-1} = W^H/N
vie.savetex("vie-07-W2",   vie.arr2tex(real(round(WN)), "%g"));
vie.savetex("vie-07-X2col", vie.arr2tex(real(Xv), "%g"));
%%
%[text] ## FFT の演算量
%[text] $ N $ 点 DFT を行列演算で計算すると複素乗算は $ N^2 $ 回，周波数分割型 FFT では $ \\frac{N}{2}\\log\_2 N $ 回。
N = 2.^(1:10);
mulMat = N.^2;
mulFFT = N/2.*log2(N);
clf
semilogy(N, mulMat, "o-", "Color", cWarm, "LineWidth", 1.5), hold on
semilogy(N, mulFFT, "s-", "Color", cMain, "LineWidth", 1.5), hold off, grid on
legend(["行列演算 {\itN}^2","FFT ({\itN}/2)log_2{\itN}"], "Location","northwest")
xlabel("$N$", "Interpreter","latex"), ylabel("複素乗算回数"), set(gca, "FontSize", 13)
exportgraphics(gca, fullfile(resfolder,"vie-07-fftcount.png"), "Resolution", 120, "Padding", 10)
n1024 = [mulMat(end) mulFFT(end) mulMat(end)/mulFFT(end)]
vie.savetex("vie-07-fft-mat",   vie.fmtint(mulMat(end)));
vie.savetex("vie-07-fft-fft",   vie.fmtint(mulFFT(end)));
vie.savetex("vie-07-fft-ratio", sprintf("%.0f", n1024(3)));
%%
%[text] ## 例題：周波数スペクトル（シフトした sinc 配列）
%[text] 教科書の例題。sinc 配列 $ h[\\boldsymbol{n}]=\\prod\_{d}\\frac{\\omega\_{\\mathrm{c}d}}{\\pi}\\mathrm{sinc}\\left(\\frac{\\omega\_{\\mathrm{c}d}}{\\pi}n\_d\\right) $ を $ \\boldsymbol{n}\_0 $ だけシフトした配列の DSFT は $ H\_{\\boldsymbol{n}\_0}(\\mathrm{e}^{\\mathrm{j}\\boldsymbol{\\omega}^\\top})=\\mathrm{e}^{-\\mathrm{j}\\boldsymbol{\\omega}^\\top\\boldsymbol{n}\_0}\\prod\_d\\mathrm{rect}(\\cdot) $ で，振幅スペクトルは rect の積（シフトで不変），位相スペクトルは平面 $ -\\boldsymbol{\\omega}^\\top\\boldsymbol{n}\_0 $ 。
%[text] 数値例： $ \\omega\_{\\mathrm{c}1}=\\omega\_{\\mathrm{c}2}=\\pi/2 $ ， $ \\boldsymbol{n}\_0=(1\\ 2)^\\top $ 。無限に広がる sinc 配列を $ \\boldsymbol{n}-\\boldsymbol{n}\_0\\in\\{-M,\\ldots,M\\}^2 $ で打ち切り，DSFT を定義の和で計算する（打ち切りのため振幅には小さな波打ちが残る）。
wc = [pi/2 pi/2];                              % 遮断角周波数 ω_c1, ω_c2
n0 = [1; 2];                                   % シフト量 n0
M = 200;
m = -M:M;                                      % n - n0 の範囲
wg = linspace(-pi, pi, 121);                   % 周波数の標本（1 軸あたり）
h1 = wc(1)/pi*sincn(wc(1)/pi*m);               % 第 1 次元の sinc
h2 = wc(2)/pi*sincn(wc(2)/pi*m);               % 第 2 次元の sinc
hsh = h1.'*h2;                                 % h[n - n0]（行が n1，列が n2）
E1 = exp(-1j*wg.'*(m + n0(1)));                % e^{-j ω1 n1}，n1 = m + n0(1)
E2 = exp(-1j*wg.'*(m + n0(2)));                % e^{-j ω2 n2}
Hsh = E1*hsh*E2.';                             % H_{n0}(e^{jω^T})（行が ω1，列が ω2）
[Wg2, Wg1] = meshgrid(wg);
pass = abs(Wg1) < wc(1) & abs(Wg2) < wc(2);    % 通過域
magPass = [min(abs(Hsh(pass))) max(abs(Hsh(pass)))]  % 通過域の振幅（≈1）
phErr = angle(Hsh.*exp(1j*(Wg1*n0(1) + Wg2*n0(2))));
maxPhErr = max(abs(phErr(pass)))               % 通過域の位相は -ω^T n0 に一致
%[text] 通過域の位相スペクトルを展開（アンラップ）して曲面として描くと，原点をとおる平面 $ -\\boldsymbol{\\omega}^\\top\\boldsymbol{n}\_0 $ になる。sinc 配列は偶関数なので $ h[\\boldsymbol{n}-\\boldsymbol{n}\_0] $ は $ \\mathbf{c}=\\boldsymbol{n}\_0 $ に関して対称で，群遅延 $ \\tau\_\\mathrm{g}(\\boldsymbol{\\omega})=-\\nabla\_{\\boldsymbol{\\omega}}\\angle H\_{\\boldsymbol{n}\_0}(\\mathrm{e}^{\\mathrm{j}\\boldsymbol{\\omega}^\\top}) $ は $ \\boldsymbol{n}\_0 $ で一定（直線位相）。スライドでは「フィルタの位相応答による分類」の二次元の直線位相の図に使う。
ip = abs(wg) < wc(1);                          % 通過域の周波数（両軸とも同じ）
wp = wg(ip);
P1 = unwrap(angle(Hsh(ip, ip)), [], 2);        % 各行（ω2 方向）を展開
col = unwrap(P1(:,1));                         % 左端の列（ω1 方向）を展開
Pun = P1 + (col - P1(:,1));                    % 行ごとのずれ（2π の整数倍）をそろえる
c0 = find(wp == 0);
Pun = Pun - 2*pi*round(Pun(c0,c0)/(2*pi));     % ω = 0 で位相 0
[Wp2, Wp1] = meshgrid(wp);
planeErr = max(abs(Pun + (Wp1*n0(1) + Wp2*n0(2))), [], "all")   % 平面 -ω^T n0 との差
[g2, g1] = gradient(Pun, wp(2) - wp(1));       % 位相の勾配（g1：ω1 方向，g2：ω2 方向）
tauG = -[mean(g1(:)) mean(g2(:))]              % 群遅延 ≈ n0^T
figPh = figure("Position", [100 100 440 360]); % 小さく貼るので専用の図にする
sk = [1:7:numel(wp) numel(wp)];                % 網目は 7 点おきに描く
wl2 = wc(1)*[-1 1 1 -1];
patch(wl2, [-1 -1 1 1]*wc(2), zeros(1,4), cGray, "FaceAlpha", 0.15, "EdgeColor", cGray), hold on   % ω1-ω2 平面（位相 0）
surf(Wp2, Wp1, Pun, "FaceColor", 1-0.35*(1-cMain), "EdgeColor", "none", "FaceAlpha", 0.85)
mesh(Wp2(sk,sk), Wp1(sk,sk), Pun(sk,sk), "FaceColor", "none", "EdgeColor", cMain)
plot3(0, 0, 0, "o", "MarkerFaceColor", cWarm, "MarkerEdgeColor", cWarm, "MarkerSize", 9)
hold off, grid on, view(20, 20)                % 勾配の向き (ω2,ω1)=(2,1) が画面の横になる向き
xlim(wc(2)*[-1 1]), ylim(wc(1)*[-1 1]), zlim([-1.6 1.6]*pi), pbaspect([1 1 1.1])
xlabel("$\omega_2$", "Interpreter","latex"), ylabel("$\omega_1$", "Interpreter","latex")
zlabel("$\angle H_{{\bf n}_0}(\mathrm{e}^{\mathrm{j}{\bf\omega}^\top})$", "Interpreter","latex")
xticks([-pi/2 0 pi/2]), xticklabels(["-\pi/2","0","\pi/2"]), yticks([-pi/2 0 pi/2]), yticklabels(["-\pi/2","0","\pi/2"])
zticks(-pi:pi:pi), zticklabels(["-\pi","0","\pi"])
set(gca, "FontSize", 18, "XTickLabelRotation", 0, "YTickLabelRotation", 0)
exportgraphics(gca, fullfile(resfolder,"vie-07-shift-phase.png"), "Resolution", 120, "Padding", 10)
close(figPh)
vie.savetex("vie-07-shift-n0", strjoin(compose("%d", n0.'), "\ \ "));
%%
%[text] ## 例題：周波数応答（ $ 3\\times3 $ 矩形フィルタ）
%[text] 教科書の例題。 $ 3\\times3 $ 矩形フィルタ（インパルス応答 $ h[\\boldsymbol{n}]=1/9,\\ \\boldsymbol{n}\\in\\{-1,0,1\\}^2 $ ）の周波数応答は
%[text]{"align":"center"} $ H(\\mathrm{e}^{\\mathrm{j}\\boldsymbol{\\omega}^\\top})=\\frac19(1+2\\cos\\omega\_1)(1+2\\cos\\omega\_2) $
%[text] 数値で確かめる：直流 $ \\boldsymbol{\\omega}=\\mathbf{0} $ ，最高周波数 $ \\boldsymbol{\\omega}=(\\pi\\ \\pi)^\\top $ ，零点（ $ 1+2\\cos\\omega\_d=0 $ ）。
Hsep = @(w1,w2) (1 + 2*cos(w1)).*(1 + 2*cos(w2))/9;
H00 = Hsep(0,0)
Hpp = Hsep(pi,pi)
wz = acos(-1/2)                                % 零点 ω_d = ±2π/3
Hz = Hsep(wz, 0)
vie.savetex("vie-07-H00", sprintf("%g", H00));
vie.savetex("vie-07-Hpi", sprintf("%.3f", Hpp));
vie.savetex("vie-07-Hpi-frac", fracstr(Hpp));
vie.savetex("vie-07-Hzero", pistr(wz));
%[text] 4 種類のカーネルの振幅応答 $ |H(\\mathrm{e}^{\\mathrm{j}\\boldsymbol{\\omega}^\\top})| $ を DSFT の定義に従って計算する。カーネルの行の添え字が $ n\_1 $ （垂直），列の添え字が $ n\_2 $ （水平）で，中心が原点。
[W2, W1] = meshgrid(linspace(-pi, pi, 61));    % 横軸 ω2，縦軸 ω1
kers = {ones(3)/9, [1 2 1; 2 4 2; 1 2 1]/16, [0 1 0; 1 -4 1; 0 1 0], [0 -1 0; -1 5 -1; 0 -1 0]};
tags = ["box","gauss","lap","us"];
ttl  = ["平均（矩形）","加重平均","4 近傍ラプラシアン","アンシャープマスク"];
[m2, m1] = meshgrid(-1:1);                    % m1：行（垂直），m2：列（水平）
Hmag = cell(1,4);
for k = 1:4
    H = zeros(size(W1));
    for i = 1:9
        H = H + kers{k}(i)*exp(-1j*(W1*m1(i) + W2*m2(i)));
    end
    Hmag{k} = abs(H);
    clf
    mesh(W2, W1, Hmag{k}), axis tight, view(-35, 30), colormap(gca, cmapMain)
    xlabel("$\omega_2$", "Interpreter","latex"), ylabel("$\omega_1$", "Interpreter","latex")
    zlabel("$|H(\mathrm{e}^{\mathrm{j}{\bf\omega}^\top})|$", "Interpreter","latex"), title(ttl(k))
    xticks([-pi 0 pi]), xticklabels(["-\pi","0","\pi"]), yticks([-pi 0 pi]), yticklabels(["-\pi","0","\pi"])
    set(gca, "FontSize", 13)
    exportgraphics(gca, fullfile(resfolder,"vie-07-freq-"+tags(k)+".png"), "Resolution", 110, "Padding", 10)
end
errBox = max(abs(Hmag{1} - abs(Hsep(W1,W2))), [], "all")   % 矩形フィルタは閉じた形と一致
usRange = [min(Hmag{4}(:)) max(Hmag{4}(:))]   % アンシャープマスクの |H| の範囲
vie.savetex("vie-07-us-min", sprintf("%g", round(usRange(1), 6)));
vie.savetex("vie-07-us-max", sprintf("%g", round(usRange(2), 6)));
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
nexttile, plot(n, xin, "k", "LineWidth", 1.5), title("入力"), axis tight, set(gca, "FontSize", 12)
nexttile, plot(n, ylin, "Color", cMain, "LineWidth", 1.5), title("直線位相の出力（同じ形）"), axis tight, set(gca, "FontSize", 12)
nexttile, plot(n, ynl, "Color", cWarm, "LineWidth", 1.5), title("非直線位相の出力（ひずむ）"), axis tight, set(gca, "FontSize", 12)
xlabel("$n$", "Interpreter","latex")
exportgraphics(gcf, fullfile(resfolder,"vie-07-phase-demo.png"), "Resolution", 120, "Padding", 10)
%[text] 位相応答 $ \\angle H(\\mathrm{e}^{\\mathrm{j}\\omega}) $ を比べる。直線位相は $ -5\\omega $ の直線，全域通過フィルタは曲線。
wl = linspace(0, pi, 256);
[Hn, ~] = freqz([-a 1], [1 -a], wl);
clf
plot(wl, -5*wl, "Color", cMain, "LineWidth", 2), hold on
plot(wl, unwrap(angle(Hn)), "Color", cWarm, "LineWidth", 2), hold off, grid on
legend(["直線位相（傾き -5）","非直線位相"], "Location","southwest")
xlabel("$\omega$", "Interpreter","latex"), ylabel("$\angle H(\mathrm{e}^{\mathrm{j}\omega})$", "Interpreter","latex")
xlim([0 pi]), set(gca, "FontSize", 13)
xticks([0 pi/2 pi]), xticklabels(["0","\pi/2","\pi"])
exportgraphics(gca, fullfile(resfolder,"vie-07-phase-resp.png"), "Resolution", 120, "Padding", 10)
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
%[text] 偶対称なインパルス応答 $ h=(1,3,3,1)/8 $ （中心 $ c=1.5 $ ）は直線位相 $ \\angle H(\\mathrm{e}^{\\mathrm{j}\\omega})=-1.5\\omega $ （群遅延 $ \\tau\_\\mathrm{g}=c $ ）。非対称な $ h=(4,2,1,1)/8 $ は非直線位相。
hs = [1 3 3 1]/8; hn = [4 2 1 1]/8;
cs = (numel(hs) - 1)/2                         % 対称の中心
assert(isequal(hs, fliplr(hs)))
[Hs, ~] = freqz(hs, 1, wl); [Hnn, ~] = freqz(hn, 1, wl);
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile
stem(0:3, hs, "filled", "Color", cMain, "LineWidth", 1.5), hold on
stem(0:3, hn, "Color", cWarm, "LineWidth", 1.5), hold off
xlim([-0.5 3.5]), legend(["偶対称","非対称"]), title("インパルス応答")
xlabel("$n$", "Interpreter","latex"), ylabel("$h[n]$", "Interpreter","latex"), set(gca, "FontSize", 14)
nexttile([1 2])
plot(wl(1:end-1), unwrap(angle(Hs(1:end-1))), "Color", cMain, "LineWidth", 2), hold on   % ω = π は H = 0 で位相が定まらないので除く
plot(wl, unwrap(angle(Hnn)), "Color", cWarm, "LineWidth", 2), hold off, grid on
legend(["偶対称：直線位相","非対称：非直線位相"], "Location","southwest"), xlim([0 pi])
xticks([0 pi/2 pi]), xticklabels(["0","\pi/2","\pi"])
xlabel("$\omega$", "Interpreter","latex"), ylabel("$\angle H(\mathrm{e}^{\mathrm{j}\omega})$", "Interpreter","latex"), title("位相応答"), set(gca, "FontSize", 14)
exportgraphics(gcf, fullfile(resfolder,"vie-07-sym-phase.png"), "Resolution", 120, "Padding", 10)
slope = mean(diff(unwrap(angle(Hs(1:200))))./diff(wl(1:200)))   % 傾き ≈ -1.5
vie.savetex("vie-07-sym-slope", sprintf("%.1f", slope));
vie.savetex("vie-07-sym-c", sprintf("%g", cs));
%%
%[text] ## まとめ
%[text] - 二次元余弦波の角周波数は位相の各方向の偏微分で与えられ，標本化すると $ \\boldsymbol{\\omega}=\\boldsymbol{L}^\\top\\boldsymbol{\\nu} $ となる
%[text] - 周期構造行列 $ \\boldsymbol{N} $ の基本周期に含まれる整数ベクトルの数は $ |\\det(\\boldsymbol{N})| $
%[text] - DFT は DSFT の周波数標本で，行列 $ \\mathbf{W}\_N $ で表され，各次元の一次元 DFT（FFT）に分離できる
%[text] - 位置ずれは位相スペクトルだけを変え，畳み込みは周波数領域では積になる（周波数応答）
%[text] - 画像では位相スペクトルが重要で，対称なインパルス応答は直線位相をもつ \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
function s = pistr(v)
% PISTR π の有理数倍を LaTeX の文字列にする（例：3*pi/4 → "3\pi/4"，0 → "0"）
[p, q] = rat(v/pi);
if p == 0
    s = "0";
    return
end
sgn = "";
if p < 0
    sgn = "-";
    p = -p;
end
if p == 1
    s = sgn + "\pi";
else
    s = sgn + string(p) + "\pi";
end
if q ~= 1
    s = s + "/" + string(q);
end
end

function s = fracstr(v)
% FRACSTR 有理数を "p/q" の文字列にする（整数ならそのまま）
[p, q] = rat(v);
if q == 1
    s = string(p);
else
    s = string(p) + "/" + string(q);
end
end

function y = sincn(x)
% SINCN 正規化 sinc 関数 sin(pi x)/(pi x)（x = 0 で 1）
y = ones(size(x));
nz = x ~= 0;
y(nz) = sin(pi*x(nz))./(pi*x(nz));
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
