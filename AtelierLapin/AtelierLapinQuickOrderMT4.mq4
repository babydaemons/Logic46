//+------------------------------------------------------------------+
//|                                    AtelierLapinQuickOrderMT4.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class DrawObject
{
public:
    DrawObject(int line, ENUM_OBJECT obj_type, string name, int x, int y, int z, int size_x, int size_y)
    {
        obj_name = name;
        if (!ObjectCreate(0, obj_name, obj_type, 0, 0, 0)) {
            printf("DrawObject::SetInger(line %d): ERROR %d", line, GetLastError());
            ExpertRemove();
        }

        SetInteger(line, OBJPROP_BACK, false);                      // オブジェクトの背景表示設定
        SetInteger(line, OBJPROP_SELECTABLE, false);                // オブジェクトの選択可否設定
        SetInteger(line, OBJPROP_SELECTED, false);                  // オブジェクトの選択状態
        SetInteger(line, OBJPROP_HIDDEN, false);                    // オブジェクトリスト表示設定
        if (obj_type != OBJ_LABEL && obj_type != OBJ_TEXT) {
            SetInteger(line, OBJPROP_XSIZE, size_x);                // ボタンサイズ幅
            SetInteger(line, OBJPROP_YSIZE, size_y);                // ボタンサイズ高さ
        }
        SetInteger(line, OBJPROP_CORNER, CORNER_RIGHT_LOWER);       // コーナーアンカー設定

        SetInteger(line, OBJPROP_XDISTANCE, x);
        SetInteger(line, OBJPROP_YDISTANCE, y);
        SetInteger(line, OBJPROP_ZORDER, z);
    }

    void SetInteger(int line, ENUM_OBJECT_PROPERTY_INTEGER prop_id, long value)
    {
        if (!ObjectSetInteger(0, obj_name, prop_id, value)) {
            printf("DrawObject::SetInger(line %d): ERROR %d", line, GetLastError());
            ExpertRemove();
        }
    }

    void SetString(int line, ENUM_OBJECT_PROPERTY_STRING prop_id, string value)
    {
        if (!ObjectSetString(0, obj_name, prop_id, value)) {
            printf("DrawObject::SetString(line %d): ERROR %d", line, GetLastError());
            ExpertRemove();
        }
    }

private:
    string obj_name;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // オブジェクト全削除
    ObjectsDeleteAll();

    const int FONT_SIZE = 14;
    const string FONT_NAME = "HGｺﾞｼｯｸE";
    const color LABEL_COLOR = clrCyan;

    int x0 = 10;
    int y0 = 10;

    // 背景パネルの描画
    int size_x0 = 36 * FONT_SIZE;
    int size_y0 = 16 * FONT_SIZE;
    int x00 = x0 + size_x0;
    int y00 = y0 + size_y0;
    DrawObject background(__LINE__, OBJ_RECTANGLE_LABEL, "Background", x00, y00, 0, size_x0, size_y0);
    background.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'  0,   0,  70');

    int padding_y3 = 8;
    int size_y3 = FONT_SIZE + padding_y3;
    int size_y  = size_y3 + 8;
    int size_x  = FONT_SIZE * 8;

    // 発注ボタンの描画
    int size_x1 = (int)(1.5 * size_x);
    int size_y1 = (int)(1.5 * size_y);
    int x11 = x0 + size_x1 + (size_x / 2);
    int y11 = y0 + size_y1 + 10;
    DrawObject buttonSell(__LINE__, OBJ_BUTTON, "buttonSell", x11, y11, 0, size_x1, size_y1);
    buttonSell.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    buttonSell.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, C'183, 183, 255');
    buttonSell.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'205, 205, 255');
    buttonSell.SetInteger(__LINE__, OBJPROP_COLOR, C'  0,   0, 255');
    buttonSell.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    buttonSell.SetString(__LINE__, OBJPROP_TEXT, "▼Ｓｅｌｌ");

    x11 += size_x1 + (int)(2.5 * FONT_SIZE);
    DrawObject buttonBuy(__LINE__, OBJ_BUTTON, "buttonBuy", x11, y11, 0, size_x1, size_y1);
    buttonBuy.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    buttonBuy.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, C'255, 183, 183');
    buttonBuy.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'255, 205, 205');
    buttonBuy.SetInteger(__LINE__, OBJPROP_COLOR, C'255,   0,   0');
    buttonBuy.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    buttonBuy.SetString(__LINE__, OBJPROP_TEXT, "▲Ｂｕｙ");

    // 価格ラベルの描画
    int x22 = x0 + size_x + FONT_SIZE;
    int y22 = y11 + 2 * size_y;
    DrawObject labelPrice2(__LINE__, OBJ_LABEL, "labelPrice2", x22, y22, 0, size_x, size_y);
    labelPrice2.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    labelPrice2.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    labelPrice2.SetString(__LINE__, OBJPROP_TEXT, "1756.60");
    labelPrice2.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y22 += size_y;
    DrawObject labelPrice1(__LINE__, OBJ_LABEL, "labelPrice1", x22, y22, 0, size_x, size_y);
    labelPrice1.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    labelPrice1.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    labelPrice1.SetString(__LINE__, OBJPROP_TEXT, "245771");
    labelPrice1.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y22 += size_y;
    DrawObject labelRatio(__LINE__, OBJ_LABEL, "labelRatio", x22, y22, 0, size_x, size_y);
    labelRatio.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    labelRatio.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    labelRatio.SetString(__LINE__, OBJPROP_TEXT, "132.913");
    labelRatio.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    // パラメータ入力エディットオブジェクトの描画
    int x33 = x0 + 2 * size_x + (int)(1.75 * FONT_SIZE);
    int y33 = y11 + 2 * size_y;
    DrawObject editSymbol2(__LINE__, OBJ_EDIT, "editSymbol2", x33, y33, 0, size_x, size_y3);
    editSymbol2.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    editSymbol2.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    editSymbol2.SetString(__LINE__, OBJPROP_TEXT, "XAUUSD");
    editSymbol2.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    editSymbol2.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrLightGray);

    y33 += size_y;
    DrawObject editSymbol1(__LINE__, OBJ_EDIT, "editSymbol1", x33, y33, 0, size_x, size_y3);
    editSymbol1.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    editSymbol1.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    editSymbol1.SetString(__LINE__, OBJPROP_TEXT, "XAUJPY");
    editSymbol1.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    editSymbol1.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrLightGray);

    y33 += size_y;
    DrawObject editLots(__LINE__, OBJ_EDIT, "editLots", x33, y33, 0, size_x, size_y3);
    editLots.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    editLots.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    editLots.SetString(__LINE__, OBJPROP_TEXT, "0.01");
    editLots.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    editLots.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrLightGray);

    y33 += size_y;
    DrawObject editMagicNumber(__LINE__, OBJ_EDIT, "editMagicNumber", x33, y33, 0, size_x, size_y3);
    editMagicNumber.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    editMagicNumber.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    editMagicNumber.SetString(__LINE__, OBJPROP_TEXT, "12345678");
    editMagicNumber.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    editMagicNumber.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrLightGray);

    // パラメータ入力ラベルオブジェクトの描画
    int x44 = x11 + 4 * FONT_SIZE - 5;
    int y44 = y11 + size_y;
    DrawObject labelEnableOrder(__LINE__, OBJ_LABEL, "labelEnableOrder", x44, y44, 0, size_x, size_y);
    labelEnableOrder.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    labelEnableOrder.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    labelEnableOrder.SetString(__LINE__, OBJPROP_TEXT, "クイック発注ボタン表示");
    labelEnableOrder.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y44 += size_y;
    DrawObject labelSymbol2(__LINE__, OBJ_LABEL, "labelSymbol2", x44, y44, 0, size_x, size_y);
    labelSymbol2.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    labelSymbol2.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    labelSymbol2.SetString(__LINE__, OBJPROP_TEXT, "　　　　　　　　銘柄２");
    labelSymbol2.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y44 += size_y;
    DrawObject labelSymbol1(__LINE__, OBJ_LABEL, "labelSymbol1", x44, y44, 0, size_x, size_y);
    labelSymbol1.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    labelSymbol1.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    labelSymbol1.SetString(__LINE__, OBJPROP_TEXT, "　　　　　　　　銘柄１");
    labelSymbol1.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y44 += size_y;
    DrawObject labelLots(__LINE__, OBJ_LABEL, "labelLots", x44, y44, 0, size_x, size_y);
    labelLots.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    labelLots.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    labelLots.SetString(__LINE__, OBJPROP_TEXT, "　　　　　発注ロット数");
    labelLots.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y44 += size_y;
    DrawObject labelMagicNumber(__LINE__, OBJ_LABEL, "labelMagicNumber", x44, y44, 0, size_x, size_y);
    labelMagicNumber.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    labelMagicNumber.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    labelMagicNumber.SetString(__LINE__, OBJPROP_TEXT, "　　　マジックナンバー");
    labelMagicNumber.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    // クイック発注ボタン表示チェックボックスの描画
    int x55 = x33;
    int y55 = y11 + size_y - 2;
    DrawObject checkEnableOrder(__LINE__, OBJ_BUTTON, "checkEnableOrder", x55, y55, 0, FONT_SIZE + 2, FONT_SIZE + 2);
    checkEnableOrder.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE - 4);
    checkEnableOrder.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrBlack);
    checkEnableOrder.SetInteger(__LINE__, OBJPROP_BGCOLOR, clrWhite);
    checkEnableOrder.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    checkEnableOrder.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    checkEnableOrder.SetString(__LINE__, OBJPROP_TEXT, "レ");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---

}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---

}
//+------------------------------------------------------------------+
