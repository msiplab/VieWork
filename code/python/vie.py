"""「画像情報工学」Python ノートブック用の共通ヘルパー．

MATLAB 版の +vie パッケージ（code/matlab/+vie）のうち，データの取得にあたる部分に対応する．
画像処理そのものは各ノートブックで scikit-image，SciPy，NumPy などを使って書く．
Google Colab では，各ノートブックの最初のセルがこのファイルを GitHub から取得する．

    import vie
    X = vie.msipimg(5, 256, "gray")   # 参考資料のサンプル画像（石像の顔）

import したときに日本語フォントと図の配色を設定する（vie.setup）．

Copyright (c) Shogo MURAMATSU, 2026
All rights reserved.
"""
from __future__ import annotations

import os
import urllib.request
from pathlib import Path

import numpy as np

REPO_RAW = "https://raw.githubusercontent.com/msiplab/VieWork/master/"
MSIPWORKM_RAW = "https://raw.githubusercontent.com/msiplab/MsipWorkM/master/"
KODAK_URL = "https://www.r0k.us/graphics/kodak/kodak/"

# 図の配色（スライドと同じロゴの 3 色と灰色）
CMAIN = (0 / 255, 136 / 255, 85 / 255)    # メイン（緑）#008855
CCOOL = (46 / 255, 117 / 255, 182 / 255)  # 寒色系（青）#2E75B6
CWARM = (197 / 255, 90 / 255, 17 / 255)   # 暖色系（橙）#C55A11
CGRAY = (0.6, 0.6, 0.6)                   # 補助線（灰）

_FONT_URL = "https://github.com/google/fonts/raw/main/ofl/bizudgothic/BIZUDGothic-Regular.ttf"


def datfolder() -> Path:
    """データフォルダを返す（無ければ作る）．

    VieWork を clone した環境では <root>/data，Colab などでは作業フォルダの data．
    """
    here = Path(__file__).resolve().parent
    root = here.parent.parent
    folder = root / "data" if (root / "VieWork.prj").exists() else Path.cwd() / "data"
    folder.mkdir(parents=True, exist_ok=True)
    return folder


def datafile(name: str) -> Path:
    """VieWork の data フォルダで管理しているファイルを返す（無ければ GitHub から取得）．"""
    path = datfolder() / name
    if not path.exists():
        urllib.request.urlretrieve(REPO_RAW + "data/" + name, path)
    return path


def setup() -> None:
    """日本語を表示できるフォントと図の既定値を matplotlib に設定する．"""
    import matplotlib as mpl
    from matplotlib import font_manager

    names = {f.name for f in font_manager.fontManager.ttflist}
    for cand in ("BIZ UDGothic", "BIZ UDPGothic", "Noto Sans CJK JP", "Noto Sans JP",
                 "IPAexGothic", "Yu Gothic", "Meiryo", "MS Gothic", "Hiragino Sans"):
        if cand in names:
            family = cand
            break
    else:
        # Colab などで日本語フォントが無いときは BIZ UDGothic（スライドと同じ書体）を取得する
        path = datfolder() / "BIZUDGothic-Regular.ttf"
        if not path.exists():
            urllib.request.urlretrieve(_FONT_URL, path)
        font_manager.fontManager.addfont(str(path))
        family = font_manager.FontProperties(fname=str(path)).get_name()
    mpl.rcParams["font.family"] = family
    # ヒンティングの方式によっては，BIZ UDGothic の 9 pt でマイナス記号が消えるので，自動ヒンティングにする
    mpl.rcParams["text.hinting"] = "force_autohint"
    mpl.rcParams["axes.unicode_minus"] = False
    mpl.rcParams["mathtext.fontset"] = "cm"
    mpl.rcParams["figure.dpi"] = 100
    mpl.rcParams["axes.prop_cycle"] = mpl.cycler(color=[CMAIN, CCOOL, CWARM, CGRAY])


def msipimg(idx: int, size=None, mode: str = "rgb") -> np.ndarray:
    """参考資料（教科書 MsipText）のサンプル画像 msipimgNN.tif を uint8 で返す．

    idx は 1〜8（01 海岸，02 花束，03 マカロン，04 石造りの建物，05 石像の顔，
    06 縞模様の路面，07 モンブラン，08 スイカ．いずれも 512×512 のカラー）．
    mode="gray" で輝度 Y = 0.299R + 0.587G + 0.114B（参考資料 2.3 節の YCbCr の Y）の
    グレースケールにする．size を与えると scikit-image の resize（3 次補間，縮小時は
    アンチエイリアス）で縮小する（スカラーなら正方形）．
    MATLAB 版とは縮小の実装が異なるので，画素値はわずかに異なる．
    """
    from skimage import io
    from skimage.transform import resize

    name = f"msipimg{idx:02d}.tif"
    path = datfolder() / name
    if not path.exists():
        try:
            urllib.request.urlretrieve(REPO_RAW + "data/" + name, path)
        except OSError:
            urllib.request.urlretrieve(MSIPWORKM_RAW + "data/" + name, path)
    X = io.imread(path)
    if X.ndim == 3 and X.shape[2] == 4:   # アルファチャネルがあれば落とす
        X = X[:, :, :3]
    X = X.astype(np.float64)
    if mode == "gray":
        X = X @ np.array([0.299, 0.587, 0.114])
    if size is not None:
        if np.isscalar(size):
            size = (size, size)
        X = resize(X, tuple(size) + X.shape[2:], order=3, mode="symmetric",
                   anti_aliasing=True, preserve_range=True)
    return np.clip(np.floor(X + 0.5), 0, 255).astype(np.uint8)


def kodim(idx: int) -> np.ndarray:
    """Kodak Lossless True Color Image Suite の kodimNN.png を uint8 の RGB で返す．"""
    from skimage import io

    name = f"kodim{idx:02d}.png"
    path = datfolder() / name
    if not path.exists():
        urllib.request.urlretrieve(KODAK_URL + name, path)
    return io.imread(path)


if os.environ.get("VIE_NO_SETUP") is None:
    try:
        setup()
    except Exception:  # フォントの取得に失敗しても計算は続けられるようにする
        pass
