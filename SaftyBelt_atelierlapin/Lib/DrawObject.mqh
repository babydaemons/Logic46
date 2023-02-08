//+------------------------------------------------------------------+
//|                                               Lib/DrawObject.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

void Abort(string msg) {
    MessageBox("このダイアログのスクリーンショットを取って\n開発者にお問い合わせください。\n\n" + msg);
    DebugBreak();
}

enum VISUAL_MODE {
    VISUAL_MODE_UNKNOWN,
    VISUAL_MODE_DISABLED,
    VISUAL_MODE_ENABLED
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class DrawObject {
public:
    DrawObject(int line, ENUM_OBJECT type, string name) : obj_name(name), obj_type(type) {}

    enum { DPI100 = 96 };

    static int ScaleCoordinate(double x) {
        int dpi = TerminalInfoInteger(TERMINAL_SCREEN_DPI);
        x = x * ((double)dpi / (double)DPI100);
        return (int)MathRound(x);
    }

    static int ScaleSize(double x, double ratio = 18.0) {
        int dpi = TerminalInfoInteger(TERMINAL_SCREEN_DPI);
        x = MathRound(x - (dpi - DPI100) / ratio);
        return (int)x;
    }

    static int ScaleFontSize(double x, int min) {
        return (int)MathMax(ScaleSize(x, 24.0), min);
    }

private:
    void Initialize(int line) {
        if (!Exist() && !ObjectCreate(0, obj_name, obj_type, 0, 0, 0)) {
            int error = GetLastError();
            Abort(StringFormat("DrawObject::DrawObject(line %d): ERROR %d", line, error));
        }

        SetInteger(line, OBJPROP_BACK, false);                      // オブジェクトの背景表示設定
        SetInteger(line, OBJPROP_SELECTABLE, false);                // オブジェクトの選択可否設定
        SetInteger(line, OBJPROP_SELECTED, false);                  // オブジェクトの選択状態
        SetInteger(line, OBJPROP_HIDDEN, true);                     // オブジェクトリスト表示設定
        SetInteger(line, OBJPROP_CORNER, CORNER_LEFT_UPPER);        // コーナーアンカー設定
        SetInteger(line, OBJPROP_ZORDER, 0);
    }

public:
    void Initialize(int line, int x, int y, int size_x, int size_y, bool scaled = true) {
        if (VisualMode()) {
            return;
        }

        Initialize(line);

        if (scaled) {
            x = ScaleCoordinate(x);
            y = ScaleCoordinate(y);
        }

        SetInteger(line, OBJPROP_XDISTANCE, x);
        SetInteger(line, OBJPROP_YDISTANCE, y);
        SetSize(line, size_x, size_y, scaled);
    }

    void SetSize(int line, int size_x, int size_y, bool scaled = true) {
        if (VisualMode()) {
            return;
        }

        if (scaled) {
            size_x = ScaleCoordinate(size_x);
            size_y = ScaleCoordinate(size_y);
        }

        if (obj_type != OBJ_LABEL && obj_type != OBJ_TEXT) {
            SetInteger(line, OBJPROP_XSIZE, size_x);                // ボタンサイズ幅
            SetInteger(line, OBJPROP_YSIZE, size_y);                // ボタンサイズ高さ
        }
    }

    void GetRectangle(int line, int& x, int& y, int& size_x, int& size_y) {
        if (VisualMode()) {
            x = y = size_x = size_y = 0;
            return;
        }

        x = (int)GetInteger(line, OBJPROP_XDISTANCE);
        y = (int)GetInteger(line, OBJPROP_YDISTANCE);
        size_x = (int)GetInteger(line, OBJPROP_XSIZE);
        size_y = (int)GetInteger(line, OBJPROP_YSIZE);
    }

    void SetInteger(int line, ENUM_OBJECT_PROPERTY_INTEGER prop_id, long value) {
        if (VisualMode()) {
            return;
        }

        if (Exist() && !ObjectSetInteger(0, obj_name, prop_id, value)) {
            int error = GetLastError();
            Abort(StringFormat("DrawObject::SetInteger(line %d): ERROR %d", line, error));
        }
    }

    void SetString(int line, ENUM_OBJECT_PROPERTY_STRING prop_id, string value) {
        if (VisualMode()) {
            return;
        }

        if (Exist() && !ObjectSetString(0, obj_name, prop_id, value)) {
            int error = GetLastError();
            Abort(StringFormat("DrawObject::SetString(line %d): ERROR %d", line, error));
        }
    }

    long GetInteger(int line, ENUM_OBJECT_PROPERTY_INTEGER prop_id) {
        if (VisualMode()) {
            return 0;
        }

        long value = 0;
        if (Exist() && !ObjectGetInteger(0, obj_name, prop_id, 0, value)) {
            int error = GetLastError();
            Abort(StringFormat("DrawObject::GetInteger(line %d): ERROR %d", line, error));
        }
        return value;
    }

    string GetString(int line, ENUM_OBJECT_PROPERTY_STRING prop_id) {
        if (VisualMode()) {
            return "";
        }

        string value = "";
        if (Exist() && !ObjectGetString(0, obj_name, prop_id, 0, value)) {
            int error = GetLastError();
            Abort(StringFormat("DrawObject::GetInteger(line %d): ERROR %d", line, error));
        }
        return value;
    }

    bool IsTarget(string sparam) {
        return obj_name == sparam;
    }

    void Remove(int line) {
        if (VisualMode()) {
            return;
        }

        if (Exist()) {
            if (!ObjectDelete(0, obj_name)) {
                int error = GetLastError();
                Abort(StringFormat("DrawObject::Remove(line %d): ERROR %d", line, error));
            } else {
                OnRemoved();
            }
        }
    }

    string Name() {
        return obj_name;
    }

    static bool HasChartPropertyChanged(int line, int id) {
        return id == CHARTEVENT_CHART_CHANGE;
    }

    bool Exist() {
        if (VisualMode()) {
            return true;
        }

        int subwindow_number = ObjectFind(0, obj_name);
        return subwindow_number >= 0;
    }

protected:
    virtual void OnRemoved() {}

    static bool VisualMode() {
        if (visual_mode == VISUAL_MODE_UNKNOWN) {
#ifdef __MQL4__
            visual_mode = IsVisualMode() ? VISUAL_MODE_ENABLED : VISUAL_MODE_DISABLED;
#else
            visual_mode = MQLInfoInteger(MQL_VISUAL_MODE) == 1 ? VISUAL_MODE_ENABLED : VISUAL_MODE_DISABLED;
#endif
        }
        return visual_mode == VISUAL_MODE_ENABLED;
    }

private:
    string obj_name;
    ENUM_OBJECT obj_type;

    static VISUAL_MODE visual_mode;
};

VISUAL_MODE DrawObject::visual_mode = VISUAL_MODE_UNKNOWN;

class TextObject : public DrawObject {
public:
    TextObject(int line, ENUM_OBJECT type, string name) : DrawObject(line, type, name), prev_text(""), text_color(clrNONE), border_color(clrNONE), background_color(clrNONE) {}

    static void SetDefaultFont(string name, int size) {
        FONT_NAME = name;
        FONT_SIZE = size;
    }

    void SetFont(string name, int size) {
        font_name = name;
        font_size = size;
    }

    static void SetDefaultColor(color text_color, color border_color, color background_color) {
        TEXT_COLOR = text_color;
        BORDER_COLOR = border_color;
        BACKGROUND_COLOR = background_color;
    }

    void SetColor(color text, color border, color background) {
        text_color = text;
        border_color = border;
        background_color = background;
    }

    void Initialize(int line, int x, int y, int size_x, int size_y, bool scaled = true) {
        DrawObject::Initialize(line, x, y, size_x, size_y, scaled);
        if (font_name == "" || font_size == 0) {
            font_name = FONT_NAME;
            font_size = FONT_SIZE;
        }
        SetString(line, OBJPROP_FONT, font_name);
        SetInteger(line, OBJPROP_FONTSIZE, font_size);

        if (text_color == clrNONE) {
            text_color = TEXT_COLOR;
        }
        if (border_color == clrNONE) {
            border_color = BORDER_COLOR;
        }
        if (background_color == clrNONE) {
            background_color = BACKGROUND_COLOR;
        }
    }

    void SetTextValue(int line, string text, bool force = false) {
        if (!SetText(line, text, force)) {
            return;
        }
        if (text == NONE_TEXT) {
            SetInteger(line, OBJPROP_COLOR, NONE_COLOR);
        }
        else {
            SetInteger(line, OBJPROP_COLOR, TEXT_COLOR);
        }
    }

    bool SetText(int line, string text, bool force = false) {
        if (!force && text == prev_text) {
            return false;
        }
        SetString(line, OBJPROP_TEXT, text);
        prev_text = text;
        return true;
    }

    string GetText(int line) {
        prev_text = GetString(line, OBJPROP_TEXT);
        return prev_text;
    }

    bool IsEmpty(int line) {
        return prev_text == "";
    }

    void InitText(int line, string init_text) {
        if (IsEmpty(line)) {
            prev_text = init_text;
        }
        SetString(line, OBJPROP_TEXT, prev_text);
    }

    //+------------------------------------------------------------------+
    //| 3桁おきにカンマ区切りの表記の文字列を返す                        |
    //+------------------------------------------------------------------+
    static string FormatComma(double number, int precision, string pcomma = ",", string ppoint = ".") {
        if (number == FLT_MAX) {
            return NONE_TEXT;
        }

        string sign   = number >= 0 ? "" : "-";
        string snum   = DoubleToString(MathAbs(number), precision);
        int    decp   = StringFind(snum, ".", 0);
        string sright = StringSubstr(snum, decp + 1, precision);
        string sleft  = StringSubstr(snum, 0, decp);
        string formated = "";
        string comma    = "";

        while (StringLen(sleft) > 3) {
            int    length = StringLen(sleft);
            string part   = StringSubstr(sleft, length - 3);
            formated = part + comma + formated;
            comma    = pcomma;
            sleft    = StringSubstr(sleft, 0, length - 3);
        }

        if (sleft != "")   formated = sleft + comma + formated;
        if (precision > 0) formated = formated + ppoint + sright;
        return sign + formated;
    }

protected:
    virtual void OnRemoved() {
        prev_text = "";
    }

    void ApplyTextColor(int line) {
        SetInteger(line, OBJPROP_COLOR, text_color);
    }

    void ApplyBorderColor(int line) {
        SetInteger(line, OBJPROP_BORDER_COLOR, border_color);
    }

    void ApplyBackgroundColor(int line) {
        SetInteger(line, OBJPROP_BGCOLOR, background_color);
    }

private:
    static string FONT_NAME;
    static int FONT_SIZE;

private:
    string font_name;
    int font_size;
    string prev_text;

protected:
    static color TEXT_COLOR;
    static color BORDER_COLOR;
    static color BACKGROUND_COLOR;

protected:
    color text_color;
    color border_color;
    color background_color;

public:
    static const string NONE_TEXT;
    static const color NONE_COLOR;
};

string TextObject::FONT_NAME;
int TextObject::FONT_SIZE;
color TextObject::TEXT_COLOR;
color TextObject::BORDER_COLOR;
color TextObject::BACKGROUND_COLOR;
const string TextObject::NONE_TEXT = "━━━";
const color TextObject::NONE_COLOR = C'0,140,210';

class LabelObject : public TextObject {
public:
    LabelObject(int line, string name) : TextObject(line, OBJ_LABEL, name), prev_value(FLT_MAX) {}

    void Initialize(int line, int x, int y, int size_x, int size_y, bool scaled = true) {
        TextObject::Initialize(line, x, y, size_x, size_y, scaled);
        SetText(line, Name());
        ApplyTextColor(line);
    }

    void SetNumberValue(int line, double value, int digit, bool force = false) {
        if (!force && value == prev_value) {
            return;
        }

        SetText(line, FormatComma(value, digit), force);
        if (value == FLT_MAX) {
            SetInteger(line, OBJPROP_COLOR, NONE_COLOR);
        }
        else if (value < 0) {
            SetInteger(line, OBJPROP_COLOR, clrRed);
        }
        else {
            ApplyTextColor(line);
        }

        prev_value = value;
    }

    double GetValue(int line) {
        return prev_value;
    }

    void SetTextColor(int line, color new_color) {
        text_color = new_color;
        ApplyTextColor(line);
    }

protected:
    virtual void OnRemoved() {
        TextObject::OnRemoved();
        prev_value = FLT_MAX;
    }

private:
    double prev_value;
};

class EditObject : public TextObject {
public:
    EditObject(int line, string name) : TextObject(line, OBJ_EDIT, name) {}

    void Initialize(int line, int x, int y, int size_x, int size_y, bool scaled = true) {
        TextObject::Initialize(line, x, y, size_x, size_y, scaled);
        ApplyTextColor(line);
        ApplyBorderColor(line);
        ApplyBackgroundColor(line);
    }

    bool HasEdited(int line, int id, string sparam) {
        if (id != CHARTEVENT_OBJECT_ENDEDIT) {
            return false;
        }

        if (!IsTarget(sparam)) {
            return false;
        }

		string text = GetString(line, OBJPROP_TEXT);
        SetText(line, text);
        return true;
    }

protected:
    virtual void OnRemoved() {
        /* 編集後のテキスト値を保持するため空実装 */
    }
};

class ButtonObject : public TextObject {
public:
    ButtonObject(int line, string name) : TextObject(line, OBJ_BUTTON, name) {}

    void Initialize(int line, int x, int y, int size_x, int size_y, bool scaled = true) {
        TextObject::Initialize(line, x, y, size_x, size_y, scaled);
        ApplyTextColor(line);
        ApplyBorderColor(line);
        ApplyBackgroundColor(line);
    }

    bool HasPressed(int line, int id, string sparam) {
        if (id != CHARTEVENT_OBJECT_CLICK) {
            return false;
        }

        if (!IsTarget(sparam)) {
            return false;
        }

        if (GetInteger(line, OBJPROP_STATE) == 0) {
            return false;
        }

        return true;
    }

    bool Restore(int line) {
        if (GetInteger(line, OBJPROP_STATE) == false) {
            return false;
        }

        Sleep(100);
        SetInteger(line, OBJPROP_STATE, false);

        return true;
    }
};

class CheckboxObject : public TextObject {
public:
    CheckboxObject(int line, string name, bool init_state) : TextObject(line, OBJ_BUTTON, name), checked(init_state) {}

    void Initialize(int line, int x, int y, int size_x, int size_y, bool scaled = true) {
        TextObject::Initialize(line, x, y, size_x, size_y, scaled);
        SetInteger(line, OBJPROP_STATE, checked);
        SetInteger(line, OBJPROP_BORDER_COLOR, clrBlack);
        SetInteger(line, OBJPROP_BGCOLOR, clrWhite);
        UpdateCheck(line);
    }

    bool HasPressed(int line, int id, string sparam, bool& state) {
        if (id != CHARTEVENT_OBJECT_CLICK) {
            return false;
        }

        if (!IsTarget(sparam)) {
            return false;
        }

        checked = GetInteger(line, OBJPROP_STATE) != 0;
        UpdateCheck(line);
        state = checked;

        return true;
    }

    bool IsChecked(int line) {
        UpdateCheck(line);
        return checked;
    }

private:
    void UpdateCheck(int line) {
        SetInteger(line, OBJPROP_STATE, checked);
        SetInteger(line, OBJPROP_COLOR, checked ? clrBlack : clrWhite);
        SetText(line, checked ? "レ" : "");
    }

private:
    bool checked;
};
//+------------------------------------------------------------------+
