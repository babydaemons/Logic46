//+------------------------------------------------------------------+
//|                                                   OrderPanel.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "DrawObject.mqh"
#include "PositionUtil.mqh"

const string FONT_NAME = "BIZ UDPゴシック";
const int FONT_SIZE1 = DrawObject::ScaleFontSize(12.0, 9);
const int FONT_SIZE2 = DrawObject::ScaleFontSize(11.0, 8);

DrawObject Border(__LINE__, OBJ_RECTANGLE_LABEL, "Boder");
DrawObject Background(__LINE__, OBJ_RECTANGLE_LABEL, "Background");
LabelObject LabelMagicNumber(__LINE__, "マジックナンバー");
LabelObject LabelSymbol(__LINE__, "銘柄");
LabelObject LabelLots(__LINE__, "発注ロット数");
LabelObject LabelTotalProfit(__LINE__, "マジックナンバー全損益");
LabelObject LabelTakeProfit(__LINE__, "利確金額");
LabelObject LabelStopLoss(__LINE__, "損切金額");
LabelObject LabelEnableOrder(__LINE__, "クイック決済ボタン表示");
LabelObject LabelDispMagicNumber(__LINE__, " ");
LabelObject LabelDispSymbol1(__LINE__, "　   ");
LabelObject LabelDispSymbol2(__LINE__, " 　  ");
LabelObject LabelDispSymbol3(__LINE__, "  　 ");
LabelObject LabelDispSymbol4(__LINE__, "   　");
LabelObject LabelDispLots1(__LINE__, " 　   ");
LabelObject LabelDispLots2(__LINE__, "  　  ");
LabelObject LabelDispLots3(__LINE__, "   　 ");
LabelObject LabelDispLots4(__LINE__, "    　");
LabelObject LabelDispTotalProfit(__LINE__, "　　");
LabelObject LabelDispTakeProfit(__LINE__, " 　　");
LabelObject LabelDispStopLoss(__LINE__, "　　 ");
CheckboxObject CheckboxEnableSettlement(__LINE__, "　", false);
ButtonObject ButtonSettlement(__LINE__, "マジックナンバー全決済");

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitPanel() {
    // printf("FONT_SIZE1:%d, FONT_SIZE2:%d", FONT_SIZE1, FONT_SIZE2);

    // オブジェクト全削除
    RemovePanel();

    const color BORDER_COLOR = C'0,0,255';
    const color BACKGROUND_COLOR = C'0,0,70';

    TextObject::SetDefaultFont(FONT_NAME, FONT_SIZE1);
    TextObject::SetDefaultColor(clrCyan, BACKGROUND_COLOR, BACKGROUND_COLOR);

    int x0 = DrawObject::ScaleSize(12.0);
    int y0 = DrawObject::ScaleSize(24.0);
    int x00 = x0;
    int y00 = y0;

    // 背景パネルの描画
    int size_x00 = DrawObject::ScaleSize(50 * FONT_SIZE1);
    int size_y00 = DrawObject::ScaleSize(13 * FONT_SIZE1);
    int line_width = 1;
    Border.Initialize(__LINE__, x00 - line_width, y00 - line_width, size_x00 + 2 * line_width, size_y00 + 2 * line_width);
    Border.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,255');

    Background.Initialize(__LINE__, x00, y00, size_x00, size_y00);
    Background.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,70');

    int margin_y1 = 2;
    int padding_y1 = 2;
    int size_x10 = DrawObject::ScaleSize(FONT_SIZE1 * 9);
    int size_y10 = DrawObject::ScaleSize(FONT_SIZE1 + 2 * margin_y1 + 2 * padding_y1);

    // ラベルオブジェクトの描画
    int x10 = x00 + DrawObject::ScaleSize(8);
    int y10 = y00 + DrawObject::ScaleSize(11);
    int x20 = x10 + DrawObject::ScaleSize(15 * FONT_SIZE1);
    int y20 = y10;
    LabelMagicNumber.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    y10 += size_y10;
    int x30 = x20;
    int y30 = y10;
    LabelSymbol.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    y10 += size_y10;
    int x40 = x20;
    int y40 = y10;
    LabelLots.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    y10 += size_y10;
    int x50 = x20;
    int y50 = y10;
    LabelTotalProfit.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    y10 += size_y10;
    LabelTakeProfit.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    y10 += size_y10;
    LabelStopLoss.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    int size_x20 = DrawObject::ScaleSize(FONT_SIZE1 * 9);
    int size_y20 = size_y10;
    LabelDispMagicNumber.Initialize(__LINE__, x20, y20, size_x20, size_y20);

    int size_x30 = DrawObject::ScaleSize(FONT_SIZE1 * 11.25);
    int size_y30 = size_y20;
    LabelDispSymbol1.Initialize(__LINE__, x30, y30, size_x30, size_y30);

    x30 += size_x30;
    LabelDispSymbol2.Initialize(__LINE__, x30, y30, size_x30, size_y30);

    x30 += size_x30;
    LabelDispSymbol3.Initialize(__LINE__, x30, y30, size_x30, size_y30);

    x30 += size_x30;
    LabelDispSymbol4.Initialize(__LINE__, x30, y30, size_x30, size_y30);

    int size_x40 = size_x30;
    int size_y40 = size_y30;
    LabelDispLots1.Initialize(__LINE__, x40, y40, size_x40, size_y40);

    x40 += size_x40;
    LabelDispLots2.Initialize(__LINE__, x40, y40, size_x40, size_y40);

    x40 += size_x40;
    LabelDispLots3.Initialize(__LINE__, x40, y40, size_x40, size_y40);

    x40 += size_x40;
    LabelDispLots4.Initialize(__LINE__, x40, y40, size_x40, size_y40);

    int size_x50 = size_x40;
    int size_y50 = size_y40;
    LabelDispTotalProfit.Initialize(__LINE__, x50, y50, size_x50, size_y50);

    y50 += size_y50;
    LabelDispTakeProfit.Initialize(__LINE__, x50, y50, size_x50, size_y50);

    y50 += size_y50;
    LabelDispStopLoss.Initialize(__LINE__, x50, y50, size_x50, size_y50);

    // クイック決済ボタン表示チェックボックスの描画
    y10 += size_y10;
    LabelEnableOrder.Initialize(__LINE__, x10, y10, size_x10, size_y10);
    int size_chk = DrawObject::ScaleFontSize(FONT_SIZE1, 9) + 1;
    CheckboxEnableSettlement.SetFont(FONT_NAME, FONT_SIZE2 - 2);
    CheckboxEnableSettlement.SetColor(clrBlack, clrBlack, clrWhite);
    CheckboxEnableSettlement.Initialize(__LINE__, x20, y10, size_chk, size_chk);

    // 背景パネルのサイズ更新
    size_x00 = x40 + size_x40 - (int)(1.25 * x00);
    size_y00 = y10 + size_y10 - (int)(0.75 * y00);
    Border.SetSize(__LINE__, size_x00 + 2 * line_width, size_y00 + 2 * line_width);
    Background.SetSize(__LINE__, size_x00, size_y00);

    ChartRedraw();

    UpdatePanel();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdatePanel() {
    LabelDispMagicNumber.SetText(__LINE__, IntegerToString(MAGIC_NUMBER));

    LabelDispTotalProfit.SetNumberValue(__LINE__, GetMagicNumberProfit(), 0);

    LabelDispTakeProfit.SetNumberValue(__LINE__, TAKE_PROFIT, 0);

    LabelDispStopLoss.SetNumberValue(__LINE__, STOP_LOSS, 0);

    if (__DEBUGGING) {
        SortPositions();
    }
    else {
        ScanPositions(MAGIC_NUMBER);
    }

    UpdateSymbolInfo(0, LabelDispSymbol1, LabelDispLots1);
    UpdateSymbolInfo(1, LabelDispSymbol2, LabelDispLots2);
    UpdateSymbolInfo(2, LabelDispSymbol3, LabelDispLots3);
    UpdateSymbolInfo(3, LabelDispSymbol4, LabelDispLots4);

    if (CheckboxEnableSettlement.IsChecked(__LINE__)) {
        DispSettlementButton();
    } else {
        HideSettlementButton();
    }

    ChartRedraw();
}

void UpdateSymbolInfo(int i, LabelObject& symbol_object, LabelObject& lots_object) {
    string symbol = "";
    double lots = 0.0;
    double profit = 0.0;
    GetPosition(i, symbol, lots, profit);
    symbol_object.SetTextValue(__LINE__, symbol, true);
    lots_object.SetNumberValue(__LINE__, lots, 2, true);
}

void RemovePanel() {
    Border.Remove(__LINE__);
    Background.Remove(__LINE__);
    LabelMagicNumber.Remove(__LINE__);
    LabelSymbol.Remove(__LINE__);
    LabelLots.Remove(__LINE__);
    LabelTotalProfit.Remove(__LINE__);
    LabelTakeProfit.Remove(__LINE__);
    LabelStopLoss.Remove(__LINE__);
    LabelEnableOrder.Remove(__LINE__);
    LabelDispMagicNumber.Remove(__LINE__);
    LabelDispSymbol1.Remove(__LINE__);
    LabelDispSymbol2.Remove(__LINE__);
    LabelDispSymbol3.Remove(__LINE__);
    LabelDispSymbol4.Remove(__LINE__);
    LabelDispLots1.Remove(__LINE__);
    LabelDispLots2.Remove(__LINE__);
    LabelDispLots3.Remove(__LINE__);
    LabelDispLots4.Remove(__LINE__);
    LabelDispTotalProfit.Remove(__LINE__);
    LabelDispTakeProfit.Remove(__LINE__);
    LabelDispStopLoss.Remove(__LINE__);
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
        SendOrderCloseAll();
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
    int size_y10 = DrawObject::ScaleCoordinate(2.5 * FONT_SIZE1);
    ButtonSettlement.SetFont(FONT_NAME, FONT_SIZE1);
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
    LabelDispTotalProfit.SetNumberValue(__LINE__, GetMagicNumberProfit(), 0);
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

//+------------------------------------------------------------------+
//| 指定マジックナンバーのポジション監視                             |
//+------------------------------------------------------------------+
void CheckMagicNumberPositions() {
    ulong magic_number = GetMagicNumber();
    double profit = GetMagicNumberProfit();
    if (profit <= -STOP_LOSS || +TAKE_PROFIT <= profit) {
        SendOrderCloseAll();
    }
}
