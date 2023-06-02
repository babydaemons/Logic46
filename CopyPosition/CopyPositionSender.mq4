//+------------------------------------------------------------------+
//|                                            CopyPositionSeder.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.00"
#property strict

#import "kernel32.dll"
uint GetEnvironmentVariableW(
    string name,
    string& returnValue,
    uint bufferSize
);
#import

#import "kernel32.dll"
uint GetPrivateProfileStringW(
    string sectionName,
    string keyName,
    string defaultValue,
    string& returnValue,
    uint bufferSize,
    string iniFilePath);
#import

#import "kernel32.dll"
ulong GetTickCount64();
#import

int     UPDATE_INTERVAL;      // ポジションコピーを行うインターバル(ミリ秒)
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
    string SymbolValue[MAX_POSITION];
    int Tickets[MAX_POSITION];
    double Lots[MAX_POSITION];
    double StopLoss[MAX_POSITION];
    double TakeProfit[MAX_POSITION];

    void Clear() {
        ArrayFill(Change, 0, MAX_POSITION, 0);
        ArrayFill(MagicNumber, 0, MAX_POSITION, 0);
        ArrayFill(EntryType, 0, MAX_POSITION, 0);
        ArrayFill(Tickets, 0, MAX_POSITION, 0);
        for (int i = 0; i < MAX_POSITION; ++i) {
            SymbolValue[i] = "";
        }
        ArrayFill(Lots, 0, MAX_POSITION, 0.0);
        ArrayFill(StopLoss, 0, MAX_POSITION, 0.0);
        ArrayFill(TakeProfit, 0, MAX_POSITION, 0.0);
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

// コピーしたいマジックナンバーの配列です
int MagicNumbers[];

// コピーポジション連携用タブ区切りファイルの個数です
int CommunacationFileCount = 0;

// コピーポジション連携用タブ区切りファイルのプレフィックスの配列です
string CommunacationPathPrefix[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // INIファイルより設定値を初期化します
    if (!Initialize()) {
        return INIT_FAILED;
    }

    // パラメータ UPDATE_INTERVAL で指定されたミリ秒の周期で
    // ポジションコピーを行います
    EventSetMillisecondTimer(UPDATE_INTERVAL);
    
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
    string sender_name = GetBrokerAccount(AccountInfoString(ACCOUNT_COMPANY), AccountInfoInteger(ACCOUNT_LOGIN));

    // Commonデータフォルダのパスを取得します
    string appdata_dir = "";
    uint appdata_dir_length = GetEnvironmentVariableW("appdata", appdata_dir, 1024);
    if (appdata_dir_length == 0) {
        printf("エラー: 環境変数 appdata の値の取得に失敗しました");
        return false;
    } 
    string common_data_dir = appdata_dir + "\\MetaQuotes\\Terminal\\Common\\Files";

    // センダー側設定のINIファイルパスをログ出力します
    string inifile_name = StringFormat("CopyPositionEA\\Sender-%s.ini", sender_name);
    string inifile_path = StringFormat("%s\\%s", common_data_dir, inifile_name);
    printf("センダー側設定INIファイルは「%s」です。", inifile_path);

    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        printf("エラー: センダー側設定INIファイル「%s」が見つかりません。", inifile_path);
        return false;
    }

    const string NONE = "<NONE>";

    // ポジションコピーを行うインターバル(ミリ秒)
    string update_interval = "";
    if (GetPrivateProfileStringW("Sender", "UPDATE_INTERVAL", NONE, update_interval, 1024, inifile_path) == 0 || update_interval == NONE) {
        printf("エラー: セクション[Sender]のキー\"UPDATE_INTERVAL\"が見つかりません。");
        return false;
    }
    UPDATE_INTERVAL = (int)StringToInteger(update_interval);

    // ポジションコピー時にシンボル名から削除するサフィックス
    string symbol_remove_suffix = "";
    GetPrivateProfileStringW("Sender", "SYMBOL_REMOVE_SUFFIX", NONE, symbol_remove_suffix, 1024, inifile_path);
    SYMBOL_REMOVE_SUFFIX = symbol_remove_suffix == NONE ? "" : symbol_remove_suffix;

    // ポジションコピー時のロット数の係数
    string lots_multiply = "";
    GetPrivateProfileStringW("Sender", "LOTS_MULTIPLY", NONE, lots_multiply, 1024, inifile_path);
    LOTS_MULTIPLY = lots_multiply == NONE ? 1.0 : StringToDouble(lots_multiply);

    // コピーしたいマジックナンバーの配列を初期化します
    string copy_magic_numbers = "";
    if (GetPrivateProfileStringW("Sender", "COPY_MAGIC_NUMBERS", NONE, copy_magic_numbers, 1024, inifile_path) == 0 || copy_magic_numbers == NONE) {
        return false;
    }
    string magic_numbers[];
    int magic_number_count = StringSplit(copy_magic_numbers, ',', magic_numbers);
    ArrayResize(MagicNumbers, magic_number_count);
    for (int i = 0; i < magic_number_count; ++i) {
        MagicNumbers[i] = (int)StringToInteger(magic_numbers[i]);
    }
    ArraySort(MagicNumbers);

    int i = 0;
    while (true) {
        string section_name = StringFormat("Reciever%03d", i + 1);
        string reciever_broker = "";
        if (GetPrivateProfileStringW(section_name, "BROKER", NONE, reciever_broker, 1024, inifile_path) == 0 || reciever_broker == NONE) {
            break;
        }
        printf("レシーバー側[%03d]の証券会社は「%s」です。", i + 1, reciever_broker);

        string reciever_account = "";
        if (GetPrivateProfileStringW(section_name, "ACCOUNT", NONE, reciever_account, 1024, inifile_path) == 0 || reciever_account == NONE) {
            break;
        }
        printf("レシーバー側[%03d]の口座番号は「%s」です。", i + 1, reciever_account);

        string reciever_name = GetBrokerAccount(reciever_broker, StringToInteger(reciever_account));
        ArrayResize(CommunacationPathPrefix, i + 1);
        CommunacationPathPrefix[i] = StringFormat("CopyPositionEA\\%s\\%s\\", sender_name, reciever_name);
        FolderCreate(CommunacationPathPrefix[i], true);
        CommunacationFileCount = ++i;
    }

    return true;
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

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // タイマーを破棄します
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 気配値が更新されたタイミングで
    // ポジション全体の差分をタブ区切りファイルに保存します
    SavePosition();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    // パラメータ UPDATE_INTERVAL で指定されたミリ秒の周期で
    // ポジション全体の差分をタブ区切りファイルに保存します
    // OnTick()で十分なはずですが万が一のための保険です
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
    for (int i = 0; i < CommunacationFileCount; ++i) {
        OutputPositionDeffference(CommunacationPathPrefix[i], change_count);
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

        // コピーしたいマジックナンバーかチェックします
        int magic_number = OrderMagicNumber();
        int index = ArrayBsearch(MagicNumbers, magic_number);
        if (magic_number != MagicNumbers[index]) { continue; }

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
        Current.SymbolValue[position_count] = OrderSymbol();
        Current.Tickets[position_count] = OrderTicket();
        Current.Lots[position_count] = OrderLots();
        Current.StopLoss[position_count] = OrderStopLoss();
        Current.TakeProfit[position_count] = OrderTakeProfit();
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
            // チケット番号が一致するとき、
            if (Previous.Tickets[previous] == Current.Tickets[current]) {
                // ストップロスまたはテイクプロフィットのいずれかが不一致ならば変化ありです
                if ((Previous.StopLoss[previous] != Current.StopLoss[current]) ||
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
        printf("コピーポジション連携用タブ区切りファイルのオープンに失敗しました: %s", path);
        return;
    }

    // ポジションの差分をコピーポジション連携用タブ区切りファイルに出力します
    for (int i = 0; i < change_count; ++i) {
        string symbol = Output.SymbolValue[i];
        StringReplace(symbol, SYMBOL_REMOVE_SUFFIX, "");
        // タブ区切りファイルの仕様
        // 0列目：+1: ポジション追加 ／ -1: ポジション削除 ／ 0: ポジション修正
        string line = StringFormat("%+d\t", Output.Change[i]);
        // 1列目：マジックナンバー
        line += StringFormat("%d\t", Output.MagicNumber[i]);
        // 2列目：エントリー種別
        line += StringFormat("%d\t", Output.EntryType[i]);
        // 3列目：シンボル名
        line += StringFormat("%s\t", symbol);
        // 4列目：コピー元チケット番号
        line += StringFormat("%d\t", Output.Tickets[i]);
        // 5列目：ポジションサイズ
        line += StringFormat("%.2f\t", LOTS_MULTIPLY * Output.Lots[i]);
        // 6列目：ストップロス
        line += StringFormat("%.6f\t", Output.StopLoss[i]);
        // 7列目：テイクプロフィット
        line += StringFormat("%.6f\t", Output.TakeProfit[i]);
        FileWrite(file, line);
    }

    FileClose(file);
}