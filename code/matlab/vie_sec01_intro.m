%[text] # 第1回 導入と全体概要
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第1回のスライド（vie2026-01）で使う図と数値をすべてこのスクリプトで作る。スライドに書ききれない計算の途中経過も，ここで丁寧に追いかける。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図と LaTeX 断片は `results` フォルダに書き出す。VieSlides 側では `tools/sync-results.ps1` でそれらを取り込む。
[datfolder,resfolder] = vie.prjfolders();
figw = 16; figh = 4.8; % 書き出す図の大きさ [cm]（スライドの横幅に合わせる）
%[text] 図の配色はスライドと揃え，ロゴの 3 色（メインの緑，寒色系の青，暖色系の橙）と灰色を使う。
cmain = [0 136 85]/255;     % メイン（緑）#008855：図の主役
ccool = [46 117 182]/255;   % 寒色系（青）#2E75B6：第 2 系統
cwarm = [197 90 17]/255;    % 暖色系（橙）#C55A11：注目させたい箇所
cgray = [0.6 0.6 0.6];      % 補助線（灰）
%%
%[text] ## 音声信号：一変量の関数とその標本化
%[text] 音叉の音のように，音声信号（モノラル）は時刻 $ t $ の**一変量の関数** $ u(t) $ とみなせる（参考資料 1.4.1 項の記法）。ここでは 1 秒間に 440 回振動する音（ラの音）を，少しずつ減衰する正弦波で模擬する。
%[text]{"align":"center"} $ u(t) = \\mathrm{e}^{-t/\\tau}\\sin(2\\pi f\_0 t),\\quad f\_0 = 440\\ \\mathrm{Hz} $
%[text] これを標本化周波数 $ f\_\\mathrm{s} $（標本化間隔 $ \\Delta\_\\mathrm{t}=1/f\_\\mathrm{s} $）で標本化すると，**数列（サンプル列）** $ x[n] = u(\\Delta\_\\mathrm{t}n) $ が得られる。
f0  = 440;          % 音の高さ [Hz]
tau = 0.4;          % 減衰の時定数 [s]
fs  = 8000;         % 標本化周波数 [Hz]
n   = 0:fs-1;       % 1 秒分の標本番号
xn  = exp(-n/fs/tau).*sin(2*pi*f0*n/fs);
%[text] 冒頭の 5 ms だけを拡大すると，連続な波形 $ u(t) $（灰色）の上に標本 $ x[n] $（緑）が等間隔に並んでいるのが分かる。右は周波数成分の時間変化（スペクトログラム）で，440 Hz に成分が集中している。「どのような成分から構成されているか」を調べるのがフーリエ解析（第7回）である。
%[text] 講義で使ったデモ（録音した声のスペクトログラムを表示する `analysisdemo`）と同じ見せ方を，録音の代わりに模擬音で再現している。
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile
tc = linspace(0,5e-3,500);
plot(tc*1e3, exp(-tc/tau).*sin(2*pi*f0*tc), "Color",cgray, "LineWidth",1), hold on
ns = 0:round(5e-3*fs);
stem(ns/fs*1e3, xn(ns+1), "filled", "MarkerSize",3, "Color",cmain), hold off
xlabel("時刻 \itt\rm [ms]"), ylabel("振幅")
title("\itu\rm(\itt\rm) と標本 \itx\rm[\itn\rm]")
grid on
nexttile
spectrogram(xn, hann(256), 192, 512, fs, "yaxis")
ylim([0 2]), title("スペクトログラム"), colorbar off
xlabel("時刻 \itt\rm [ms]"), ylabel("周波数 [kHz]")
set(gcf,"Units","centimeters","Position",[2 2 figw figh])
drawnow   % 大きさの変更を反映させてから書き出す
exportgraphics(gcf, fullfile(resfolder,"vie-01-audio.png"), "Resolution",200)
%%
%[text] ## 画像信号：多変量の関数とその標本化
%[text] 画像信号（モノクロ）は位置 $ (q\_\\mathrm{v},q\_\\mathrm{h}) $ の**多変量の関数** $ u(q\_\\mathrm{v},q\_\\mathrm{h}) $ とみなせる。標本化すると**配列（画素配列）** $ x[n\_\\mathrm{v},n\_\\mathrm{h}] $ が得られる。
%[text] 画像は参考資料のサンプル画像 msipimg05（石像の顔，512×512 のカラー）を 256×256 に縮小し，グレースケールにしたものを使う。
X = vie.msipimg(5, 256, "gray");  % 8 bit グレースケール画像（uint8）
sz = size(X)
%[text] 一配列要素あたりのビット数 $ \\beta $ は，変数の占めるバイト数（`whos`）を要素数で割れば分かる（講義のデモ `dataamount` と同じ確かめ方）。
whosX  = whos("X");
bitsX = 8*whosX.bytes/numel(X)     % 8 bits（uint8 型）
vie.savetex("vie-01-image-size", sprintf("$%d\\times%d$", sz(1), sz(2)));
vie.savetex("vie-01-image-bits", sprintf("%d", bitsX));
%[text] 画像の一部（左上の空と石像の境目）を切り出して数値を見る。明るい空（200 台）から暗い石（100 前後以下）へ，値が斜めに切り替わる様子が数値で分かる。画像は数の並びにすぎない。MATLAB の添字は 1 から始まるが，教科書の配列 $ x[n\_\\mathrm{v},n\_\\mathrm{h}] $ の添字は 0 から始まるので，位置は 1 を引いて示す。
r0 = 50; c0 = 27; w = 5;          % 切り出す位置（MATLAB の添字）と大きさ
blk = X(r0:r0+w-1, c0:c0+w-1)
vie.savetex("vie-01-pixels", "\begin{bmatrix}" + vie.arr2tex(double(blk),"%d") + "\end{bmatrix}");
vie.savetex("vie-01-pixels-pos", sprintf("n_\\mathrm{v}=%d\\sim%d,\\ n_\\mathrm{h}=%d\\sim%d", r0-1, r0+w-2, c0-1, c0+w-2));
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile
imshow(X), hold on
rectangle("Position",[c0-0.5 r0-0.5 w w],"EdgeColor",cwarm,"LineWidth",1.5), hold off
title(sprintf("%d×%d 画素", sz(1), sz(2)))
nexttile
imshow(imresize(blk, 40, "nearest"))
for i = 1:w
    for j = 1:w
        text((j-0.5)*40, (i-0.5)*40, string(blk(i,j)), ...
            "HorizontalAlignment","center", "Color",cwarm, "FontSize",9)
    end
end
title("橙枠内の画素値")
%[text] スライド用には，枠を画像に焼き込んだものを書き出す（画素値はスライド側で行列として示す）。スライド上で見えるよう，画像を 2 倍に拡大してから，切り出した範囲の外側に太さ 4 画素の橙色の枠を描く。
k   = 2;                                   % 書き出す画像の拡大率
lw  = 4;                                   % 枠の太さ（拡大後の画素数）
Xk  = imresize(X, k, "nearest");
rin = (r0-1)*k+1 : (r0+w-1)*k;             % 拡大後の画像で切り出した範囲（行）
cin = (c0-1)*k+1 : (c0+w-1)*k;             % 同（列）
boxmask = false(size(Xk));
boxmask(rin(1)-lw:rin(end)+lw, cin(1)-lw:cin(end)+lw) = true;
boxmask(rin, cin) = false;                 % 内側は残して枠だけにする
Xbox = repmat(Xk,[1 1 3]);
for ch = 1:3
    plane = Xbox(:,:,ch);
    plane(boxmask) = round(255*cwarm(ch));
    Xbox(:,:,ch) = plane;
end
imwrite(Xbox, fullfile(resfolder,"vie-01-image.png"))
%%
%[text] ## 信号の解析（一次元）：近似成分と詳細成分
%[text] 前回スライドの例を計算する。信号 $ x[n]\\ (n=0,1,2,\\ldots) $ に対し，**隣同士を足して 2 で割る**と近似成分 $ a[n] $，**左隣から引いて 2 で割る**と詳細成分 $ d[n] $ が得られる。
%[text] 現在と過去の標本だけを使う**因果的**な形に書く。こうすると，次節のフィルタ $ H\_0(z)=\\frac{1}{2}(1+z^{-1}) $，$ H\_1(z)=\\frac{1}{2}(-1+z^{-1}) $ の出力そのものになる。
%[text]{"align":"center"} $ a[n] = \\frac{1}{2}\\left(x[n]+x[n-1]\\right),\\qquad d[n] = \\frac{1}{2}\\left(-x[n]+x[n-1]\\right),\\qquad n=1,2,\\ldots $
x = [3 1 3 1 5 3 5];               % x(1) が x[0]
a = (x(2:end) + x(1:end-1))/2      % 近似成分 a[n]，n = 1,2,...
d = (-x(2:end) + x(1:end-1))/2     % 詳細成分 d[n]，n = 1,2,...
%[text] 次節の $ H\_0(z) $，$ H\_1(z) $ で x をフィルタリングした出力（n=1 以降）と一致することを確かめる。
a_f = filter([1 1]/2, 1, x);  d_f = filter([-1 1]/2, 1, x);
assert(isequal(a, a_f(2:end)) && isequal(d, d_f(2:end)))
%[text] 近似成分はゆっくり変わる成分（低周波成分），詳細成分は細かく変わる成分（高周波成分）を担う。
vie.savetex("vie-01-haar-x",   vie.arr2tex(x(1:end-1)));
vie.savetex("vie-01-haar-sum", vie.arr2tex(x(2:end)+x(1:end-1)));    % x[n]+x[n-1]
vie.savetex("vie-01-haar-dif", vie.arr2tex(-x(2:end)+x(1:end-1)));   % x[n-1]-x[n]
vie.savetex("vie-01-haar-a",   vie.arr2tex(a));
vie.savetex("vie-01-haar-d",   vie.arr2tex(d));
%%
%[text] ## 信号の合成：足し合わせると元に戻る
%[text] 定義から $ a[n]+d[n] = x[n-1] $ が成り立つ。1 標本遅れるだけで元に戻る（全体の伝達関数 $ T(z)=H\_0(z)+H\_1(z)=z^{-1} $）。足し算と引き算だけの分解だが，**信号の情報を逃さない**立派な成分分析法である。
xr = a + d
assert(isequal(xr, x(1:end-1)))    % x[n-1]，n = 1,2,...
vie.savetex("vie-01-haar-rec", vie.arr2tex(xr));
%[text] 近似成分を緑，詳細成分を青，両者の和を橙で描く。和の図には元の信号 $ x[n] $ を灰色の白抜きの丸で重ね，一致することを示す。
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nn = 1:numel(a);                   % n = 1,2,...
nexttile, stem(nn, a, "filled", "Color",cmain), ylim([-3 6]), grid on
xlabel("\itn"), title("近似成分 \ita\rm[\itn\rm]")
nexttile, stem(nn, d, "filled", "Color",ccool), ylim([-3 6]), grid on
xlabel("\itn"), title("詳細成分 \itd\rm[\itn\rm]")
nexttile, stem(nn, xr, "filled", "Color",cwarm), hold on
plot(nn, x(1:end-1), "o", "Color",cgray, "MarkerSize",10, "LineWidth",1.2), hold off
ylim([-3 6]), grid on
xlabel("\itn"), title("\ita\rm[\itn\rm]+\itd\rm[\itn\rm]（○：\itx\rm[\itn\rm-1]）")
set(gcf,"Units","centimeters","Position",[2 2 figw 4.5])
drawnow   % 大きさの変更を反映させてから書き出す
exportgraphics(gcf, fullfile(resfolder,"vie-01-haar.png"), "Resolution",200)
%%
%[text] ## フィルタバンク表現
%[text] 上の操作はフィルタで書ける。遅延器 $ z^{-1} $ を使うと，近似成分と詳細成分を作るフィルタの伝達関数は
%[text]{"align":"center"} $ H\_0(z) = \\frac{1}{2}\\left(1+z^{-1}\\right),\\qquad H\_1(z) = \\frac{1}{2}\\left(-1+z^{-1}\\right) $
%[text] 両者を足すと $ T(z) = H\_0(z)+H\_1(z) = z^{-1} $，すなわち**全体は単なる遅延**になる。インパルス応答（係数列）で確かめる。
h0 = [1  1]/2;     % H0(z) の係数（z^0, z^-1 の順）
h1 = [-1 1]/2;     % H1(z) の係数
t  = h0 + h1       % T(z) の係数：[0 1] は z^{-1}
%[text] 実際に信号を通すと，出力は入力を 1 標本遅らせたものになる。
y  = conv(x, h0) + conv(x, h1)
%%
%[text] ## 画像変換の効果：3 レベルウェーブレット変換
%[text] 画像にも同じ考え方（近似と詳細への分解）を縦横に繰り返し適用できる。ここではハールウェーブレットで 3 レベル分解する。
%[text] 画像は参考資料のサンプル画像 msipimg08（スイカ）を 256×256 のグレースケールにしたものを使う。縞模様の輪郭にだけ大きな係数が残り，それ以外はほぼ零になる様子がよく見える（石像の顔 msipimg05 などと比べて選んだ）。
Xd = im2double(vie.msipimg(8, 256, "gray"));
[C,S] = wavedec2(Xd, 3, "haar");
%[text] 変換前の画素値は 0 から 1 まで広く分布する**デンス（密）**な表現だが，変換後の係数は**ほとんどが零に近い**。
thr  = 0.05;                                   % 「ほぼ零」とみなすしきい値
pz   = mean(abs(C) < thr)*100                  % ほぼ零の係数の割合 [%]
px   = mean(Xd(:) < thr)*100                   % 比較：画素値が thr 未満の割合 [%]
vie.savetex("vie-01-dwt-zero",  sprintf("%.1f", pz));
vie.savetex("vie-01-dwt-thr",   sprintf("%.2f", thr));
vie.savetex("vie-01-dwt-pixel", sprintf("%.1f", px));
%[text] 係数を画像として並べる。左上に小さく残るのが近似成分，残りが各レベル・各方向の詳細成分である。
coef = zeros(size(Xd));
A3 = appcoef2(C,S,"haar",3); n3 = size(A3,1);
coef(1:n3,1:n3) = A3/max(A3(:));
for lv = 3:-1:1
    [H,V,D] = detcoef2("all",C,S,lv); m = size(H,1);
    coef(1:m, m+1:2*m)     = abs(H)*2;   % 詳細成分は見やすいよう 2 倍して表示
    coef(m+1:2*m, 1:m)     = abs(V)*2;
    coef(m+1:2*m, m+1:2*m) = abs(D)*2;
end
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Xd), title("変換前（デンス）")
nexttile, imshow(min(coef,1)), title("変換後（ほとんど零）")
%[text] スライドでは両者を矢印（分析・合成）でつないで示すので，画像は別々に書き出す。
imwrite(Xd,          fullfile(resfolder,"vie-01-dwt-a.png"))
imwrite(min(coef,1), fullfile(resfolder,"vie-01-dwt-b.png"))
%%
%[text] ## データ量：静止画像
%[text] 教科書の例「静止画像のデータ量」（1.1.2 項）。 $ N\_1\\times N\_2 $ 画素，一配列要素あたり $ \\beta $ ビットのグレースケール画像の総ビット数は $ B = \\beta N\_1 N\_2 $。RGB カラー画像なら一画素あたり $ 3\\beta $ [bpp] なので $ B = 3\\beta N\_1 N\_2 $。
N1 = 2304; N2 = 3456;               % 画素数
Npix = N1*N2                         % 総画素数（約 800 万画素）
bt = 8;                            % 8-bit 符号なし整数型
Bgray = bt*N1*N2                   % グレースケール画像 [bits]
bt = 64;                           % 倍精度実数型
Brgb  = 3*bt*N1*N2                 % RGB カラー画像 [bits]
ratio = Brgb/Bgray                   % 後者は前者の何倍か
%[text] 教科書の値（63700992 bits ≃ 8 MB，1528823808 bits ≃ 191 MB，24 倍）と一致することを確かめる。Mega は $ 10^6 $，1 byte は 8 bits とする。
isequal([Bgray Brgb ratio], [63700992 1528823808 24])
[round(Bgray/8/1e6) round(Brgb/8/1e6)]   % [MB]
vie.savetex("vie-01-still-npix",  sprintf("%d", round(Npix/1e6)*100));   % 「約 800 万画素」の 800
vie.savetex("vie-01-still-gray",  vie.fmtint(Bgray));
vie.savetex("vie-01-still-grayMB",sprintf("%.0f", Bgray/8/1e6));
vie.savetex("vie-01-still-rgb",   vie.fmtint(Brgb));
vie.savetex("vie-01-still-rgbMB", sprintf("%.0f", Brgb/8/1e6));
vie.savetex("vie-01-still-ratio", sprintf("%d", ratio));
%[text] 実際の画像データでも確かめる。講義のデモ `dataamount` と同じく，画像を読み込んで `whos` でバイト数を見る。参考資料のサンプル画像 msipimg02（花束，512×512）は 8-bit の RGB カラー画像で，倍精度実数型に変換すると 8 倍のバイト数になる。
P  = vie.msipimg(2);                 % uint8 の RGB カラー画像（512×512×3）
Pd = im2double(P);                   % 倍精度実数型に変換
szp = size(P)
whosP  = whos("P");  whosPd = whos("Pd");
[whosP.bytes  8*3*szp(1)*szp(2)/8]   % β = 8：whos のバイト数と 3βN1N2/8
[whosPd.bytes 64*3*szp(1)*szp(2)/8]  % β = 64
%%
%[text] ## 1 秒あたりのビット数（ビットレート）
%[text] 動画像では **画素数 × 画面数/秒 × ビット数/画素** がビットレート $ R $ [bps] になる。教科書の式 $ R = \\beta|\\Omega\_\\mathrm{S}||\\Omega\_\\mathrm{C}|\\Delta\_\\mathrm{t}^{-1} $ で，RGB 各 8 bit なら一画素 24 bit である。まず前回スライドの HDTV と SDTV（いずれも 30 フレーム/秒）を計算する。
Rhd = 1920*1080*30*24                % ハイビジョン品質（HDTV）[bps]
Rsd = 720*480*30*24                  % アナログ放送品質（SDTV）[bps]
vie.savetex("vie-01-rate-hd",   sprintf("%.1f", Rhd/1e9));
vie.savetex("vie-01-rate-sd",   sprintf("%.1f", Rsd/1e6));
%[text] ### 教科書の例題「動画像のビットレート」
%[text] 画素数 $ N\_1\\times N\_2 = 4320\\times 7680 $（8K），フレーム間隔 $ \\Delta\_\\mathrm{t} = 1/60 $ s，一配列要素あたり $ \\beta = 8 $ bits の RGB カラー動画像のビットレートを求める。フレームレートは $ \\Delta\_\\mathrm{t}^{-1} = 60 $ [1/s] である（ $ 1/60 $ は二進の浮動小数点数で割り切れないので，逆数のまま掛ける）。
N1 = 4320; N2 = 7680;                % 画素数
bt = 8;                            % 一配列要素あたりのビット数
fps  = 60;                           % フレームレート 1/Δt [1/s]
bpp8k = 3*bt                       % 一画素あたりのビット数 [bpp]
N8k   = N1*N2                        % 1 フレームあたりの画素数（約 3300 万画素）
B8k   = 3*bt*N1*N2                 % 1 フレームあたりのビット数 [bits/frame]
R8k   = B8k*fps                      % ビットレート R = B Δt^{-1} [bps]
%[text] 教科書の解答（24 bpp，33177600 画素，796262400 bits/frame，47775744000 bps ≃ 48 Gbps）と一致することを確かめる。
isequal([bpp8k N8k B8k R8k], [24 33177600 796262400 47775744000])
%[text] 教科書のサンプル（MsipWorkM の例題 1.1）と同じく，実際に 1 フレーム分の配列を作って要素数から数えても同じになる。
frame = zeros(N1,N2,3,"uint8");      % 8K の RGB カラー 1 フレーム（約 100 MB）
isequal(bt*numel(frame), B8k)
clear frame
vie.savetex("vie-01-rate-8kbpp", sprintf("%d", bpp8k));
vie.savetex("vie-01-rate-8kB",   vie.fmtint(B8k));
vie.savetex("vie-01-rate-8kfps", sprintf("%d", fps));
vie.savetex("vie-01-rate-8k",    vie.fmtint(R8k));
vie.savetex("vie-01-rate-8kG",   sprintf("%.0f", R8k/1e9));
%[text] ### 地上デジタル放送との比較
%[text] 地上デジタル放送では HDTV を約 14 Mbps，SDTV を約 4 Mbps で送る（前回スライドの値）。圧縮前と比べると次のとおり。
Rdtv = [14e6 4e6];
cr   = [Rhd Rsd]./Rdtv               % 何分の一に圧縮しているか
vie.savetex("vie-01-dtv-hd", sprintf("%.0f", Rdtv(1)/1e6));
vie.savetex("vie-01-dtv-sd", sprintf("%.0f", Rdtv(2)/1e6));
vie.savetex("vie-01-cr-hd", sprintf("%.0f", cr(1)));
vie.savetex("vie-01-cr-sd", sprintf("%.0f", cr(2)));
%[text] 圧縮前を青，地デジを緑の横棒で比べる。棒の右端に値を添える。
figure   % 新しい図に描く
barlabels = ["SDTV 地デジ","SDTV 圧縮前","HDTV 地デジ","HDTV 圧縮前"];
vals   = [Rdtv(2) Rsd Rdtv(1) Rhd]/1e6;  % [Mbps]
hb = barh(1:4, vals, 0.6, "FaceColor","flat", "EdgeColor","none");
hb.CData = [cmain; ccool; cmain; ccool];
text(vals+30, 1:4, compose("%.0f Mbps", vals), "FontSize",12, "VerticalAlignment","middle")
yticks(1:4), yticklabels(barlabels), ylim([0.4 4.6])
xlim([0 2100]), xlabel("ビットレート [Mbps]"), grid on
set(gca,"FontSize",12)
set(gcf,"Units","centimeters","Position",[2 2 12 4.2])
drawnow   % 大きさの変更を反映させてから書き出す
exportgraphics(gcf, fullfile(resfolder,"vie-01-bitrate.png"), "Resolution",200)
%%
%[text] ## まとめ
%[text] - 音声は一変量の関数，画像は多変量の関数。標本化すると数列・配列になる
%[text] - 足し算と引き算だけで，信号を近似成分と詳細成分に分解・合成できる
%[text] - 画像を変換すると，係数のほとんどが零に近くなる（スパースな表現）
%[text] - データ量は $ B=\\beta N\_1N\_2 $（RGB なら $ 3\\beta N\_1N\_2 $），ビットレートは $ R=B\\Delta\_\\mathrm{t}^{-1} $
%[text] - 非圧縮の映像は Gbps 級。放送では 1/100 程度に圧縮している \
%%
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
