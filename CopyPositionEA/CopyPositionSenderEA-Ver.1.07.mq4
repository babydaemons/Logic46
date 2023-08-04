//+------------------------------------------------------------------+
//|                                          CopyPositionSederEA.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include "WindowsAPI.mqh"

string  SYMBOL_REMOVE_SUFFIX; // ポジションコピー時にシンボル名から削除するサフィックス
double  LOTS_MULTIPLY;        // ポジションコピー時のロット数の係数

//+------------------------------------------------------------------+
//| ポジション操作を表す列挙値です                                   |
//+------------------------------------------------------------------+
enum ENUM_POSITION_OPERATION {
    POSITION_ADD = +1,
    POSITION_REMOVE = -1,
    POSITION_MODIFY = 0,
};

#define MAX_POSITION 1024

//+------------------------------------------------------------------+
//| ポジション全体を表す構造体です                                   |
//+------------------------------------------------------------------+
struct POSITION_LIST {
    int Change[MAX_POSITION];
    int MagicNumber[MAX_POSITION];
    int EntryType[MAX_POSITION];
    double EntryPrice[MAX_POSITION];
    string SymbolValue[MAX_POSITION];
    int Tickets[MAX_POSITION];
    double Lots[MAX_POSITION];
    double StopLoss[MAX_POSITION];
    double TakeProfit[MAX_POSITION];
    datetime OpenTime[MAX_POSITION];

    void Clear() {
        ArrayFill(Change, 0, MAX_POSITION, 0);
        ArrayFill(MagicNumber, 0, MAX_POSITION, 0);
        ArrayFill(EntryType, 0, MAX_POSITION, 0);
        ArrayFill(EntryPrice, 0, MAX_POSITION, 0);
        ArrayFill(Tickets, 0, MAX_POSITION, 0);
        for (int i = 0; i < MAX_POSITION; ++i) {
            SymbolValue[i] = "";
        }
        ArrayFill(Lots, 0, MAX_POSITION, 0.0);
        ArrayFill(StopLoss, 0, MAX_POSITION, 0.0);
        ArrayFill(TakeProfit, 0, MAX_POSITION, 0.0);
        ArrayFill(OpenTime, 0, MAX_POSITION, 0);
    }
};

// ポジション全体を表す構造体です
// 添字0と1で交互に現在と前回のポジションの状況を保持します
POSITION_LIST Positions[2];

// ポジション全体を表す構造体配列の添字で
// 0と1のどちらが現在を表すか示すフラグです
bool CurrentIndex;

// 通信用タブ区切りファイルに書き出す
// ポジション全体の差分を表す構造体です
POSITION_LIST Output;

// コピーポジション連携用タブ区切りファイルの個数です
int CommunacationDirCount = 0;

// コピーポジション連携用タブ区切りファイルのプレフィックスの配列です
string CommunacationPathDir[];

// シンボル名の変換("変換前シンボル名|変換後シンボル名"のカンマ区切り)
struct SYMBOL_CONVERSION {
    int Count;
    string Before[];
    string After[];
};
SYMBOL_CONVERSION SymbolConversion;

// 送信元証券会社名です
string SenderBroker;

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
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
#ifdef __CHECK_EXPERT_NAME
    // EAの名前をチェック
    const string EXPART_NAME = "CopyPositionSenderEA-Ver.1.01";
    string ExpertName = MQLInfoString(MQL_PROGRAM_NAME);
    if (ExpertName != EXPART_NAME) {
        string error_message = StringFormat("EAのファイル名を「%s.ex4」からリネームしないで下さい。", EXPART_NAME);
        MessageBox(error_message, "エラー", MB_ICONSTOP | MB_OK);
        return INIT_FAILED;
    }
#endif // __CHECK_EXPERT_NAME

    // EA開始時刻です
    StartServerTimeEA = TimeCurrent();
    
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
    
    // ポジション全体を表す構造体を
    // 添字0と1の両方(現在と前回の両方)を初期化します
    for (int i = 0; i < 2; ++i) {
        Positions[i].Clear();
    }

    // 添字0を現在のポジション状態にします
    CurrentIndex = (bool)0;

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| INIファイルより設定値を初期化します                              |
//+------------------------------------------------------------------+
bool Initialize()
{
    // センダー側を識別する証券会社名+口座番号を取得します
    SenderBroker = AccountInfoString(ACCOUNT_COMPANY);
    string sender_name = GetBrokerAccount(SenderBroker, AccountInfoInteger(ACCOUNT_LOGIN));

    // Commonデータフォルダのパスを取得します
    string appdata_dir = "";
    uint appdata_dir_length = GetEnvironmentVariable("appdata", appdata_dir, 1024);
    if (appdata_dir_length == 0) {
        string error_message = "※エラー: 環境変数 appdata の値の取得に失敗しました";
        printf(error_message);
        MessageBox(error_message, "エラー", MB_ICONERROR);
        return false;
    } 
    string common_data_dir = appdata_dir + "\\MetaQuotes\\Terminal\\Common\\Files";

    // センダー側設定のINIファイルパスをログ出力します
    string inifile_name = StringFormat("CopyPositionEA\\Sender-%s.ini", sender_name);
    inifile_path = StringFormat("%s\\%s", common_data_dir, inifile_name);
    printf("●センダー側設定INIファイルは「%s」です。", inifile_path);
    printf("●センダー側証券会社名は「%s」です。", AccountInfoString(ACCOUNT_COMPANY));
    printf("●センダー側口座番号は「%d」です。", AccountInfoInteger(ACCOUNT_LOGIN));

    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        string error_message = "※エラー: センダー側設定INIファイルが見つかりません。\n" +
                               StringFormat("●センダー側証券会社名は「%s」です。\n", AccountInfoString(ACCOUNT_COMPANY)) +
                               StringFormat("●センダー側口座番号は「%d」です。", AccountInfoInteger(ACCOUNT_LOGIN));
        ERROR(error_message);
        return false;
    }

    string sender_broker = "";
    if (GetPrivateProfileString("Sender", "BROKER", NONE, sender_broker, 1024, inifile_path) == 0 || sender_broker == NONE || AccountInfoString(ACCOUNT_COMPANY) != sender_broker) {
        string error_message = "※センダー側証券会社名が一致しません: セクション[Sender]のキー\"BROKER\"を見直してください。";
        ERROR(error_message);
        return false;
    }

    string sender_account = "";
    if (GetPrivateProfileString("Sender", "ACCOUNT", NONE, sender_account, 1024, inifile_path) == 0 || sender_account == NONE || AccountInfoInteger(ACCOUNT_LOGIN) != StringToInteger(sender_account)) {
        string error_message = "※センダー側証券会社名が一致しません: セクション[Sender]のキー\"ACCOUNT\"を見直してください。";
        ERROR(error_message);
        return false;
    }

    // ポジションコピー時にシンボル名から削除するサフィックスを自動検索する
    int totalSymbols = SymbolsTotal(false);
    bool existSymbol = false;
    SYMBOL_REMOVE_SUFFIX = "";
    for (int i = 0; i < totalSymbols; i++) {
        string symbolName = SymbolName(i, false);
        if (StringSubstr(symbolName, 0, 6) == "USDJPY") {
            SYMBOL_REMOVE_SUFFIX = symbolName;
            StringReplace(SYMBOL_REMOVE_SUFFIX, "USDJPY", "");
            break;
        }
    }

    // ポジションコピー時のロット数の係数
    string lots_multiply = "";
    GetPrivateProfileString("Sender", "LOTS_MULTIPLY", NONE, lots_multiply, 1024, inifile_path);
    LOTS_MULTIPLY = lots_multiply == NONE ? 1.0 : StringToDouble(lots_multiply);

    // シンボル名の変換("変換前シンボル名|変換後シンボル名"のカンマ区切り)
    string symbol_conversion_list = "";
    GetPrivateProfileString("Sender", "SYMBOL_CONVERSION", NONE, symbol_conversion_list, 1024, inifile_path);
    InitializeSymbolConversion(symbol_conversion_list);

    // レシーバー側の設定個数を取得
    string reciever_count = "";
    if (GetPrivateProfileString("Sender", "RECIEVER_COUNT", NONE, reciever_count, 1024, inifile_path) == 0 || reciever_count == NONE) {
        string error_message = "※エラー: セクション[Sender]のキー\"RECIEVER_COUNT\"が見つかりません。";
        ERROR(error_message);
        return false;
    }
    CommunacationDirCount = (int)StringToInteger(reciever_count);
    printf("●%d個のレシーバー側にポジションをコピーします。", CommunacationDirCount);

    for (int i = 0; i < CommunacationDirCount; ++i) {
        string section_name = StringFormat("Reciever%03d", i + 1);
        string reciever_broker = "";
        if (GetPrivateProfileString(section_name, "BROKER", NONE, reciever_broker, 1024, inifile_path) == 0 || reciever_broker == NONE) {
            string error_message = StringFormat("※エラー: セクション[%s]のキー\"BROKER\"が見つかりません。", section_name);
            ERROR(error_message);
            return false;
        }

        string reciever_account = "";
        if (GetPrivateProfileString(section_name, "ACCOUNT", NONE, reciever_account, 1024, inifile_path) == 0 || reciever_account == NONE) {
            string error_message = StringFormat("※エラー: セクション[%s]のキー\"ACCOUNT\"が見つかりません。", section_name);
            ERROR(error_message);
            return false;
        }

        string reciever_name = GetBrokerAccount(reciever_broker, StringToInteger(reciever_account));
        ArrayResize(CommunacationPathDir, i + 1);
        CommunacationPathDir[i] = StringFormat("CopyPositionEA\\%s\\%s", sender_name, reciever_name);

        // ポジションコピー連携ファイル用フォルダを作成する
        if (!FolderCreate(CommunacationPathDir[i], FILE_COMMON)) {
            string error_message = StringFormat("※エラー: コピー連携ファイルのフォルダーの作成に失敗しました: \"%s\"", CommunacationPathDir[i]);
            ERROR(error_message);
            return false;
        }

        printf("[%03d]レシーバー側の証券会社は「%s」です。", i + 1, reciever_broker);
        printf("[%03d]レシーバー側の口座番号は「%s」です。", i + 1, reciever_account);
        printf("[%03d]レシーバー側からのポジションコピーフォルダは「%s」です。", i + 1, CommunacationPathDir[i]);
    }

    printf("●コピーポジションの送信監視を開始します。");
    return true;
}

//+------------------------------------------------------------------+
//| 証券会社名と口座番号の組の文字列を返します                       |
//+------------------------------------------------------------------+
string GetBrokerAccount(string& broker, long account)
{
    StringReplace(broker, " ", "_");
    StringReplace(broker, ",", "");
    StringReplace(broker, ".", "");
    return StringFormat("%s-%d", broker, account);
}

//+------------------------------------------------------------------+
//| シンボル名の変換情報を初期化します                               |
//+------------------------------------------------------------------+
void InitializeSymbolConversion(string symbol_conversion_list)
{
    if (symbol_conversion_list == NONE) {
        SymbolConversion.Count = 0;
        return;
    }

    string symbol_conversion[];
    SymbolConversion.Count = StringSplit(symbol_conversion_list, ',', symbol_conversion);
    ArrayResize(SymbolConversion.Before, SymbolConversion.Count);
    ArrayResize(SymbolConversion.After, SymbolConversion.Count);
    for (int i = 0; i < SymbolConversion.Count; ++i) {
        string conversion[];
        StringSplit(symbol_conversion[i], '|', conversion);
        SymbolConversion.Before[i] = conversion[0];
        SymbolConversion.After[i] = conversion[1];
    }
}

//+------------------------------------------------------------------+
//| シンボル名の変換を行います                                       |
//+------------------------------------------------------------------+
string ConvertSymbol(string symbol_before)
{
    for (int i = 0; i < SymbolConversion.Count; ++i) {
        if (SymbolConversion.Before[i] == symbol_before) {
            return SymbolConversion.After[i];
        }
    }

    return symbol_before;
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
    // 100ミリ秒の周期でポジション全体の差分をタブ区切りファイルに保存します
    SavePosition();
}

//+------------------------------------------------------------------+
//| ポジション全体の差分をタブ区切りファイルに保存します             |
//+------------------------------------------------------------------+
void SavePosition()
{
    // 出力するポジション全体の差分を表す構造体をクリアします
    Output.Clear();

    // 現在のポジション全体の状態を走査します
    // 戻り値 position_count は現在のポジションの総数です
    int current = (int)CurrentIndex;
    int position_count = ScanCurrentPositions(Positions[current]);

    // ポジションの差分を走査します
    int previous = (int)!CurrentIndex;

    // 追加されたポジション全体の状態を走査します
    // 戻り値 change_count は差分の総数です
    int change_count = ScanAddedPositions(Positions[current], Positions[previous], position_count, 0);

    // 削除されたポジション全体の状態を走査します
    // 戻り値 change_count は差分の総数です
    change_count = ScanRemovedPositions(Positions[current], Positions[previous], position_count, change_count);

    // 現在のポジション状態の添字と前回のポジション状態の添字を入れ替えます
    CurrentIndex = !CurrentIndex;

    // ポジションの差分が0件ならばファイル出力しません
    if (change_count == 0) {
        return;
    }

    // コピーポジション連携用タブ区切りファイルを出力します
    for (int i = 0; i < CommunacationDirCount; ++i) {
        OutputPositionDeffference(CommunacationPathDir[i], change_count);
    }
}

//+------------------------------------------------------------------+
//| 現在のポジション全体の状態を走査します                           |
//+------------------------------------------------------------------+
int ScanCurrentPositions(POSITION_LIST& Current)
{
    // 現在のポジション状態を取得する前に
    // 現在の添字が指す配列要素をクリアします
    Current.Clear();

    // 現在のポジション状態を全て取得します
    int position_count = 0;
    for (int i = 0; i < OrdersTotal(); ++i) {
        // トレード中のポジションを選択します
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { continue; }

        // EA起動時よりも過去に建てられたポジションはコピー対象外です
        if (OrderOpenTime() <= StartServerTimeEA) { continue;}

        int entry_type = 0;
        switch (OrderType()) {
        case OP_BUY:
            entry_type = +1;
            break;
        case OP_BUYLIMIT:
            entry_type = +2;
            break;
        case OP_BUYSTOP:
            entry_type = +3;
            break;
        case OP_SELL:
            entry_type = -1;
            break;
        case OP_SELLLIMIT:
            entry_type = -2;
            break;
        case OP_SELLSTOP:
            entry_type = -3;
            break;
        default:
            continue;
        }

        Current.Change[position_count] = INT_MAX;
        Current.EntryType[position_count] = entry_type;
        Current.EntryPrice[position_count] = OrderOpenPrice();
        Current.SymbolValue[position_count] = OrderSymbol();
        Current.Tickets[position_count] = OrderTicket();
        Current.Lots[position_count] = OrderLots();
        Current.StopLoss[position_count] = OrderStopLoss();
        Current.TakeProfit[position_count] = OrderTakeProfit();
        Current.OpenTime[position_count] = OrderOpenTime();
        ++position_count;
    }

    return position_count;
}

//+------------------------------------------------------------------+
//| 追加されたポジション全体の状態を走査します                       |
//+------------------------------------------------------------------+
int ScanAddedPositions(POSITION_LIST& Current, POSITION_LIST& Previous, int position_count, int change_count)
{
    // 外側のカウンタ current のループで現在のポジション全体をスキャンします
    for (int current = 0; current < position_count; ++current) {
        bool added = true; // ポジション追加フラグ

        // 内側のカウンタ previous のループで前回のポジション全体をスキャンします
        for (int previous = 0; Previous.Tickets[previous] != 0 && previous < MAX_POSITION; ++previous) {
            // EA起動時よりも過去に建てられたポジションはコピー対象外です
            if (Previous.OpenTime[previous] <= StartServerTimeEA) { continue; }

            // チケット番号が一致するとき、
            if (Previous.Tickets[previous] == Current.Tickets[current]) {
                // エントリー価格またはストップロスまたはテイクプロフィットのいずれかが不一致ならば変化ありです
                if ((Previous.EntryPrice[previous] != Current.EntryPrice[current]) ||
                    (Previous.StopLoss[previous] != Current.StopLoss[current]) ||
                    (Previous.TakeProfit[previous] != Current.TakeProfit[current])) {
                    change_count = AppendChangedPosition(Current, POSITION_MODIFY, change_count, current);
                    added = false;
                    break;               
                }
                else {
                    // チケット番号・ストップロス・テイクプロフィットが完全一致なので変化なしです
                    added = false;
                    break;
                }
            }
        }

        // チケット番号が不一致のとき、ポジション追加です
        if (added) {
            change_count = AppendChangedPosition(Current, POSITION_ADD, change_count, current);                 
        }
    }

    return change_count;
}

//+------------------------------------------------------------------+
//| 削除されたポジション全体の状態を走査します                       |
//+------------------------------------------------------------------+
int ScanRemovedPositions(POSITION_LIST& Current, POSITION_LIST& Previous, int position_count, int change_count)
{
    // 外側のカウンタ previous のループで前回のポジション全体をスキャンします
    for (int previous = 0; Previous.Tickets[previous] != 0 && previous < MAX_POSITION; ++previous) {
        bool removed = true; // ポジション削除フラグ

        // 内側のカウンタ current のループで現在のポジション全体をスキャンします
        for (int current = 0; current < position_count; ++current) {
            // チケット番号が一致したらポジションに変化はありません
            // ポジション修正は ScanAddedPositions() で確認済みです
            if (Previous.Tickets[previous] == Current.Tickets[current]) {
                removed = false;
                break;
            }
        }

        // チケット番号が不一致のとき、ポジション削除です
        if (removed) {
            change_count = AppendChangedPosition(Previous, POSITION_REMOVE, change_count, previous);                 
        }
    }

    return change_count;
}

//+------------------------------------------------------------------+
//| 出力する差分情報構造体にポジションの要素を追記します             |
//+------------------------------------------------------------------+
int AppendChangedPosition(POSITION_LIST& Current, ENUM_POSITION_OPERATION change, int dst, int src)
{
    Output.Change[dst] = change;
    Output.Tickets[dst] = Current.Tickets[src];
    Output.EntryType[dst] = Current.EntryType[src];
    Output.EntryPrice[dst] = Current.EntryPrice[src];
    Output.SymbolValue[dst] = Current.SymbolValue[src];
    Output.Lots[dst] = Current.Lots[src];
    Output.StopLoss[dst] = Current.StopLoss[src];
    Output.TakeProfit[dst] = Current.TakeProfit[src];
    return ++dst;
}

//+------------------------------------------------------------------+
//| コピーポジション連携用タブ区切りファイルを出力します             |
//+------------------------------------------------------------------+
void OutputPositionDeffference(string output_path_prefix, int change_count)
{
    // システムが開始されてから経過したミリ秒数を取得します
    ulong epoch = GetTickCount64();

    // コピーポジション連携用タブ区切りファイルのファイル名
    string path = StringFormat("%s\\%020u.tsv", output_path_prefix, epoch);

    // ファイルをオープンします
    int file = FileOpen(path, FILE_WRITE | FILE_TXT |FILE_ANSI | FILE_COMMON, '\t', CP_ACP);

    // ファイルのオープンに失敗した場合は、ログを出力して処理を中断します
    if (file == INVALID_HANDLE) {
        printf("※コピーポジション連携用タブ区切りファイルのオープンに失敗しました: %s", path);
        return;
    }

    // ポジションの差分をコピーポジション連携用タブ区切りファイルに出力します
    for (int i = 0; i < change_count; ++i) {
        string symbol = Output.SymbolValue[i];
        StringReplace(symbol, SYMBOL_REMOVE_SUFFIX, "");
        // タブ区切りファイルの仕様
        // 0列目：送信元証券会社名
        string line = SenderBroker + "\t";
        // 1列目：+1: ポジション追加 ／ -1: ポジション削除 ／ 0: ポジション修正
        line += StringFormat("%+d\t", Output.Change[i]);
        // 2列目：マジックナンバー
        line += StringFormat("%d\t", Output.MagicNumber[i]);
        // 3列目：エントリー種別
        line += StringFormat("%d\t", Output.EntryType[i]);
        // 4列目：エントリー価格
        line += StringFormat("%.6f\t", Output.EntryPrice[i]);
        // 5列目：シンボル名
        line += StringFormat("%s\t", ConvertSymbol(symbol));
        // 6列目：コピー元チケット番号
        line += StringFormat("%d\t", Output.Tickets[i]);
        // 7列目：ポジションサイズ
        line += StringFormat("%.2f\t", LOTS_MULTIPLY * Output.Lots[i]);
        // 8列目：ストップロス
        line += StringFormat("%.6f\t", Output.StopLoss[i]);
        // 9列目：テイクプロフィット
        line += StringFormat("%.6f", Output.TakeProfit[i]);

        string logging_line = line;
        StringReplace(logging_line, "\t", " ");
        printf("ポジションコピー送信: " + logging_line);

        FileWrite(file, line);
    }

    FileClose(file);

    // 出力したコピーポジション連携用タブ区切りファイルのファイル名をログ出力します
    printf("⇒連携ファイル: \"%s\"", path);
}