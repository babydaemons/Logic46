//+------------------------------------------------------------------+
//|                                                MQL45_Defines.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#ifndef __MQL45_DEFINES_INCLUDED
#define __MQL45_DEFINES_INCLUDED

#define EMPTY -1

#define OP_BUY 0
#define OP_SELL 1
#define OP_BUYLIMIT 2
#define OP_SELLLIMIT 3
#define OP_BUYSTOP 4
#define OP_SELLSTOP 5

#define MODE_OPEN 0
#define MODE_CLOSE 3
#define MODE_VOLUME 4 
#define MODE_REAL_VOLUME 5
#define MODE_TRADES 0
#define MODE_HISTORY 1
#define SELECT_BY_POS 0
#define SELECT_BY_TICKET 1

#define DOUBLE_VALUE 0
#define FLOAT_VALUE 1
#define LONG_VALUE INT_VALUE

#define CHART_BAR 0
#define CHART_CANDLE 1

#define MODE_ASCEND 0
#define MODE_DESCEND 1

#define MODE_LOW 1
#define MODE_HIGH 2
#define MODE_TIME 5
#define MODE_BID 9
#define MODE_ASK 10
#define MODE_POINT 11
#define MODE_DIGITS 12
#define MODE_SPREAD 13
#define MODE_STOPLEVEL 14
#define MODE_LOTSIZE 15
#define MODE_TICKVALUE 16
#define MODE_TICKSIZE 17
#define MODE_SWAPLONG 18
#define MODE_SWAPSHORT 19
#define MODE_STARTING 20
#define MODE_EXPIRATION 21
#define MODE_TRADEALLOWED 22
#define MODE_MINLOT 23
#define MODE_LOTSTEP 24
#define MODE_MAXLOT 25
#define MODE_SWAPTYPE 26
#define MODE_PROFITCALCMODE 27
#define MODE_MARGINCALCMODE 28
#define MODE_MARGININIT 29
#define MODE_MARGINMAINTENANCE 30
#define MODE_MARGINHEDGED 31
#define MODE_MARGINREQUIRED 32
#define MODE_FREEZELEVEL 33

#define MODE_MAIN 0
#define MODE_SIGNAL 1

#define MODE_PLUSDI 1
#define MODE_MINUSDI 2

#define MODE_UPPER 1
#define MODE_LOWER 2

#define MODE_GATORJAW 1
#define MODE_GATORTEETH 2
#define MODE_GATORLIPS 3

#define MODE_TENKANSEN 1
#define MODE_KIJUNSEN 2
#define MODE_SENKOUSPANA 3
#define MODE_SENKOUSPANB 4
#define MODE_CHIKOUSPAN 5

#endif /*__MQL45_DEFINES_INCLUDED*/