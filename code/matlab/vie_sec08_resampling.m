%[text] # 第8回 幾何処理（拡大縮小）
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第8回のスライド（vie2026-08）で使う図と数値を作る。間引き・平均による縮小，最近傍・双線形補間による拡大，標本化と周波数スペクトル（一次元と多次元），ダウン／アップサンプラ，デシメーションとインタポレーション（エリアシングとイメージング），補間フィルタ（零次ホールド，双線形，3次畳み込み補間）を扱う。
%[text] 記号は教科書に合わせる。再標本化行列を $ \\boldsymbol{M} $ （一次元では間引き率・補間率 $ M $ ），標本化行列を $ \\boldsymbol{L} $ ，一次元の標本化間隔を $ \\Delta\_\\mathrm{t} $ ，二次元の標本化間隔を $ \\Delta\_\\mathrm{v},\\Delta\_\\mathrm{h} $ （垂直・水平），連続の角周波数を $ \\nu $ ，正規化角周波数を $ \\omega $ とする。波形 $ u(\\cdot) $ のフーリエ変換を $ \\tilde{u}(\\cdot) $ ，サンプル列（櫛状化した分布） $ x(\\cdot) $ のフーリエ変換を $ \\tilde{x}(\\cdot) $ ，配列の DSFT を $ X(\\mathrm{e}^{\\mathrm{j}\\omega}) $ と書く。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図の配色はロゴの 3 色（メインの緑，寒色系の青，暖色系の橙）と灰色にそろえる。
[~,resfolder] = vie.prjfolders();
cMain = [0 136 85]/255;                        % メイン（緑）
cCool = [46 117 182]/255;                      % 寒色系（青）
cWarm = [197 90 17]/255;                       % 暖色系（橙）
cGray = [0.45 0.45 0.45];                      % 灰色
%[text] 参考資料のサンプル画像 msipimg06（縞模様の路面）をグレースケールにし， $ 256\\times256 $ に縮小して使う。段の縁の細い溝（1 画素ほどの幅の斜めの線）と石の細かい模様が，間引きでエリアシングを起こしやすい（溝が途切れた破線に化ける）。msipimg07（モンブラン），msipimg08（スイカ）の切り出しとも比べ，エリアシングが最もはっきり見えるこの画像を選んだ。
X = im2double(vie.msipimg(6, 256, "gray"));  % 256×256 のグレースケール
size(X)
imwrite(X, fullfile(resfolder,"vie-08-org.png"))
%%
%[text] ## 間引きによる縮小
%[text] 垂直・水平とも偶数番目の画素だけを残す（ $ y[\\boldsymbol{n}]=x[\\boldsymbol{M}\\boldsymbol{n}] $ ， $ \\boldsymbol{M}=\\mathrm{diag}(2,2) $ ）。柵の縞が別の模様に化ける（エリアシング）。
Yd = X(1:2:end, 1:2:end);
imwrite(Yd, fullfile(resfolder,"vie-08-dec.png"))
%%
%[text] ## 平均による縮小
%[text] 前回スライドの例： $ 2\\times2 $ ブロックの平均値を出力する（教科書の例「ブロック平均」）。
x4 = [0 2 4 4; 4 6 4 4; 0 6 4 4; 2 4 6 6]
y2 = (x4(1:2:end,1:2:end) + x4(2:2:end,1:2:end) + x4(1:2:end,2:2:end) + x4(2:2:end,2:2:end))/4
vie.savetex("vie-08-x4",  vie.arr2tex(x4,"%d"));
vie.savetex("vie-08-avg", vie.arr2tex(y2,"%g"));
%[text] スライドの図（TikZ）のマス目の数値も，ここから書き出す。左上のブロックの平均の計算式も添える。
vie.savetex("vie-08-x4-grid",  tikzgrid(x4));
vie.savetex("vie-08-blk-grid", tikzgrid(x4(1:2,1:2)));
hl = false(size(y2)); hl(1,1) = true;          % 左上のブロックの結果を強調
vie.savetex("vie-08-avg-grid", tikzgrid(y2, hl));
blk = x4(1:2,1:2).';                           % x[0,0], x[0,1], x[1,0], x[1,1] の順
vie.savetex("vie-08-blk-avg", sprintf("\\dfrac{%d+%d+%d+%d}{4}=%g", blk(:), y2(1,1)));
%[text] 画像にも施す。
Ya = (X(1:2:end,1:2:end) + X(2:2:end,1:2:end) + X(1:2:end,2:2:end) + X(2:2:end,2:2:end))/4;
imwrite(Ya, fullfile(resfolder,"vie-08-avg.png"))
figure
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(X),  title("原画像")
nexttile, imshow(Yd), title("間引き")
nexttile, imshow(Ya), title("ブロック平均")
%%
%[text] ## 最近傍補間による拡大
%[text] 各画素を $ 2\\times2 $ ブロックに複製する。
y8nn = kron(x4, ones(2))
vie.savetex("vie-08-nn", vie.arr2tex(y8nn,"%d"));
Znn = kron(Ya, ones(2));                     % 縮小画像を 2×2 倍に拡大
imwrite(Znn, fullfile(resfolder,"vie-08-nn.png"))
%%
%[text] ## 双線形補間による拡大
%[text] 零値挿入の後，線形補間フィルタ $ f[n]=(\\frac12,1,\\frac12) $ を垂直・水平に施す（周囲は零値）。元の画素はそのまま残り，間は隣どうしの平均で埋まる。
fl = [1/2 1 1/2];
u8 = zeros(8); u8(1:2:end,1:2:end) = x4;     % 零値挿入
y8bl = conv2(fl, fl, u8, "full");
y8bl = y8bl(2:9, 2:9)                        % 元の画素が偶数番目に来るように切り出す
vie.savetex("vie-08-bl", vie.arr2tex(y8bl,"%g"));
%[text] スライドの例で取り上げる 3 つの値（添え字は 0 始まり）。 $ y[0,1] $ は水平に隣り合う 2 画素の平均， $ y[1,1] $ は 4 画素の平均， $ y[7,7] $ は右下の隅で，元の画素 $ x[3,3] $ と外側の零値 3 つの平均になる。
assert(y8bl(1,2) == (x4(1,1)+x4(1,2))/2 && y8bl(2,2) == sum(x4(1:2,1:2),"all")/4 && y8bl(8,8) == x4(4,4)/4)
vie.savetex("vie-08-bl-y01", sprintf("\\frac{%d+%d}{2}=%g", x4(1,1), x4(1,2), y8bl(1,2)));
vie.savetex("vie-08-bl-y11", sprintf("\\frac{%d+%d+%d+%d}{4}=%g", blk(:), y8bl(2,2)));
vie.savetex("vie-08-bl-y77", sprintf("%d/4=%g", x4(4,4), y8bl(8,8)));
%[text] 画像にも施す（境界は複製拡張）。
Ub = zeros(2*size(Ya)); Ub(1:2:end,1:2:end) = Ya;
Zbl = imfilter(Ub, fl'*fl, "replicate");
Zbl(:,end) = Zbl(:,end-1); Zbl(end,:) = Zbl(end-1,:);   % 右端・下端は複製で補う
imwrite(Zbl, fullfile(resfolder,"vie-08-bl.png"))
figure
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Znn), title("最近傍補間")
nexttile, imshow(Zbl), title("双線形補間")
%[text] 拡大部分（青い帯の斜めの端を含む $ 64\\times64 $ の領域）を比べる。最近傍補間では斜めの縁が階段状になり，双線形補間ではなめらかになる。
zr = 120:183; zc = 50:113;                   % 斜めの縁を含む領域
imwrite(imresize(Znn(zr,zc), 3, "nearest"), fullfile(resfolder,"vie-08-nn-zoom.png"))
imwrite(imresize(Zbl(zr,zc), 3, "nearest"), fullfile(resfolder,"vie-08-bl-zoom.png"))
%%
%[text] ## 一次元の標本化とスペクトル
%[text] 波形 $ u(t) $ を標本化間隔 $ \\Delta\_\\mathrm{t} $ で標本化する（ $ D=1 $ ， $ \\boldsymbol{L}=\\Delta\_\\mathrm{t} $ ）。サンプル列 $ x(t)=u(t)\\,\\mathrm{comb}\_{\\Delta\_\\mathrm{t}}(t) $ のフーリエ変換は
%[text] $ \\tilde{x}(\\nu)=\\frac{1}{\\Delta\_\\mathrm{t}}\\sum\_{k=-\\infty}^{\\infty}\\tilde{u}(\\nu-k\\nu\_\\mathrm{s}),\\quad \\nu\_\\mathrm{s}=\\frac{2\\pi}{\\Delta\_\\mathrm{t}} $
%[text] となり，スペクトル $ \\tilde{u}(\\nu) $ が $ \\nu\_\\mathrm{s} $ ごとに周期化される（教科書 4.1.3 項）。帯域が $ |\\nu|<\\nu\_\\mathrm{max} $ のとき， $ \\Delta\_\\mathrm{t} $ が大きく $ \\nu\_\\mathrm{s}<2\\nu\_\\mathrm{max} $ となると隣どうしが重なってエリアシングが生じる。縦軸は $ \\Delta\_\\mathrm{t} $ 倍した $ \\Delta\_\\mathrm{t}\\tilde{x}(\\nu) $ で描く。
nuv = linspace(-5, 5, 2001);                 % 角周波数 ν（単位は ν_max）
tri = @(v) max(1 - abs(v), 0);               % 三角形のスペクトル ũ(ν)（帯域 ν_max）
nusList = [3 1.4];                           % 標本化角周波数 ν_s = 2π/Δ_t（ν_max の倍数）
figure(Units="centimeters", Position=[2 2 9 6.8])
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, plot(nuv, tri(nuv), "Color", cCool, "LineWidth", 2)
title("$\tilde{u}(\nu)$", "Interpreter","latex")
text(-4.9, 1.2, "原信号のスペクトル", "Color", cCool)
for nus = nusList
    nexttile, hold on
    S = zeros(size(nuv));
    for k = -5:5
        plot(nuv, tri(nuv - k*nus), ":", "Color", cGray)
        S = S + tri(nuv - k*nus);            % Δ_t x̃(ν) = Σ_k ũ(ν - kν_s)
    end
    if nus >= 2
        cS = cMain; note = "重ならない";
    else
        cS = cWarm; note = "重なる：エリアシング";
    end
    plot(nuv, S, "Color", cS, "LineWidth", 2)
    plot([0 nus], [1.2 1.2], "-", "Color", cGray)                   % ν_s の間隔
    plot(0, 1.2, "<", nus, 1.2, ">", "MarkerSize", 4, "MarkerFaceColor", cGray, "Color", cGray)
    text(nus + 0.1, 1.2, "$\nu_\mathrm{s}$", "Interpreter","latex", "HorizontalAlignment","left")
    text(-4.9, 1.2, note, "Color", cS)
    hold off
    title("$\Delta_\mathrm{t}\tilde{x}(\nu)\quad(\nu_\mathrm{s}=2\pi/\Delta_\mathrm{t}=" + nus + "\nu_\mathrm{max})$", "Interpreter","latex")
end
xlabel("$\nu/\nu_\mathrm{max}$", "Interpreter","latex")
for ax = findobj(gcf, "Type","axes").'
    set(ax, "YLim", [0 1.5], "YTick", [0 1], "XTick", -5:5, "XTickLabel", compose("$%d$", -5:5), ...
        "TickLabelInterpreter","latex"), grid(ax, "on")
end
fontsize(gcf, 9.5, "points")
set(findall(gcf, "Type","text", "Interpreter","tex"), "FontSize", 8)   % 和文の注記は一回り小さく
exportgraphics(gcf, fullfile(resfolder,"vie-08-sampling.png"), "Resolution", 300)
%%
%[text] ## 多次元の標本化とスペクトル
%[text] 二次元では標本化行列 $ \\boldsymbol{L}=\\mathrm{diag}(\\Delta\_\\mathrm{v},\\Delta\_\\mathrm{h}) $ の格子で標本化する。サンプル列のフーリエ変換は
%[text] $ \\tilde{x}(\\boldsymbol{\\nu})=\\frac{1}{|\\det(\\boldsymbol{L})|}\\sum\_{\\boldsymbol{m}\\in\\mathbb{Z}^D}\\tilde{u}(\\boldsymbol{\\nu}-2\\pi\\boldsymbol{L}^{-\\top}\\boldsymbol{m}) $
%[text] となり，周期構造行列 $ 2\\pi\\boldsymbol{L}^{-\\top} $ の周期性をもつ（教科書 4.1.3 項）。前回の演習課題（8）－2 の図の見せ方にならい，標本化格子と，標本化後の周波数スペクトルのサポート（台）を描く。垂直の間隔を水平の 2 倍にとる。
Dv = 2; Dh = 1;                                % 標本化間隔（垂直・水平）
L = diag([Dv Dh])                              % 標本化行列（第 1 次元が垂直）
detL = abs(det(L))                             % 基本平行多面体 FPD(L) の面積
Lp = 2*pi*(L.'\eye(2))                         % 周期構造行列 2πL^{-T}
vie.savetex("vie-08-lat-dv", sprintf("%g", Dv));
vie.savetex("vie-08-lat-dh", sprintf("%g", Dh));
vie.savetex("vie-08-lat-L", vie.arr2tex(L,"%g"));
vie.savetex("vie-08-lat-det", sprintf("%g", detL));
vie.savetex("vie-08-lat-per", strjoin(join(arrayfun(@pistr, Lp), " & ", 2), "\\" + newline));
vie.savetex("vie-08-lat-perv", pistr(Lp(1,1)));
vie.savetex("vie-08-lat-perh", pistr(Lp(2,2)));
%[text] 標本化格子 $ \\boldsymbol{q}=\\boldsymbol{L}\\boldsymbol{n} $ 。教科書の図と同じく，水平 $ q\_\\mathrm{h} $ を右向き，垂直 $ q\_\\mathrm{v} $ を下向きにとる。薄い緑の領域が基本平行多面体 $ \\mathrm{FPD}(\\boldsymbol{L}) $ （面積 $ |\\det(\\boldsymbol{L})| $ ），矢印が $ \\boldsymbol{L} $ の列ベクトル。
[nh, nv] = meshgrid(0:4, 0:2);
Q = L*[nv(:) nh(:)].';                         % 標本点（第 1 行が q_v，第 2 行が q_h）
figure(Units="centimeters", Position=[2 2 6 6.2])
hold on
fill([0 Dh Dh 0], [0 0 Dv Dv], cMain, "FaceAlpha", 0.15, "EdgeColor", "none")
plot(Q(2,:), Q(1,:), "o", "MarkerSize", 6, "MarkerFaceColor", cMain, "MarkerEdgeColor", cMain)
quiver(0, 0, 0, Dv, 0, "Color", cWarm, "LineWidth", 1.5, "MaxHeadSize", 0.2)
quiver(0, 0, Dh, 0, 0, "Color", cWarm, "LineWidth", 1.5, "MaxHeadSize", 0.4)
text(-0.12, Dv*0.55, "$\Delta_\mathrm{v}$", "Interpreter","latex", "HorizontalAlignment","right", "Color", cWarm)
text(Dh*0.5, 0.12, "$\Delta_\mathrm{h}$", "Interpreter","latex", "HorizontalAlignment","center", "VerticalAlignment","top", "Color", cWarm)
hold off
ax = gca;
set(ax, "YDir","reverse", "XAxisLocation","top", "TickLabelInterpreter","latex", ...
    "XTick", 0:4, "YTick", 0:4, "XLim", [-0.7 4.5], "YLim", [-0.4 4.6])
axis equal, grid on, box off
xlim([-0.7 4.5]), ylim([-0.4 4.6])
xlabel("$q_\mathrm{h}$", "Interpreter","latex"), ylabel("$q_\mathrm{v}$", "Interpreter","latex")
fontsize(gcf, 11, "points")
exportgraphics(gcf, fullfile(resfolder,"vie-08-lattice.png"), "Resolution", 300)
%[text] 波形のスペクトル $ \\tilde{u}(\\boldsymbol{\\nu}) $ のサポートをひし形 $ |\\nu\_\\mathrm{v}|/(0.45\\pi)+|\\nu\_\\mathrm{h}|/(0.9\\pi)\\le1 $ とする。標本化後は $ 2\\pi\\boldsymbol{L}^{-\\top}\\boldsymbol{m} $ だけずれた複製が並ぶ（青：元のサポート，緑：複製）。破線は複製ごとの周期の区切り（ $ \\boldsymbol{0} $ を中心とする $ \\mathrm{FPD}(2\\pi\\boldsymbol{L}^{-\\top}) $ の平行移動）で，サポートが区切りの中に収まれば重ならない。矢印が $ 2\\pi\\boldsymbol{L}^{-\\top} $ の列ベクトル（垂直の周期 $ 2\\pi/\\Delta\_\\mathrm{v} $ ，水平の周期 $ 2\\pi/\\Delta\_\\mathrm{h} $ ）。
av = 0.45*pi; ah = 0.9*pi;                     % サポートの半径（垂直・水平）
sup = polyshape([0 ah 0 -ah], [-av 0 av 0]);   % 横軸 ν_h，縦軸 ν_v
lim = 2.5*pi;
figure(Units="centimeters", Position=[2 2 7 7])
hold on
for mv = -4:4
    for mh = -2:2
        s = Lp*[mv; mh];                       % ずれ 2πL^{-T} m（第 1 成分が垂直）
        if mv == 0 && mh == 0, continue, end
        plot(translate(sup, s(2), s(1)), "FaceColor", cMain, "FaceAlpha", 0.25, "EdgeColor", cMain)
    end
end
plot(sup, "FaceColor", cCool, "FaceAlpha", 0.7, "EdgeColor", cCool)
xline((-3:2:3)*Lp(2,2)/2, "--", "Color", cGray)   % 周期の区切り（水平）
yline((-5:2:5)*Lp(1,1)/2, "--", "Color", cGray)   % 周期の区切り（垂直）
xline(0, "k"), yline(0, "k")
quiver(0, 0, Lp(2,2), 0, 0, "Color", cWarm, "LineWidth", 1.5, "MaxHeadSize", 0.12)
quiver(0, 0, 0, Lp(1,1), 0, "Color", cWarm, "LineWidth", 1.5, "MaxHeadSize", 0.25)
text(Lp(2,2), -0.12*pi, "$2\pi/\Delta_\mathrm{h}$", "Interpreter","latex", "HorizontalAlignment","center", ...
    "VerticalAlignment","bottom", "Color", cWarm, "BackgroundColor","w", "Margin", 0.5)
text(0.1*pi, Lp(1,1)+0.1*pi, "$2\pi/\Delta_\mathrm{v}$", "Interpreter","latex", "HorizontalAlignment","left", ...
    "VerticalAlignment","top", "Color", cWarm, "BackgroundColor","w", "Margin", 0.5)
hold off
ax = gca;
tk = (-2:2)*pi;
set(ax, "YDir","reverse", "TickLabelInterpreter","latex", "XTick", tk, "YTick", tk, ...
    "XTickLabel", arrayfun(@(v) "$"+pistr(v)+"$", tk), "YTickLabel", arrayfun(@(v) "$"+pistr(v)+"$", tk))
axis equal, box on
xlim([-lim lim]), ylim([-lim lim])
xlabel("$\nu_\mathrm{h}$", "Interpreter","latex"), ylabel("$\nu_\mathrm{v}$", "Interpreter","latex")
fontsize(gcf, 11, "points")
exportgraphics(gcf, fullfile(resfolder,"vie-08-spec2d.png"), "Resolution", 300)
%[text] 複製どうしが重ならないこと（エリアシングが生じないこと）を確かめる。
ovl = 0;
for mv = -1:1
    for mh = -1:1
        if mv == 0 && mh == 0, continue, end
        s = Lp*[mv; mh];
        ovl = ovl + area(intersect(sup, translate(sup, s(2), s(1))));
    end
end
ovl                                            % 0 なら重ならない
%%
%[text] ## ダウンサンプラとアップサンプラ
%[text] 間引き $ y[n]=x[Mn] $ と零値挿入（各サンプルの間に $ M-1 $ 個の零を挿入）。 $ M=2 $ の例：
xd = [2 2 4 2 2 4];
yds = xd(1:2:end)
xu = [2 2 4];
yus = zeros(1, 2*numel(xu)); yus(1:2:end) = xu
vie.savetex("vie-08-ds-x", strjoin(string(xd),",\ "));
vie.savetex("vie-08-ds-y", strjoin(string(yds),",\ "));
vie.savetex("vie-08-us-x", strjoin(string(xu),",\ "));
vie.savetex("vie-08-us-y", strjoin(string(yus),",\ "));
%%
%[text] ## レート変換器（デシメータ・インタポレータ）の数値例
%[text] デシメータ：平均フィルタ $ h[n]=(\\frac12,\\frac12) $ （ $ n=0,1 $ ）の後に 2 対 1 の間引き。
v = filter([1/2 1/2], 1, xd)                 % v[n] = (x[n]+x[n-1])/2（x[-1]=0）
ydec = v(2:2:end)                            % 平均が揃う奇数番目を出力（位相の選択）
vie.savetex("vie-08-dec-v", strjoin(compose("%g",v),",\ "));
vie.savetex("vie-08-dec-y", strjoin(compose("%g",ydec),",\ "));
%[text] インタポレータ：零値挿入の後，最近傍補間フィルタ $ f[m]=(1,1) $ （ $ m=0,1 $ ）。
yint = filter([1 1], 1, yus)
vie.savetex("vie-08-int-y", strjoin(string(yint),",\ "));
%%
%[text] ## エリアシング（間引き率 2）
%[text] 間引き後のスペクトルは $ Y(\\mathrm{e}^{\\mathrm{j}\\omega})=\\frac12X(\\mathrm{e}^{\\mathrm{j}\\omega/2})+\\frac12X(\\mathrm{e}^{\\mathrm{j}(\\omega-2\\pi)/2}) $ 。帯域 $ 0.7\\pi $ の信号では，引き伸ばされた 2 つの成分が重なる。通過域 $ |\\omega|<\\pi/2 $ の理想低域通過フィルタの出力 $ v[n] $ を間引けば重ならない。
w = linspace(-pi, 3*pi, 2001);
Xw = @(om) max(1 - abs(mod(om+pi, 2*pi) - pi)/(0.7*pi), 0);   % 周期 2π，帯域 0.7π
Y1 = 0.5*(Xw(w/2) + Xw((w - 2*pi)/2));
Hid = @(om) double(abs(mod(om+pi, 2*pi) - pi) < pi/2);        % 理想低域通過（π/2）
Vw = @(om) Hid(om).*Xw(om);
figure(Units="centimeters", Position=[2 2 8 5.8])
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, plot(w, Xw(w), "Color", cCool, "LineWidth", 2)
title("$X(\mathrm{e}^{\mathrm{j}\omega})$", "Interpreter","latex")
nexttile, plot(w, 0.5*Xw(w/2), "--", "Color", cMain, "LineWidth", 1.5), hold on
plot(w, 0.5*Xw((w-2*pi)/2), "--", "Color", cGray, "LineWidth", 1.5)
plot(w, Y1, "Color", cWarm, "LineWidth", 2), hold off
title("$Y(\mathrm{e}^{\mathrm{j}\omega})$", "Interpreter","latex")
text(-0.95*pi, 0.68, "フィルタなしで間引き：破線の 2 成分が重なる", "Color", cWarm)
nexttile, plot(w, 0.5*Vw(w/2), "--", "Color", cMain, "LineWidth", 1.5), hold on
plot(w, 0.5*Vw((w-2*pi)/2), "--", "Color", cGray, "LineWidth", 1.5), hold off
title("$\frac{1}{2}V(\mathrm{e}^{\mathrm{j}\omega/2})+\frac{1}{2}V(\mathrm{e}^{\mathrm{j}(\omega-2\pi)/2})$", "Interpreter","latex")
text(-0.95*pi, 0.68, "低域通過フィルタの後に間引き：重ならない", "Color", cMain)
xlabel("$\omega$", "Interpreter","latex")
axs = flipud(findobj(gcf, "Type","axes"));     % 上の段から順に
for k = 1:3
    set(axs(k), "XTick", -pi:pi:3*pi, "XTickLabel", ["$-\pi$","$0$","$\pi$","$2\pi$","$3\pi$"], ...
        "TickLabelInterpreter","latex"), grid(axs(k), "on")
end
set(axs(1), "YLim", [0 1.2], "YTick", [0 1])
set(axs(2:3), "YLim", [0 0.8], "YTick", [0 0.5])
set(axs(1:2), "XTickLabel", [])               % 横軸の目盛の数値は最下段だけ
fontsize(gcf, 9, "points")
set(findall(gcf, "Type","text", "Interpreter","tex"), "FontSize", 7.5)
exportgraphics(gcf, fullfile(resfolder,"vie-08-alias.png"), "Resolution", 300)
%%
%[text] ## イメージング（補間率 2）
%[text] 零値挿入後のスペクトルは $ Y(\\mathrm{e}^{\\mathrm{j}\\omega})=X(\\mathrm{e}^{\\mathrm{j}2\\omega}) $ 。 $ \\omega=\\pi $ のまわりに余分な成分（イメージング）が現れる。補間フィルタ（理想低域通過，利得 2）で取り除く。
Xw2 = @(om) max(1 - abs(mod(om+pi, 2*pi) - pi)/(0.8*pi), 0);
Yi = Xw2(2*w);
Fi = 2*Hid(w);
figure(Units="centimeters", Position=[2 2 10 6.4])
tiledlayout(3,1,"TileSpacing","compact","Padding","compact")
nexttile, plot(w, Xw2(w), "Color", cCool, "LineWidth", 2)
title("$X(\mathrm{e}^{\mathrm{j}\omega})$", "Interpreter","latex")
nexttile, plot(w, Yi, "Color", cWarm, "LineWidth", 2)
title("$Y(\mathrm{e}^{\mathrm{j}\omega})=X(\mathrm{e}^{\mathrm{j}2\omega})$", "Interpreter","latex")
text(0.5*pi, 1.8, "零値挿入後：イメージングが生じる", "Color", cWarm, "HorizontalAlignment","center")
nexttile, plot(w, Fi.*Yi, "Color", cMain, "LineWidth", 2)
title("$F(\mathrm{e}^{\mathrm{j}\omega})Y(\mathrm{e}^{\mathrm{j}\omega})$", "Interpreter","latex")
text(pi, 1.75, "イメージング除去", "Color", cMain, "HorizontalAlignment","center")
xlabel("$\omega$", "Interpreter","latex")
axs = flipud(findobj(gcf, "Type","axes"));     % 上の段から順に
for k = 1:3
    set(axs(k), "YLim", [0 2.3], "XTick", -pi:pi:3*pi, "XTickLabel", ["$-\pi$","$0$","$\pi$","$2\pi$","$3\pi$"], ...
        "TickLabelInterpreter","latex"), grid(axs(k), "on")
end
set(axs(1:2), "XTickLabel", [])               % 横軸の目盛の数値は最下段だけ
fontsize(gcf, 9, "points")
set(findall(gcf, "Type","text", "Interpreter","tex"), "FontSize", 7.5)
exportgraphics(gcf, fullfile(resfolder,"vie-08-imaging.png"), "Resolution", 300)
%%
%[text] ## デシメーションフィルタと補間フィルタの振幅応答
%[text] 平均フィルタ $ (\\frac12,\\frac12) $ ： $ |H|=|\\cos(\\omega/2)| $ 。最近傍補間フィルタ $ (1,1) $ ： $ |F|=2|\\cos(\\omega/2)| $ 。線形補間フィルタ $ (\\frac12,1,\\frac12) $ ： $ F=1+\\cos\\omega $ 。
%[text] 凡例の代わりに，曲線のそばに名前を添える。
wp = linspace(0, pi, 501);
figure(Units="centimeters", Position=[2 2 8 6])
plot(wp, double(wp < pi/2), "--", "Color", cGray, "LineWidth", 1.5), hold on
plot(wp, abs(cos(wp/2)), "Color", cMain, "LineWidth", 2), hold off, grid on
xlim([0 pi]), ylim([0 1.15])
text(0.03*pi, 1.07, "理想特性", "Color", cGray)
text(0.6*pi, 0.98, ["平均値フィルタ","(1/2,1/2)"], "Color", cMain, "VerticalAlignment","top")
set(gca, "XTick", [0 pi/2 pi], "XTickLabel", ["$0$","$\pi/2$","$\pi$"], "TickLabelInterpreter","latex")
xlabel("$\omega$", "Interpreter","latex"), ylabel("$|H(\mathrm{e}^{\mathrm{j}\omega})|$", "Interpreter","latex")
fontsize(gcf, 10, "points")
set(findall(gcf, "Type","text", "Interpreter","tex"), "FontSize", 8.5)
exportgraphics(gcf, fullfile(resfolder,"vie-08-decfilt.png"), "Resolution", 300)
%[text] 補間フィルタ。 $ \\omega=\\pi $ （イメージングの中心）では最近傍も線形も 0。 $ \\omega=3\\pi/4 $ での値を丸印で示す。
vals = [2*abs(cos(3*pi/8)) 1 + cos(3*pi/4)]
figure(Units="centimeters", Position=[2 2 8 6])
plot(wp, 2*double(wp < pi/2), "--", "Color", cGray, "LineWidth", 1.5), hold on
plot(wp, 2*abs(cos(wp/2)), "Color", cWarm, "LineWidth", 2)
plot(wp, 1 + cos(wp), "Color", cMain, "LineWidth", 2)
plot(3*pi/4, vals(1), "o", "Color", cWarm, "MarkerFaceColor", "w", "LineWidth", 1.5)
plot(3*pi/4, vals(2), "o", "Color", cMain, "MarkerFaceColor", "w", "LineWidth", 1.5), hold off, grid on
xlim([0 pi]), ylim([0 2.35])
text(0.03*pi, 2.18, "理想特性（利得 2）", "Color", cGray)
text(0.62*pi, 1.45, "最近傍 (1,1)", "Color", cWarm)
text(0.47*pi, 0.8, "線形 (1/2,1,1/2)", "Color", cMain, "HorizontalAlignment","right")
set(gca, "XTick", [0 pi/2 3*pi/4 pi], "XTickLabel", ["$0$","$\pi/2$","$3\pi/4$","$\pi$"], "TickLabelInterpreter","latex")
xlabel("$\omega$", "Interpreter","latex"), ylabel("$|F(\mathrm{e}^{\mathrm{j}\omega})|$", "Interpreter","latex")
fontsize(gcf, 10, "points")
set(findall(gcf, "Type","text", "Interpreter","tex"), "FontSize", 8.5)
exportgraphics(gcf, fullfile(resfolder,"vie-08-intfilt.png"), "Resolution", 300)
vie.savetex("vie-08-f34-nn", sprintf("%.2f",vals(1)));
vie.savetex("vie-08-f34-bl", sprintf("%.2f",vals(2)));
%%
%[text] ## 二次元の補間フィルタの周波数応答
%[text] 教科書の例題「補間フィルタ」：補間率 $ 2\\times2 $ 倍の零次ホールドフィルタ $ F\_\\mathrm{ZH}(\\boldsymbol{z})=(1+z\_\\mathrm{v}^{-1})(1+z\_\\mathrm{h}^{-1}) $ と双線形補間フィルタ $ F\_\\mathrm{BL}(\\boldsymbol{z})=\\frac14(z\_\\mathrm{v}+2+z\_\\mathrm{v}^{-1})(z\_\\mathrm{h}+2+z\_\\mathrm{h}^{-1}) $ の利得を，インパルス応答から直接計算する。
fzh = ones(2);                                 % 零次ホールド（n_v, n_h = 0,1）
fbl = [1 2 1].'*[1 2 1]/4;                     % 双線形（n_v, n_h = -1,0,1）
Fzh = @(wv,wh) sum(fzh .* exp(-1j*(wv*(0:1).' + wh*(0:1))), "all");
Fbl = @(wv,wh) sum(fbl .* exp(-1j*(wv*(-1:1).' + wh*(-1:1))), "all");
gainDC  = round(abs([Fzh(0,0) Fbl(0,0)]), 10)                 % ω = 0（直流）：ともに M = |det(M)| = 4
gainPi2 = round(abs([Fzh(pi/2,pi/2) Fbl(pi/2,pi/2)]), 10)     % ω = (π/2 π/2)^T：零次ホールド 2，双線形 1
assert(isequal(gainDC, [4 4]) && isequal(gainPi2, [2 1]))     % 教科書の解答と一致
vie.savetex("vie-08-f2d-dc", sprintf("%g", gainDC(1)));
vie.savetex("vie-08-fzh-pi2", sprintf("%g", gainPi2(1)));
vie.savetex("vie-08-fbl-pi2", sprintf("%g", gainPi2(2)));
%%
%[text] ## 3次畳み込み補間
%[text] 教科書の例題「3次畳み込み補間」：Keys の補間核 $ \\kappa(q) $ （ $ a=-1/2 $ ）による補間率 $ 2\\times2 $ 倍の補間フィルタ $ f[\\boldsymbol{n}]=\\kappa(n\_1/2)\\,\\kappa(n\_2/2) $ ， $ \\boldsymbol{n}\\in\\{-4,\\ldots,4\\}^2 $ 。
a = -1/2;
kappa = @(q) ((a+2)*abs(q).^3 - (a+3)*abs(q).^2 + 1).*(abs(q) <= 1) ...
    + (a*abs(q).^3 - 5*a*abs(q).^2 + 8*a*abs(q) - 4*a).*(abs(q) > 1 & abs(q) <= 2);
nn = -4:4;
f1 = kappa(nn/2)                               % 一次元の補間フィルタ f_d[n_d]
fcub = f1.'*f1;                                % 二次元（分離型）
%[text] 教科書の解答の行列（小数第 4 位）と比べる。
ftext = [0 0 0 0 0 0 0 0 0;
    0 0.0039 0 -0.0352 -0.0625 -0.0352 0 0.0039 0;
    0 0 0 0 0 0 0 0 0;
    0 -0.0352 0 0.3164 0.5625 0.3164 0 -0.0352 0;
    0 -0.0625 0 0.5625 1.0000 0.5625 0 -0.0625 0;
    0 -0.0352 0 0.3164 0.5625 0.3164 0 -0.0352 0;
    0 0 0 0 0 0 0 0 0;
    0 0.0039 0 -0.0352 -0.0625 -0.0352 0 0.0039 0;
    0 0 0 0 0 0 0 0 0];
assert(isequal(round(fcub,4), ftext))          % 教科書と一致
%[text] スライドには中央の行 $ f[0,n\_2] $ （ $ n\_2=-4,\\ldots,4 $ ）を載せる。零は "0"，それ以外は小数第 4 位まで（教科書の書式）。
row = compose("%.4f", fcub(5,:)); row(abs(fcub(5,:)) < 1e-12) = "0";
vie.savetex("vie-08-cubic-row", strjoin(row, ","));
%%
%[text] ## 画像の縮小（分離処理）
%[text] 垂直・水平とも間引き率 2。フィルタなし，平均 $ (\\frac12,\\frac12) $ ， $ (\\frac14,\\frac12,\\frac14) $ を比べる。
h2 = [1/2 1/2]; h3 = [1/4 1/2 1/4];
D0 = X(1:2:end,1:2:end);
D1 = imfilter(X, h2'*h2, "replicate"); D1 = D1(1:2:end,1:2:end);
D2 = imfilter(X, h3'*h3, "replicate"); D2 = D2(1:2:end,1:2:end);
figure
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, imshow(D0), title("フィルタなし")
nexttile, imshow(D1), title("(1/2,1/2)")
nexttile, imshow(D2), title("(1/4,1/2,1/4)")
imwrite(D1, fullfile(resfolder,"vie-08-dec-h2.png"))
imwrite(D2, fullfile(resfolder,"vie-08-dec-h3.png"))
%%
%[text] ## まとめ
%[text] - 標本化は周波数スペクトルを周期化する（一次元は $ 2\\pi/\\Delta\_\\mathrm{t} $ ，多次元は周期構造行列 $ 2\\pi\\boldsymbol{L}^{-\\top} $ ）。間隔が粗いとエリアシングが生じる
%[text] - 縮小は「低域通過フィルタ＋間引き」（デシメーション），拡大は「零値挿入＋補間フィルタ」（インタポレーション）
%[text] - 平均による縮小と双線形補間による拡大は，それぞれエリアシングとイメージングを抑える \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

function s = pistr(v)
% PISTR π の整数倍を LaTeX の文字列にする（例：2*pi → "2\pi"，pi → "\pi"，0 → "0"）
c = round(v/pi, 6);
if c == 0
    s = "0";
elseif c == 1
    s = "\pi";
elseif c == -1
    s = "-\pi";
else
    s = sprintf("%g", c) + "\pi";
end
end

function s = tikzgrid(A, hl)
% TIKZGRID 配列 A の各要素を TikZ のマス目（\node）にする。第 (r,c) 要素を座標 (c-1, -(r-1)) に置く
%   HL が true の要素は塗り（msipwarmlight）で強調する
if nargin < 2
    hl = false(size(A));
end
lines = strings(numel(A), 1);
k = 0;
for r = 1:size(A,1)
    for c = 1:size(A,2)
        k = k + 1;
        opt = "draw,minimum size=6mm";
        if hl(r,c)
            opt = opt + ",fill=msipwarmlight";
        end
        lines(k) = sprintf("\\node[%s] at (%d,%d) {%g};", opt, c-1, -(r-1), A(r,c));
    end
end
s = strjoin(lines, newline);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
