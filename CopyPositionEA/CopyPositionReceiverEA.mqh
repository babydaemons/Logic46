//+------------------------------------------------------------------+
//|                                          CopyPositionReciver.mqh |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include "CopyPositionEA.mqh"

string  SYMBOL_APPEND_SUFFIX; // ポジションコピー時にシンボル名に追加するサフィックス
int     RETRY_INTERVAL_INIT;  // 発注時・ポジション修正時のリトライ時間の初期値(ミリ秒)
int     RETRY_COUNT_MAX;      // 発注時・ポジション修正時のリトライ最大回数
int     SLIPPAGE;             // スリッページ(ポイント)

// シンボル名の変換("変換前シンボル名|変換後シンボル名"のカンマ区切り)
SYMBOL_CONVERSION SymbolConversion[];

// ポジションコピー時のロット数の係数の配列です
double LotsMultiply[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // INIファイルより設定値を初期化します
    if (!Initialize()) {
        return INIT_FAILED;
    }

    // 100ミリ秒の周期でポジションコピーを行います
    if (!EventSetMillisecondTimer(100)) {
        string error_message = "ポジションコピーのインターバルタイマーを設定できませんでした。";
        MessageBox(error_message, "エラー", MB_ICONSTOP | MB_OK);
        return INIT_FAILED;
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| INIファイルより設定値を初期化します                              |
//+------------------------------------------------------------------+
bool Initialize()
{
    // レシーバー側を識別する証券会社名+口座番号を取得します
    string ReciverBroker = AccountInfoString(ACCOUNT_COMPANY);
    string ReciverAccount = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    string receiver_name = GetBrokerAccountName(ReciverBroker, ReciverAccount);

    // レシーバー側設定のINIファイルパスをログ出力します
    string inifile_name = "";
    string inifile_path = "";
    CreateSettingPath(receiver_name, false, inifile_name, inifile_path);
    printf("●レシーバー側設定INIファイルは「%s」です。", inifile_path);
    printf("●レシーバー側証券会社名は「%s」です。", ReciverBroker);
    printf("●レシーバー側口座番号は「%s」です。", ReciverBroker);

    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        string error_message = "※エラー: レシーバー側設定INIファイルが見つかりません。\n" +
                               StringFormat("●レシーバー側証券会社名は「%s」です。\n", ReciverBroker) +
                               StringFormat("●レシーバー側口座番号は「%s」です。", ReciverAccount);
        ERROR(inifile_path, error_message);
        CreateReciverINI(ReciverBroker, ReciverAccount, "センダー側証券会社名", "センダー側口座番号");
        return false;
    }

    string receiver_broker = "";
    if (GetPrivateProfileString("Receiver", "BROKER", NONE, receiver_broker, 1024, inifile_path) == 0 || receiver_broker == NONE || ReciverBroker != receiver_broker) {
        string error_message = "※レシーバー側証券会社名が一致しません: セクション[Receiver]のキー\"BROKER\"を見直してください。";
        ERROR(inifile_path, error_message);
        return false;
    }

    string receiver_account = "";
    if (GetPrivateProfileString("Receiver", "ACCOUNT", NONE, receiver_account, 1024, inifile_path) == 0 || receiver_account == NONE || ReciverAccount != receiver_account) {
        string error_message = "※レシーバー側口座番号が一致しません: セクション[Receiver]のキー\"ACCOUNT\"を見直してください。";
        ERROR(inifile_path, error_message);
        return false;
    }

    string retry_interval_init = "";
    if (GetPrivateProfileString("Receiver", "RETRY_INTERVAL_INIT", NONE, retry_interval_init, 1024, inifile_path) == 0 || retry_interval_init == NONE) {
        string error_message = "※エラー: セクション[Receiver]のキー\"RETRY_INTERVAL_INIT\"が見つかりません。";
        ERROR(inifile_path, error_message);
        return false;
    }
    RETRY_INTERVAL_INIT = (int)StringToInteger(retry_interval_init);

    string retry_count_max = "";
    if (GetPrivateProfileString("Receiver", "RETRY_COUNT_MAX", NONE, retry_count_max, 1024, inifile_path) == 0 || retry_count_max == NONE) {
        string error_message = "※エラー: セクション[Receiver]のキー\"RETRY_COUNT_MAX\"が見つかりません。";
        ERROR(inifile_path, error_message);
        return false;
    }
    RETRY_COUNT_MAX = (int)StringToInteger(retry_count_max);

    // ポジションコピー時にシンボル名へ追加するサフィックスを自動検索する
    SYMBOL_APPEND_SUFFIX = GetSymbolSuffix(false);

    // センダー側の設定個数を取得
    string sender_count = "";
    if (GetPrivateProfileString("Receiver", "SENDER_COUNT", NONE, sender_count, 1024, inifile_path) == 0 || sender_count == NONE) {
        string error_message = "※エラー: セクション[Receiver]のキー\"SENDER_COUNT\"が見つかりません。";
        ERROR(inifile_path, error_message);
        return false;
    }
    CommunacationDirCount = (int)StringToInteger(sender_count);
    printf("●%d個のセンダー側からポジションをコピーします。", CommunacationDirCount);

    ArrayResize(SymbolConversion, CommunacationDirCount);

    for (int i = 0; i < CommunacationDirCount; ++i) {
        string section_name = StringFormat("Sender%03d", i + 1);
        string sender_broker = "";
        string sender_account = "";
        if (!GetBrokerAccountPair(inifile_path, section_name, sender_broker, sender_account)) {
            return false;
        }

        // センダー側設定INIファイルの存在確認
        string sender_name = GetBrokerAccountName(sender_broker, sender_account);
        if (!CheckSenderSetting(inifile_path, section_name, sender_broker, sender_account, ReciverBroker, ReciverAccount)) {
            return false;
        }

        // ポジションコピー時のロット数の係数
        string lots_multiply = "";
        GetPrivateProfileString(section_name, "LOTS_MULTIPLY", NONE, lots_multiply, 1024, inifile_path);
        ArrayResize(LotsMultiply, i + 1);
        LotsMultiply[i] = lots_multiply == NONE ? 1.0 : StringToDouble(lots_multiply);

        // シンボル名の変換("変換前シンボル名|変換後シンボル名"のカンマ区切り)
        string symbol_conversion_list = "";
        GetPrivateProfileString(section_name, "SYMBOL_CONVERSION", NONE, symbol_conversion_list, 1024, inifile_path);
        InitializeSymbolConversion(symbol_conversion_list, i);

        // ポジションコピー連携ファイル用フォルダを作成する
        ArrayResize(CommunacationPathDir, i + 1);
        CommunacationPathDir[i] = StringFormat("CopyPositionEA\\%s\\%s", sender_name, receiver_name);
        if (!FolderCreate(CommunacationPathDir[i], FILE_COMMON)) {
            string error_message = StringFormat("※エラー: コピー連携ファイルのフォルダーの作成に失敗しました: \"%s\"", CommunacationPathDir[i]);
            ERROR(inifile_path, error_message);
            return false;
        }

        printf("[%03d]センダー側の証券会社は「%s」です。", i + 1, sender_broker);
        printf("[%03d]センダー側の口座番号は「%s」です。", i + 1, sender_account);
        printf("[%03d]センダー側からのポジションコピー時のロット係数は「%.3f」です。", i + 1, LotsMultiply[i]);
        printf("[%03d]センダー側からのポジションコピーフォルダは「%s」です。", i + 1, CommunacationPathDir[i]);
    }

#ifdef __MQL4__
    bool trade_allowed = IsTradeAllowed();
#else
    bool trade_allowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
#endif
    if (!trade_allowed) {
        string error_message = "※エラー: 自動売買が許可されていません。";
        ERROR(inifile_path, error_message);
        return false;
    }

    printf("●コピーポジションの受信監視を開始します。");
    return true;
}

//+------------------------------------------------------------------+
//| センダー側の設定を確認します                                     |
//+------------------------------------------------------------------+
bool CheckSenderSetting(string base_inifile_path, string base_section_name, string sender_broker, string sender_account, string receiver_broker, string receiver_account)
{
    if (StringFind(sender_broker, "側") != -1) {
        string error_message = StringFormat("センダー側証券会社名がテンプレートから変更されていません。\n※セクション:\n[%s]", base_section_name); 
        ERROR(base_inifile_path, error_message);
        return false;
    }

    if (StringFind(sender_account, "側") != -1) {
        string error_message = StringFormat("センダー側口座番号がテンプレートから変更されていません。\n※セクション:\n[%s]", base_section_name); 
        ERROR(base_inifile_path, error_message);
        return false;
    }

    string sender_name = GetBrokerAccountName(sender_broker, sender_account);
    string inifile_name = "";
    string inifile_path = "";
    CreateSettingPath(sender_name, true, inifile_name, inifile_path);
    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        string error_message = "※エラー: センダー側設定INIファイルが見つかりません。\n" +
                               StringFormat("●センダー側証券会社名は「%s」です。\n", sender_broker) +
                               StringFormat("●センダー側口座番号は「%s」です。", sender_account);
        ERROR(inifile_path, error_message);
        CreateSenderINI(sender_broker, sender_account, receiver_broker, receiver_account);
        return false;
    }

    // センダー側設定INIファイルのレシーバー側の設定個数を取得
    string setting_count_text = "";
    if (GetPrivateProfileString("Sender", "RECIEVER_COUNT", NONE, setting_count_text, 1024, inifile_path) == 0 || setting_count_text == NONE) {
        string error_message = "※エラー: セクション[Sender]のキー\"RECIEVER_COUNT\"が見つかりません。";
        ERROR(inifile_path, error_message);
        return false;
    }

    long setting_count = StringToInteger(setting_count_text);
    for (int i = 0; i < setting_count; ++i) {
        string section_name = StringFormat("Receiver%03d", i + 1);
        string broker = "";
        string account = "";
        if (!GetBrokerAccountPair(inifile_path, section_name, broker, account)) {
            return false;
        }
        if (broker == receiver_broker && account == receiver_account) {
            return true;
        }
    }

    string error_message = StringFormat("※エラー: セクション[Sender]の中に「%s」と「%s」の設定が見つかりません。", receiver_broker, receiver_account);
    ERROR(inifile_path, error_message);
    return false;
}

//+------------------------------------------------------------------+
//| シンボル名の変換情報を初期化します                               |
//+------------------------------------------------------------------+
void InitializeSymbolConversion(string symbol_conversion_list, int k)
{
    if (symbol_conversion_list == NONE) {
        SymbolConversion[k].Count = 0;
        return;
    }

    string symbol_conversion[];
    SymbolConversion[k].Count = StringSplit(symbol_conversion_list, ',', symbol_conversion);
    ArrayResize(SymbolConversion[k].Before, SymbolConversion[k].Count);
    ArrayResize(SymbolConversion[k].After, SymbolConversion[k].Count);
    for (int i = 0; i < SymbolConversion[k].Count; ++i) {
        string conversion[];
        StringSplit(symbol_conversion[i], '|', conversion);
        SymbolConversion[k].Before[i] = conversion[0];
        SymbolConversion[k].After[i] = conversion[1];
    }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // タイマーを破棄します
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    // 100ミリ秒の周期でポジション全体の差分をタブ区切りファイルから読みだします
    LoadPositions();
}

//+------------------------------------------------------------------+
//| ポジション全体の差分を全てのタブ区切りファイルから読みだします   |
//+------------------------------------------------------------------+
void LoadPositions()
{
    for (int i = 0; i < CommunacationDirCount; ++i) {
        LoadPosition(CommunacationPathDir[i], LotsMultiply[i], i);
    }
}

//+------------------------------------------------------------------+
//| ポジション全体の差分をタブ区切りファイルから読みだします         |
//+------------------------------------------------------------------+
void LoadPosition(string communication_dir, double lots_multiply, int k)
{
    string file_name;
    long search_handle = FileFindFirst(communication_dir + "\\*.tsv", file_name, FILE_COMMON);
    if (search_handle == INVALID_HANDLE) {
        return;
    }

    do {
        string path = communication_dir + "\\" + file_name;
        int file = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON, '\t', CP_ACP);
        if (file == INVALID_HANDLE) {
            continue;
        }

        // 見つかったコピーポジション連携用タブ区切りファイルのファイル名をログ出力します
        printf("⇒連携ファイル: \"%s\"", path);

        string line;
        while ((line = FileReadString(file)) != "") {
            string field[];
            StringSplit(line, '\t', field);
            // タブ区切りファイルの仕様
            // 0列目：送信元証券会社名
            string sender_broker = field[0];
            // 1列目：+1: ポジション追加 ／ -1: ポジション削除 ／ 0: ポジション修正
            int change = (int)StringToInteger(field[1]);
            // 2列目：マジックナンバー
            int magic_number = (int)StringToInteger(field[2]);
            // 3列目：エントリー時刻
            string entry_date = field[3];
            // 4列目：エントリー種別
            int entry_type = (int)StringToInteger(field[4]);
            // 5列目：エントリー価格
            double entry_price = StringToDouble(field[5]);
            // 6列目：シンボル名
            string symbol = ConvertSymbol(field[6], k) + SYMBOL_APPEND_SUFFIX;
            // 5列目：エントリー価格を補正
            if (entry_type > 0) {
                entry_price = MathMin(entry_price, SymbolInfoDouble(symbol, SYMBOL_ASK));
            }
            else {
                entry_price = MathMax(entry_price, SymbolInfoDouble(symbol, SYMBOL_BID));
            }
            // 7列目：コピー元チケット番号
            int ticket = (int)StringToInteger(field[7]);
            // 8列目：ポジションサイズ
            double lots = RoundLots(symbol, StringToDouble(field[8]) * lots_multiply);
            // 9列目：ストップロス
            double stoploss = StringToDouble(field[9]);
            // 10列目：テイクプロフィット
            double takeprofit = StringToDouble(field[10]);

            printf("ポジションコピー受信: %s %+d %d %s %+d %.6f %s %d %.2f %.6f %.6f",
                sender_broker, change, magic_number, entry_date, entry_type, entry_price, symbol, ticket, lots, stoploss, takeprofit);

            if (change == +1) {
                Entry(sender_broker, magic_number, entry_type, entry_price, symbol, ticket, lots, stoploss, takeprofit);
            }
            else if (change == -1) {
                Exit(sender_broker, magic_number, entry_type, entry_price, symbol, ticket, stoploss, takeprofit);
            }
            else {
                Modify(sender_broker, magic_number, entry_type, entry_price, symbol, ticket, stoploss, takeprofit);
            }
        }

        FileClose(file);
        FileDelete(path, FILE_COMMON);
    } while (FileFindNext(search_handle, file_name));

    FileFindClose(search_handle);
}

//+------------------------------------------------------------------+
//| シンボル名の変換を行います                                       |
//+------------------------------------------------------------------+
string ConvertSymbol(string symbol_before, int k)
{
    for (int i = 0; i < SymbolConversion[k].Count; ++i) {
        if (SymbolConversion[k].Before[i] == symbol_before) {
            return SymbolConversion[k].After[i];
        }
    }

    return symbol_before;
}
