//+------------------------------------------------------------------+
//|                                                   DrawObject.mqh |
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
        SetInteger(line, OBJPROP_HIDDEN, true);                     // オブジェクトリスト表示設定
        SetInteger(line, OBJPROP_CORNER, CORNER_LEFT_UPPER);        // コーナーアンカー設定
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

    void GetRectangle(int line, int& x, int& y, int& size_x, int& size_y) {
        x = (int)GetInteger(line, OBJPROP_XDISTANCE);
        y = (int)GetInteger(line, OBJPROP_YDISTANCE);
        size_x = (int)GetInteger(line, OBJPROP_XSIZE);
        size_y = (int)GetInteger(line, OBJPROP_YSIZE);
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

    string Name() {
        return obj_name;
    }

    long GetInteger(int line, ENUM_OBJECT_PROPERTY_INTEGER prop_id) {
        long value = 0;
        if (!ObjectGetInteger(0, obj_name, prop_id, 0, value)) {
            int error = GetLastError();
            printf("DrawObject::GetInteger(line %d): ERROR %d", line, error);
            ExpertRemove();
        }
        return value;
    }

    bool IsTarget(string sparam) {
        return obj_name == sparam;
    }

    void Remove(int line) {
        if (!ObjectDelete(0, obj_name)) {
            int error = GetLastError();
            printf("DrawObject::Remove(line %d): ERROR %d", line, error);
            ExpertRemove();
        }
    }

private:
    string obj_name;
    ENUM_OBJECT obj_type;
};

class TextObject : public DrawObject {
public:
    TextObject(int line, ENUM_OBJECT type, string name) : DrawObject(line, type, name) {}

    static void SetDefaultFont(string name, int size) {
        FONT_NAME = name;
        FONT_SIZE = size;
    }

    void SetFont(string name, int size) {
        font_name = name;
        font_size = size;
    }

    void Initialize(int line, int x, int y, int size_x, int size_y) {
        DrawObject::Initialize(line, x, y, size_x, size_y);
        if (font_name == "" || font_size == 0) {
            font_name = FONT_NAME;
            font_size = FONT_SIZE;
        }
        SetString(line, OBJPROP_FONT, font_name);
        SetInteger(line, OBJPROP_FONTSIZE, font_size);
    }

    void SetText(int line, string text) {
        SetString(line, OBJPROP_TEXT, text);
    }

private:
    string font_name;
    int font_size;

private:
    static string FONT_NAME;
    static int FONT_SIZE;
};

string TextObject::FONT_NAME;
int TextObject::FONT_SIZE;

class LabelObject : public TextObject {
public:
    LabelObject(int line, string name) : TextObject(line, OBJ_LABEL, name) {}

    void Initialize(int line, int x, int y, int size_x, int size_y) {
        TextObject::Initialize(line, x, y, size_x, size_y);
        SetText(line, Name());
        SetInteger(line, OBJPROP_COLOR, COLOR);
    }

    static void SetDefaultColor(color foreground_color) {
        COLOR = foreground_color;
    }

private:
    static color COLOR;
};

color LabelObject::COLOR;

class EditObject : public TextObject {
public:
    EditObject(int line, string name) : TextObject(line, OBJ_EDIT, name) {}

    void Initialize(int line, int x, int y, int size_x, int size_y) {
        TextObject::Initialize(line, x, y, size_x, size_y);
        SetInteger(line, OBJPROP_COLOR, COLOR);
        SetInteger(line, OBJPROP_BORDER_COLOR, BORDER_COLOR);
        SetInteger(line, OBJPROP_BGCOLOR, BACKGROUND_COLOR);
    }

    static void SetDefaultColor(color foreground_color, color border_color, color background_color) {
        COLOR = foreground_color;
        BORDER_COLOR = border_color;
        BACKGROUND_COLOR = background_color;
    }

private:
    static color COLOR;
    static color BORDER_COLOR;
    static color BACKGROUND_COLOR;
};

color EditObject::COLOR;
color EditObject::BORDER_COLOR;
color EditObject::BACKGROUND_COLOR;

class ButtonObject : public TextObject {
public:
    ButtonObject(int line, string name) : TextObject(line, OBJ_BUTTON, name) {}

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

    void Initialize(int line, int x, int y, int size_x, int size_y) {
        TextObject::Initialize(line, x, y, size_x, size_y);
        SetInteger(line, OBJPROP_STATE, checked);
        SetInteger(line, OBJPROP_BORDER_COLOR, clrBlack);
        SetInteger(line, OBJPROP_BGCOLOR, clrWhite);
        SetText(line, "レ");
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

private:
    void UpdateCheck(int line) {
        if (checked) {
            SetInteger(line, OBJPROP_COLOR, clrBlack);
        }
        else {
            SetInteger(line, OBJPROP_COLOR, clrWhite);
        }
    }

private:
    bool checked;
};
