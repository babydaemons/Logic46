//+------------------------------------------------------------------+
//|                                                      pyforex.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

const int FIVE_MINUTES = 5;
const int HOUR_MINUTES = 60;
const int DAY_MINUES = 24 * HOUR_MINUTES;
const int WEEK_MINUES = 5 * DAY_MINUES;
const int MONTH_MINUES = 4 * WEEK_MINUES;
const int PREDICT_MINUTES = 60;
const int ROW_COUNT_MINUTES = 250 * DAY_MINUES;
const int FETCH_ROW_COUNT = ROW_COUNT_MINUTES + PREDICT_MINUTES;

#import "pyforex.dll"

string CommonFolderPath;
string ModulePath;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    FolderCreate("pyforex", FILE_COMMON);
    FolderClean("pyforex", FILE_COMMON);

    CommonFolderPath = TerminalInfoString(TERMINAL_COMMONDATA_PATH);
    ModulePath = CommonFolderPath + "\\Files\\pyforex.exe";

    PyForexLibrary::CreateProcess(ModulePath, CommonFolderPath);

    Learning();
    ExpertRemove();
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
/*
    PyForexLibrary::TerminateProcess();
*/
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
}

//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void Learning()
{
    double close_prices[];
    CopyClose(Symbol(), PERIOD_M1, 0, FETCH_ROW_COUNT, close_prices);
    int file_close_prices = FileOpen("pyforex\\close_prices.bin", FILE_WRITE | FILE_BIN | FILE_COMMON);
    FileWriteArray(file_close_prices, close_prices);
    FileClose(file_close_prices);

    datetime datetimes[];
    CopyTime(Symbol(), PERIOD_M1, 0, FETCH_ROW_COUNT, datetimes);
    int file_datetimes = FileOpen("pyforex\\datetimes.bin", FILE_WRITE | FILE_BIN | FILE_COMMON);
    FileWriteArray(file_datetimes, datetimes);
    FileClose(file_datetimes);
}
