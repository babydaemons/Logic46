//+------------------------------------------------------------------+
//|                                             Lib/PositionUtil.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

struct POSITION_INFO {
    string symbol;
    double lots;
    double profit;
};

POSITION_INFO PositionList[];

void ClearPositions() {
    ArrayResize(PositionList, 0);
}

void AddPosition(string symbol, double lots, double profit) {
    int n = ArraySize(PositionList);
    for (int i = 0; i < n; ++ i) {
        if (PositionList[i].symbol == symbol) {
            PositionList[i].lots += lots;
            PositionList[i].profit += profit;
            return;
        }
    }

    ArrayResize(PositionList, n + 1, n);
    PositionList[n].symbol = symbol;
    PositionList[n].lots = lots;
    PositionList[n].profit = profit;
    return;
}

int SortPositions() {
    int n = ArraySize(PositionList);
    for (int i = 0; i < n - 1; ++i) {
        for (int j = i + 1; j < n; ++j) {
            if (ComparePositions(PositionList[i], PositionList[j]) < 0) {
                POSITION_INFO temp = PositionList[i];
                PositionList[i] = PositionList[j];
                PositionList[j] = temp;
            }
        }
    }
    return n;
}

int ComparePositions(const POSITION_INFO& a, const POSITION_INFO& b) {
    if (MathAbs(a.lots) > MathAbs(b.lots)) {
        return +1;
    }
    else if (MathAbs(a.lots) < MathAbs(b.lots)) {
        return -1;
    }

    if (Sign(a.lots) > Sign(b.lots)) {
        return +1;
    }
    else if (Sign(a.lots) < Sign(b.lots)) {
        return -1;
    }

    if (a.symbol > b.symbol) {
        return +1;
    }
    else if (a.symbol < b.symbol) {
        return -1;
    }
    
    return 0;
}

int Sign(double x) {
    if (x > 0) {
        return +1;
    }
    if (x < 0) {
        return -1;
    }
    return 0;
}

void GetPosition(int i, string& symbol, double& lots, double& profit) {
    if (i < ArraySize(PositionList)) {
        symbol = PositionList[i].symbol;
        lots = PositionList[i].lots;
        profit = PositionList[i].profit;
    }
    else {
        symbol = TextObject::NONE_TEXT;
        lots = FLT_MAX;
        profit = FLT_MAX;
    }
}