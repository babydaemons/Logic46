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
const int LEARNING_ROW_COUNT = (25 + 1) * DAY_MINUES + PREDICT_MINUTES;
const int PREDICT_ROW_COUNT = (10 + 1) * DAY_MINUES + PREDICT_MINUTES;
const int BARS = 90;

#import "pyforex.dll"

string PipeName;
string CommonFolerPath;
string DataFolerPath;
string LearningResponsePath;
string ModulePath;
int PipeHandle = INVALID_HANDLE;
int LoggingFile = INVALID_HANDLE;
bool DoLearning = false;
int PrevLearned = -1;

int hMACD05M = INVALID_HANDLE;
int hMACD01H = INVALID_HANDLE;

enum PYTHON_REQUEST {
    PYTHON_REQUEST_LEARNING = 11111,
    PYTHON_REQUEST_PREDICT = 22222,
    PYTHON_REQUEST_TERMINATE = 33333,
};

#define PYTHON_REQUEST_ARRAY_SIZE 6

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

    //ModulePath = CommonFolerPath + "\\Files\\pyforex_loader3.bat";
    ModulePath = CommonFolerPath + "\\Files\\pyforex.exe";

    LoggingFile = FileOpen("pyforex\\pyforex_logging.tsv", FILE_WRITE | FILE_COMMON, CP_UTF8);

    hMACD05M = iMACD(Symbol(), PERIOD_M5, 12, 26, 9, PRICE_OPEN);
    hMACD01H = iMACD(Symbol(), PERIOD_H1, 12, 26, 9, PRICE_OPEN);

    DoLearning = true;

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    MqlDateTime date = {};
    TimeCurrent(date);
    if (date.day_of_year != PrevLearned) {
        DoLearning = true;
    }

    if (DoLearning) {
        if (PrevLearned != -1) {
            Terminate();
        }
        if (!Learning()) {
            return;
        }
        PrevLearned = date.day_of_year;
        DoLearning =false;
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
    double buffer[];
    if (!CreateBuffer(LEARNING_ROW_COUNT, LEARNING_ROW_COUNT, LEARNING_ROW_COUNT, buffer)) {
        return false;
    }
    ExpertRemove();
    return true;
}

//+------------------------------------------------------------------+
//| 予測値の算出                                                     |
//+------------------------------------------------------------------+
bool Predict(double& predict_value)
{
    double buffer[];
    if (!CreateBuffer(PREDICT_ROW_COUNT, PREDICT_ROW_COUNT, PREDICT_ROW_COUNT, buffer)) {
        return false;
    }

    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    long request[PYTHON_REQUEST_ARRAY_SIZE] = {};
    request[0] = PYTHON_REQUEST_PREDICT;
    request[1] = PREDICT_ROW_COUNT;
    request[2] = PREDICT_ROW_COUNT;
    request[3] = PREDICT_ROW_COUNT;
    request[4] = (long)TimeCurrent();
    request[5] = (long)(1000000 * ask);
    FileWriteArray(PipeHandle, request);

    uint write_array_count = FileWriteArray(PipeHandle, buffer);

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

    string logging_line = StringFormat("%s\t%.3f\t%+f\n", TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS), ask, predict_value);
    FileWriteString(LoggingFile, logging_line);
    return true;
}

//+------------------------------------------------------------------+
//| 学習/予測データの作成                                            |
//+------------------------------------------------------------------+
bool CreateBuffer(int price_bars, int macd05M_bars, int macd01H_bars, double& buffer[])
{
    double values05M[];
    CopyOpen(Symbol(), PERIOD_M5, 0, price_bars, values05M);
    if (ArraySize(values05M) != price_bars) {
        return false;
    }
    ArrayReverse(values05M);
    ArrayAppend(buffer, values05M);

    double macd5m[];
    CopyBuffer(hMACD05M, MAIN_LINE, 0, macd05M_bars, macd5m);
    if (ArraySize(macd5m) != macd05M_bars) {
        return false;
    }
    ArrayReverse(macd5m);
    ArrayAppend(buffer, macd5m);

    double signal05m[];
    CopyBuffer(hMACD05M, SIGNAL_LINE, 0, macd05M_bars, signal05m);
    if (ArraySize(signal05m) != macd05M_bars) {
        return false;
    }
    ArrayReverse(signal05m);
    ArrayAppend(buffer, signal05m);

    double macd01h[];
    CopyBuffer(hMACD01H, MAIN_LINE, 0, macd01H_bars, macd01h);
    if (ArraySize(macd01h) != macd01H_bars) {
        return false;
    }
    ArrayReverse(macd01h);
    ArrayAppend(buffer, macd01h);

    double signal01h[];
    CopyBuffer(hMACD01H, MAIN_LINE, 0, macd01H_bars, signal01h);
    if (ArraySize(signal01h) != macd01H_bars) {
        return false;
    }
    ArrayReverse(signal01h);
    ArrayAppend(buffer, signal01h);

    return true;
}

//+------------------------------------------------------------------+
//| 配列の追記                                                       |
//+------------------------------------------------------------------+
void ArrayAppend(double& dst[], const double& src[])
{
    int offset = ArraySize(dst);
    int dst_size = offset + ArraySize(src);
    ArrayResize(dst, dst_size);
    ArrayCopy(dst, src, offset, 0);
}

//+------------------------------------------------------------------+
//| 価格の文字列化                                                   |
//+------------------------------------------------------------------+
string PriceToString(double price)
{
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    return DoubleToString(price, digits);
}

//+------------------------------------------------------------------+
//| 予測プロセスの終了                                               |
//+------------------------------------------------------------------+
bool Terminate()
{
    return true;
}
