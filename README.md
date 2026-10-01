[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=msiplab/VieWork&project=VieWork.prj)

# VieWork
新潟大学工学部電子情報通信プログラム「画像情報工学」サプリメント

## フォルダ構成

```
VieWork/
├── VieWork.prj        MATLAB プロジェクト（パス設定が自動で行われる）
├── code/
│   ├── matlab/        MATLAB ライブスクリプト（プレーンテキスト .m 形式）
│   │   └── +vie/      共通ユーティリティ関数
│   └── python/        Jupyter ノートブック（Google Colab 用．MATLAB 版の移植）と共通ヘルパー vie.py
├── data/              画像データ（msipimg##.tif は Git 管理，kodim##.png はダウンロード取得・管理外）
└── results/           スクリプトが出力する図・画像（Git 管理外）
```

`results` は Git の管理外です。`data` のうち，スライドに使う参考資料のサンプル画像 `msipimg01.tif`〜`msipimg08.tif`（MsipWorkM と同じもの）だけを Git で管理し，`vie.msipimg` で読み込みます。演習用の Kodak 画像 `kodim##.png` は `vie.download_img` で取得するもので，Git では管理しません。

## MATLAB Online と MATLAB Connector のすすめ

講義スライドの図と数値は MATLAB 版のライブスクリプトで作っています。新潟大学の学生は[大学の包括ライセンス](https://jp.mathworks.com/academia/tah-portal/niigata-university-31576302.html)で MATLAB を使えるので、MATLAB 版をぜひ動かしてください。

- **MATLAB Online**：ブラウザだけで MATLAB が使えます（インストール不要）。このページ先頭の「Open in MATLAB Online」のボタンを押すと、VieWork が自分の MATLAB Drive に複製され、プロジェクト `VieWork.prj` が開いてパスが設定されます。Python 版の各ノートブックの先頭にも、対応するライブスクリプトを開くボタンがあります。
- **MATLAB Connector**：手元の PC に [MATLAB Connector](https://jp.mathworks.com/products/matlab-drive.html) を入れると、MATLAB Drive のファイルが PC のフォルダと自動で同期されます。大学では MATLAB Online、自宅では手元の MATLAB、のように、同じファイルを続けて使えます。

## MATLAB コードの動かし方

MATLAB でプロジェクトファイルを開くと、パス設定が自動で行われます。

```matlab
openProject('VieWork.prj')
```

初回だけ演習用の画像データを取得してください（Kodak Lossless True Color Image Suite）。

```matlab
vie.download_img
```

あとは各回のスクリプトを実行してください。

```matlab
vie_sec04_pixel        % 第4回 画素処理
```

| 回 | スクリプト | 回 | スクリプト |
|---|---|---|---|
| 01 | `vie_sec01_intro` | 08 | `vie_sec08_resampling` |
| 02 | `vie_sec02_vision` | 09 | `vie_sec09_transform` |
| 03 | `vie_sec03_color` | 10 | `vie_sec10_restoration` |
| 04 | `vie_sec04_pixel` | 11 | `vie_sec11_motion` |
| 05 | `vie_sec05_neighbor` | 12 | `vie_sec12_coding` |
| 06 | `vie_sec06_boundary` | 13 | `vie_sec13_binary` |
| 07 | `vie_sec07_fourier` | 14 | `vie_sec14_recognition` |

- スクリプト名 `vie_secNN_<主題>.m` は講義の第 NN 回に対応します。
- スライドに書ききれない計算の過程や補足を、コメントとして詳しく書いています。スライドの例題の数値や図はすべてこのスクリプトの出力です。
- ライブスクリプトはプレーンテキスト Live Code 形式（`.m`）で保存しています（要 MATLAB R2025a 以降）。
- 出力は `results/`、入力データは `data/` に置かれます。パスは `vie.prjfolders` で解決してください。

```matlab
[datfolder,resfolder] = vie.prjfolders();
```

### スライドとの連携

各スクリプトは `results/` に図 `vie-NN-*.png` と数値 `vie-NN-*.tex` を書き出します。
講義スライド（VieSlides）はこれを `tools/sync-results.ps1` で取り込み、
`\includegraphics` と `\viesnippet{}` で参照します。

| 関数 | 役割 |
|---|---|
| `vie.savetex(name, content)` | `results/<name>.tex` に LaTeX の断片を書き出す |
| `vie.arr2tex(X, fmt)` | 行列を `a & b \\ c & d` の形に整形する |
| `vie.fmtint(v)` | 整数を 3 桁区切り（`{,}`）で整形する |

スクリプトは MATLAB の同じワークスペースで続けて実行することがあるため、
`det`、`edge`、`corner` など組み込み関数と同じ名前の変数は使わないでください。

## Python コードの動かし方
`code/python/` のノートブック `vie_secNN_<主題>.ipynb` は、上の MATLAB ライブスクリプトを Python に移植したものです（回と主題は MATLAB 版と同じ）。
GitHub でノートブックを開き、先頭の「Open in Colab」のボタンをクリックしてください。

- 最初のセルが共通ヘルパー `code/python/vie.py`（サンプル画像の取得と日本語フォント・配色の設定）を GitHub から取得します。
- 画像処理には scikit-image、SciPy、NumPy などを使います。MATLAB の関数を移植したものは使っていません。
- 教科書の例題の数値は、スライドの値と一致することを `assert` で確かめています。画像から計算する値は、ライブラリの実装が MATLAB と異なるため、スライド（MATLAB 版）の値とわずかに異なります。
- ノートブックは出力を消した状態で保存しています。

手元で動かす場合は Python 3.12 以降で次のパッケージを入れてください。

```
pip install numpy scipy scikit-image matplotlib pillow PyWavelets colour-demosaicing jupyter
```

## Google Colab をはじめる
- https://colab.research.google.com

## Scikit-image ライブラリ
- https://scikit-image.org/
- http://www.turbare.net/transl/scipy-lecture-notes/packages/scikit-image/index.html

## SciPy ライブラリ
- https://docs.scipy.org/doc/scipy/reference/
- http://www.turbare.net/transl/scipy-lecture-notes/advanced/image_processing/index.html

### SciPy.ndimage 
- https://docs.scipy.org/doc/scipy/reference/ndimage.html

### SciPy.fftpack
- https://docs.scipy.org/doc/scipy/reference/fftpack.html

### SciPy.signal
- https://docs.scipy.org/doc/scipy/reference/signal.html

## Pillow ライブラリ
- https://pillow.readthedocs.io/en/stable/index.html

## PyTorch
- https://pytorch.org/

### PyTorch Vision
- https://pytorch.org/vision/stable/index.html

## MATLAB/Simulink
- https://jp.mathworks.com/academia/tah-portal/niigata-university-31576302.html

## 参考サイト
- https://qiita.com/croquette0212/items/36cadce5bf0fb703ed19
- http://ishidate.my.coocan.jp/python/python.htm
- http://www.turbare.net/transl/scipy-lecture-notes/packages/scikit-image/index.html

## 関連講義へのリンク

- [プログラミングBI/BII](https://github.com/msiplab/EicProgLab)
- [電子情報通信実験Ⅳ](https://github.com/msiplab/EicEngLabIV)
- [画像処理特論](https://github.com/msiplab/AtipWork)
