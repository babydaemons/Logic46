//+------------------------------------------------------------------+
//|                                                      pyforex.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define SAMPLE_PERIOD PERIOD_H1

const int HOUR_MINUTES = 1;
const int DAY_MINUES = 24 * HOUR_MINUTES;
const int PREDICT_MINUTES = 4 * HOUR_MINUTES;
const int ROW_COUNT_MINUTES = 250 * DAY_MINUES;
const int FETCH_ROW_COUNT = ROW_COUNT_MINUTES + PREDICT_MINUTES;

#import "pyforex.dll"

string PipeName;
string CommonFolerPath;
string DataFolerPath;
string LearningResponsePath;
string ModulePath;
int PipeHandle = INVALID_HANDLE;
bool HasCreated = false;
bool HasLearned = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    DataFolerPath = TerminalInfoString(TERMINAL_DATA_PATH);
    CommonFolerPath = TerminalInfoString(TERMINAL_COMMONDATA_PATH);
    LearningResponsePath = "pyforex\\response_data.txt";

    string fields[];
    StringSplit(DataFolerPath, '\\', fields);
    for (int i = 0; i < ArraySize(fields); i++) {
        if (StringLen(fields[i]) == 32) {
            PipeName = fields[i];
            break;
        }
    }

    ModulePath = CommonFolerPath + "\\Files\\pyforex_loader.bat";
    //ModulePath = CommonFolerPath + "\\Files\\pyforex.exe";

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    PyForexLibrary::TerminateProcess();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    MqlDateTime t = {};
    TimeToStruct(TimeCurrent(), t);
    bool do_learning = false;
    if (!HasLearned && t.day_of_week == FRIDAY && t.hour == 23) {
        do_learning = true;
    }

    if (!HasCreated) {
        PyForexLibrary::CreateProcess(ModulePath, CommonFolerPath, PipeName);
        string pipe_path = "\\\\.\\pipe\\pyforex_" + PipeName;
        PipeHandle = PipeOpen(pipe_path, FILE_WRITE | FILE_READ | FILE_BIN | FILE_ANSI);

        HasCreated = true;
        do_learning = true;
    }

    if (t.day_of_week < FRIDAY) {
        HasLearned = false;
    }

    if (do_learning) {
        RequestLearning();
        ResponseLearning();
        HasLearned = true;
    }

    RequestPredict();
    double predit_result_value = ResponsePredict();
}

//+------------------------------------------------------------------+
//| 名前付きパイプを開く                                             |
//+------------------------------------------------------------------+
int PipeOpen(string pipe_path, int flags)
{
    printf(pipe_path);
    int pipe = INVALID_HANDLE;
    while (true) {
        pipe = FileOpen(pipe_path, flags);
        if (pipe != INVALID_HANDLE) {
            break;
        }
        PyForexLibrary::Sleep(100);
    }
    return pipe;
}

//+------------------------------------------------------------------+
//| 名前付きパイプから1行読む                                        |
//+------------------------------------------------------------------+
string PipeReadLine(int pipe)
{
    string s = "";
    while (true) {
        string c = FileReadString(pipe, 1);
        s += c;
        if (c == "\n") {
            break;
        }
    }
    StringReplace(s, "\r", "");
    return s;
}

//+------------------------------------------------------------------+
//| 学習モデルの生成                                                 |
//+------------------------------------------------------------------+
void RequestLearning()
{
    FolderCreate("pyforex", FILE_COMMON);
    FileDelete(LearningResponsePath, FILE_COMMON);

    double close_prices[];
    CopyOpen(Symbol(), SAMPLE_PERIOD, 0, FETCH_ROW_COUNT, close_prices);

    string command = StringFormat("EXECUTE_LEARNING,%d", ArraySize(close_prices) * 8);
    FileWriteString(PipeHandle, command + "\n");
    FileWriteArray(PipeHandle, close_prices);
}

//+------------------------------------------------------------------+
//| 学習モデルの生成                                                 |
//+------------------------------------------------------------------+
void ResponseLearning()
{
    while (true) {
        if (FileIsExist(LearningResponsePath, FILE_COMMON)) {
            break;
        }
        PyForexLibrary::Sleep(100);
    }
    FileDelete(LearningResponsePath, FILE_COMMON);
}

//+------------------------------------------------------------------+
//| 予測値の算出                                                     |
//+------------------------------------------------------------------+
void RequestPredict()
{
    double close_prices[];
    CopyOpen(Symbol(), SAMPLE_PERIOD, 0, 1729, close_prices);

    string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    string command = StringFormat("EXECUTE_PREDICT,%d,%s,%.3f", ArraySize(close_prices) * 8, timestamp, ask);
    FileWriteString(PipeHandle, command + "\n");
    FileWriteArray(PipeHandle, close_prices);
}

//+------------------------------------------------------------------+
//| 予測値の算出                                                     |
//+------------------------------------------------------------------+
double ResponsePredict()
{
    string result = "";
    while (true) {
        result = PipeReadLine(PipeHandle);
        if (StringSubstr(result, 0, 4) == "DONE") {
            break;
        }
        PyForexLibrary::Sleep(100);
    }

    string predict_value_text = StringSubstr(result, 5);
    return StringToDouble(predict_value_text);
}
