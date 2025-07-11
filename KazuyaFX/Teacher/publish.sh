#!/bin/bash

export ROOT_DIR=KazuyaFX_先生用セットアップ

taskkill.exe -im EXPLZH.EXE -f 1>/dev/null 2>&1

rm -rf ${ROOT_DIR}/Users/Administrator/AppData/Roaming/MetaQuotes/Terminal/F1DD1D6E7C4A311D1B1CA0D34E33291D/MQL4/Experts
mkdir -p ${ROOT_DIR}/Users/Administrator/AppData/Roaming/MetaQuotes/Terminal/F1DD1D6E7C4A311D1B1CA0D34E33291D/MQL4/Experts
cp -pr ../Experts/KazuyaFX_*フォルダ ${ROOT_DIR}/Users/Administrator/AppData/Roaming/MetaQuotes/Terminal/F1DD1D6E7C4A311D1B1CA0D34E33291D/MQL4/Experts
git add -f ${ROOT_DIR}/KazuyaFX
git add -f ${ROOT_DIR}/Users/Administrator/AppData/Roaming/MetaQuotes/Terminal/F1DD1D6E7C4A311D1B1CA0D34E33291D/MQL4/Experts/*/*
git add -f ${ROOT_DIR}/Users/Administrator/AppData/Roaming/MetaQuotes/Terminal/F1DD1D6E7C4A311D1B1CA0D34E33291D/MQL4/Experts/*/*/*

if [ ! -d ${ROOT_DIR} ]
then
    mkdir -p ${ROOT_DIR}
fi
printf "\n\n##### インストーラーをビルド...\n"
(cd KazuyaFX_Installer; powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1; cp -p KazuyaFX_Installer.exe ../${ROOT_DIR})
git add KazuyaFX_Installer/KazuyaFX_Installer.exe ${ROOT_DIR}/KazuyaFX_Installer.exe

printf "\n##### .NETアプリをビルド...\n"
(cd KazuyaFX; dotnet publish KazuyaFX.csproj -c Release -o ../${ROOT_DIR}/KazuyaFX; cd ../${ROOT_DIR}/KazuyaFX; rm -rf app *.pdb)
git add ${ROOT_DIR}/KazuyaFX/*

cp -p KazuyaFX.ico ./${ROOT_DIR}/KazuyaFX/

"/c/Program Files/Explzh/EXPLZH.EXE" &
