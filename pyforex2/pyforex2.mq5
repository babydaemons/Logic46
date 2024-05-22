//+------------------------------------------------------------------+
//|                                                      pyforex.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

const int FIVE_MINUTES = 1;
const int HOUR_MINUTES = 12 * FIVE_MINUTES;
const int DAY_MINUES = 24 * HOUR_MINUTES;
const int PREDICT_MINUTES = 4 * HOUR_MINUTES;
const int LEARNING_ROW_COUNT = (200 + 1) * DAY_MINUES + PREDICT_MINUTES;
const int PREDICT_ROW_COUNT = (20 + 1) * DAY_MINUES + PREDICT_MINUTES;
const int BARS = 60;

#import "pyforex.dll"

string PipeName;
string CommonFolerPath;
string DataFolerPath;
string LearningResponsePath;
string ModulePath;
int PipeHandle = INVALID_HANDLE;
int LoggingFile = INVALID_HANDLE;
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

    ModulePath = CommonFolerPath + "\\Files\\pyforex_loader3.bat";
    //ModulePath = CommonFolerPath + "\\Files\\pyforex.exe";

    LoggingFile = FileOpen("pyforex\\pyforex_logging.tsv", FILE_WRITE | FILE_COMMON, CP_UTF8);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    PyForexAPI::TerminateProcess();
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
        PyForexAPI::CreateProcess(ModulePath, CommonFolerPath, PipeName, PREDICT_MINUTES, BARS);
        string pipe_path = "\\\\.\\pipe\\pyforex_" + PipeName;
        PipeHandle = PipeOpen(pipe_path, FILE_WRITE | FILE_READ | FILE_BIN | FILE_ANSI);

        HasCreated = true;
        do_learning = true;
    }

    if (t.day_of_week < FRIDAY) {
        HasLearned = false;
    }

    if (do_learning) {
        Learning();
        HasLearned = true;
    }

    double predit_result_value = 0;
    Predict(predit_result_value);
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
        printf("Error = %d", GetLastError());
        PyForexAPI::Sleep(100);
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
bool Learning()
{
    FolderCreate("pyforex", FILE_COMMON);
    FileDelete(LearningResponsePath, FILE_COMMON);

    double valuesM05[];
    int read_count = CopyOpen(Symbol(), PERIOD_M5, 0, LEARNING_ROW_COUNT, valuesM05);
    if (read_count != LEARNING_ROW_COUNT) {
        return false;
    }
    ArrayReverse(valuesM05);

    string command = StringFormat("EXECUTE_LEARNING,%d", LEARNING_ROW_COUNT);
    FileWriteString(PipeHandle, command + "\n");
    FileWriteArray(PipeHandle, valuesM05);

    while (true) {
        if (FileIsExist(LearningResponsePath, FILE_COMMON)) {
            break;
        }
        PyForexAPI::Sleep(100);
    }
    FileDelete(LearningResponsePath, FILE_COMMON);

    return true;
}

//+------------------------------------------------------------------+
//| 予測値の算出                                                     |
//+------------------------------------------------------------------+
bool Predict(double& predict_value)
{
    double close_prices[];
    int read_count = CopyOpen(Symbol(), PERIOD_M5, 0, PREDICT_ROW_COUNT, close_prices);
    if (read_count != PREDICT_ROW_COUNT) {
        return false;
    }

    string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    string command = StringFormat("EXECUTE_PREDICT,%d,%s,%.3f", ArraySize(close_prices) * 8, timestamp, ask);
    uint write_string_length = FileWriteString(PipeHandle, command + "\n");
    uint write_array_count = FileWriteArray(PipeHandle, close_prices);

    string result = "";
    while (true) {
        result = PipeReadLine(PipeHandle);
        if (StringSubstr(result, 0, 4) == "DONE") {
            break;
        }
        PyForexAPI::Sleep(100);
    }

    string predict_value_text = StringSubstr(result, 5);
    predict_value = StringToDouble(predict_value_text);

    string logging_line = StringFormat("%s\t%.3f\t%f\n", TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS), ask, predict_value);
    FileWriteString(LoggingFile, logging_line);
    return true;
}
