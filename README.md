[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=msiplab/VieWork)

# VieWork
新潟大学工学部電子情報通信プログラム「画像情報工学」サプリメント

## フォルダ構成

```
VieWork/
├── VieWork.prj        MATLAB プロジェクト（パス設定が自動で行われる）
├── code/
│   ├── matlab/        MATLAB ライブスクリプト（プレーンテキスト .m 形式）
│   │   └── +vie/      共通ユーティリティ関数
│   └── python/        Jupyter ノートブック（Google Colab 用）
├── data/              画像データ（ダウンロード取得・Git 管理外）
└── results/           スクリプトが出力する図・画像（Git 管理外）
```

`data` と `results` は Git の管理外です。`vie.prjfolders` が必要に応じて作成します。

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
ソースコードにアクセスして「Open in Colab」のボタンをクリックしてください。

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
