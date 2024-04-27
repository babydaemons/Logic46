//+------------------------------------------------------------------+
//|                                                      pyforex.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input string PYTHON = "C:\\Users\\shingo\\AppData\\Local\\Programs\\Python\\Python312\\python.exe";
input string SCRIPT = "C:\\Users\\shingo\\AppData\\Roaming\\MetaQuotes\\Terminal\\30CF3465B87D17D00E7FD8366A68D7C6\\MQL5\\Experts\\Logic46\\pyforex\\pyforex\\pyforex.py";

const string SHARED_MEMORY_NAME = "b2cc1ec1d82f8463cf03b1c0e2c0990794c57c53";
const string READ_SHARED_MEMORY_NAME = "Local\\" + SHARED_MEMORY_NAME + "R";
const string WRITE_SHARED_MEMORY_NAME = "Local\\" + SHARED_MEMORY_NAME + "W";
const uint READ_SHARED_MEMORY_SIZE = 1 * 1024 * 1024;
const uint WRITE_SHARED_MEMORY_SIZE = 1 * 1024 * 1024 * 1024;

const int FIVE_MINUTES = 5;
const int HOUR_MINUTES = 60;
const int DAY_MINUES = 19 * HOUR_MINUTES + 30;
const int WEEK_MINUES = 5 * DAY_MINUES;
const int MONTH_MINUES = 4 * WEEK_MINUES;
const int PREDICT_MINUTES = 60;
const int ROW_COUNT_MINUTES = 250 * DAY_MINUES;
const int FETCH_ROW_COUNT = ROW_COUNT_MINUTES + PREDICT_MINUTES;

#import "pyforex.dll"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
/*
    string command_line = StringFormat("%s %s %s %d %d", PYTHON, SCRIPT, SHARED_MEMORY_NAME, READ_SHARED_MEMORY_SIZE, WRITE_SHARED_MEMORY_SIZE);
    PyForexLibrary::CreateProcess(command_line);
    PyForexLibrary::CreateSharedMemory(READ_SHARED_MEMORY_NAME, READ_SHARED_MEMORY_SIZE);
    PyForexLibrary::CreateSharedMemory(WRITE_SHARED_MEMORY_NAME, WRITE_SHARED_MEMORY_SIZE);
*/
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
    FolderCreate("pyforex", FILE_COMMON);
    FolderClean("pyforex", FILE_COMMON);

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
