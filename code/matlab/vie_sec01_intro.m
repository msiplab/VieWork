%[text] # 第1回 導入と全体概要
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第1回のスライド（vie2026-01）で使う図と数値をすべてこのスクリプトで作る。スライドに書ききれない計算の途中経過も，ここで丁寧に追いかける。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
%[text] 図と LaTeX 断片は `results` フォルダに書き出す。VieSlides 側では `tools/sync-results.ps1` でそれらを取り込む。
[datfolder,resfolder] = vie.prjfolders();
figw = 16; figh = 6;   % 書き出す図の大きさ [cm]（スライドの横幅に合わせる）
%%
%[text] ## 音声信号：一変量の関数とその標本化
%[text] 音叉の音のように，音声信号（モノラル）は時刻 $ t $ の**一変量の関数** $ x(t) $ とみなせる。ここでは 1 秒間に 440 回振動する音（ラの音）を，少しずつ減衰する正弦波で模擬する。
%[text]{"align":"center"} $ x(t) = \\mathrm{e}^{-t/\\tau}\\sin(2\\pi f\_0 t),\\quad f\_0 = 440\\ \\mathrm{Hz} $
%[text] これを標本化周波数 $ f\_\\mathrm{s} $ で標本化すると，**数列（サンプル列）** $ x[n] = x(n/f\_\\mathrm{s}) $ が得られる。
f0  = 440;          % 音の高さ [Hz]
tau = 0.4;          % 減衰の時定数 [s]
fs  = 8000;         % 標本化周波数 [Hz]
n   = 0:fs-1;       % 1 秒分の標本番号
xn  = exp(-n/fs/tau).*sin(2*pi*f0*n/fs);
%[text] 冒頭の 5 ms だけを拡大すると，連続な波形 $ x(t) $ の上に標本 $ x[n] $ が等間隔に並んでいるのが分かる。下段は周波数成分の時間変化（スペクトログラム）で，440 Hz に成分が集中している。「どのような成分から構成されているか」を調べるのがフーリエ解析（第7回）である。
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile
tc = linspace(0,5e-3,500);
plot(tc*1e3, exp(-tc/tau).*sin(2*pi*f0*tc), "Color",[.6 .6 .6]), hold on
ns = 0:round(5e-3*fs);
stem(ns/fs*1e3, xn(ns+1), "filled", "MarkerSize",3), hold off
xlabel("時刻 [ms]"), ylabel("振幅"), title("x(t) と標本 x[n]")
grid on
nexttile
spectrogram(xn, hann(256), 192, 512, fs, "yaxis")
ylim([0 2]), title("スペクトログラム"), colorbar off
set(gcf,"Units","centimeters","Position",[2 2 figw figh])
exportgraphics(gcf, fullfile(resfolder,"vie-01-audio.png"), "Resolution",200)
%%
%[text] ## 画像信号：多変量の関数とその標本化
%[text] 画像信号（モノクロ）は位置 $ (q\_\\mathrm{v},q\_\\mathrm{h}) $ の**多変量の関数** $ u(q\_\\mathrm{v},q\_\\mathrm{h}) $ とみなせる。標本化すると**配列（画素配列）** $ x[n\_\\mathrm{v},n\_\\mathrm{h}] $ が得られる。
X = imread("cameraman.tif");      % Image Processing Toolbox 付属の 256×256, 8 bit 画像
sz = size(X)
%[text] 画像の一部（顔のあたり）を切り出して数値を見る。画像は数の並びにすぎない。
r0 = 60; c0 = 110; w = 5;         % 切り出す位置と大きさ
blk = X(r0:r0+w-1, c0:c0+w-1)
vie.savetex("vie-01-pixels", "\begin{bmatrix}" + vie.arr2tex(double(blk),"%d") + "\end{bmatrix}");
vie.savetex("vie-01-pixels-pos", sprintf("n_\\mathrm{v}=%d\\sim%d,\\ n_\\mathrm{h}=%d\\sim%d", r0-1, r0+w-2, c0-1, c0+w-2));
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile
imshow(X), hold on
rectangle("Position",[c0-0.5 r0-0.5 w w],"EdgeColor","r","LineWidth",1.5), hold off
title("256×256 画素")
nexttile
imshow(imresize(blk, 40, "nearest"))
for i = 1:w
    for j = 1:w
        text((j-0.5)*40, (i-0.5)*40, string(blk(i,j)), ...
            "HorizontalAlignment","center", "Color","r", "FontSize",9)
    end
end
title("赤枠内の画素値")
%[text] スライド用には，赤枠を画像に焼き込んだものを書き出す（画素値はスライド側で行列として示す）。
Xbox = repmat(X,[1 1 3]);
boxmask = false(size(X));
boxmask(r0-1:r0+w, [c0-1 c0+w]) = true;
boxmask([r0-1 r0+w], c0-1:c0+w) = true;
Xbox(repmat(boxmask,[1 1 3])) = 0;
Xbox(:,:,1) = Xbox(:,:,1) + uint8(boxmask)*255;
imwrite(imresize(Xbox,2,"nearest"), fullfile(resfolder,"vie-01-image.png"))
%%
%[text] ## 信号の解析（一次元）：近似成分と詳細成分
%[text] 前回スライドの例を計算する。信号 $ x[n] $ に対し，**隣同士を足して 2 で割る**と近似成分 $ a[n] $，**右隣を引いて 2 で割る**と詳細成分 $ d[n] $ が得られる。
%[text]{"align":"center"} $ a[n] = \\frac{1}{2}\\left(x[n]+x[n+1]\\right),\\qquad d[n] = \\frac{1}{2}\\left(x[n]-x[n+1]\\right) $
x = [3 1 3 1 5 3 5];
a = (x(1:end-1) + x(2:end))/2      % 近似成分
d = (x(1:end-1) - x(2:end))/2      % 詳細成分
%[text] 近似成分はゆっくり変わる成分（低周波成分），詳細成分は細かく変わる成分（高周波成分）を担う。
vie.savetex("vie-01-haar-x",   vie.arr2tex(x(1:end-1)));
vie.savetex("vie-01-haar-sum", vie.arr2tex(x(1:end-1)+x(2:end)));
vie.savetex("vie-01-haar-dif", vie.arr2tex(x(1:end-1)-x(2:end)));
vie.savetex("vie-01-haar-a",   vie.arr2tex(a));
vie.savetex("vie-01-haar-d",   vie.arr2tex(d));
%%
%[text] ## 信号の合成：足し合わせると元に戻る
%[text] 定義から $ a[n]+d[n] = x[n] $ が成り立つ。足し算と引き算だけの分解だが，**信号の情報を逃さない**立派な成分分析法である。
xr = a + d
isequal(xr, x(1:end-1))
vie.savetex("vie-01-haar-rec", vie.arr2tex(xr));
tiledlayout(1,3,"TileSpacing","compact","Padding","compact")
nexttile, stem(0:numel(a)-1, a, "filled"), ylim([-3 6]), grid on, title("近似成分 a[n]")
nexttile, stem(0:numel(d)-1, d, "filled"), ylim([-3 6]), grid on, title("詳細成分 d[n]")
nexttile, stem(0:numel(xr)-1, xr, "filled"), ylim([-3 6]), grid on, title("a[n]+d[n]")
set(gcf,"Units","centimeters","Position",[2 2 figw 4.5])
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
Xd = im2double(X);
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
%[text] 教科書の例（静止画像のデータ量）。 $ N\_1\\times N\_2 $ 画素，一配列要素あたり $ \\beta $ ビットのグレースケール画像の総ビット数は $ B = \\beta N\_1 N\_2 $。RGB カラー画像なら $ B = 3\\beta N\_1 N\_2 $。
N1 = 2304; N2 = 3456;               % 約 800 万画素
Bgray = 8*N1*N2                      % 8 bit グレースケール [bits]
Brgb  = 3*64*N1*N2                   % 倍精度実数の RGB [bits]
ratio = Brgb/Bgray
vie.savetex("vie-01-still-gray",  fmtint(Bgray));
vie.savetex("vie-01-still-grayMB",sprintf("%.0f", Bgray/8/1e6));
vie.savetex("vie-01-still-rgb",   fmtint(Brgb));
vie.savetex("vie-01-still-rgbMB", sprintf("%.0f", Brgb/8/1e6));
vie.savetex("vie-01-still-ratio", sprintf("%d", ratio));
%%
%[text] ## 1 秒あたりのビット数（ビットレート）
%[text] 動画像では **画素数 × 画面数/秒 × ビット数/画素** がビットレート $ R $ [bps] になる。教科書の式 $ R = \\beta|\\Omega\_\\mathrm{S}||\\Omega\_\\mathrm{C}|\\Delta\_\\mathrm{t}^{-1} $ で，RGB 各 8 bit なら一画素 24 bit である。
Rhd = 1920*1080*30*24                % ハイビジョン品質（HDTV）[bps]
Rsd = 720*480*30*24                  % アナログ放送品質（SDTV）[bps]
R8k = 7680*4320*60*24                % 教科書の例題：8K 60p [bps]
vie.savetex("vie-01-rate-hd",   sprintf("%.1f", Rhd/1e9));
vie.savetex("vie-01-rate-sd",   sprintf("%.1f", Rsd/1e6));
vie.savetex("vie-01-rate-8k",   fmtint(R8k));
vie.savetex("vie-01-rate-8kG",  sprintf("%.0f", R8k/1e9));
%[text] 地上デジタル放送では HDTV を約 14 Mbps，SDTV を約 4 Mbps で送る（前回スライドの値）。圧縮前と比べると次のとおり。
Rdtv = [14e6 4e6];
cr   = [Rhd Rsd]./Rdtv               % 何分の一に圧縮しているか
vie.savetex("vie-01-cr-hd", sprintf("%.0f", cr(1)));
vie.savetex("vie-01-cr-sd", sprintf("%.0f", cr(2)));
clf   % 直前の tiledlayout を消してから描く
barh(categorical(["SDTV 地デジ","SDTV 圧縮前","HDTV 地デジ","HDTV 圧縮前"], ...
     ["SDTV 地デジ","SDTV 圧縮前","HDTV 地デジ","HDTV 圧縮前"]), ...
     [Rdtv(2) Rsd Rdtv(1) Rhd]/1e6)
xlabel("ビットレート [Mbps]"), grid on
set(gca,"FontSize",13)
set(gcf,"Units","centimeters","Position",[2 2 figw 5])
exportgraphics(gcf, fullfile(resfolder,"vie-01-bitrate.png"), "Resolution",200)
%%
%[text] ## まとめ
%[text] - 音声は一変量の関数，画像は多変量の関数。標本化すると数列・配列になる
%[text] - 足し算と引き算だけで，信号を近似成分と詳細成分に分解・合成できる
%[text] - 画像を変換すると，係数のほとんどが零に近くなる（スパースな表現）
%[text] - 非圧縮の映像は Gbps 級。放送では 1/100 程度に圧縮している \
%%
%[text] ## 【関数定義】
function s = fmtint(v)
% 整数を 3 桁ごとにカンマで区切った文字列にする（LaTeX 用）
s = string(sprintf("%d", round(v)));
s = regexprep(s, "(\d)(?=(\d{3})+$)", "$1{,}");
end
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
