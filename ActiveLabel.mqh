//+------------------------------------------------------------------+
//|                                                  ActiveLabel.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#ifndef __MQL45_INCLUDED
#include "MQL45/MQL45.mqh"
#endif

class ActiveLabel MQL45_DERIVERED {
public:
    //+------------------------------------------------------------------+
    //| 改行で区切って処理する                                           |
    //+------------------------------------------------------------------+
    static void Comment(string msg)
    {
        if (IsTesting() && !IsVisualMode()) {
            return;
        }
    
        if (!Initialized) {
            DeleteObjects();
        }
    
        string lines[];
        int count = StringSplit(msg, '\n',lines) - 1;
        for (int i = count; i >= 0 ; --i) {
            string line = i < count ? lines[i] : " ";
            DrawLine(i, line, POSITION_X, POSITION_Y + (count - i) * (FONT_SIZE + LINE_SPACE));
        }
    
        Initialized = true;
    }

    //+------------------------------------------------------------------+
    //| 3桁おきにカンマ区切りの表記の文字列を返す                        |
    //+------------------------------------------------------------------+
    static string FormatComma(double number, int precision, string pcomma = ",", string ppoint = ".")
    {
    	string sign   = number >= 0 ? "+" : "-";
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
        return(sign + formated);
    }  

private:
    //+------------------------------------------------------------------+
    //| プレフィックスで始まるオブジェクトを全削除する                   |
    //+------------------------------------------------------------------+
    static void DeleteObjects()
    {
        for(int i = ObjectsTotal(); i >= 0; i--) {
            string objname = ObjectName(i);
            if (StringFind(objname, "{{LabelComment}}-") >= 0) {
                ObjectDelete(objname);
            }
        }
    }

    //+------------------------------------------------------------------+
    //| 1行ごとにラベルオブジェクトを作成する                            |
    //+------------------------------------------------------------------+
    static void DrawLine(int i, string line, int x, int y)
    {
        string objname = StringFormat("{{LabelComment}}-%08d", i);
        if (!Initialized) {
            ObjectCreate(0, objname, OBJ_LABEL, 0, 0, 0);
            if (!ObjectSetString(0, objname, OBJPROP_FONT, FONT_NAME)) {
                Alert(StringFormat("ObjectSetString(): Error %d", GetLastError()));
            }
            ObjectSetInteger(0, objname, OBJPROP_FONTSIZE, FONT_SIZE);
            ObjectSetInteger(0, objname, OBJPROP_COLOR, FONT_COLOR);
            ObjectSetInteger(0, objname, OBJPROP_CORNER, CORNER_RIGHT_LOWER);
            ObjectSetInteger(0, objname, OBJPROP_XDISTANCE, x);
            ObjectSetInteger(0, objname, OBJPROP_YDISTANCE, y);
        }
        ObjectSetString(0, objname, OBJPROP_TEXT, line);
    }

public:
    static bool Initialized; // 初期化済みフラグ
    static string FONT_NAME; // フォント名
    static color FONT_COLOR;// 文字色
    static int FONT_SIZE;  // フォントサイズ
    static int LINE_SPACE; // 行間
    static int POSITION_X; // オブジェクト群の左側スペース
    static int POSITION_Y;// オブジェクト群の上側スペース
};

bool    ActiveLabel::Initialized = false; // 初期化済みフラグ
string  ActiveLabel::FONT_NAME = "BIZ UDゴシック"; // フォント名
color   ActiveLabel::FONT_COLOR = clrYellow;// 文字色
int     ActiveLabel::FONT_SIZE = 12;  // フォントサイズ
int     ActiveLabel::LINE_SPACE = 2; // 行間
int     ActiveLabel::POSITION_X = 400; // オブジェクト群の右側スペース
int     ActiveLabel::POSITION_Y = 12;// オブジェクト群の下側スペース
