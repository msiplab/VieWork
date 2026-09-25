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
vie_sec02_resolution   % 第2回 解像度
```

- スクリプト名 `vie_secNN_<主題>.m` は講義の第 NN 回に対応します。
- ライブスクリプトはプレーンテキスト Live Code 形式（`.m`）で保存しています（要 MATLAB R2025a 以降）。
- 出力は `results/`、入力データは `data/` に置かれます。パスは `vie.prjfolders` で解決してください。

```matlab
[datfolder,resfolder] = vie.prjfolders();
```

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
