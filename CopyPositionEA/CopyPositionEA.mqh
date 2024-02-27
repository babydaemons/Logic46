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

//+------------------------------------------------------------------+
//| エラー表示します                                                 |
//+------------------------------------------------------------------+
void ERROR(string inifile_path, string error_message)
{
    MessageBox(error_message + "\n\n※INIファイルパス:\n" + inifile_path, "エラー", MB_ICONERROR);
    printf(error_message);
    printf("※INIファイルパス: " + inifile_path);
}

//+------------------------------------------------------------------+
//| シンボルに付加・削除するサフィックスを返します                   |
//+------------------------------------------------------------------+
string GetSymbolSuffix(bool sender)
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
    printf("⇒コピーポジション%sするサフィックスは \'%s\' です。", sender ? "送信時に削除" : "受信時に追加", symbolSuffix);
    return symbolSuffix;
}

//+------------------------------------------------------------------+
//| INIファイルのパスを返します                                      |
//+------------------------------------------------------------------+
void CreateSettingPath(string name, bool sender, string& inifile_name, string& inifile_path)
{
    // Commonデータフォルダのパスを取得します
    string common_data_dir = TerminalInfoString(TERMINAL_COMMONDATA_PATH);

    string setting_dir = "CopyPositionEA";
    inifile_name = StringFormat("%s\\%s-%s.ini", setting_dir, sender ? "Sender" : "Receiver", name);
    inifile_path = StringFormat("%s\\Files\\%s", common_data_dir, inifile_name);
    if (!FolderCreate(setting_dir, FILE_COMMON)) {
        string error_message = "※エラー: INIファイルのフォルダの作成に失敗しました\n" + common_data_dir + "\\" + setting_dir;
        ERROR(inifile_path, error_message);
        return;
    }
}

//+------------------------------------------------------------------+
//| センダー側INIのテンプレートを作成します                          |
//+------------------------------------------------------------------+
void CreateSenderINI(string sender_broker, string sender_account, string reciver_broker, string reciver_account)
{
    string sender_name = GetBrokerAccountName(sender_broker, sender_account);
    string inifile_name = "";
    string inifile_path = "";
    CreateSettingPath(sender_name, true, inifile_name, inifile_path);

    int file = FileOpen(inifile_name, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON, '\t', CP_ACP);
    if (file == INVALID_HANDLE) {
        string error_message = "※エラー: INIファイルの作成に失敗しました\n" + inifile_path + "\n" + ErrorDescription();
        ERROR(inifile_path, error_message);
        return;
    }
    FileWrite(file, "[Sender]");
    FileWrite(file, "; (エラーチェック用)センダー側証券会社名");
    FileWrite(file, "BROKER = " + sender_broker);
    FileWrite(file, "; (エラーチェック用)センダー側口座番号");
    FileWrite(file, "ACCOUNT = " + sender_account);
    FileWrite(file, "; (オプション)ロット数の係数");
    FileWrite(file, ";LOTS_MULTIPLY = 0.1");
    FileWrite(file, "; (オプション)シンボル名の変換(\"変換前シンボル名|変換後シンボル名\"のカンマ区切り)");
    FileWrite(file, ";SYMBOL_CONVERSION = XAUUSD|GOLD,XAGUSD|SILVER");
    FileWrite(file, "; レシーバー側の設定個数");
    FileWrite(file, "RECIEVER_COUNT = 1");
    FileWrite(file, "");
    FileWrite(file, "[Receiver001]");
    FileWrite(file, "; (エラーチェック用)レシーバー側証券会社名");
    FileWrite(file, "BROKER = " + reciver_broker);
    FileWrite(file, "; (エラーチェック用)レシーバー側口座番号");
    FileWrite(file, "ACCOUNT = " + reciver_account);
    FileWrite(file, "; (オプション)ロット数の係数");
    FileWrite(file, ";LOTS_MULTIPLY = 1.0");
    FileWrite(file, "; (オプション)シンボル名の変換(\"変換前シンボル名|変換後シンボル名\"のカンマ区切り)");
    FileWrite(file, ";SYMBOL_CONVERSION = GOLD|XAUUSD,SILVER|XAGUSD");
    FileClose(file);
    MessageBox("テンプレートのセンダー側INIファイルを作成しました。\n" + inifile_path, "ご案内", MB_ICONINFORMATION);
}

//+------------------------------------------------------------------+
//| レシーバー側INIのテンプレートを作成します                        |
//+------------------------------------------------------------------+
void CreateReciverINI(string receiver_broker, string receiver_account, string sender_broker, string sender_account)
{
    string receiver_name = GetBrokerAccountName(receiver_broker, receiver_account);
    string inifile_name = "";
    string inifile_path = "";
    CreateSettingPath(receiver_name, false, inifile_name, inifile_path);

    int file = FileOpen(inifile_name, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON, '\t', CP_ACP);
    if (file == INVALID_HANDLE) {
        string error_message = "※エラー: INIファイルの作成に失敗しました\n" + inifile_path + "\n" + ErrorDescription();
        ERROR(inifile_path, error_message);
        return;
    }
    FileWrite(file, "[Receiver]");
    FileWrite(file, "; (エラーチェック用)レシーバー側証券会社名");
    FileWrite(file, "BROKER = " + receiver_broker);
    FileWrite(file, "; (エラーチェック用)レシーバー側口座番号");
    FileWrite(file, "ACCOUNT = " + receiver_account);
    FileWrite(file, "; (オプション)ロット数の係数");
    FileWrite(file, ";LOTS_MULTIPLY = 0.1");
    FileWrite(file, "; (オプション)シンボル名の変換(\"変換前シンボル名|変換後シンボル名\"のカンマ区切り)");
    FileWrite(file, ";SYMBOL_CONVERSION = XAUUSD|GOLD,XAGUSD|SILVER");
    FileWrite(file, "; 発注時・ポジション修正時のリトライ時間の初期値(ミリ秒)");
    FileWrite(file, "RETRY_INTERVAL_INIT = 100");
    FileWrite(file, "; 発注時・ポジション修正時のリトライ最大回数");
    FileWrite(file, "RETRY_COUNT_MAX = 5");
    FileWrite(file, "; スリッページ");
    FileWrite(file, "SLIPPAGE = 10");
    FileWrite(file, "; センダー側の設定個数");
    FileWrite(file, "SENDER_COUNT = 1");
    FileWrite(file, "");
    FileWrite(file, "[Sender001]");
    FileWrite(file, "; (エラーチェック用)センダー側証券会社名");
    FileWrite(file, "BROKER = " + sender_broker);
    FileWrite(file, "; (エラーチェック用)センダー側口座番号");
    FileWrite(file, "ACCOUNT = " + sender_account);
    FileWrite(file, "; (オプション)ロット数の係数");
    FileWrite(file, ";LOTS_MULTIPLY = 1.0");
    FileWrite(file, "; (オプション)シンボル名の変換(\"変換前シンボル名|変換後シンボル名\"のカンマ区切り)");
    FileWrite(file, ";SYMBOL_CONVERSION = GOLD|XAUUSD,SILVER|XAGUSD");
    FileClose(file);
    MessageBox("テンプレートのレシーバー側INIファイルを作成しました。\n" + inifile_path, "ご案内", MB_ICONINFORMATION);
}

//+------------------------------------------------------------------+
//| 証券会社名と口座番号の組の文字列を返します                       |
//+------------------------------------------------------------------+
string GetBrokerAccountName(string broker, string account)
{
    StringReplace(broker, " ", "_");
    StringReplace(broker, ",", "");
    StringReplace(broker, ".", "");
    return StringFormat("%s-%s", GetBrokerName(broker), account);
}

//+------------------------------------------------------------------+
//| 証券会社名の文字列を返します 　　　　　　　                      |
//+------------------------------------------------------------------+
string GetBrokerName(string broker)
{
    StringReplace(broker, " ", "_");
    StringReplace(broker, ",", "");
    StringReplace(broker, ".", "");
    return broker;
}

//+------------------------------------------------------------------+
//| 証券会社名と口座番号の組の取得します                             |
//+------------------------------------------------------------------+
bool GetBrokerAccountPair(string inifile_path, string section_name, string& broker, string& account)
{
    broker = "";
    if (GetPrivateProfileString(section_name, "BROKER", NONE, broker, 1024, inifile_path) == 0 || broker == NONE) {
        string error_message = StringFormat("※エラー: セクション[%s]のキー\"BROKER\"が見つかりません。", section_name);
        ERROR(inifile_path, error_message);
        return false;
    }

    account = "";
    if (GetPrivateProfileString(section_name, "ACCOUNT", NONE, account, 1024, inifile_path) == 0 || account == NONE) {
        string error_message = StringFormat("※エラー: セクション[%s]のキー\"ACCOUNT\"が見つかりません。", section_name);
        ERROR(inifile_path, error_message);
        return false;
    }

    return true;
}
