# -*- mode: python -*-
import sys
import os
from PyInstaller.utils.hooks import collect_data_files

# PyInstaller スペックファイル
a = Analysis(
    ["KazuyaFX_Setup.py"],
    pathex=["."],
    binaries=[],
    datas=[("KazuyaFX_Setup.zip", ".")],  # ZIP をリソースに含める
    hiddenimports=[],
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
)

pyz = PYZ(a.pure)
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    name="KazuyaFX_Setup",
    debug=False,
    strip=False,
    upx=True,
    console=True,  # ここを変更（コンソール表示）
    icon="KazuyaFX_Setup.ico",  # アイコン指定
    singlefile=True,  # これを追加（One-File モード）
)
