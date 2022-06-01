//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::AccountBalance()
{
    return(AccountInfoDouble(ACCOUNT_BALANCE));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::AccountCredit()
{
    return(AccountInfoDouble(ACCOUNT_CREDIT));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::AccountCompany()
{
    return(AccountInfoString(ACCOUNT_COMPANY));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::AccountCurrency()
{
    return(AccountInfoString(ACCOUNT_CURRENCY));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::AccountEquity()
{
    return(AccountInfoDouble(ACCOUNT_EQUITY));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::AccountFreeMargin()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double profit = AccountInfoDouble(ACCOUNT_PROFIT);

    return(balance - margin + profit);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::AccountLeverage()
{
    return((int)AccountInfoInteger(ACCOUNT_LEVERAGE));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::AccountMargin()
{
    return(AccountInfoDouble(ACCOUNT_MARGIN));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::AccountFreeMarginCheck(string symbol, int cmd, double volume)
{
    ENUM_ORDER_TYPE order_type = IntegerToOrderType(cmd);
    double price, margin;

    if(order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_LIMIT || order_type == ORDER_TYPE_BUY_STOP) {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    }

    if(OrderCalcMargin(order_type, symbol, volume, price, margin)) {
        return(margin);
    }
    return(0);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::AccountName()
{
    return(AccountInfoString(ACCOUNT_NAME));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::AccountNumber()
{
    return((int)AccountInfoInteger(ACCOUNT_LOGIN));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::AccountProfit()
{
    return(AccountInfoDouble(ACCOUNT_PROFIT));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::AccountServer()
{
    return(AccountInfoString(ACCOUNT_SERVER));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::AccountStopoutLevel()
{
    return((int)AccountInfoDouble(ACCOUNT_MARGIN_SO_SO));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::AccountStopoutMode()
{
    return((int)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE));
}
