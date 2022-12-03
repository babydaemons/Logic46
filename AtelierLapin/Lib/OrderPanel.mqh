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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
DrawObject Border(__LINE__, OBJ_RECTANGLE_LABEL, "Boder");
DrawObject Background(__LINE__, OBJ_RECTANGLE_LABEL, "Background");

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
LabelObject LabelMagicNumber(__LINE__, "マジックナンバー");
LabelObject LabelLots(__LINE__, "発注ロット数");
LabelObject LabelSymbol(__LINE__, "銘柄");
LabelObject LabelMargin(__LINE__, "必要証拠金");
LabelObject LabelSize(__LINE__, "契約サイズ");
LabelObject LabelSwapType(__LINE__, "SwapType");
LabelObject LabelBuySwap(__LINE__, "BuySwap");
LabelObject LabelSellSwap(__LINE__, "SellSwap");
LabelObject LabelProfit(__LINE__, "マジックナンバー全損益");
LabelObject LabelEnableOrder(__LINE__, "クイック決済ボタン表示");
EditObject EditMagicNumber(__LINE__, "EditMagicNumber");
EditObject EditLots(__LINE__, "EditLots");
LabelObject LabelOrderSymbol(__LINE__, "発注銘柄");
LabelObject LabelOrderMargin(__LINE__, "発注必要証拠金");
LabelObject LabelOrderSize(__LINE__, "発注契約サイズ");
LabelObject LabelOrderSwapType(__LINE__, "OrderSwapType");
LabelObject LabelOrderBuySwap(__LINE__, "OrderBuySwap");
LabelObject LabelOrderSellSwap(__LINE__, "OrderSellSwap");
LabelObject LabelOrderProfit(__LINE__, "OrderProfit");
ButtonObject ButtonSell(__LINE__, "ButtonSell");
ButtonObject ButtonBuy(__LINE__, "ButtonBuy");
CheckboxObject CheckboxEnableSettlement(__LINE__, "CheckboxEnableSettlement", false);
ButtonObject ButtonSettlement(__LINE__, "ButtonSettlement");

const string FONT_NAME = "BIZ UDPゴシック";
const int FONT_SIZE1 = 11;
const int FONT_SIZE2 = 10;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitPanel() {
    // オブジェクト全削除
    RemovePanel();

    TextObject::SetDefaultFont(FONT_NAME, FONT_SIZE1);
    LabelObject::SetDefaultColor(clrCyan);
    EditObject::SetDefaultColor(clrBlack, clrBlack, clrWhite);

    int x0 = 12;
    int y0 = 24;

    // 背景パネルの描画
    int size_x00 = DrawObject::ScaleSize(27.2 * FONT_SIZE1);
    int size_y00 = DrawObject::ScaleSize(21.4 * FONT_SIZE1);
    int x00 = x0;
    int y00 = y0;
    int line_width = 1;
    Border.Initialize(__LINE__, x00 - line_width, y00 - line_width, size_x00 + 2 * line_width, size_y00 + 2 * line_width);
    Border.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,255');

    Background.Initialize(__LINE__, x00, y00, size_x00, size_y00);
    Background.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,70');

    int margin_y1 = 2;
    int padding_y1 = 2;
    int size_x10 = DrawObject::ScaleSize(FONT_SIZE1 * 9);
    int size_y10 = DrawObject::ScaleSize(FONT_SIZE1 + 3 * margin_y1 + 2 * padding_y1);

    // パラメータ入力ラベルオブジェクトの描画
    int x10 = x00 + DrawObject::ScaleSize(8);
    int y10 = y00 + DrawObject::ScaleSize(11);
    int x20 = x10 + DrawObject::ScaleSize(15 * FONT_SIZE1);
    int y20 = y10;
    LabelMagicNumber.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    y10 += size_y10;
    LabelLots.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    y10 += size_y10;
    LabelSymbol.Initialize(__LINE__, x10, y10, size_x10, size_y10);

    int margin_y2 = 2;
    int padding_y2 = 2;
    int size_x11 = size_x10;
    int size_y11 = DrawObject::ScaleSize(FONT_SIZE2 + 2 * margin_y2 + 1 * padding_y2);
    int x11 = x10 + DrawObject::ScaleSize(0.8 * FONT_SIZE2);
    int y11 = y10 + size_y10;
    TextObject::SetDefaultFont(FONT_NAME, FONT_SIZE2);
    LabelMargin.Initialize(__LINE__, x11, y11, size_x11, size_y11);

    y11 += size_y11;
    LabelSize.Initialize(__LINE__, x11, y11, size_x11, size_y11);

    y11 += size_y11;
    LabelSwapType.Initialize(__LINE__, x11, y11, size_x11, size_y11);

    y11 += size_y11;
    LabelBuySwap.Initialize(__LINE__, x11, y11, size_x11, size_y11);

    y11 += size_y11;
    LabelSellSwap.Initialize(__LINE__, x11, y11, size_x11, size_y11);

    // パラメータ入力エディットオブジェクトの描画
    TextObject::SetDefaultFont(FONT_NAME, FONT_SIZE1);
    int y2E = y00 + DrawObject::ScaleSize(11 - padding_y1);
    int size_y1E = DrawObject::ScaleSize(FONT_SIZE1 + 3 * margin_y1 + 2 * padding_y1 - padding_y1);
    EditMagicNumber.Initialize(__LINE__, x20, y2E, size_x10, size_y1E);
    EditMagicNumber.InitText(__LINE__, "12345678");

    y20 += size_y10; y2E += size_y10;
    EditLots.Initialize(__LINE__, x20, y2E, size_x10, size_y1E);
    EditLots.InitText(__LINE__, "0.01");

    y20 += size_y10;
    LabelOrderSymbol.Initialize(__LINE__, x20, y20, size_x10, size_y10);
    LabelOrderSymbol.SetText(__LINE__, Symbol());

    int x21 = x20;
    int y21 = y20 + size_y10;
    TextObject::SetDefaultFont(FONT_NAME, FONT_SIZE2);
    LabelOrderMargin.Initialize(__LINE__, x21, y21, size_x11, size_y11);

    y21 += size_y11;
    LabelOrderSize.Initialize(__LINE__, x21, y21, size_x11, size_y11);

    y21 += size_y11;
    LabelOrderSwapType.Initialize(__LINE__, x21, y21, size_x11, size_y11);

    y21 += size_y11;
    LabelOrderBuySwap.Initialize(__LINE__, x21, y21, size_x11, size_y11);

    y21 += size_y11;
    LabelOrderSellSwap.Initialize(__LINE__, x21, y21, size_x11, size_y11);

    // 発注ボタンの描画
    int size_x20 = DrawObject::ScaleSize(10.7 * FONT_SIZE1);
    int size_y20 = DrawObject::ScaleSize(2.9 * FONT_SIZE1);
    int x30 = x10;
    int y30 = y21 + (int)(1.3 * size_y11);
    TextObject::SetDefaultFont(FONT_NAME, FONT_SIZE1);
    ButtonBuy.Initialize(__LINE__, x30, y30, size_x20, size_y20);
    ButtonBuy.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, C'255,0,0');
    ButtonBuy.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'255,205,205');
    ButtonBuy.SetInteger(__LINE__, OBJPROP_COLOR, C'255,0,0');
    ButtonBuy.SetString(__LINE__, OBJPROP_TEXT, "Ｂｕｙ");

    x30 = x20;
    ButtonSell.Initialize(__LINE__, x30, y30, size_x20, size_y20);
    ButtonSell.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, C'0,0,255');
    ButtonSell.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'205,205,255');
    ButtonSell.SetInteger(__LINE__, OBJPROP_COLOR, C'0,0,255');
    ButtonSell.SetString(__LINE__, OBJPROP_TEXT, "Ｓｅｌｌ");

    int y40 = y30 + (int)(1.2 * size_y20);
    LabelProfit.Initialize(__LINE__, x10, y40, size_x10, size_y10);
    LabelOrderProfit.Initialize(__LINE__, x20, y40, size_x10, size_y10);

    // クイック決済ボタン表示チェックボックスの描画
    y40 += size_y10;
    LabelEnableOrder.Initialize(__LINE__, x10, y40, size_x10, size_y10);
    int size_chk = DrawObject::ScaleSize(FONT_SIZE1 + padding_y1);
    CheckboxEnableSettlement.Initialize(__LINE__, x20, y40 + 1, size_chk, size_chk);

    ChartRedraw();

    UpdatePanel();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdatePanel() {
    LabelOrderMargin.SetValue(__LINE__, GetInitMargin(), 0);

    LabelOrderSize.SetValue(__LINE__, GetLotSize(), 0);

    LabelOrderSwapType.SetText(__LINE__, GetSwapType());

    LabelOrderBuySwap.SetValue(__LINE__, GetBuySwap(), 2);

    LabelOrderSellSwap.SetValue(__LINE__, GetSellSwap(), 2);

    LabelOrderProfit.SetValue(__LINE__, GetMagicNumberProfit(), 0);

    if (CheckboxEnableSettlement.IsChecked(__LINE__)) {
        DispSettlementButton();
    } else {
        HideSettlementButton();
    }
}

void RemovePanel() {
    Border.Remove(__LINE__);
    Background.Remove(__LINE__);
    LabelMagicNumber.Remove(__LINE__);
    LabelLots.Remove(__LINE__);
    LabelSymbol.Remove(__LINE__);
    LabelMargin.Remove(__LINE__);
    LabelSize.Remove(__LINE__);
    LabelSwapType.Remove(__LINE__);
    LabelBuySwap.Remove(__LINE__);
    LabelSellSwap.Remove(__LINE__);
    LabelProfit.Remove(__LINE__);
    LabelEnableOrder.Remove(__LINE__);
    EditMagicNumber.Remove(__LINE__);
    EditLots.Remove(__LINE__);
    LabelOrderSymbol.Remove(__LINE__);
    LabelOrderMargin.Remove(__LINE__);
    LabelOrderSize.Remove(__LINE__);
    LabelOrderSwapType.Remove(__LINE__);
    LabelOrderBuySwap.Remove(__LINE__);
    LabelOrderSellSwap.Remove(__LINE__);
    LabelOrderProfit.Remove(__LINE__);
    ButtonSell.Remove(__LINE__);
    ButtonBuy.Remove(__LINE__);
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
        RemovePanel();
        InitPanel();
    }

    if (ButtonBuy.HasPressed(__LINE__, id, sparam)) {
        ButtonBuy.SetInteger(__LINE__, OBJPROP_COLOR, C'255,125,125');
        ChartRedraw();
        SendBuyOrder();
        ButtonBuy.Restore(__LINE__);
        ButtonBuy.SetInteger(__LINE__, OBJPROP_COLOR, C'255,0,0');
        ChartRedraw();
    }

    if (ButtonSell.HasPressed(__LINE__, id, sparam)) {
        ButtonSell.SetInteger(__LINE__, OBJPROP_COLOR, C'125,125,255');
        ChartRedraw();
        SendSellOrder();
        ButtonSell.Restore(__LINE__);
        ButtonSell.SetInteger(__LINE__, OBJPROP_COLOR, C'0,0,255');
        ChartRedraw();
    }

    if (ButtonSettlement.HasPressed(__LINE__, id, sparam)) {
        ButtonSettlement.SetText(__LINE__, "★マジックナンバー全決済中★");
        ChartRedraw();
        SendOrderCloseAll();
        ButtonSettlement.Restore(__LINE__);
        ButtonSettlement.SetText(__LINE__, "マジックナンバー全決済");
        ChartRedraw();
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

    if (EditMagicNumber.HasEdited(__LINE__, id, sparam)) {
        int magic_number = GetMagicNumber();
        if (magic_number > 0) {
            EditMagicNumber.SetText(__LINE__, StringFormat("%d", magic_number));
        }
        else {
            MessageBox("マジックナンバーは1以上の値を指定してください", "エラー");
            EditMagicNumber.SetText(__LINE__, "12345678");
        }
        ChartRedraw();
    }

    if (EditLots.HasEdited(__LINE__, id, sparam)) {
        ChartRedraw();
        double lots = GetLots();
        double min_lots = GetMinLot();
        double max_lots = GetMaxLot();
        if (min_lots <= lots && lots <= max_lots) {
            EditLots.SetText(__LINE__, StringFormat("%.2f", lots));
        }
        else {
            string message = StringFormat("発注ロット数は%.2f以上%.2f以下の値を指定してください", min_lots, max_lots);
            MessageBox(message, "エラー");
            EditLots.SetText(__LINE__, StringFormat("%.2f", min_lots));
        }
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
    int size_y10 = DrawObject::ScaleCoordinate(3.2 * FONT_SIZE1);
    ButtonSettlement.SetFont(FONT_NAME, (int)(1.2 * FONT_SIZE1));
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
//| マジックナンバーの取得                                           |
//+------------------------------------------------------------------+
int GetMagicNumber() {
    int magic_number = (int)StringToInteger(EditMagicNumber.GetText(__LINE__));
    return magic_number;
}

//+------------------------------------------------------------------+
//| 入力された発注ロット数の取得                                     |
//+------------------------------------------------------------------+
double GetLots() {
    double lots = StringToDouble(EditLots.GetText(__LINE__));
    return lots;
}
