//+------------------------------------------------------------------+
//|                                            MQL45_DateAndTime.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::Day()
{
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.day);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::DayOfWeek()
{
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.day_of_week);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::DayOfYear()
{
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.day_of_year);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::Hour()
{
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.hour);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::Minute()
{
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.min);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::Month()
{
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.mon);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::Seconds()
{
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.sec);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::TimeDay(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.day);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::TimeDayOfWeek(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.day_of_week);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::TimeDayOfYear(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.day_of_year);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::TimeHour(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.hour);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::TimeMinute(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.min);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::TimeMonth(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.mon);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::TimeSeconds(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.sec);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::TimeYear(datetime date)
{
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.year);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::Year()
{
    MqlDateTime tm;
    TimeCurrent(tm);
    return(tm.year);
}
