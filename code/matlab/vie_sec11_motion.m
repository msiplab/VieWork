%[text] # 第11回 動き検出処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第11回のスライド（vie2026-11）で使う図と数値を作る。エッジ画像のスペクトル，大域的定速移動モデルのスペクトル（速度に応じて傾く），ブロックマッチング法（差分絶対値和 SAD）による動き推定，位相限定相関（POC）を扱う。
%[text] 教科書には動き推定の章がないため，記号は相互相関（4.2.3 項）や距離（1.2.1 項）に合わせる。連続変数の角周波数を $ \\boldsymbol{\\nu} $ ，時間方向の角周波数を $ \\nu\_\\mathrm{t} $ とする。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[~,resfolder] = vie.prjfolders();
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
%[text] 一次元の静止信号 $ x\_0(q) $ が速度 $ v $ で動く： $ x(q,t)=x\_0(q-vt) $ 。水平位置 $ n $ と時刻 $ t $ の配列を作り，二次元 DFT の振幅スペクトルを見る。スペクトルは直線 $ \\nu\_\\mathrm{t}=-v\\,\\nu $ 上に集中し，速いほど傾きが大きい。
x0 = exp(-((0:N-1) - N/2).^2/(2*3^2));     % ガウス形の塊
k = [0:N/2-1, -N/2:-1];                     % DFT の周波数番号
vs = [0 0.5 1];
tiledlayout(2,3,"TileSpacing","compact","Padding","compact")
for i = 1:numel(vs)
    v = vs(i);
    Xt = zeros(N);                           % 行：時刻 t，列：位置 n
    for t = 0:N-1                            % 周波数領域でずらす（非整数の速度も扱える）
        Xt(t+1,:) = real(ifft(fft(x0).*exp(-1j*2*pi*k*v*t/N)));
    end
    nexttile(i), imshow(Xt), title(sprintf("v=%g", v))
    Sp = log(1 + abs(fftshift(fft2(Xt))));
    nexttile(i+3), imshow(Sp, []), title("振幅スペクトル")
    imwrite(Xt, fullfile(resfolder,sprintf("vie-11-xt-v%02d.png", round(10*v))))
    imwrite(Sp/max(Sp(:)), fullfile(resfolder,sprintf("vie-11-spec-v%02d.png", round(10*v))))
end
%%
%[text] ## ブロックマッチング：前回スライドの例題
%[text] $ 2\\times2 $ の対象ブロックに最も近いブロックを，差分絶対値和（SAD）で $ d\_0,d\_1\\in\\{-1,0,1\\} $ の範囲から全探索する（ $ d\_0 $ ：水平， $ d\_1 $ ：垂直）。
B = [1 1; 1 1];                              % 対象ブロック
W = [0 0 0 0; 2 2 1 1; 2 2 1 1; 0 0 0 0];    % 探索窓（ブロックの位置 (0,0) は W(2:3,2:3)）
d = -1:1;
SAD = zeros(3);                               % 行：d1，列：d0
for i1 = 1:3, for i0 = 1:3
    C = W(2+d(i1):3+d(i1), 2+d(i0):3+d(i0));
    SAD(i1,i0) = sum(abs(C - B), "all");
end, end
SAD
[~, idx] = min(SAD(:)); [i1, i0] = ind2sub([3 3], idx);
dhat = [d(i0) d(i1)]                         % 推定した動きベクトル (d0, d1)
SSD = zeros(3);
for i1 = 1:3, for i0 = 1:3
    C = W(2+d(i1):3+d(i1), 2+d(i0):3+d(i0));
    SSD(i1,i0) = sum((C - B).^2, "all");
end, end
SSD
vie.savetex("vie-11-sad", vie.arr2tex(SAD,"%d"));
vie.savetex("vie-11-ssd", vie.arr2tex(SSD,"%d"));
vie.savetex("vie-11-dhat", sprintf("(%d,\\ %d)", dhat));
%%
%[text] ## 動き推定の例（ブロックサイズ 16×16）
%[text] 静止した背景の上を，模様のある正方形と明るい円が速度 $ (d\_0,d\_1)=(2,2) $ で動く 2 フレームを作り，全探索（ $ \\pm7 $ 画素）のブロックマッチングで動きベクトル場を求める。
rng(0)
M = 256;
bg = imgaussfilt(rand(M), 2); bg = 0.3 + 0.4*mat2gray(bg);   % 背景（静止）
tex = mat2gray(imgaussfilt(rand(40), 1));                    % 正方形の模様
[X1, Y1] = meshgrid(1:M);
frame = @(s) insertobj(bg, tex, 60+s, 110+s, X1, Y1, 170+s, 110+s);
F0 = frame(0); F1 = frame(2);                % 1 フレームで (2,2) 移動
imwrite(F1, fullfile(resfolder,"vie-11-bm-frame.png"))
bs = 16; R = 7;
[U, V] = deal(zeros(M/bs));
for bi = 1:M/bs, for bj = 1:M/bs
    r0 = (bi-1)*bs + 1; c0 = (bj-1)*bs + 1;
    blk = F1(r0:r0+bs-1, c0:c0+bs-1);        % 現フレームのブロック
    best = inf;
    for dy = -R:R, for dx = -R:R              % 参照フレーム（前フレーム）内を全探索
        rr2 = r0 - dy; cc2 = c0 - dx;
        if rr2 < 1 || cc2 < 1 || rr2+bs-1 > M || cc2+bs-1 > M, continue, end
        sad = sum(abs(blk - F0(rr2:rr2+bs-1, cc2:cc2+bs-1)), "all");
        if sad < best - 1e-9, best = sad; U(bi,bj) = dx; V(bi,bj) = dy; end
    end, end
end, end
clf
imshow(ones(M)), hold on                    % 白地に動きベクトル場を描く
[gx, gy] = meshgrid((0:M/bs-1)*bs + bs/2);
quiver(gx, gy, 4*U, 4*V, 0, "b", "LineWidth", 2, "MaxHeadSize", 1.5)
plot(gx(:), gy(:), "b.", "MarkerSize", 6), hold off
exportgraphics(gca, fullfile(resfolder,"vie-11-bm-field.png"), "Resolution", 110)
moving = [U(V~=0 | U~=0) V(V~=0 | U~=0)];
mode_vec = mode(moving, 1)                   % 動いた領域で最も多いベクトル
vie.savetex("vie-11-bm-vec", sprintf("(%d,\\ %d)", mode_vec));
%%
%[text] ## 位相限定相関（POC）
%[text] cameraman.tif を $ (5,-3) $ 画素（水平，垂直）ずらした画像との POC を計算すると，ずれの位置に鋭いピークが立つ。
Xc = im2double(imread("cameraman.tif"));
Xs = circshift(Xc, [-3 5]) + 0.01*randn(size(Xc));   % 垂直 -3，水平 +5
Rc = conj(fft2(Xc)).*fft2(Xs);
P = real(ifft2(Rc./max(abs(Rc), eps)));
[~, ip] = max(P(:)); [pr, pc] = ind2sub(size(P), ip);
shift = [mod(pc-1+128, 256)-128, mod(pr-1+128, 256)-128]   % (水平, 垂直)
peak = max(P(:))
Pd = fftshift(P);
clf
mesh(-128:127, -128:127, Pd), axis tight, view(-30, 40)
xlabel("水平ラグ"), ylabel("垂直ラグ"), zlabel("POC"), set(gca, "FontSize", 12)
exportgraphics(gca, fullfile(resfolder,"vie-11-poc.png"), "Resolution", 110)
vie.savetex("vie-11-poc-shift", sprintf("(%d,\\ %d)", shift));
vie.savetex("vie-11-poc-peak", sprintf("%.2f", peak));
%%
%[text] ## まとめ
%[text] - 動いている映像のスペクトルは速度に応じて傾いた平面に集中する（大域的定速移動モデル）
%[text] - 動き推定には，ブロックマッチング法（SAD や SSD の最小化）や位相限定相関が使われる
%[text] - 見かけ上の動きには，空間勾配の欠落，光源変化，アパーチャ問題，オクルージョンなどの本質的な問題がある \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.
function F = insertobj(bg, tex, r0, c0, X, Y, rb, cb)
% 背景 bg に模様 tex の正方形（左上 (r0,c0)）と明るい円（中心 (rb,cb)）を重ねる
F = bg;
[h, w] = size(tex);
F(r0:r0+h-1, c0:c0+w-1) = tex;
F((X - cb).^2 + (Y - rb).^2 <= 12^2) = 1;
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
