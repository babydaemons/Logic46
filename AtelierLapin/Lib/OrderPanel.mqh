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

const string FONT_NAME = "BIZ UDゴシック";
const int FONT_SIZE = 12;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitPanel() {
    // オブジェクト全削除
    RemovePanel();

    TextObject::SetDefaultFont(FONT_NAME, FONT_SIZE);
    LabelObject::SetDefaultColor(clrCyan);
    EditObject::SetDefaultColor(clrBlack, clrBlack, clrWhite);

    int x0 = 12;
    int y0 = 22;

    // 背景パネルの描画
    int size_x0 = (int)(29.6 * FONT_SIZE);
    int size_y0 = (int)(25.2 * FONT_SIZE);
    int x00 = x0;
    int y00 = y0;
    int line_width = 1;
    Border.Initialize(__LINE__, x00 - line_width, y00 - line_width, size_x0 + 2 * line_width, size_y0 + 2 * line_width);
    Border.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,255');

    Background.Initialize(__LINE__, x00, y00, size_x0, size_y0);
    Background.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,70');

    int margin_y = 3;
    int padding_y = 3;
    int size_y = FONT_SIZE + 2 * margin_y + 2 * padding_y;
    int size_x = FONT_SIZE * 7;

    // パラメータ入力ラベルオブジェクトの描画
    int x1 = x0 + 8;
    int y1 = y0 + 8;
    int y2 = y1;
    LabelMagicNumber.Initialize(__LINE__, x1, y1, size_x, size_y);

    y1 += size_y;
    LabelLots.Initialize(__LINE__, x1, y1, size_x, size_y);

    y1 += size_y;
    LabelSymbol.Initialize(__LINE__, x1, y1, size_x, size_y);

    y1 += size_y;
    LabelMargin.Initialize(__LINE__, x1, y1, size_x, size_y);

    y1 += size_y;
    LabelSize.Initialize(__LINE__, x1, y1, size_x, size_y);

    y1 += size_y;
    LabelSwapType.Initialize(__LINE__, x1, y1, size_x, size_y);

    y1 += size_y;
    LabelBuySwap.Initialize(__LINE__, x1, y1, size_x, size_y);

    y1 += size_y;
    LabelSellSwap.Initialize(__LINE__, x1, y1, size_x, size_y);

    // パラメータ入力エディットオブジェクトの描画
    int x2 = x0 + (int)(2.4 * size_x);
    EditMagicNumber.Initialize(__LINE__, x2, y2 - margin_y, size_x, size_y - padding_y);
    EditMagicNumber.SetText(__LINE__, "12345678");

    y2 += size_y;
    EditLots.Initialize(__LINE__, x2, y2 - margin_y, size_x, size_y - padding_y);
    EditLots.SetText(__LINE__, "0.01");

    y2 += size_y;
    LabelOrderSymbol.Initialize(__LINE__, x2, y2, size_x, size_y);
    LabelOrderSymbol.SetText(__LINE__, Symbol());

    y2 += size_y;
    LabelOrderMargin.Initialize(__LINE__, x2, y2, size_x, size_y);

    y2 += size_y;
    LabelOrderSize.Initialize(__LINE__, x2, y2, size_x, size_y);

    y2 += size_y;
    LabelOrderSwapType.Initialize(__LINE__, x2, y2, size_x, size_y);

    y2 += size_y;
    LabelOrderBuySwap.Initialize(__LINE__, x2, y2, size_x, size_y);

    y2 += size_y;
    LabelOrderSellSwap.Initialize(__LINE__, x2, y2, size_x, size_y);

    // 発注ボタンの描画
    int size_x1 = (int)(1.75 * size_x);
    int size_y1 = (int)(1.5 * size_y);
    int x3 = x1;
    int y3 = y2 + (int)(2.1 * FONT_SIZE);
    ButtonBuy.Initialize(__LINE__, x3, y3, size_x1, size_y1);
    ButtonBuy.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, C'255,0,0');
    ButtonBuy.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'255,205,205');
    ButtonBuy.SetInteger(__LINE__, OBJPROP_COLOR, C'255,0,0');
    ButtonBuy.SetString(__LINE__, OBJPROP_TEXT, "Ｂｕｙ");

    x3 += (int)(1.3 * size_x1);
    ButtonSell.Initialize(__LINE__, x3, y3, size_x1, size_y1);
    ButtonSell.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, C'0,0,255');
    ButtonSell.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'205,205,255');
    ButtonSell.SetInteger(__LINE__, OBJPROP_COLOR, C'0,0,255');
    ButtonSell.SetString(__LINE__, OBJPROP_TEXT, "Ｓｅｌｌ");

    int y4 = y3 + size_y1 + FONT_SIZE;
    LabelProfit.Initialize(__LINE__, x1, y4, size_x, size_y);
    LabelOrderProfit.Initialize(__LINE__, x2, y4, size_x, size_y);

    // クイック決済ボタン表示チェックボックスの描画
    y4 += size_y;
    LabelEnableOrder.Initialize(__LINE__, x1, y4, size_x, size_y);
    CheckboxEnableSettlement.SetFont(FONT_NAME, FONT_SIZE - 4);
    CheckboxEnableSettlement.Initialize(__LINE__, x2, y4, FONT_SIZE + 2, FONT_SIZE + 2);

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
        SendBuyOrder();
        ButtonBuy.Restore(__LINE__);
    }

    if (ButtonSell.HasPressed(__LINE__, id, sparam)) {
        SendSellOrder();
        ButtonSell.Restore(__LINE__);
    }

    if (ButtonSettlement.HasPressed(__LINE__, id, sparam)) {
        SendOrderCloseAll();
        ButtonSettlement.Restore(__LINE__);
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
    }

    if (EditLots.HasEdited(__LINE__, id, sparam)) {
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
    int x = panel_x + 1;
    int y = panel_y + panel_size_y;
    int size_x = panel_size_x;
    int size_y = DrawObject::ConvertDPI((int)(FONT_SIZE * 2.8));
    ButtonSettlement.SetFont(FONT_NAME, (int)(1.2 * FONT_SIZE));
    ButtonSettlement.Initialize(__LINE__, x, y, size_x, size_y, false);
    ButtonSettlement.SetInteger(__LINE__, OBJPROP_COLOR, clrRed);
    ButtonSettlement.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'255,220,110');
    ButtonSettlement.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrOrange);
    ButtonSettlement.SetText(__LINE__, "マジックナンバー全決済");
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HideSettlementButton() {
    ButtonSettlement.Remove(__LINE__);
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
