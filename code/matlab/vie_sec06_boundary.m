%[text] # 第6回 境界処理
%[text] 村松正吾　「画像情報工学」
%[text] 動作確認： MATLAB R2026b
%[text] 第6回のスライド（vie2026-06）で使う図と数値を作る。畳み込みと相互相関，FIR/IIR システム，可分離システム，有限長信号の畳み込みと境界処理（零値・周期・複製・対称拡張），内積・ノルムと線形フィルタ，列ベクトル化と行列表現を扱う。
%[text:tableOfContents]{"heading":"目次"}
%%
%[text] ## 準備
[datfolder,resfolder] = vie.prjfolders();
vie.download_img(false)
%%
%[text] ## 二次元畳み込みの計算例
%[text] 前回スライドの例。入力 $ 3\\times3 $ ，インパルス応答 $ 3\\times3 $ （中心が原点）。畳み込み
%[text]{"align":"center"} $ y[\\boldsymbol{n}]=\\sum\_{\\boldsymbol{k}}x[\\boldsymbol{k}]h[\\boldsymbol{n}-\\boldsymbol{k}] $
%[text] の出力は $ 5\\times5 $ に広がる。
X2 = [1 2 3; 4 5 6; 7 8 9];
H2 = [1 0 -1; 1 0 -1; 1 0 -1];
Y2 = conv2(X2, H2)                                 % full：出力は 5×5
vie.savetex("vie-06-conv2-x", vie.arr2tex(X2,"%d"));
vie.savetex("vie-06-conv2-h", vie.arr2tex(H2,"%d"));
vie.savetex("vie-06-conv2-y", vie.arr2tex(Y2,"%d"));
%[text] 反転したインパルス応答 $ w[\\boldsymbol{n}]=h[-\\boldsymbol{n}] $ との相互相関としても同じ結果になる（ `filter2` は相関を計算する）。
W2 = rot90(H2, 2)                                   % 各軸を反転
isequal(filter2(W2, X2, "full"), Y2)
vie.savetex("vie-06-conv2-w", vie.arr2tex(W2,"%d"));
%[text] 出力の中央 $ y[1,1] $ （0 始まりで 2 行 2 列）は，反転カーネルを重ねた積和：
yc = sum(W2 .* X2, "all")
%%
%[text] ## FIR システムと IIR システム
%[text] インパルス応答のサポート領域（非零係数の存在する領域）が有限なら FIR，無限なら IIR。IIR の例として理想低域通過フィルタ（sinc 関数の積）を， FIR の例として $ 7\\times7 $ のガウシアンを，同じ範囲に描く。
[n0,n1] = meshgrid(-15:15);
hIIR = sinc(n0/3).*sinc(n1/3)/9;                   % 無限に広がる（ここでは一部だけ表示）
hFIR = zeros(size(n0));
g = fspecial("gaussian", 7, 1.2);
hFIR(13:19,13:19) = g;                              % 中央 7×7 以外は零
tiledlayout(1,2,"TileSpacing","compact","Padding","compact")
nexttile, mesh(n0,n1,hIIR), title("IIR（サポート領域が無限）"), axis tight, view(-30,35)
xlabel("n_0"), ylabel("n_1")
nexttile, mesh(n0,n1,hFIR), title("FIR（サポート領域が有限）"), axis tight, view(-30,35)
xlabel("n_0"), ylabel("n_1")
exportgraphics(gcf, fullfile(resfolder,"vie-06-firiir.png"), "Resolution", 120)
%%
%[text] ## 可分離システム
%[text] $ 3\\times3 $ 平均フィルタは $ h[n\_0,n\_1]=h\_0[n\_0]h\_1[n\_1] $ ， $ h\_0=h\_1=\\frac13(1,1,1) $ と分離できる。二次元畳み込みを一次元畳み込み 2 回で計算しても同じ結果になる。
h1 = ones(3,1)/3;
Hsep = h1*h1'                                       % 1/9 が並ぶ
Xr = magic(6);
Ya = conv2(Xr, Hsep);                               % 二次元畳み込み
Yb = conv2(conv2(Xr, h1), h1');                     % 縦→横の一次元畳み込み
maxdiff = max(abs(Ya - Yb), [], "all")              % 丸め誤差程度
%[text] $ K\\times K $ カーネルの一画素当たりの乗算回数は，そのままだと $ K^2 $ ，分離すると $ 2K $ 。
K = [3 5 9 17];
mults = [K.^2; 2*K]
vie.savetex("vie-06-sep-K",  strjoin(string(K)," & "));
vie.savetex("vie-06-sep-K2", strjoin(string(K.^2)," & "));
vie.savetex("vie-06-sep-2K", strjoin(string(2*K)," & "));
%%
%[text] ## 有限長信号の畳み込み
%[text] 前回スライドの例。 $ x[n]=(1,2,4,2) $ （ $ n=0,1,2,3 $ ）， $ h[n]=(\\frac14,\\frac12,\\frac14) $ （ $ n=-1,0,1 $ ，非因果的）。出力は $ n=-1,\\dots,4 $ の 6 点に増える。
x1 = [1 2 4 2];
h1d = [1/4 1/2 1/4];
y1 = conv(x1, h1d)                                  % n = -1,0,1,2,3,4
vie.savetex("vie-06-fin-y", strjoin(compose("%g",y1),",\ "));
%%
%[text] ## 一次元の境界処理
%[text] $ x[n]=(1,2,4,2) $ を両側 2 点ずつ拡張する。周期拡張は `circular` ，複製拡張は `replicate` ，対称拡張（標本間対称 HS）は `symmetric` 。標本上対称（WS）は添え字を折り返して作る。
padZ = padarray(x1, [0 2], 0);
padP = padarray(x1, [0 2], "circular");
padR = padarray(x1, [0 2], "replicate");
padH = padarray(x1, [0 2], "symmetric");            % HS：画素の間で折り返す
padW = x1([3 2 1 2 3 4 3 2]);                       % WS：端の画素上で折り返す
pads = [padZ; padP; padR; padH; padW]
names = ["零値拡張","周期拡張","複製拡張","対称拡張（HS）","対称拡張（WS）"];
for k = 1:5
    vie.savetex("vie-06-pad"+k, strjoin(string(pads(k,:))," & "));
end
%%
%[text] ## 例題：対称拡張（WS）による有限長信号のフィルタリング
%[text] WS で拡張してから畳み込み，元の 4 点だけを取り出す（棄却・クリッピング）。出力の長さは入力と同じ 4 点。
yW = conv(padW, h1d, "valid");                      % 拡張後 8 点 → valid で 6 点
yW = yW(2:5)                                        % n = 0,1,2,3
yZ = conv(x1, h1d, "same")                          % 零値拡張の場合（端が小さくなる）
vie.savetex("vie-06-ws-y", strjoin(compose("%g",yW),",\ "));
vie.savetex("vie-06-zp-y", strjoin(compose("%g",yZ),",\ "));
%%
%[text] ## 画像の境界処理の例
%[text] kodim04 の一部に $ 17\\times17 $ のガウシアン（ $ \\sigma\_\\mathrm{g}=4 $ ）を施す。拡張点数は 16 点（両側 8 点）。零値拡張では縁が黒く滲み，対称拡張では滲まない。
Xc = im2double(imread(fullfile(datfolder,"kodim04.png")));
Xc = imresize(Xc(1:512, :, :), 0.5);                % 上半分を縮小（256×256）
Xc = min(max(Xc,0),1);
fgau = fspecial("gaussian", 17, 4);
Ez = padarray(Xc, [8 8], 0);                        % 零値拡張画像
Es = padarray(Xc, [8 8], "symmetric");              % 対称拡張画像
Yz = imfilter(Xc, fgau, 0);                         % 零値拡張で処理
Ys = imfilter(Xc, fgau, "symmetric");               % 対称拡張で処理
tiledlayout(2,2,"TileSpacing","compact","Padding","compact")
nexttile, imshow(Ez), title("零値拡張画像")
nexttile, imshow(Yz), title("処理画像（零値拡張）")
nexttile, imshow(Es), title("対称拡張画像")
nexttile, imshow(Ys), title("処理画像（対称拡張）")
imwrite(Ez, fullfile(resfolder,"vie-06-pad-zero.png"))
imwrite(Es, fullfile(resfolder,"vie-06-pad-sym.png"))
imwrite(Yz, fullfile(resfolder,"vie-06-out-zero.png"))
imwrite(Ys, fullfile(resfolder,"vie-06-out-sym.png"))
imwrite(imresize(Yz(1:40,1:40,:), 3, "nearest"), fullfile(resfolder,"vie-06-out-zero-zoom.png"))
imwrite(imresize(Ys(1:40,1:40,:), 3, "nearest"), fullfile(resfolder,"vie-06-out-sym-zoom.png"))
%[text] 左上隅の画素の明るさ（R 成分）を比べると，零値拡張では暗くなる。
cornerv = [Xc(1,1,1) Yz(1,1,1) Ys(1,1,1)]
vie.savetex("vie-06-corner-org", sprintf("%.2f",cornerv(1)));
vie.savetex("vie-06-corner-z",   sprintf("%.2f",cornerv(2)));
vie.savetex("vie-06-corner-s",   sprintf("%.2f",cornerv(3)));
%%
%[text] ## 内積・ノルム・距離・コサイン類似度
%[text] 教科書の例。二つの配列の内積，ノルム，距離，コサイン類似度，二乗誤差和。
Xa = [7 5 3; 3 2 2]; Ya6 = [-4 9 6; 7 5 7];
ip   = sum(Xa .* Ya6, "all")
nx   = norm(Xa(:)), ny = norm(Ya6(:))
dist = norm(Xa(:) - Ya6(:))
cosv = ip/(nx*ny)
sse  = dist^2
l1   = norm(Xa(:), 1)                                % 1-ノルム（絶対値和）
vals = [ip nx ny dist cosv sse l1];
tags = ["ip","nx","ny","dist","cos","sse","l1"];
for k = 1:numel(tags)
    vie.savetex("vie-06-"+tags(k), sprintf("%g",vals(k)));
end
%%
%[text] ## 移動平均・移動差分は内積
%[text] $ \\mathbb{R}^2 $ で平均 $ \\mathbf{f}=\\frac12(1,1)^\\top $ ，差分 $ \\mathbf{f}=(1,-1)^\\top $ との内積をとる。
V = [1 1; 1 -1; 2 1]';                              % 列が v
avg2 = [1/2 1/2]*V
dif2 = [1 -1]*V
%[text] $ \\mathbb{R}^{2\\times2} $ の配列 $ \\mathsf{v} $ との内積（成分毎の積の和）で，平均・水平差分・垂直差分を抽出する。
Vv = [2 2; 1 1];
Favg = ones(2)/4; Fh = [-1 1; -1 1]; Fv = [-1 -1; 1 1];
ext = [sum(Favg.*Vv,"all") sum(Fh.*Vv,"all") sum(Fv.*Vv,"all")]
vie.savetex("vie-06-ext-avg", sprintf("%g",ext(1)));
vie.savetex("vie-06-ext-h",   sprintf("%g",ext(2)));
vie.savetex("vie-06-ext-v",   sprintf("%g",ext(3)));
%%
%[text] ## 画像フィルタ
%[text] 各画素の近傍 $ 3\\times3 $ 配列とマスクの内積を全画素で計算する。cameraman.tif に平均，4 近傍ラプラシアン，ソーベル（水平・垂直）を施す（表示は正規化）。
Cm = im2double(imread("cameraman.tif"));
masks = {ones(3)/9, [0 1 0; 1 -4 1; 0 1 0], [-1 0 1; -2 0 2; -1 0 1], [-1 -2 -1; 0 0 0; 1 2 1]};
mtag = ["avg","lap","sobh","sobv"];
tiledlayout(1,4,"TileSpacing","compact","Padding","compact")
for k = 1:4
    Yk = imfilter(Cm, masks{k}, "symmetric");
    if k > 1, Yk = 0.5 + Yk/(2*max(abs(Yk(:)))); end   % 負の値を含むので 0.5 を中心に表示
    nexttile, imshow(Yk)
    imwrite(Yk, fullfile(resfolder,"vie-06-cam-"+mtag(k)+".png"))
end
imwrite(Cm, fullfile(resfolder,"vie-06-cam.png"))
%%
%[text] ## 配列の列ベクトル化
%[text] 列の順（縦方向が先）に並べる。 $ 2\\times2 $ の例：
Xv = [0 2; 4 6]
xv = Xv(:)'
Xback = reshape(xv, 2, 2)                           % 配列化（逆写像）
vie.savetex("vie-06-vec-x", strjoin(string(xv),",\ "));
%[text] 4K 画像（ $ 2160\\times3840 $ 画素）は約 800 万次元のベクトル：
dim4k = 2160*3840
vie.savetex("vie-06-dim4k", vie.fmtint(dim4k));
%%
%[text] ## 対称畳み込みの行列表現
%[text] 前回スライドの例。 $ 2\\times3 $ 配列 $ \\mathsf{u} $ を WS 対称拡張（周期的にも延長）してから，インパルス応答 $ h[\\boldsymbol{k}] $ （ $ \\boldsymbol{k}\\in\\{0,1\\}^2 $ ， $ h[0,0]=h[1,0]=1,\\ h[0,1]=h[1,1]=-1 $ ）と畳み込む。
U = [0 2 4; 1 3 5];
Hk = [1 -1; 1 -1];                                  % 行が k0，列が k1
wsidx = @(n,N) N-1 - abs(mod(n, 2*(N-1)) - (N-1));  % WS 対称＋周期の添え字（0 始まり）
ut = @(n0,n1) U(wsidx(n0,2)+1, wsidx(n1,3)+1);      % 拡張された u
Vout = zeros(2,3);
for a = 0:1, for b = 0:2
    for k0 = 0:1, for k1 = 0:1
        Vout(a+1,b+1) = Vout(a+1,b+1) + Hk(k0+1,k1+1)*ut(a-k0, b-k1);
    end, end
end, end
Vout
Uext = arrayfun(@(i,j) ut(i,j), repmat((-1:2)',1,5), repmat(-1:3,4,1))   % 拡張の様子
%[text] このシステムは線形なので行列表現 $ \\mathbf{T} $ をもつ。 $ \\mathbf{T} $ の各列は，単位インパルス（標準基底）に対する出力を列ベクトル化したもの。
T = zeros(6);
for m = 1:6
    E = zeros(2,3); E(m) = 1;
    U0 = U; U = E;                                  % 一時的に入力を差し替える
    ut = @(n0,n1) U(wsidx(n0,2)+1, wsidx(n1,3)+1);
    Vm = zeros(2,3);
    for a = 0:1, for b = 0:2
        for k0 = 0:1, for k1 = 0:1
            Vm(a+1,b+1) = Vm(a+1,b+1) + Hk(k0+1,k1+1)*ut(a-k0, b-k1);
        end, end
    end, end
    T(:,m) = Vm(:);
    U = U0;
end
T
check = isequal(T*U(:), Vout(:))                    % v = T u
vie.savetex("vie-06-sc-u",    vie.arr2tex(U,"%d"));
vie.savetex("vie-06-sc-uext", vie.arr2tex(Uext,"%d"));
vie.savetex("vie-06-sc-v",    vie.arr2tex(Vout,"%d"));
vie.savetex("vie-06-sc-T",    vie.arr2tex(T,"%d"));
vie.savetex("vie-06-sc-uvec", vie.arr2tex(U(:),"%d"));
vie.savetex("vie-06-sc-vvec", vie.arr2tex(Vout(:),"%d"));
%%
%[text] ## まとめ
%[text] - 畳み込みは反転したインパルス応答との相互相関（荷重移動平均／差分）に一致する
%[text] - 可分離システムは一次元処理の繰り返しで計算でき，演算量が少ない
%[text] - 有限長信号の畳み込みは出力が広がるので，境界処理（零値・周期・複製・対称拡張）が必要
%[text] - 線形フィルタは内積の繰り返しであり，列ベクトル化により行列 $ \\mathbf{T} $ で表現できる \
%[text] © Copyright, Shogo MURAMATSU, All rights reserved.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
