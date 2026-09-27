%[text] # 第11回 動き検出処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第11回のスライド（vie2026-11）で使う図と数値を作る。エッジ画像のスペクトル，大域的定速移動モデルのスペクトル（速度に応じて傾く），ブロックマッチング法（差の絶対値和 SAD）による動き推定，位相限定相関（POC）を扱う。
%[text] 教科書には動き推定の章がないため，記号は教科書の関連箇所に合わせる。
%[text] - 連続変数の角周波数を $ \\boldsymbol{\\nu}=(\\nu\_\\mathrm{v}\\ \\nu\_\\mathrm{h}\\ \\nu\_\\mathrm{t})^\\top $ とする（ $ \\nu\_\\mathrm{t} $ は時間方向）。
%[text] - 動きベクトルは $ \\boldsymbol{m}=[m\_\\mathrm{v}\\ \\ m\_\\mathrm{h}]^\\top $ ，すなわち**（垂直，水平）の順**に並べる（教科書 3.1 節の $ \\boldsymbol{m} $ と同じ順）。
%[text] - 差の絶対値和は教科書 7.3 節 COLUMN「予測符号化」の $ \\mathrm{SAD}(\\boldsymbol{m};b)=\\sum\_{\\boldsymbol{n}\\in\\mathcal{N}\_b}|x\_{n\_\\mathrm{t}}[\\boldsymbol{n}]-x\_{m\_\\mathrm{t}}[\\boldsymbol{n}+\\boldsymbol{m}]| $ に従う。 $ \\boldsymbol{m} $ は現フレームのブロックの位置から，参照フレーム内で一致するブロックの位置へのずれである。
%[text] - 相互相関とクロススペクトルは教科書 4.2.3 項，位相限定相関は同項の COLUMN「位相限定相関」に従う。 \
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図と LaTeX 断片は `results` フォルダに書き出す。VieSlides 側では `tools/sync-results.ps1` でそれらを取り込む。
[~,resfolder] = vie.prjfolders();
%[text] 図の配色はスライドと揃え，ロゴの 3 色（メインの緑，寒色系の青，暖色系の橙）と灰色を使う。
cmain = [0 136 85]/255;     % メイン（緑）#008855：図の主役
ccool = [46 117 182]/255;   % 寒色系（青）#2E75B6：第 2 系統（信号・データ）
cwarm = [197 90 17]/255;    % 暖色系（橙）#C55A11：注目させたい箇所
cgray = [0.6 0.6 0.6];      % 補助線（灰）
%%
%[text] ## 標本化によるスペクトルの周期化（前回スライドの図を踏襲）
%[text] 斜めに傾いた細長いスペクトル $ \\tilde{u}(\\boldsymbol{\\nu}) $ （円形とは限らない）を，標本化行列 $ \\boldsymbol{L}=\\mathrm{diag}(\\Delta\_\\mathrm{v},\\Delta\_\\mathrm{h}) $ の直交標本化で周期化する（教科書 4.1.3 項「FT と DSFT の関係」）。
%[text] $ \\tilde{x}(\\boldsymbol{\\nu})=\\frac{1}{|\\det(\\boldsymbol{L})|}\\sum\_{\\boldsymbol{m}\\in\\mathbb{Z}^2}\\tilde{u}(\\boldsymbol{\\nu}-2\\pi\\boldsymbol{L}^{-\\top}\\boldsymbol{m}) $ 。図では $ \\Delta\_\\mathrm{v}=\\Delta\_\\mathrm{h}=1 $ とし，周期 $ 2\\pi $ ごとに複製が並ぶ。
nuRange = 3*pi; M = 481;
nu = linspace(-nuRange, nuRange, M);
[NUh, NUv] = meshgrid(nu, nu);                  % 横：nu_h，縦：nu_v
th = deg2rad(12);                               % 傾き（垂直軸から）
sgh = 0.42; sgv = 1.05;                         % 細長いガウス形（水平に狭く，垂直に広い）
uspec = @(h,v) exp(-((h*cos(th) - v*sin(th)).^2/(2*sgh^2) + (h*sin(th) + v*cos(th)).^2/(2*sgv^2)));
U = uspec(NUh, NUv);
Xs = zeros(size(U));
for mv = -2:2
    for mh = -2:2
        Xs = Xs + uspec(NUh - 2*pi*mh, NUv - 2*pi*mv);   % 2*pi*L^{-T}*m（L = I）
    end
end
cmapS = interp1([0 1], [1 1 1; ccool], linspace(0, 1, 256));   % 白→青
ttl = ["$\tilde{u}(\mbox{\boldmath$\nu$})$", "$\tilde{x}(\mbox{\boldmath$\nu$})$"];
fn = ["vie-11-sampspec-a.png", "vie-11-sampspec-b.png"];
Z = {U, Xs};
for i = 1:2
    fig = figure(Units="centimeters", Position=[2 2 5.2 5.2]);
    ax = axes(fig);
    imagesc(ax, nu, nu, Z{i}), axis(ax, "xy", "image"), colormap(ax, cmapS), clim(ax, [0 1])
    hold(ax, "on")
    xline(ax, 0, "Color", cgray, "LineWidth", 0.5), yline(ax, 0, "Color", cgray, "LineWidth", 0.5)   % 原点を通る補助線
    if i == 2
        plot(ax, pi*[-1 1 1 -1 -1], pi*[-1 -1 1 1 -1], "--", "Color", [0 0 0], "LineWidth", 0.8)   % 基本周期の範囲
    end
    hold(ax, "off")
    set(ax, "Box","on", "Layer","top", ...
        "XTick", [-2*pi 0 2*pi], "YTick", [-2*pi 0 2*pi], "TickLabelInterpreter","latex", "FontSize", 13, ...
        "XTickLabel", ["$-\frac{2\pi}{\Delta_\mathrm{h}}$", "$0$", "$\frac{2\pi}{\Delta_\mathrm{h}}$"], ...
        "YTickLabel", ["$-\frac{2\pi}{\Delta_\mathrm{v}}$", "$0$", "$\frac{2\pi}{\Delta_\mathrm{v}}$"])
    xlabel(ax, "$\nu_\mathrm{h}$", "Interpreter","latex", "FontSize", 15)
    ylabel(ax, "$\nu_\mathrm{v}$", "Interpreter","latex", "FontSize", 15, "Rotation", 0)
    title(ax, ttl(i), "Interpreter","latex", "FontSize", 15)
    exportgraphics(fig, fullfile(resfolder, fn(i)), "Resolution", 300)
    close(fig)
end
%%
%[text] ## エッジ画像のスペクトル
%[text] 斜めの直線（エッジ）をもつ画像の振幅スペクトルは，直線と直交する方向に伸びる。画像ごとにさまざまな形のスペクトルをもつ。
N = 128;
[cc, rr] = meshgrid(1:N);
E = double(abs((rr - N/2) + 0.5*(cc - N/2)) < 1.5 & hypot(rr - N/2, cc - N/2) < N/2.5);   % 傾き -1/2 の線分
E = imgaussfilt(E, 0.7);                    % 縁の階段状の折り返しを抑える
S = log(1 + abs(fftshift(fft2(E))));
imwrite(E, fullfile(resfolder,"vie-11-edge.png"))
imwrite(S/max(S(:)), fullfile(resfolder,"vie-11-edge-spec.png"))
%%
%[text] ## 大域的定速移動モデル：時空間画像とスペクトル
%[text] 一次元の静止信号 $ x\_0(q) $ が垂直方向に速度 $ v $ で動く： $ x(q\_\\mathrm{v},t)=x\_0(q\_\\mathrm{v}-vt) $ 。縦軸を垂直位置 $ q\_\\mathrm{v} $ ，横軸を時刻 $ t $ とする配列を作り，二次元 DFT の振幅スペクトルを見る（後の標本化の図と同じく，横軸 $ \\nu\_\\mathrm{t} $ ，縦軸 $ \\nu\_\\mathrm{v} $ ）。スペクトルは直線 $ \\nu\_\\mathrm{t}=-v\\,\\nu\_\\mathrm{v} $ 上に集中し，静止なら $ \\nu\_\\mathrm{t}=0 $ （縦の直線），速いほど傾く。
%[text] 非整数の速度では $ N $ フレームで周期がつながらず，時間方向の端の不連続がスペクトルの漏れ（縦縞）になるので，時間方向にハン窓を掛けてから DFT する。
x0 = exp(-((0:N-1)' - N/4).^2/(2*3^2));    % ガウス形の塊（列ベクトル：垂直位置．v=0.5 で折り返さないよう下寄り）
k = [0:N/2-1, -N/2:-1]';                    % DFT の周波数番号
wt = hann(N)';                              % 時間方向の窓
vs = [0 0.5 1];
for i = 1:numel(vs)
    v = vs(i);
    Xt = zeros(N);                           % 行：垂直位置 q_v，列：時刻 t
    for t = 0:N-1                            % 周波数領域でずらす（非整数の速度も扱える）
        Xt(:,t+1) = real(ifft(fft(x0).*exp(-1j*2*pi*k*v*t/N)));
    end
    Sp = log(1 + abs(fftshift(fft2(Xt.*wt))));
    Z = {Xt, Sp/max(Sp(:))};
    lab = {["$t$", "$q_\mathrm{v}$"], ["$\nu_\mathrm{t}$", "$\nu_\mathrm{v}$"]};
    fn = [sprintf("vie-11-xt-v%02d.png", round(10*v)), sprintf("vie-11-spec-v%02d.png", round(10*v))];
    for j = 1:2
        fig = figure(Units="centimeters", Position=[2 2 3.4 3.4]);
        ax = axes(fig);
        imagesc(ax, Z{j}), axis(ax, "xy", "image"), colormap(ax, gray(256))
        set(ax, "XTick", [], "YTick", [])
        xlabel(ax, lab{j}(1), "Interpreter","latex", "FontSize", 10)
        ylabel(ax, lab{j}(2), "Interpreter","latex", "FontSize", 10, "Rotation", 0)
        exportgraphics(fig, fullfile(resfolder, fn(j)), "Resolution", 300)
        close(fig)
    end
end
%%
%[text] ## 大域的定速移動モデル：三次元のスペクトル（垂直移動の例）
%[text] 速度 $ \\boldsymbol{v}=(v\_\\mathrm{v}\\ v\_\\mathrm{h})^\\top $ で動く画像のスペクトルは
%[text]{"align":"center"} $ \\tilde{x}(\\nu\_\\mathrm{v},\\nu\_\\mathrm{h},\\nu\_\\mathrm{t})=\\tilde{x}\_0(\\nu\_\\mathrm{v},\\nu\_\\mathrm{h})\\cdot 2\\pi\\,\\delta(\\nu\_\\mathrm{v}v\_\\mathrm{v}+\\nu\_\\mathrm{h}v\_\\mathrm{h}+\\nu\_\\mathrm{t}) $
%[text] となり，法線ベクトル $ (v\_\\mathrm{v}\\ v\_\\mathrm{h}\\ 1)^\\top $ と直交する平面の上に集まる。静止画像 $ x\_0 $ のスペクトルが $ (\\nu\_\\mathrm{v},\\nu\_\\mathrm{h})=(\\pm1,\\pm2) $ のインパルスからなるとき，垂直方向に速度 $ v\_\\mathrm{v} $ で動かすと，各インパルスは $ \\nu\_\\mathrm{t} $ 方向に $ \\nu\_\\mathrm{t}=-v\_\\mathrm{v}\\nu\_\\mathrm{v} $ の位置へ移る（ $ v\_\\mathrm{h}=0 $ なので $ \\nu\_\\mathrm{h} $ には依らない）。
%[text] 図の見せ方は，前回の演習・試験用の図（3 次元の動画像スペクトル）を参考にした。軸は $ \\nu\_\\mathrm{v} $ を上， $ \\nu\_\\mathrm{t} $ を右手前， $ \\nu\_\\mathrm{h} $ を右奥にとる。青の点がスペクトル，緑の面がスペクトルの乗る平面，橙の矢印が法線ベクトルである。
nuv0 = [1 1 -1 -1];                         % 静止画像のインパルスの垂直周波数 ν_v
nuh0 = [2 -2 2 -2];                         % 同じく水平周波数 ν_h
vh = 0;                                     % 水平速度（垂直移動の例なので 0）
for vv = [0 2]                              % 垂直速度：静止と v_v = 2
    nut = -(nuv0*vv + nuh0*vh);             % 移った先の時間周波数 ν_t
    disp(table(nuv0.', nuh0.', nut.', 'VariableNames', ["nu_v" "nu_h" "nu_t"]))
    figure("Color","w","Position",[100 100 460 380])
    drawspec3d(nuv0, nuh0, nut, vv, vh, cmain, ccool, cwarm, cgray)
    exportgraphics(gcf, fullfile(resfolder,sprintf("vie-11-spec3d-v%d.png", vv)), ...
        "Resolution", 200, "Padding", "figure")   % 2 枚の縮尺を揃えるため図全体を書き出す
end
%[text] 2 枚を同じ縮尺でスライドに並べられるよう，両方の描画範囲を合わせた共通の矩形で余白を切り落とす。
files = fullfile(resfolder, ["vie-11-spec3d-v0.png" "vie-11-spec3d-v2.png"]);
imgs = arrayfun(@(f) imread(f), files, "UniformOutput", false);
ink = false(size(imgs{1}, [1 2]));
for i = 1:numel(imgs), ink = ink | any(imgs{i} < 250, 3); end   % 白でない画素
rsel = find(any(ink, 2)); csel = find(any(ink, 1));
pad = 8;
rsel = max(rsel(1)-pad, 1):min(rsel(end)+pad, size(ink, 1));
csel = max(csel(1)-pad, 1):min(csel(end)+pad, size(ink, 2));
for i = 1:numel(imgs), imwrite(imgs{i}(rsel, csel, :), files(i)), end
%[text] スライドの例（ $ v\_\\mathrm{v}=2 $ ）の数値。 $ \\nu\_\\mathrm{v}=1 $ の成分は $ \\nu\_\\mathrm{t}=-2 $ に， $ \\nu\_\\mathrm{v}=-1 $ の成分は $ \\nu\_\\mathrm{t}=2 $ に移り，いずれも平面の式 $ \\nu\_\\mathrm{v}v\_\\mathrm{v}+\\nu\_\\mathrm{t}=0 $ を満たす。
vv = 2;
nutp = -vv*1                                 % ν_v = 1 の成分の移り先
nutm = -vv*(-1)                              % ν_v = -1 の成分の移り先
assert(1*vv + nutp == 0 && (-1)*vv + nutm == 0)
vie.savetex("vie-11-ex-vv", sprintf("%d", vv));
vie.savetex("vie-11-ex-nutp", sprintf("%d", nutp));
vie.savetex("vie-11-ex-nutm", sprintf("%d", nutm));
vie.savetex("vie-11-ex-check", sprintf("1\\cdot%d+(%d)=%d", vv, nutp, 1*vv + nutp));
%%
%[text] ## ブロックマッチング：前回スライドの例題
%[text] $ 2\\times2 $ の対象ブロック（現フレーム $ \\mathsf{x}\_{n\_\\mathrm{t}} $ ）に最も近いブロックを，参照フレーム $ \\mathsf{x}\_{m\_\\mathrm{t}} $ の $ 4\\times4 $ の探索窓から，差の絶対値和（SAD）を評価式とする全探索で求める。探索範囲は $ \\mathcal{N}\_\\mathrm{w}=\\{-1,0,1\\}^2 $ である。
%[text] 探索窓の中央の $ 2\\times2 $ （ `win(2:3,2:3)` ）が，対象ブロックと同じ位置（ $ \\boldsymbol{m}=\\mathbf{0} $ ）である。変位 $ \\boldsymbol{m}=[m\_\\mathrm{v}\\ \\ m\_\\mathrm{h}]^\\top $ の候補は `win(2+mv:3+mv, 2+mh:3+mh)` で，教科書の $ x\_{m\_\\mathrm{t}}[\\boldsymbol{n}+\\boldsymbol{m}] $ に当たる。
blk = [1 1; 1 1];                            % 対象ブロック（現フレーム）
win = [0 0 0 0; 2 2 1 1; 2 2 1 1; 0 0 0 0];  % 探索窓（参照フレーム）
mvs = -1:1;                                  % 垂直の変位 m_v の候補
mhs = -1:1;                                  % 水平の変位 m_h の候補
SAD = zeros(numel(mvs), numel(mhs));         % 行：m_v，列：m_h
SSD = zeros(numel(mvs), numel(mhs));
for iv = 1:numel(mvs)
    for ih = 1:numel(mhs)
        cand = win(2+mvs(iv):3+mvs(iv), 2+mhs(ih):3+mhs(ih));   % 候補ブロック
        SAD(iv,ih) = sum(abs(blk - cand), "all");
        SSD(iv,ih) = sum((blk - cand).^2, "all");
    end
end
SAD
SSD
[sadmin, idx] = min(SAD(:));
[iv, ih] = ind2sub(size(SAD), idx);
mhat = [mvs(iv) mhs(ih)]                     % 推定した動きベクトル [m_v m_h]（垂直，水平）
%[text] 演習課題の解説と同じく，一つの変位について SAD を差の絶対値の和に展開して書いておく。ここでは $ \\boldsymbol{m}=\\mathbf{0} $ （動きなし）の場合を示す。
cand0 = win(2:3, 2:3);
terms = compose("|%d-%d|", [reshape(blk.',1,[]); reshape(cand0.',1,[])].');
sadexpr = strjoin(terms, "+") + "=" + sprintf("%d", sum(abs(blk - cand0), "all"))
%[text] スライドの表（対象ブロックと探索窓）は，前回の演習課題（11）の図と同じ見せ方で TikZ で描く。数値はここから `\def` のマクロとして渡し，スライドでは書き写さない。
vie.savetex("vie-11-sad", vie.arr2tex(SAD,"%d"));
vie.savetex("vie-11-ssd", vie.arr2tex(SSD,"%d"));
vie.savetex("vie-11-sad-min", sprintf("%d", sadmin));
vie.savetex("vie-11-sad-expr", sadexpr);
vie.savetex("vie-11-dhat", intvec2tex(mhat));
vie.savetex("vie-11-sad-block", "\def\viesadblock{" + rows2list(blk) + "}");
vie.savetex("vie-11-sad-window", "\def\viesadwindow{" + rows2list(win) + "}");
vie.savetex("vie-11-sad-mhat", "\def\viesadmv{" + mhat(1) + "}\def\viesadmh{" + mhat(2) + "}");
%%
%[text] ## 動き推定の例（ブロックサイズ 16×16）
%[text] 静止した背景（参考資料 6 章 COLUMN「一次自己回帰過程」の AR(1) 過程 $ x[n]=\\rho x[n-1]+w[n] $ を垂直・水平の両方向に適用して白色ノイズから生成した $ 256\\times256 $ の画像。 $ \\rho=0.95 $ は参考資料が自然画像の値として挙げるもの。物体が目立つよう濃淡を $ [0.25,0.7] $ に収める）の上を，模様のある正方形（msipimg07「モンブラン」の中央を切り出して $ 48\\times48 $ に縮小したもの，細い線状の模様がある）と明るい円が 1 フレームあたり $ [2\\ \\ 2]^\\top $ 画素（垂直，水平とも +2，右下向き）動く 2 フレームを作る。現フレーム $ \\mathsf{x}\_{n\_\\mathrm{t}} $ を $ 16\\times16 $ のブロックに分け，前フレーム $ \\mathsf{x}\_{m\_\\mathrm{t}} $ （ $ m\_\\mathrm{t}=n\_\\mathrm{t}-1 $ ）の $ \\pm7 $ 画素の範囲を全探索する。
%[text] 教科書の SAD の定義では $ \\boldsymbol{m} $ は参照フレーム内で一致する位置へのずれなので，物体が $ [2\\ \\ 2]^\\top $ 動いたブロックでは $ \\hat{\\boldsymbol{m}}\_b=[-2\\ \\ -2]^\\top $ （物体の移動と逆向き）が得られる。
M = 256;
rng(0)
rho = 0.95; burn = 64;                                      % AR(1) の相関係数と，立ち上がりを捨てる画素数
W = randn(M+burn);                                          % 白色ノイズ w
A1 = filter(1, [1 -rho], filter(1, [1 -rho], W, [], 1), [], 2);   % 垂直・水平に x[n] = rho x[n-1] + w[n]
A1 = A1(burn+1:end, burn+1:end);
bg = 0.25 + 0.45*rescale(A1);                               % 背景（静止）：AR(1) 過程の生成画像，濃淡を狭める
Xm = im2double(vie.msipimg(7, 512, "gray"));                % モンブラン
tex = imresize(Xm(217:296, 217:296), [48 48]);              % 正方形の模様（中央 80×80 を縮小）
[X1, Y1] = meshgrid(1:M);
dmov = [2 2];                                % 物体の 1 フレームあたりの移動 [垂直 水平]
frame = @(s) insertobj(bg, tex, [60 110] + s, [170 110] + s, X1, Y1);
F0 = frame([0 0]);                           % 参照フレーム（前フレーム）
F1 = frame(dmov);                            % 現フレーム
imwrite(F1, fullfile(resfolder,"vie-11-bm-frame.png"))
bs = 16;                                     % ブロックサイズ
R = 7;                                       % 探索範囲 ±R 画素
nb = M/bs;
[MV, MH] = deal(zeros(nb));                  % 各ブロックの動きベクトルの垂直・水平成分
for bi = 1:nb
    for bj = 1:nb
        r0 = (bi-1)*bs + 1; c0 = (bj-1)*bs + 1;
        cur = F1(r0:r0+bs-1, c0:c0+bs-1);    % 現フレームのブロック
        best = sum(abs(cur - F0(r0:r0+bs-1, c0:c0+bs-1)), "all");   % m = 0 から始める
        for mv = -R:R
            for mh = -R:R
                rr2 = r0 + mv; cc2 = c0 + mh;   % 参照フレームの候補ブロックの左上（n + m）
                if rr2 < 1 || cc2 < 1 || rr2+bs-1 > M || cc2+bs-1 > M, continue, end
                sad = sum(abs(cur - F0(rr2:rr2+bs-1, cc2:cc2+bs-1)), "all");
                if sad < best - 1e-9, best = sad; MV(bi,bj) = mv; MH(bi,bj) = mh; end
            end
        end
    end
end
nsearch = (2*R+1)^2                          % ブロック毎の評価回数
%[text] 動きベクトル場を白地に描く（ブロックの境界を灰色の格子で示す）。矢印は $ \\hat{\\boldsymbol{m}}\_b $ の向きで，見やすいように 4 倍の長さで描く。
figure("Color","w")
imshow(ones(M)), hold on
for g = 0:bs:M
    plot([g g]+0.5, [0 M]+0.5, "Color", 0.85*[1 1 1])
    plot([0 M]+0.5, [g g]+0.5, "Color", 0.85*[1 1 1])
end
[gx, gy] = meshgrid((0:nb-1)*bs + bs/2 + 0.5);
quiver(gx, gy, 4*MH, 4*MV, 0, "Color", cmain, "LineWidth", 2, "MaxHeadSize", 1.5)
plot(gx(:), gy(:), ".", "Color", cmain, "MarkerSize", 6), hold off
exportgraphics(gca, fullfile(resfolder,"vie-11-bm-field.png"), "Resolution", 110)
moving = [MV(MV~=0 | MH~=0) MH(MV~=0 | MH~=0)];
mode_vec = mode(moving, 1)                   % 動いた領域で最も多いベクトル [m_v m_h]
vie.savetex("vie-11-bm-vec", intvec2tex(mode_vec));
vie.savetex("vie-11-bm-move", intvec2tex(dmov));
vie.savetex("vie-11-bm-bs", sprintf("%d", bs));
vie.savetex("vie-11-bm-range", sprintf("%d", R));
vie.savetex("vie-11-bm-count", sprintf("%d^2=%d", 2*R+1, nsearch));
%%
%[text] ## 位相限定相関（POC）
%[text] 参考資料のサンプル画像 msipimg05（石像の顔，グレースケール， $ 256\\times256 $ に縮小）を $ \\boldsymbol{n}\_0=[-3\\ \\ 5]^\\top $ 画素（垂直，水平）ずらした画像 $ y[\\boldsymbol{n}]=x[\\boldsymbol{n}-\\boldsymbol{n}\_0] $ との POC を計算する。テンプレート $ \\mathsf{v} $ を元の画像， $ \\mathsf{x} $ をずらした画像とすると，クロススペクトル $ \\overline{V}X $ を振幅で正規化して逆変換した POC 配列は，ラグ $ \\boldsymbol{\\ell}=\\boldsymbol{n}\_0 $ に鋭いピークをもつ。
rng(1)
Xc = im2double(vie.msipimg(5, 256, "gray"));   % 石像の顔
n0 = [-3 5];                                 % 与えるずれ [垂直 水平]
Xs = circshift(Xc, n0) + 0.01*randn(size(Xc));   % y[n] = x[n - n0]（巡回）に少し雑音を加える
Rc = conj(fft2(Xc)).*fft2(Xs);               % クロススペクトル conj(V) X
P = real(ifft2(Rc./max(abs(Rc), eps)));      % POC 配列
[peak, ip] = max(P(:));
[pr, pc] = ind2sub(size(P), ip);
lag = mod([pr pc] - 1 + 128, 256) - 128      % ピークのラグ [垂直 水平]
peak
assert(isequal(lag, n0))
%[text] 原点付近（ラグ $ \\pm20 $ ）を立体表示する。
Pd = fftshift(P);                            % ラグ 0 を中央へ
lr = -20:20;
figure("Color","w")
mesh(lr, lr, Pd(lr+129, lr+129), "EdgeColor", cmain), axis tight, view(-30, 40)
xlabel("$\ell_\mathrm{h}$", "Interpreter", "latex")
ylabel("$\ell_\mathrm{v}$", "Interpreter", "latex")
zlabel("$p_{vx}[\ell_\mathrm{v},\ell_\mathrm{h}]$", "Interpreter", "latex")
set(gca, "FontSize", 14)
exportgraphics(gca, fullfile(resfolder,"vie-11-poc.png"), "Resolution", 110)
vie.savetex("vie-11-poc-shift", intvec2tex(lag));
vie.savetex("vie-11-poc-n0", intvec2tex(n0));
vie.savetex("vie-11-poc-peak", sprintf("%.2f", peak));
%%
%[text] ## 見かけ上の動き：光源変化の影響（前回スライドの図を踏襲）
%[text] 動かない球を，フレーム $ n\_\\mathrm{t}-1 $ では左上から，フレーム $ n\_\\mathrm{t} $ では右上から照らす。拡散反射（ランバート反射）の明るさ $ a+k\\max(0,\\boldsymbol{\\eta}^\\top\\boldsymbol{\\ell}) $ （ $ \\boldsymbol{\\eta} $ ：面の法線， $ \\boldsymbol{\\ell} $ ：光源の向き）で陰影をつけ，床には光と反対側に影を落とす。物体は動いていないのに，明るい面と影が入れ替わり，動いたように見える。
Ms = 200;
[xs, ys] = meshgrid(linspace(-1.3, 1.3, Ms), linspace(1.3, -1.3, Ms));   % 横：右が正，縦：上が正（縦横同じ縮尺）
r0 = 0.75; yc = 0.1;                            % 球の半径と中心の高さ
dx = xs/r0; dy = (ys - yc)/r0; in = dx.^2 + dy.^2 <= 1;
nz = sqrt(max(0, 1 - dx.^2 - dy.^2));          % 球面の法線の奥行き成分
lights = {[-1 1 0.9], [1 1 0.9]};              % 左上から，右上から
names = ["vie-11-light-a.png", "vie-11-light-b.png"];
for i = 1:2
    l = lights{i}/norm(lights{i});
    I = 0.93*ones(Ms);                          % 背景（明るい灰）
    ysh = -0.78; floorY = ys < -0.6;            % 床
    I(floorY) = 0.82;
    % 床の影：光と反対側にずれた楕円
    shx = -0.5*sign(l(1)); sh = ((xs - shx)/0.85).^2 + ((ys - ysh)/0.14).^2 <= 1;
    I(sh & floorY) = 0.55;
    shade = 0.15 + 0.8*max(0, dx*l(1) + dy*l(2) + nz*l(3));
    I(in) = shade(in);
    imwrite(I, fullfile(resfolder, names(i)))
end
%%
%[text] ## まとめ
%[text] - 動いている映像のスペクトルは速度に応じて傾いた平面に集中する（大域的定速移動モデル）
%[text] - 動き推定には，ブロックマッチング法（SAD や SSD の最小化）や位相限定相関が使われる
%[text] - 動きベクトルは $ \\boldsymbol{m}=[m\_\\mathrm{v}\\ \\ m\_\\mathrm{h}]^\\top $ （垂直，水平）の順に表す
%[text] - 見かけ上の動きには，空間勾配の欠落，光源変化，アパーチャ問題，オクルージョンなどの本質的な問題がある \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
function F = insertobj(bg, tex, psq, pcir, X, Y)
% 背景 bg に模様 tex の正方形（左上 psq = [行 列]）と明るい円（中心 pcir = [行 列]）を重ねる
F = bg;
[h, w] = size(tex);
F(psq(1):psq(1)+h-1, psq(2):psq(2)+w-1) = tex;
F((X - pcir(2)).^2 + (Y - pcir(1)).^2 <= 12^2) = 1;
end

function s = intvec2tex(m)
% 整数ベクトル [a b] を教科書の表記 \tr{[a\quad b]}（列ベクトルの転置）にする
s = "\tr{[" + strjoin(compose("%d", m), "\quad ") + "]}";
end

function s = rows2list(A)
% 行列を TikZ の \foreach で読める入れ子のリスト {a,b,...},{c,d,...} にする
rowsA = strings(size(A,1), 1);
for i = 1:size(A,1)
    rowsA(i) = "{" + strjoin(compose("%d", A(i,:)), ",") + "}";
end
s = strjoin(rowsA, ",");
end

function drawspec3d(nuv, nuh, nut, vv, vh, cmain, ccool, cwarm, cgray)
% 三次元の周波数空間にスペクトルの点，平面，法線ベクトルを描く
% 描画座標は (x, y, z) = (ν_t, ν_h, ν_v)．ν_v を上，ν_t を右手前，ν_h を右奥に向ける
L = [3.4 3.4 2.8];                           % 各軸（ν_t, ν_h, ν_v）の半分の長さ
hold on
% 平面 ν_v v_v + ν_h v_h + ν_t = 0（スペクトルが乗る面）
[pv, ph] = meshgrid([-1.6 1.6], [-2.8 2.8]);
pt = -(pv*vv + ph*vh);
patch(pt([1 2 4 3]), ph([1 2 4 3]), pv([1 2 4 3]), cmain, ...
    "FaceAlpha", 0.12, "EdgeColor", cmain, "LineStyle", ":")
% 座標軸（矢印）と目盛
axlab = ["$\nu_\mathrm{t}$" "$\nu_\mathrm{h}$" "$\nu_\mathrm{v}$"];
tk = {[-2 2], [-2 2], [-1 1]};               % 目盛の位置
tkoff = {[0 0.6 -0.45], [0 0 0.3], [-0.35 0 0]};   % 目盛の数字のずらし方
for a = 1:3
    e = zeros(1,3); e(a) = 1;
    plot3(L(a)*[-1 1]*e(1), L(a)*[-1 1]*e(2), L(a)*[-1 1]*e(3), "k", "LineWidth", 0.8)
    quiver3(0.8*L(a)*e(1), 0.8*L(a)*e(2), 0.8*L(a)*e(3), ...
        0.2*L(a)*e(1), 0.2*L(a)*e(2), 0.2*L(a)*e(3), 0, "k", "LineWidth", 0.8, "MaxHeadSize", 1.2)
    p = (L(a) + 0.45)*e; if a == 2, p(3) = -0.45; end   % ν_h の名前は軸の下に置く
    text(p(1), p(2), p(3), axlab(a), "Interpreter", "latex", "FontSize", 26, ...
        "HorizontalAlignment", "center")
    for t = tk{a}
        q = t*e; d = 0.1*[0 0 1]; if a == 3, d = 0.1*[1 0 0]; end
        plot3(q(1) + [-1 1]*d(1), q(2) + [-1 1]*d(2), q(3) + [-1 1]*d(3), "k")
        o = tkoff{a};
        if a == 2, continue, end                 % ν_h の目盛の数字は省く（混み合うため）
        if a == 1 && vv == 0, continue, end      % 静止のときは ν_t の目盛の数字も省く（点と重なるため）
        text(q(1)+o(1), q(2)+o(2), q(3)+o(3), sprintf("%d", t), "FontSize", 20, ...
            "HorizontalAlignment", "center", "Color", 0.3*[1 1 1])
    end
end
% スペクトルの点（インパルス）と，それらを結ぶ補助線
ord = [1 2 4 3 1];
plot3(nut(ord), nuh(ord), nuv(ord), "--", "Color", cgray)
scatter3(nut, nuh, nuv, 90, ccool, "filled")
% 法線ベクトル (v_v v_h 1)^T（成分の並びは (ν_v, ν_h, ν_t)）
quiver3(0, 0, 0, 1, vh, vv, 0, "Color", cwarm, "LineWidth", 3.5, "MaxHeadSize", 0.5)
% 数字が点や軸に重ならない位置に置く（静止のときは左上）
if vv == 0, o = [-1.2 0 2.1]; ha = "right"; else, o = [0.3 0 0.4]; ha = "left"; end
text(1 + o(1), vh + o(2), vv + o(3), sprintf("$(%d\\ %d\\ 1)^\\top$", vv, vh), ...
    "Interpreter", "latex", "FontSize", 22, "Color", cwarm, "HorizontalAlignment", ha)
hold off
axis equal off
xlim([-1 1]*(L(1)+0.6)), ylim([-1 1]*(L(2)+0.6)), zlim([-1 1]*(L(3)+0.6))
view(40, 25)
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
