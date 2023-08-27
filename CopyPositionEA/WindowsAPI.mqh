//+------------------------------------------------------------------+
//|                                                   WindowsAPI.mqh |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.00"
#property strict

#import "kernel32.dll"
uint GetPrivateProfileStringW(
    string sectionName,
    string keyName,
    string defaultValue,
    ushort& returnValue[],
    uint bufferSize,
    string iniFilePath);
#import

uint GetPrivateProfileString(
    string sectionName,
    string keyName,
    string defaultValue,
    string& returnValue,
    uint bufferSize,
    string iniFilePath)
{
    static ushort buffer[1024];
    ArrayFill(buffer, 0, 1024, 0);
    uint result = GetPrivateProfileStringW(sectionName, keyName, defaultValue, buffer, 1024, iniFilePath);
    returnValue = ShortArrayToString(buffer);
    return result;
}

const string NONE = "<NONE>";

#import "kernel32.dll"
ulong GetTickCount64();
#import
