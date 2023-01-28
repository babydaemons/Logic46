//+------------------------------------------------------------------+
//|                                           Lib/SaftyBeltPanel.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

#ifdef __DEBUG_INTERVAL
#import "kernel32.dll"
uint SleepEx(uint milliseconds, int flag);
#import
#endif

#include "DrawObject.mqh"

enum ENUM_WATCHSTATUS {
    WATCHSTATUS_ENTRY_WAITING,
    WATCHSTATUS_ENTRY_WATCHING,
    WATCHSTATUS_EXIT_WATCHING,
};
const string WatchStatusMessages[] = {
    "エントリー中断中です(中断時間 %s～%s)",
    "エントリー監視中です(中断時間 %s～%s)",
    "決済監視中です",
};
ENUM_WATCHSTATUS WatchStatus;
string WatchStatusMessage;

const string FONT_NAME = "BIZ UDPゴシック";
const int FONT_SIZE = DrawObject::ScaleFontSize(12.0, 9);
const color BORDER_COLOR = C'0,0,255';
const color BACKGROUND_COLOR = C'0,0,70';

DrawObject Border(__LINE__, OBJ_RECTANGLE_LABEL, "Boder");
DrawObject Background(__LINE__, OBJ_RECTANGLE_LABEL, "Background");
LabelObject LabelSymbol(__LINE__, "銘柄");
LabelObject LabelPositionType(__LINE__, "ポジション");
LabelObject LabelProfit(__LINE__, "ポジション損益");
LabelObject LabelLots(__LINE__, "発注ロット数");
LabelObject LabelLongEntryPrice(__LINE__, "ロング待機中逆指値価格");
LabelObject LabelAskBid(__LINE__, "Ask/Bid");
LabelObject LabelShortEntryPrice(__LINE__, "ショート待機中逆指値価格");
LabelObject LabelPositionStopLossPrice(__LINE__, "発注中決済価格");
LabelObject LabelPrevUpdateTime(__LINE__, "逆指値前回更新時刻");
LabelObject LabelUpdateInterval(__LINE__, "更新時間間隔");
LabelObject LabelNextUpdateTime(__LINE__, "次回の逆指値更新まで");
LabelObject LabelMailAdress(__LINE__, "送信先メールアドレス");
LabelObject LabelWatchStatus(__LINE__, "ポジション監視状態");
LabelObject LabelEnableOrder(__LINE__, "クイック決済ボタン表示");
LabelObject LabelDispSymbol(__LINE__, " ");
LabelObject LabelDispPositionType(__LINE__, "　 ");
LabelObject LabelDispProfit(__LINE__, " 　");
LabelObject LabelDispLots(__LINE__, "　　　");
LabelObject LabelDispLongEntryPrice(__LINE__, " 　 ");
LabelObject LabelDispLongEntryWidth(__LINE__, "　  ");
LabelObject LabelDispAskPrice(__LINE__, "   　");
LabelObject LabelDispBidPrice(__LINE__, " 　   ");
LabelObject LabelDispShortEntryPrice(__LINE__, "  　  ");
LabelObject LabelDispShortEntryWidth(__LINE__, "   　 ");
LabelObject LabelDispPositionStopLossPrice(__LINE__, "    　");
LabelObject LabelDispPrevUpdateTime(__LINE__, "　　   ");
LabelObject LabelDispUpdateInterval(__LINE__, " 　　  ");
LabelObject LabelDispNextUpdateTime(__LINE__, "  　　 ");
LabelObject LabelDispMailAdress(__LINE__, "   　　");
LabelObject LabelDispWatchStatus(__LINE__, "　　");
CheckboxObject CheckboxEnableSettlement(__LINE__, "　", false);
ButtonObject ButtonSettlement(__LINE__, "マジックナンバー全決済");

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitPanel() {
    // オブジェクト全削除
    RemovePanel();

    TextObject::SetDefaultFont(FONT_NAME, FONT_SIZE);
    TextObject::SetDefaultColor(clrCyan, BACKGROUND_COLOR, BACKGROUND_COLOR);

    int x0 = DrawObject::ScaleSize(12.0);
    int y0 = DrawObject::ScaleSize(24.0);
    int x00 = x0;
    int y00 = y0;

    // 背景パネルの描画
    int size_x00 = DrawObject::ScaleSize(50 * FONT_SIZE);
    int size_y00 = DrawObject::ScaleSize(13 * FONT_SIZE);
    int line_width = 1;
    Border.Initialize(__LINE__, x00 - line_width, y00 - line_width, size_x00 + 2 * line_width, size_y00 + 2 * line_width);
    Border.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,255');

    Background.Initialize(__LINE__, x00, y00, size_x00, size_y00);
    Background.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,70');

    int margin_y1 = 2;
    int padding_y1 = 2;
    int size_x10 = DrawObject::ScaleSize(FONT_SIZE * 16);
    int size_y10 = DrawObject::ScaleSize(FONT_SIZE + 2 * margin_y1 + 2 * padding_y1);
    int size_x20 = DrawObject::ScaleSize(FONT_SIZE * 7);
    int size_y20 = size_y10;
    int size_x30 = DrawObject::ScaleSize(FONT_SIZE * 24);
    int size_y30 = size_y20;

    // ラベルオブジェクトの描画
    int x10 = x00 + DrawObject::ScaleSize(8);
    int y10 = y00 + DrawObject::ScaleSize(11);
    int x20 = x10 + size_x10;
    int y20 = y10;
    int x30 = x20 + size_x20;
    int y30 = y20 + 4 * size_y20;
    LabelSymbol.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelPositionType.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelProfit.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelLots.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelLongEntryPrice.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelAskBid.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelShortEntryPrice.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelPositionStopLossPrice.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelPrevUpdateTime.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelUpdateInterval.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelNextUpdateTime.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelMailAdress.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    y10 += size_y10;
    LabelWatchStatus.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    LabelDispSymbol.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispPositionType.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispProfit.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispLots.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispLongEntryPrice.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispAskPrice.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispShortEntryPrice.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispPositionStopLossPrice.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispPrevUpdateTime.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispUpdateInterval.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispNextUpdateTime.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispMailAdress.Initialize(__LINE__, x20, y20, size_x20, size_y20);
    y20 += size_y20;
    LabelDispWatchStatus.Initialize(__LINE__, x20, y20, size_x20, size_y20);

    LabelDispLongEntryWidth.Initialize(__LINE__, x30, y30, size_x30, size_y30);
    y30 += size_y30;
    LabelDispBidPrice.Initialize(__LINE__, x30, y30, size_x30, size_y30);
    y30 += size_y30;
    LabelDispShortEntryWidth.Initialize(__LINE__, x30, y30, size_x30, size_y30);

    // クイック決済ボタン表示チェックボックスの描画
    y10 += size_y10;
    LabelEnableOrder.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    int size_chk = DrawObject::ScaleFontSize(FONT_SIZE, 9) + 1;
    CheckboxEnableSettlement.SetFont(FONT_NAME, FONT_SIZE - 3);
    CheckboxEnableSettlement.SetColor(clrBlack, clrBlack, clrWhite);
    CheckboxEnableSettlement.Initialize(__LINE__, x20, y10, size_chk, size_chk);

    // 背景パネルのサイズ更新
    size_x00 = x30 + size_x30 - (int)(1.25 * x00);
    size_y00 = y10 + size_y10 - (int)(0.75 * y00);
    Border.SetSize(__LINE__, size_x00 + 2 * line_width, size_y00 + 2 * line_width);
    Background.SetSize(__LINE__, size_x00, size_y00);

    ChartRedraw();

    UpdatePanel();
}

datetime last_order_modified;
datetime last_position_modified;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdatePanel() {
    double ask = 0;
    double bid = 0;
    double point = 0;
    int digit = 0;
    GetPriceInfo(ask, bid, point, digit);

    int buy_ticket = 0;
    double buy_profit = 0;
    int buy_position_count = 0;
    int sell_ticket = 0;
    double sell_profit = 0;
    int sell_position_count = 0;
    double total_profit = GetPositionProfit(buy_ticket, buy_profit, buy_position_count, sell_ticket, sell_profit, sell_position_count);

#ifdef __DEBUG_INTERVAL
#ifdef __MQL4__
    bool visual_mode = IsVisualMode();
#else
    bool visual_mode = MQLInfoInteger(MQL_VISUAL_MODE) != 0;
    if (visual_mode && (buy_position_count > 0 || sell_position_count > 0)) {
        ChartRedraw();
        SleepEx(__DEBUG_INTERVAL, 0);
    }
#endif

    bool watching = IsWatching();
    bool order_modified = false;
    datetime now = TimeCurrent();
    datetime next_update = last_order_modified + ORDER_MODIFY_INTERVAL_SECONDS;
    datetime next_entry = last_order_modified + 60 * RE_ORDER_DISABLE_MINUTES;
    static double buy_entry = 0;
    static double sell_entry = 0;
    static double position_stop_loss = 0;
    if (watching && now > next_entry && buy_ticket == 0 && sell_position_count == 0) {
        buy_entry = NormalizeDouble(ask + ENTRY_WIDTH * point, digit);
        buy_ticket = OrderBuyEntry(buy_entry);
        order_modified = true;
    } else if (!watching && buy_ticket == 0 && sell_position_count == 0) {
        DeleteOrderAll();
        buy_entry = NormalizeDouble(ask + ENTRY_WIDTH * point, digit);
        order_modified = true;
    } else if (now > next_update && buy_ticket != 0) {
        buy_entry = NormalizeDouble(ask + ENTRY_WIDTH * point, digit);
        if (buy_position_count == 0) {
            if (ModifyBuyOrder(buy_ticket, buy_entry)) {
                order_modified = true;
            }
        } else {
            if (TrailingStopBuyPosition(buy_ticket, position_stop_loss)) {
                last_position_modified = now;
                order_modified = true;
            }
        }
    }
    if (buy_position_count > 0 && sell_position_count == 0) {
        if (sell_ticket != 0 && DeleteSellOrder(sell_ticket)) {
            order_modified = true;
        }
    }

    if (watching && now > next_entry && sell_ticket == 0 && buy_position_count == 0) {
        sell_entry = NormalizeDouble(bid - ENTRY_WIDTH * point, digit);
        sell_ticket = OrderSellEntry(sell_entry);
        order_modified = true;
    } else if (!watching && buy_ticket == 0 && sell_position_count == 0) {
        DeleteOrderAll();
        sell_entry = NormalizeDouble(bid - ENTRY_WIDTH * point, digit);
        order_modified = true;
    } else if (now > next_update && sell_ticket != 0) {
        sell_entry = NormalizeDouble(bid - ENTRY_WIDTH * point, digit);
        if (sell_position_count == 0) {
            if (ModifySellOrder(sell_ticket, sell_entry)) {
                order_modified = true;
            }
        } else {
            if (TrailingStopSellPosition(sell_ticket, position_stop_loss)) {
                last_position_modified = now;
                order_modified = true;
            }
        }
    }
    if (sell_position_count > 0 && buy_position_count == 0) {
        if (buy_ticket != 0 && DeleteBuyOrder(buy_ticket)) {
            order_modified = true;
        }
    }

    if (order_modified) {
        last_order_modified = now;
    }

    LabelDispSymbol.SetText(__LINE__, Symbol());
    string position_status_message = TextObject::NONE_TEXT;
    color position_status_color = TextObject::NONE_COLOR;
    if (sell_position_count > 0) {
        position_status_message = "Sell";
        position_status_color = clrCyan;
    }
    else if (buy_position_count > 0) {
        position_status_message = "Buy";
        position_status_color = clrCyan;
    }
    LabelDispPositionType.SetText(__LINE__, position_status_message);
    LabelDispPositionType.SetTextColor(__LINE__, position_status_color);
    LabelDispProfit.SetNumberValue(__LINE__, total_profit, 0);
    LabelDispLots.SetText(__LINE__, DoubleToString(LOTS, 2));
    LabelDispAskPrice.SetText(__LINE__, DoubleToString(ask, digit));
    LabelDispBidPrice.SetText(__LINE__, DoubleToString(bid, digit));
    if (buy_position_count == 0 && sell_position_count == 0) {
        LabelDispLongEntryPrice.SetText(__LINE__, DoubleToString(buy_entry, digit));
        LabelDispLongEntryPrice.SetTextColor(__LINE__, clrCyan);
        LabelDispLongEntryWidth.SetText(__LINE__, StringFormat("(%+.0fポイント)", NormalizeDouble((buy_entry - ask) / point, 0)));
        LabelDispShortEntryPrice.SetText(__LINE__, DoubleToString(sell_entry, digit));
        LabelDispShortEntryPrice.SetTextColor(__LINE__, clrCyan);
        LabelDispShortEntryWidth.SetText(__LINE__, StringFormat("(%+.0fポイント)", NormalizeDouble((sell_entry - bid) / point, 0)));
        LabelDispPositionStopLossPrice.SetText(__LINE__, TextObject::NONE_TEXT);
        LabelDispPositionStopLossPrice.SetTextColor(__LINE__, TextObject::NONE_COLOR);
        ENUM_WATCHSTATUS status = watching ? WATCHSTATUS_ENTRY_WATCHING : WATCHSTATUS_ENTRY_WAITING;
        string watch_status_message = StringFormat(WatchStatusMessages[status], CLOSE_TIME, OPEN_TIME);
        LabelDispWatchStatus.SetText(__LINE__, watch_status_message);
        LabelDispWatchStatus.SetTextColor(__LINE__, watching ? clrCyan : clrRed);
    }
    else {
        LabelDispLongEntryPrice.SetText(__LINE__, TextObject::NONE_TEXT);
        LabelDispLongEntryPrice.SetTextColor(__LINE__, TextObject::NONE_COLOR);
        LabelDispLongEntryWidth.SetText(__LINE__, " ");
        LabelDispShortEntryPrice.SetText(__LINE__, TextObject::NONE_TEXT);
        LabelDispShortEntryPrice.SetTextColor(__LINE__, TextObject::NONE_COLOR);
        LabelDispShortEntryWidth.SetText(__LINE__, " ");
        LabelDispPositionStopLossPrice.SetText(__LINE__, DoubleToString(position_stop_loss, digit));
        LabelDispPositionStopLossPrice.SetTextColor(__LINE__, clrCyan);
        LabelDispWatchStatus.SetText(__LINE__, WatchStatusMessages[WATCHSTATUS_EXIT_WATCHING]);
        LabelDispWatchStatus.SetTextColor(__LINE__, clrMagenta);
    }
    LabelDispPrevUpdateTime.SetText(__LINE__, GetTimestamp(last_order_modified));
    LabelDispUpdateInterval.SetText(__LINE__, GetInterval((datetime)ORDER_MODIFY_INTERVAL_SECONDS));
    LabelDispNextUpdateTime.SetText(__LINE__, GetInterval((last_order_modified + ORDER_MODIFY_INTERVAL_SECONDS) - now));
    LabelDispMailAdress.SetText(__LINE__, MAIL_TO_ADDRESS);

    if (CheckboxEnableSettlement.IsChecked(__LINE__)) {
        DispSettlementButton();
    } else {
        HideSettlementButton();
    }

    ChartRedraw();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RemovePanel() {
    Border.Remove(__LINE__);
    Background.Remove(__LINE__);
    LabelSymbol.Remove(__LINE__);
    LabelPositionType.Remove(__LINE__);
    LabelProfit.Remove(__LINE__);
    LabelLots.Remove(__LINE__);
    LabelLongEntryPrice.Remove(__LINE__);
    LabelAskBid.Remove(__LINE__);
    LabelShortEntryPrice.Remove(__LINE__);
    LabelPositionStopLossPrice.Remove(__LINE__);
    LabelPrevUpdateTime.Remove(__LINE__);
    LabelUpdateInterval.Remove(__LINE__);
    LabelNextUpdateTime.Remove(__LINE__);
    LabelMailAdress.Remove(__LINE__);
    LabelWatchStatus.Remove(__LINE__);
    LabelEnableOrder.Remove(__LINE__);
    LabelDispSymbol.Remove(__LINE__);
    LabelDispPositionType.Remove(__LINE__);
    LabelDispProfit.Remove(__LINE__);
    LabelDispLots.Remove(__LINE__);
    LabelDispLongEntryPrice.Remove(__LINE__);
    LabelDispLongEntryWidth.Remove(__LINE__);
    LabelDispAskPrice.Remove(__LINE__);
    LabelDispBidPrice.Remove(__LINE__);
    LabelDispShortEntryPrice.Remove(__LINE__);
    LabelDispShortEntryWidth.Remove(__LINE__);
    LabelDispPositionStopLossPrice.Remove(__LINE__);
    LabelDispPrevUpdateTime.Remove(__LINE__);
    LabelDispUpdateInterval.Remove(__LINE__);
    LabelDispNextUpdateTime.Remove(__LINE__);
    LabelDispMailAdress.Remove(__LINE__);
    LabelDispWatchStatus.Remove(__LINE__);
    CheckboxEnableSettlement.Remove(__LINE__);
    ButtonSettlement.Remove(__LINE__);

    ChartRedraw();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
    if (DrawObject::HasChartPropertyChanged(__LINE__, id)) {
        UpdatePanel();
    }

    if (ButtonSettlement.HasPressed(__LINE__, id, sparam)) {
        ClosePositionAll();
        WatchStatus = IsWatching() ? WATCHSTATUS_ENTRY_WATCHING : WATCHSTATUS_ENTRY_WAITING;
        WatchStatusMessage = WatchStatusMessages[WatchStatus];
        LabelDispWatchStatus.SetText(__LINE__, WatchStatusMessage);
        RestoreSttlementButton();
    }

    static bool prev_check_state = false;
    bool check_state = prev_check_state;
    bool check_changed = CheckboxEnableSettlement.HasPressed(__LINE__, id, sparam, check_state);
    if (check_changed && check_state != prev_check_state) {
        if (check_state) {
            DispSettlementButton();
        } else {
            HideSettlementButton();
        }
        prev_check_state = check_state;
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DispSettlementButton() {
    int panel_x = 0;
    int panel_y = 0;
    int panel_size_x = 0;
    int panel_size_y = 0;
    Border.GetRectangle(__LINE__, panel_x, panel_y, panel_size_x, panel_size_y);
    int x = panel_x;
    int y = panel_y + panel_size_y;
    int size_x10 = panel_size_x;
    int size_y10 = DrawObject::ScaleCoordinate(2.5 * FONT_SIZE);
    ButtonSettlement.SetFont(FONT_NAME, FONT_SIZE);
    ButtonSettlement.Initialize(__LINE__, x, y, size_x10, size_y10, false);
    ButtonSettlement.SetInteger(__LINE__, OBJPROP_COLOR, clrRed);
    ButtonSettlement.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'255,220,110');
    ButtonSettlement.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrBlack);
    ButtonSettlement.SetText(__LINE__, "マジックナンバー全決済");

    ChartRedraw();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HideSettlementButton() {
    ButtonSettlement.Remove(__LINE__);

    ChartRedraw();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateSettlementButton() {
    ButtonSettlement.SetText(__LINE__, "★マジックナンバー全決済中★");
    ButtonSettlement.SetInteger(__LINE__, OBJPROP_STATE, true);
    ChartRedraw();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RestoreSttlementButton() {
    ButtonSettlement.Restore(__LINE__);
    ButtonSettlement.SetText(__LINE__, "マジックナンバー全決済");
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| マジックナンバーの取得                                           |
//+------------------------------------------------------------------+
int GetMagicNumber() {
    return MAGIC_NUMBER;
}

/*
//+------------------------------------------------------------------+
//| 指定マジックナンバーのポジション監視                             |
//+------------------------------------------------------------------+
void CheckMagicNumberPositions() {
    ulong magic_number = GetMagicNumber();
    double profit = GetMagicNumberProfit();
    if (profit <= -STOP_LOSS) {
        SendOrderCloseAll();
        WatchStatus = WATCHSTATUS_STOPLOSS;
        SettlementTime = TimeCurrent();
        WatchStatusMessage = StringFormat(WatchStatusMessages[WatchStatus], TimeToString(SettlementTime));
        UpdatePanel();
    }
    else if (+TAKE_PROFIT <= profit) {
        SendOrderCloseAll();
        WatchStatus = WATCHSTATUS_TAKEPROFIT;
        SettlementTime = TimeCurrent();
        WatchStatusMessage = StringFormat(WatchStatusMessages[WatchStatus], TimeToString(SettlementTime));
        UpdatePanel();
   }
}
*/