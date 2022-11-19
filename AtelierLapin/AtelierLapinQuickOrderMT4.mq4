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
class DrawObject {
public:
    DrawObject(int line, ENUM_OBJECT type, string name) {
        obj_name = name;
        obj_type = type;
    }

    void Initialize(int line) {
        if (!ObjectCreate(0, obj_name, obj_type, 0, 0, 0)) {
            int error = GetLastError();
            printf("DrawObject::DrawObject(line %d): ERROR %d", line, error);
            ExpertRemove();
        }

        SetInteger(line, OBJPROP_BACK, false);                      // オブジェクトの背景表示設定
        SetInteger(line, OBJPROP_SELECTABLE, false);                // オブジェクトの選択可否設定
        SetInteger(line, OBJPROP_SELECTED, false);                  // オブジェクトの選択状態
        SetInteger(line, OBJPROP_HIDDEN, false);                    // オブジェクトリスト表示設定
        SetInteger(line, OBJPROP_CORNER, CORNER_RIGHT_LOWER);       // コーナーアンカー設定
        SetInteger(line, OBJPROP_ZORDER, 0);
    }

    void Initialize(int line, int x, int y, int size_x, int size_y) {
        Initialize(line);

        if (obj_type != OBJ_LABEL && obj_type != OBJ_TEXT) {
            SetInteger(line, OBJPROP_XSIZE, size_x);                // ボタンサイズ幅
            SetInteger(line, OBJPROP_YSIZE, size_y);                // ボタンサイズ高さ
        }
        SetInteger(line, OBJPROP_XDISTANCE, x);
        SetInteger(line, OBJPROP_YDISTANCE, y);
    }

    void SetInteger(int line, ENUM_OBJECT_PROPERTY_INTEGER prop_id, long value) {
        if (!ObjectSetInteger(0, obj_name, prop_id, value)) {
            int error = GetLastError();
            printf("DrawObject::SetInteger(line %d): ERROR %d", line, error);
            ExpertRemove();
        }
    }

    void SetString(int line, ENUM_OBJECT_PROPERTY_STRING prop_id, string value) {
        if (!ObjectSetString(0, obj_name, prop_id, value)) {
            int error = GetLastError();
            printf("DrawObject::SetString(line %d): ERROR %d", line, error);
            ExpertRemove();
        }
    }

private:
    string obj_name;
    ENUM_OBJECT obj_type;
};

DrawObject Background(__LINE__, OBJ_RECTANGLE_LABEL, "Background");
DrawObject ButtonSell(__LINE__, OBJ_BUTTON, "ButtonSell");
DrawObject ButtonBuy(__LINE__, OBJ_BUTTON, "ButtonBuy");
DrawObject LabelPrice2(__LINE__, OBJ_LABEL, "LabelPrice2");
DrawObject LabelPrice1(__LINE__, OBJ_LABEL, "LabelPrice1");
DrawObject LabelRatio(__LINE__, OBJ_LABEL, "LabelRatio");
DrawObject EditSymbol2(__LINE__, OBJ_EDIT, "EditSymbol2");
DrawObject EditSymbol1(__LINE__, OBJ_EDIT, "EditSymbol1");
DrawObject EditLots(__LINE__, OBJ_EDIT, "EditLots");
DrawObject EditMagicNumber(__LINE__, OBJ_EDIT, "EditMagicNumber");
DrawObject LabelEnableOrder(__LINE__, OBJ_LABEL, "LabelEnableOrder");
DrawObject LabelSymbol2(__LINE__, OBJ_LABEL, "LabelSymbol2");
DrawObject LabelSymbol1(__LINE__, OBJ_LABEL, "LabelSymbol1");
DrawObject LabelLots(__LINE__, OBJ_LABEL, "LabelLots");
DrawObject LabelMagicNumber(__LINE__, OBJ_LABEL, "LabelMagicNumber");
DrawObject CheckboxEnableOrder(__LINE__, OBJ_BUTTON, "CheckboxEnableOrder");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
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
    Background.Initialize(__LINE__, x00, y00, size_x0, size_y0);
    Background.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'0,0,70');

    int padding_y3 = 8;
    int size_y3 = FONT_SIZE + padding_y3;
    int size_y  = size_y3 + 8;
    int size_x  = FONT_SIZE * 8;

    // 発注ボタンの描画
    int size_x1 = (int)(1.5 * size_x);
    int size_y1 = (int)(1.5 * size_y);
    int x11 = x0 + size_x1 + (size_x / 2);
    int y11 = y0 + size_y1 + 10;
    ButtonSell.Initialize(__LINE__, x11, y11, size_x1, size_y1);
    ButtonSell.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    ButtonSell.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, C'183,183,255');
    ButtonSell.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'205,205,255');
    ButtonSell.SetInteger(__LINE__, OBJPROP_COLOR, C'0,0,255');
    ButtonSell.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    ButtonSell.SetString(__LINE__, OBJPROP_TEXT, "▼Ｓｅｌｌ");
    ButtonSell.SetInteger(__LINE__, OBJPROP_HIDDEN, true);

    x11 += size_x1 + (int)(2.5 * FONT_SIZE);
    ButtonBuy.Initialize(__LINE__, x11, y11, size_x1, size_y1);
    ButtonBuy.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    ButtonBuy.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, C'255,183,183');
    ButtonBuy.SetInteger(__LINE__, OBJPROP_BGCOLOR, C'255,205,205');
    ButtonBuy.SetInteger(__LINE__, OBJPROP_COLOR, C'255,0,0');
    ButtonBuy.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    ButtonBuy.SetString(__LINE__, OBJPROP_TEXT, "▲Ｂｕｙ");
    ButtonBuy.SetInteger(__LINE__, OBJPROP_HIDDEN, true);

    // 価格ラベルの描画
    int x22 = x0 + size_x + FONT_SIZE;
    int y22 = y11 + 2 * size_y;
    LabelPrice2.Initialize(__LINE__, x22, y22, size_x, size_y);
    LabelPrice2.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    LabelPrice2.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    LabelPrice2.SetString(__LINE__, OBJPROP_TEXT, "1756.60");
    LabelPrice2.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y22 += size_y;
    LabelPrice1.Initialize(__LINE__, x22, y22, size_x, size_y);
    LabelPrice1.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    LabelPrice1.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    LabelPrice1.SetString(__LINE__, OBJPROP_TEXT, "245771");
    LabelPrice1.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y22 += size_y;
    LabelRatio.Initialize(__LINE__, x22, y22, size_x, size_y);
    LabelRatio.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    LabelRatio.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    LabelRatio.SetString(__LINE__, OBJPROP_TEXT, "132.913");
    LabelRatio.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    // パラメータ入力エディットオブジェクトの描画
    int x33 = x0 + 2 * size_x + (int)(1.75 * FONT_SIZE);
    int y33 = y11 + 2 * size_y;
    EditSymbol2.Initialize(__LINE__, x33, y33, size_x, size_y3);
    EditSymbol2.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    EditSymbol2.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    EditSymbol2.SetString(__LINE__, OBJPROP_TEXT, "XAUUSD");
    EditSymbol2.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    EditSymbol2.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrLightGray);

    y33 += size_y;
    EditSymbol1.Initialize(__LINE__, x33, y33, size_x, size_y3);
    EditSymbol1.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    EditSymbol1.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    EditSymbol1.SetString(__LINE__, OBJPROP_TEXT, "XAUJPY");
    EditSymbol1.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    EditSymbol1.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrLightGray);

    y33 += size_y;
    EditLots.Initialize(__LINE__, x33, y33, size_x, size_y3);
    EditLots.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    EditLots.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    EditLots.SetString(__LINE__, OBJPROP_TEXT, "0.01");
    EditLots.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    EditLots.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrLightGray);

    y33 += size_y;
    EditMagicNumber.Initialize(__LINE__, x33, y33, size_x, size_y3);
    EditMagicNumber.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    EditMagicNumber.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    EditMagicNumber.SetString(__LINE__, OBJPROP_TEXT, "12345678");
    EditMagicNumber.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    EditMagicNumber.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrLightGray);

    // パラメータ入力ラベルオブジェクトの描画
    int x44 = x11 + 4 * FONT_SIZE - 5;
    int y44 = y11 + size_y;
    LabelEnableOrder.Initialize(__LINE__, x44, y44, size_x, size_y);
    LabelEnableOrder.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    LabelEnableOrder.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    LabelEnableOrder.SetString(__LINE__, OBJPROP_TEXT, "クイック発注ボタン表示");
    LabelEnableOrder.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y44 += size_y;
    LabelSymbol2.Initialize(__LINE__, x44, y44, size_x, size_y);
    LabelSymbol2.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    LabelSymbol2.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    LabelSymbol2.SetString(__LINE__, OBJPROP_TEXT, "　　　　　　　　銘柄２");
    LabelSymbol2.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y44 += size_y;
    LabelSymbol1.Initialize(__LINE__, x44, y44, size_x, size_y);
    LabelSymbol1.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    LabelSymbol1.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    LabelSymbol1.SetString(__LINE__, OBJPROP_TEXT, "　　　　　　　　銘柄１");
    LabelSymbol1.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y44 += size_y;
    LabelLots.Initialize(__LINE__, x44, y44, size_x, size_y);
    LabelLots.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    LabelLots.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    LabelLots.SetString(__LINE__, OBJPROP_TEXT, "　　　　　発注ロット数");
    LabelLots.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    y44 += size_y;
    LabelMagicNumber.Initialize(__LINE__, x44, y44, size_x, size_y);
    LabelMagicNumber.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE);
    LabelMagicNumber.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    LabelMagicNumber.SetString(__LINE__, OBJPROP_TEXT, "　　　マジックナンバー");
    LabelMagicNumber.SetInteger(__LINE__, OBJPROP_COLOR, LABEL_COLOR);

    // クイック発注ボタン表示チェックボックスの描画
    int x55 = x33;
    int y55 = y11 + size_y - 2;
    CheckboxEnableOrder.Initialize(__LINE__, x55, y55, FONT_SIZE + 2, FONT_SIZE + 2);
    CheckboxEnableOrder.SetInteger(__LINE__, OBJPROP_FONTSIZE, FONT_SIZE - 4);
    CheckboxEnableOrder.SetInteger(__LINE__, OBJPROP_BORDER_COLOR, clrBlack);
    CheckboxEnableOrder.SetInteger(__LINE__, OBJPROP_BGCOLOR, clrWhite);
    CheckboxEnableOrder.SetInteger(__LINE__, OBJPROP_COLOR, clrBlack);
    CheckboxEnableOrder.SetString(__LINE__, OBJPROP_FONT, FONT_NAME);
    CheckboxEnableOrder.SetString(__LINE__, OBJPROP_TEXT, "レ");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---

}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
    if (id == CHARTEVENT_OBJECT_CLICK && sparam == "CheckboxEnableOrder") {
        bool pressed = (bool)ObjectGetInteger(0, "CheckboxEnableOrder", OBJPROP_STATE);
        if (pressed) {
        }
        Sleep(500);
    }

}
//+------------------------------------------------------------------+
