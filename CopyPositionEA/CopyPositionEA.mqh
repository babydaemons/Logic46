//+------------------------------------------------------------------+
//|                                                 CopyPosition.mqh |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include "WindowsAPI.mqh"

//+------------------------------------------------------------------+
//| ポジション操作を表す列挙値です                                   |
//+------------------------------------------------------------------+
enum ENUM_POSITION_OPERATION {
    POSITION_ADD = +1,
    POSITION_REMOVE = -1,
    POSITION_MODIFY = 0,
};

// シンボル名の変換("変換前シンボル名|変換後シンボル名"のカンマ区切り)
struct SYMBOL_CONVERSION {
    int Count;
    string Before[];
    string After[];
};

// コピーポジション連携用タブ区切りファイルの個数です
int CommunacationDirCount = 0;

// コピーポジション連携用タブ区切りファイルのプレフィックスの配列です
string CommunacationPathDir[];

// 設定INIファイルパスです
string inifile_path;

// EA開始時刻です
datetime StartServerTimeEA;

//+------------------------------------------------------------------+
//| エラー表示します                                                 |
//+------------------------------------------------------------------+
void ERROR(string error_message)
{
    MessageBox(error_message + "\n\n※INIファイルパス:\n" + inifile_path, "エラー", MB_ICONERROR);
    printf(error_message);
    printf("※INIファイルパス: " + inifile_path);
}

//+------------------------------------------------------------------+
//| シンボルに付加・削除するサフィックスを返します                   |
//+------------------------------------------------------------------+
string GetSymbolSuffix()
{
    int totalSymbols = SymbolsTotal(false);
    string longestSymbol = "";
    for (int i = 0; i < totalSymbols; i++) {
        string symbolName = SymbolName(i, false);
        printf("[%03d/%03d]%s", i + 1, totalSymbols, symbolName);
        if (StringSubstr(symbolName, 0, 6) == "USDJPY") {
            if (StringLen(symbolName) > StringLen(longestSymbol)) {
                longestSymbol = symbolName;
            }
        }
    }

    string symbolSuffix = longestSymbol;
    StringReplace(symbolSuffix, "USDJPY", "");
    printf("⇒コピーポジション送信時に削除するサフィックスは \'%s\' です。", symbolSuffix);
    return symbolSuffix;
}

//+------------------------------------------------------------------+
//| 証券会社名と口座番号の組の文字列を返します                       |
//+------------------------------------------------------------------+
string GetBrokerAccount(string broker, long account)
{
    StringReplace(broker, " ", "_");
    StringReplace(broker, ",", "");
    StringReplace(broker, ".", "");
    return StringFormat("%s-%d", broker, account);
}
