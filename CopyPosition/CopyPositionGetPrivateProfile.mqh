//+------------------------------------------------------------------+
//|                                CopyPositionGetPrivateProfile.mqh |
//|                                          Copyright 2023, YUSUKE. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.00"
#property strict

string GetPrivateProfileString(
    const string sectionName,
    const string keyName,
    const string iniFileName)
{
    int file = FileOpen(iniFileName, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON, '\t', CP_ACP);
    if (file == INVALID_HANDLE) {
        return "";
    }

    string line = "";
    string section = "";
    string result = "";
    while (!FileIsEnding(file)) {
        line = FileReadString(file);
        if (line == "") {
            continue;
        }
        if (StringFind(line, ";", 0) == 0) {
            continue;
        }
        if (StringFind(line, "[") == 0 && StringFind(line, "]") == StringLen(line) - 1) {
            section = StringSubstr(line, 1, StringLen(line) - 2);
            continue;
        }
        string field[];
        StringSplit(line, '=', field);
        string key = StringTrimRight(StringTrimLeft(field[0]));
        string value = StringTrimRight(StringTrimLeft(field[1]));
        if (sectionName == section && keyName == key) {
            result = value;
            break;
        }
    }

    FileClose(file);

    return result;
}
