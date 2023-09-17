//+------------------------------------------------------------------+
//|                                          CopyPositionSederEA.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include "CopyPositionEA.mqh"

SYMBOL_CONVERSION SymbolConversion;

string  SYMBOL_REMOVE_SUFFIX; // ポジションコピー時にシンボル名から削除するサフィックス
double  LOTS_MULTIPLY;        // ポジションコピー時のロット数の係数

#define MAX_POSITION 1024

//+------------------------------------------------------------------+
//| ポジション全体を表す構造体です                                   |
//+------------------------------------------------------------------+
struct POSITION_LIST {
    int Change[MAX_POSITION];
    int MagicNumber[MAX_POSITION];
    datetime EntryDate[MAX_POSITION];
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
        ArrayFill(EntryDate, 0, MAX_POSITION, 0);
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

// 送信元証券会社名です
string SenderBroker;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
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
    string SenderAccount = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    string sender_name = GetBrokerAccountName(SenderBroker, SenderAccount);

    // センダー側設定のINIファイルパスをログ出力します
    string inifile_name = "";
    string inifile_path = "";
    CreateSettingPath(sender_name, true, inifile_name, inifile_path);
    printf("●センダー側設定INIファイルは「%s」です。", inifile_path);
    printf("●センダー側証券会社名は「%s」です。", SenderBroker);
    printf("●センダー側口座番号は「%s」です。", SenderAccount);

    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        string error_message = "※エラー: センダー側設定INIファイルが見つかりません。\n" +
                               StringFormat("●センダー側証券会社名は「%s」です。\n", AccountInfoString(ACCOUNT_COMPANY)) +
                               StringFormat("●センダー側口座番号は「%d」です。", AccountInfoInteger(ACCOUNT_LOGIN));
        ERROR(inifile_path, error_message);
        CreateSenderINI(SenderBroker, SenderAccount, "レシーバー側証券会社名", "レシーバー側口座番号");
        return false;
    }

    string sender_broker = "";
    if (GetPrivateProfileString("Sender", "BROKER", NONE, sender_broker, 1024, inifile_path) == 0 || sender_broker == NONE || AccountInfoString(ACCOUNT_COMPANY) != sender_broker) {
        string error_message = "※センダー側証券会社名が一致しません: セクション[Sender]のキー\"BROKER\"を見直してください。";
        ERROR(inifile_path, error_message);
        return false;
    }

    string sender_account = "";
    if (GetPrivateProfileString("Sender", "ACCOUNT", NONE, sender_account, 1024, inifile_path) == 0 || sender_account == NONE || AccountInfoInteger(ACCOUNT_LOGIN) != StringToInteger(sender_account)) {
        string error_message = "※センダー側口座番号が一致しません: セクション[Sender]のキー\"ACCOUNT\"を見直してください。";
        ERROR(inifile_path, error_message);
        return false;
    }

    // ポジションコピー時にシンボル名から削除するサフィックスを自動検索する
    SYMBOL_REMOVE_SUFFIX = GetSymbolSuffix(true);

    // ポジションコピー時のロット数の係数
    string lots_multiply = "";
    GetPrivateProfileString("Sender", "LOTS_MULTIPLY", NONE, lots_multiply, 1024, inifile_path);
    LOTS_MULTIPLY = lots_multiply == NONE ? 1.0 : StringToDouble(lots_multiply);

    // シンボル名の変換("変換前シンボル名|変換後シンボル名"のカンマ区切り)
    string symbol_conversion_list = "";
    GetPrivateProfileString("Sender", "SYMBOL_CONVERSION", NONE, symbol_conversion_list, 1024, inifile_path);
    InitializeSymbolConversion(symbol_conversion_list);

    // レシーバー側の設定個数を取得
    string receiver_count = "";
    if (GetPrivateProfileString("Sender", "RECIEVER_COUNT", NONE, receiver_count, 1024, inifile_path) == 0 || receiver_count == NONE) {
        string error_message = "※エラー: セクション[Sender]のキー\"RECIEVER_COUNT\"が見つかりません。";
        ERROR(inifile_path, error_message);
        return false;
    }
    CommunacationDirCount = (int)StringToInteger(receiver_count);
    printf("●%d個のレシーバー側にポジションをコピーします。", CommunacationDirCount);

    for (int i = 0; i < CommunacationDirCount; ++i) {
        string section_name = StringFormat("Receiver%03d", i + 1);
        string receiver_broker = "";
        string receiver_account = "";
        if (!GetBrokerAccountPair(inifile_path, section_name, receiver_broker, receiver_account)) {
            return false;
        }

        // レシーバー側設定INIファイルの存在確認
        string receiver_name = GetBrokerAccountName(receiver_broker, receiver_account);
        if (!CheckReceiverSetting(inifile_path, section_name, receiver_broker, receiver_account, SenderBroker, SenderAccount)) {
            return false;
        }

        ArrayResize(CommunacationPathDir, i + 1);
        CommunacationPathDir[i] = StringFormat("CopyPositionEA\\%s\\%s", sender_name, receiver_name);

        // ポジションコピー連携ファイル用フォルダを作成する
        if (!FolderCreate(CommunacationPathDir[i], FILE_COMMON)) {
            string error_message = StringFormat("※エラー: コピー連携ファイルのフォルダーの作成に失敗しました: \"%s\"", CommunacationPathDir[i]);
            ERROR(inifile_path, error_message);
            return false;
        }

        printf("[%03d]レシーバー側の証券会社は「%s」です。", i + 1, receiver_broker);
        printf("[%03d]レシーバー側の口座番号は「%s」です。", i + 1, receiver_account);
        printf("[%03d]レシーバー側からのポジションコピーフォルダは「%s」です。", i + 1, CommunacationPathDir[i]);
    }

    printf("●コピーポジションの送信監視を開始します。");
    return true;
}

//+------------------------------------------------------------------+
//| レシーバー側の設定を確認します                                   |
//+------------------------------------------------------------------+
bool CheckReceiverSetting(string base_inifile_path, string base_section_name, string receiver_broker, string receiver_account, string sender_broker, string sender_account)
{
    if (StringFind(receiver_broker, "側") != -1) {
        string error_message = StringFormat("レシーバー側証券会社名がテンプレートから変更されていません。\n※セクション:\n[%s]", base_section_name); 
        ERROR(base_inifile_path, error_message);
        return false;
    }

    if (StringFind(receiver_account, "側") != -1) {
        string error_message = StringFormat("レシーバー側口座番号がテンプレートから変更されていません。\n※セクション:\n[%s]", base_section_name); 
        ERROR(base_inifile_path, error_message);
        return false;
    }

    string receiver_name = GetBrokerAccountName(receiver_broker, receiver_account);
    string inifile_name = "";
    string inifile_path = "";
    CreateSettingPath(receiver_name, false, inifile_name, inifile_path);
    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        string error_message = "※エラー: レシーバー側設定INIファイルが見つかりません。\n" +
                               StringFormat("●レシーバー側証券会社名は「%s」です。\n", receiver_broker) +
                               StringFormat("●レシーバー側口座番号は「%s」です。", receiver_account);
        ERROR(inifile_path, error_message);
        CreateReciverINI(receiver_broker, receiver_account, sender_broker, sender_account);
        return false;
    }

    // レシーバー側設定INIファイルのセンダー側の設定個数を取得
    string setting_count_text = "";
    if (GetPrivateProfileString("Receiver", "SENDER_COUNT", NONE, setting_count_text, 1024, inifile_path) == 0 || setting_count_text == NONE) {
        string error_message = "※エラー: セクション[Receiver]のキー\"SENDER_COUNT\"が見つかりません。";
        ERROR(inifile_path, error_message);
        return false;
    }

    long setting_count = StringToInteger(setting_count_text);
    for (int i = 0; i < setting_count; ++i) {
        string section_name = StringFormat("Sender%03d", i + 1);
        string broker = "";
        string account = "";
        if (!GetBrokerAccountPair(inifile_path, section_name, broker, account)) {
            return false;
        }
        if (broker == sender_broker && account == sender_account) {
            return true;
        }
    }

    string error_message = StringFormat("※エラー: セクション[Receiver]の中に「%s」と「%s」の設定が見つかりません。", sender_broker, sender_account);
    ERROR(inifile_path, error_message);
    return false;
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
    int file = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON, '\t', CP_ACP);

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
        // 3列目：エントリー時刻
        line += StringFormat("%d\t", TimeToString(Output.EntryDate[i], TIME_DATE | TIME_MINUTES | TIME_SECONDS));
        // 4列目：エントリー種別
        line += StringFormat("%d\t", Output.EntryType[i]);
        // 5列目：エントリー価格
        line += StringFormat("%.6f\t", Output.EntryPrice[i]);
        // 6列目：シンボル名
        line += StringFormat("%s\t", ConvertSymbol(symbol));
        // 7列目：コピー元チケット番号
        line += StringFormat("%d\t", Output.Tickets[i]);
        // 8列目：ポジションサイズ
        line += StringFormat("%.2f\t", LOTS_MULTIPLY * Output.Lots[i]);
        // 9列目：ストップロス
        line += StringFormat("%.6f\t", Output.StopLoss[i]);
        // 10列目：テイクプロフィット
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