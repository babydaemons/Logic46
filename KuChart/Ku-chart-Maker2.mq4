//+------------------------------------------------------------------+
//|                                               Ku-chart-Maker.mq4 |
//|                      Copyright ｩ 2010, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright ｩ 2010, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
#include <WinUser32.mqh>
#define  CHART_CMD_UPDATE_DATA            33324
#define  HEADER_BYTE                        129
#define  DATA_BYTE                           44

#property indicator_separate_window
#property indicator_buffers 8

extern int MaxBars = 2000;//計算するバーの本数


// 平滑化したい場合は下記２つを調整. デフォルトでは rawdataとなる。
extern int MAPeriod = 1;//3;
extern int MAPrice  = PRICE_CLOSE;//PRICE_TYPICAL;
extern int MAMethod = MODE_LWMA;

extern color Color_USD = Orange;
extern color Color_EUR = Red;
extern color Color_GBP = Lime;
extern color Color_CHF = Snow;
extern color Color_JPY = Turquoise;
extern color Color_AUD = RoyalBlue;
extern color Color_CAD = BlueViolet;
extern color Color_NZD = DeepPink;


extern int SelectedLineWidth = 3;//チャートの通貨のラインの太さ

extern int OriginTime = 1000;//1000なら1000本前基準

extern int ZeroLevelShift = 100;//原点のレベル
extern bool UseZeroCheck = true;


extern bool UseUSD = true;//計算に使うかどうか。
extern bool UseEUR = true;
extern bool UseGBP = true;
extern bool UseCHF = true;
extern bool UseJPY = true;
extern bool UseAUD = true;
extern bool UseCAD = true;
extern bool UseNZD = true;








// 基本の6ペア
string sEURUSD = "EURUSD";
string sUSDJPY = "USDJPY";
string sUSDCHF = "USDCHF";
string sGBPUSD = "GBPUSD";
string sAUDUSD = "AUDUSD";
string sUSDCAD = "USDCAD";
string sNZDUSD = "NZDUSD";


//---- buffers
double EURAV[];
double USDAV[];
double JPYAV[];
double CHFAV[];
double GBPAV[];
double AUDAV[];
double CADAV[];
double NZDAV[];

string Indicator_Name = " EUR USD JPY  CHF GBP AUD CAD NZD";
int Objs = 0;
int Pairs = 7;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_LINE,EMPTY,GetWidth("EUR"),Color_EUR);
   SetIndexBuffer(0,EURAV);
   SetIndexLabel(0,"EUR");
   SetIndexStyle(1,DRAW_LINE,EMPTY,GetWidth("USD"),Color_USD);
   SetIndexBuffer(1,USDAV);
   SetIndexLabel(1,"USD");
   SetIndexStyle(2,DRAW_LINE,EMPTY,GetWidth("JPY"),Color_JPY);
   SetIndexBuffer(2,JPYAV);
   SetIndexLabel(2,"JPY");
   SetIndexStyle(3,DRAW_LINE,EMPTY,GetWidth("CHF"),Color_CHF);
   SetIndexBuffer(3,CHFAV);
   SetIndexLabel(3,"CHF");
   SetIndexStyle(4,DRAW_LINE,EMPTY,GetWidth("GBP"),Color_GBP);
   SetIndexBuffer(4,GBPAV);
   SetIndexLabel(4,"GBP");
   
   SetIndexStyle(5,DRAW_LINE,EMPTY,GetWidth("AUD"),Color_AUD);
   SetIndexBuffer(5,AUDAV);
   SetIndexLabel(5,"AUD");
   SetIndexStyle(6,DRAW_LINE,EMPTY,GetWidth("CAD"),Color_CAD);
   SetIndexBuffer(6,CADAV);
   SetIndexLabel(6,"CAD");
   SetIndexStyle(7,DRAW_LINE,EMPTY,GetWidth("NZD"),Color_NZD);
   SetIndexBuffer(7,NZDAV);
   SetIndexLabel(7,"NZD");
   
   if(!UseEUR) SetIndexStyle(0,DRAW_NONE);
   if(!UseUSD) SetIndexStyle(1,DRAW_NONE);
   if(!UseJPY) SetIndexStyle(2,DRAW_NONE);
   if(!UseCHF) SetIndexStyle(3,DRAW_NONE);
   if(!UseGBP) SetIndexStyle(4,DRAW_NONE);
   if(!UseAUD) SetIndexStyle(5,DRAW_NONE);
   if(!UseCAD) SetIndexStyle(6,DRAW_NONE);
   if(!UseNZD) SetIndexStyle(7,DRAW_NONE);
   
   if(!UseEUR) Color_EUR = DimGray;
   if(!UseUSD) Color_USD = DimGray;
   if(!UseJPY) Color_JPY = DimGray;
   if(!UseCHF) Color_CHF = DimGray;
   if(!UseGBP) Color_GBP = DimGray;
   if(!UseAUD) Color_AUD = DimGray;
   if(!UseCAD) Color_CAD = DimGray;
   if(!UseNZD) Color_NZD = DimGray;
   
   Pairs = 7;
   if(!UseEUR) Pairs--;
   if(!UseUSD) Pairs--;
   if(!UseJPY) Pairs--;
   if(!UseCHF) Pairs--;
   if(!UseGBP) Pairs--;
   if(!UseAUD) Pairs--;
   if(!UseCAD) Pairs--;
   if(!UseNZD) Pairs--;
   if(Pairs<1) Alert("Pairs is ",Pairs);
   
   SetLevelValue(0, ZeroLevelShift);

   IndicatorShortName(Indicator_Name);
   
   IndicatorDigits(2);
   
   Objs = 0;
   int cur = 0; 
   int st = 23;// ~の長さが23
   sl("~", cur, Color_EUR);
   cur += st;
   sl("~", cur, Color_USD);
   cur += st;
   sl("~", cur, Color_JPY);
   cur += st;
   sl("~", cur, Color_CHF);
   cur += st;
   sl("~", cur, Color_GBP);
   cur += st;
   sl("~", cur, Color_AUD);
   cur += st;       
   sl("~", cur, Color_CAD);
   cur += st;
   sl("~", cur, Color_NZD);
   cur += st;
//----

   return(0);
  }
void sl(string sym, int y, color col)
  { // ～記号を描く
   int window = WindowFind(Indicator_Name);
   string ID = Indicator_Name+Objs;
   Objs++;
   if(col<0) col=EMPTY_VALUE;//CLR_NONE;
   ObjectCreate(ID, OBJ_LABEL, window, 0, 0);
   ObjectSet(ID, OBJPROP_XDISTANCE, y +6);
   ObjectSet(ID, OBJPROP_YDISTANCE, 0);
   ObjectSetText(ID, sym, 18, "Arial Black", col);
   //Print("ID=",ID," ",col);
  }   
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int GetWidth(string sym1){
   int index = StringFind(Symbol(),sym1);
   if(index == -1) return(1);
   return(SelectedLineWidth);// 選択通貨を含む場合のみラインを太くしている。
}

double GetVal(string sym1,datetime t1,datetime t2){
   double v1,v2;

   v1 = iMA(sym1,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym1,0,t1));
   v2 = iMA(sym1,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym1,0,t2));

   if(v2==0) return(0);
   return(MathLog(v1/v2)*1000);
}

double GetValM(string sym1,string sym2,datetime t1,datetime t2){
   double v1,v2;

   v1 = iMA(sym1,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym1,0,t1));
   v2 = iMA(sym1,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym1,0,t2));

   v1 = v1*iMA(sym2,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym2,0,t1));
   v2 = v2*iMA(sym2,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym2,0,t2));

   if(v2==0) return(0);
   return(MathLog(v1/v2)*1000);
}

double GetValD(string sym1,string sym2,datetime t1,datetime t2){
   double v1,v2,v3,v4;

   v1 = iMA(sym1,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym1,0,t1));
   v2 = iMA(sym1,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym1,0,t2));
   
   v3 = iMA(sym2,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym2,0,t1));
   v4 = iMA(sym2,NULL,MAPeriod,0,MAMethod,MAPrice,iBarShift(sym2,0,t2));
   if(v3==0) return(0);
   if(v4==0) return(0);
   
   v1 = v1/v3;
   v2 = v2/v4;

   if(v2==0) return(0);
   return(MathLog(v1/v2)*1000);
}

int start()
  {
   // ～を描くのに、WindowsFind を呼んでいるが、本当は init では呼んではいけないので、startから呼びなおす。
   static bool startInit= false;
   if(!startInit)  init();
   startInit= true;
   
   int i;
//----
   double EURUSD,EURJPY,EURCHF,EURGBP,USDJPY,USDCHF,GBPUSD,CHFJPY,GBPCHF,GBPJPY,AUDUSD,AUDCHF,AUDJPY,GBPAUD,EURAUD,AUDCAD,USDCAD,GBPCAD,EURCAD,CADCHF,CADJPY;
   double AUDNZD,EURNZD,GBPNZD,NZDCAD,NZDCHF,NZDJPY,NZDUSD;
   datetime t1;
   static datetime t2 = 0;
   static datetime HstWriteTime = 0;
   
   int indicator_counted = IndicatorCounted();
   int limit = MathMin(MaxBars,Bars);
   if(HstWriteTime !=0) limit = MathMin(limit,Bars-indicator_counted+1);
   if(limit <1) return;

   //if(checkDownloadBars()<0) return;
   int ret = checkDownloadBars();
   if(ret <-1) return;//bar が不足。
   if(ret ==2) { limit = MathMin(MaxBars,Bars);HstWriteTime = 0;Print("reload");}//全リロード
   
   //Print("limit=",limit);
   if(t2 == 0) t2 = Time[OriginTime];

   for(i=limit;i>=0;i--){
      t1 = Time[i];

      EURUSD = GetVal(sEURUSD,t1,t2);
      USDJPY = GetVal(sUSDJPY,t1,t2);
      USDCHF = GetVal(sUSDCHF,t1,t2);
      GBPUSD = GetVal(sGBPUSD,t1,t2);
      AUDUSD = GetVal(sAUDUSD,t1,t2);
      USDCAD = GetVal(sUSDCAD,t1,t2);
      
      NZDUSD = GetVal(sNZDUSD,t1,t2);

      EURJPY = GetValM(sEURUSD,sUSDJPY,t1,t2);
      EURCHF = GetValM(sEURUSD,sUSDCHF,t1,t2);
      EURGBP = GetValD(sEURUSD,sGBPUSD,t1,t2);
      CHFJPY = GetValD(sUSDJPY,sUSDCHF,t1,t2);
      GBPCHF = GetValM(sGBPUSD,sUSDCHF,t1,t2);
      GBPJPY = GetValM(sGBPUSD,sUSDJPY,t1,t2);
      AUDCHF = GetValM(sAUDUSD,sUSDCHF,t1,t2);
      AUDJPY = GetValM(sAUDUSD,sUSDJPY,t1,t2);
      AUDCAD = GetValM(sAUDUSD,sUSDCAD,t1,t2);
      EURCAD = GetValM(sEURUSD,sUSDCAD,t1,t2);
      GBPCAD = GetValM(sGBPUSD,sUSDCAD,t1,t2);
      GBPAUD = GetValD(sGBPUSD,sAUDUSD,t1,t2);
      EURAUD = GetValD(sEURUSD,sAUDUSD,t1,t2);
      CADCHF = GetValD(sUSDCHF,sUSDCAD,t1,t2);
      CADJPY = GetValD(sUSDJPY,sUSDCAD,t1,t2);
      
      AUDNZD = GetValD(sAUDUSD,sNZDUSD,t1,t2);
      EURNZD = GetValD(sEURUSD,sNZDUSD,t1,t2);
      GBPNZD = GetValD(sGBPUSD,sNZDUSD,t1,t2);
      NZDCAD = GetValM(sNZDUSD,sUSDCAD,t1,t2);
      NZDCHF = GetValM(sNZDUSD,sUSDCHF,t1,t2);
      NZDJPY = GetValM(sNZDUSD,sUSDJPY,t1,t2);
      
      
      if(!UseNZD){
         AUDNZD = 0;EURNZD = 0;GBPNZD = 0;NZDCAD = 0;NZDCHF = 0;NZDJPY = 0;NZDUSD = 0;
      }
      if(!UseCAD){
         EURCAD = 0;USDCAD = 0;CADJPY = 0;CADCHF = 0;GBPCAD = 0;AUDCAD = 0;NZDCAD = 0;
      }
      if(!UseCHF){
         EURCHF = 0;USDCHF = 0;CHFJPY = 0;GBPCHF = 0;AUDCHF = 0;CADCHF = 0;NZDCHF = 0;
      }
      if(!UseAUD){
         EURAUD = 0;AUDUSD = 0;AUDJPY = 0;AUDCHF = 0;GBPAUD = 0;AUDCAD = 0;AUDNZD = 0;
      }
      if(!UseEUR){
         EURUSD = 0;EURJPY = 0;EURCHF = 0;EURGBP = 0;EURAUD = 0;EURCAD = 0;EURNZD = 0;
      }
      if(!UseUSD){
         EURUSD = 0;USDJPY = 0;USDCHF = 0;GBPUSD = 0;AUDUSD = 0;USDCAD = 0;NZDUSD = 0;
      }
      if(!UseJPY){
         EURJPY = 0;USDJPY = 0;CHFJPY = 0;GBPJPY = 0;AUDJPY = 0;CADJPY = 0;NZDJPY = 0;
      }
      if(!UseGBP){
         EURGBP = 0;GBPUSD = 0;GBPCHF = 0;GBPJPY = 0;GBPAUD = 0;GBPCAD = 0;GBPNZD = 0;
      }
      
      // マイナスの値はチャート化できないので ZeroLevelShift(100)を足す      
      EURAV[i]=( EURUSD+EURJPY+EURCHF+EURGBP+EURAUD+EURCAD+EURNZD)/Pairs + ZeroLevelShift;
      USDAV[i]=(-EURUSD+USDJPY+USDCHF-GBPUSD-AUDUSD+USDCAD-NZDUSD)/Pairs + ZeroLevelShift;
      JPYAV[i]=(-EURJPY-USDJPY-CHFJPY-GBPJPY-AUDJPY-CADJPY-NZDJPY)/Pairs + ZeroLevelShift;
      CHFAV[i]=(-EURCHF-USDCHF+CHFJPY-GBPCHF-AUDCHF-CADCHF-NZDCHF)/Pairs + ZeroLevelShift;
      GBPAV[i]=(-EURGBP+GBPUSD+GBPCHF+GBPJPY+GBPAUD+GBPCAD+GBPNZD)/Pairs + ZeroLevelShift;
      
      AUDAV[i]=(-EURAUD+AUDUSD+AUDJPY+AUDCHF-GBPAUD+AUDCAD+AUDNZD)/Pairs + ZeroLevelShift;
      CADAV[i]=(-EURCAD-USDCAD+CADJPY+CADCHF-GBPCAD-AUDCAD-NZDCAD)/Pairs + ZeroLevelShift;
      NZDAV[i]=(-EURNZD+NZDUSD+NZDJPY+NZDCHF-GBPNZD+NZDCAD-AUDNZD)/Pairs + ZeroLevelShift;
      
      
      if(UseZeroCheck){
         // ゼロより小さくなっていたら警告する。
         if(EURAV[i] < 0){ Alert("ERROR: EURAV is less than ZeroLevel. ",EURAV[i]);return;}
         if(USDAV[i] < 0){ Alert("ERROR: USDAV is less than ZeroLevel. ",USDAV[i]);return;}
         if(JPYAV[i] < 0){ Alert("ERROR: JPYAV is less than ZeroLevel. ",JPYAV[i]);return;}
         if(CHFAV[i] < 0){ Alert("ERROR: CHFAV is less than ZeroLevel. ",CHFAV[i]);return;}
         if(GBPAV[i] < 0){ Alert("ERROR: GBPAV is less than ZeroLevel. ",GBPAV[i]);return;}
         if(AUDAV[i] < 0){ Alert("ERROR: AUDAV is less than ZeroLevel. ",AUDAV[i]);return;}
         if(CADAV[i] < 0){ Alert("ERROR: CADAV is less than ZeroLevel. ",CADAV[i]);return;}
         if(NZDAV[i] < 0){ Alert("ERROR: NZDAV is less than ZeroLevel. ",NZDAV[i]);return;}
      }
      
   }


   if(HstWriteTime==0){
      // 初回
      WriteHistoryHeader("KU_EUR");
      WriteHistoryAll("KU_EUR",EURAV);
      WriteHistoryHeader("KU_USD");
      WriteHistoryAll("KU_USD",USDAV);
      WriteHistoryHeader("KU_JPY");
      WriteHistoryAll("KU_JPY",JPYAV);
      WriteHistoryHeader("KU_CHF");
      WriteHistoryAll("KU_CHF",CHFAV);

      WriteHistoryHeader("KU_GBP");
      WriteHistoryAll("KU_GBP",GBPAV);
      WriteHistoryHeader("KU_AUD");
      WriteHistoryAll("KU_AUD",AUDAV);
      WriteHistoryHeader("KU_CAD");
      WriteHistoryAll("KU_CAD",CADAV);
      WriteHistoryHeader("KU_NZD");
      WriteHistoryAll("KU_NZD",NZDAV);
      
      HstWriteTime = Time[0];

   }else if(HstWriteTime == Time[0]){
      // バーが増えないときの更新
      WriteHistory("KU_EUR",EURAV,2);
      WriteHistory("KU_USD",USDAV,2);
      WriteHistory("KU_JPY",JPYAV,2);
      WriteHistory("KU_CHF",CHFAV,2);
      
      WriteHistory("KU_GBP",GBPAV,2);
      WriteHistory("KU_AUD",AUDAV,2);
      WriteHistory("KU_CAD",CADAV,2);
      WriteHistory("KU_NZD",NZDAV,2);
      
   }else{
      // 新規バー追加の更新
      WriteHistory("KU_EUR",EURAV,1);
      WriteHistory("KU_USD",USDAV,1);
      WriteHistory("KU_JPY",JPYAV,1);
      WriteHistory("KU_CHF",CHFAV,1);
      
      WriteHistory("KU_GBP",GBPAV,1);
      WriteHistory("KU_AUD",AUDAV,1);
      WriteHistory("KU_CAD",CADAV,1);
      WriteHistory("KU_NZD",NZDAV,1);
      
      HstWriteTime = Time[0];
      //PlaySound("tick");
   }
   
   
  //チャートの更新
  UpdateChartWindow("KU_EUR");
  UpdateChartWindow("KU_USD");
  UpdateChartWindow("KU_JPY");
  UpdateChartWindow("KU_CHF");
  UpdateChartWindow("KU_GBP");
  UpdateChartWindow("KU_AUD");
  UpdateChartWindow("KU_CAD");
  UpdateChartWindow("KU_NZD");
    
//----
   return(0);
  }
//+------------------------------------------------------------------+
int checkDownloadBars()
{
   // ここはもう少し丁寧にチェックしたほうが良いだろう・・・
   if(iBars(sEURUSD,0)<MaxBars){ Comment("ERROR: "+sEURUSD+" is "+iBars(sEURUSD,0)); return(-1);}
   if(iBars(sUSDJPY,0)<MaxBars){ Comment("ERROR: "+sUSDJPY+" is "+iBars(sUSDJPY,0)); return(-1);}
   if(iBars(sUSDCHF,0)<MaxBars){ Comment("ERROR: "+sUSDCHF+" is "+iBars(sUSDCHF,0)); return(-1);}
   if(iBars(sGBPUSD,0)<MaxBars){ Comment("ERROR: "+sGBPUSD+" is "+iBars(sGBPUSD,0)); return(-1);}
   if(iBars(sAUDUSD,0)<MaxBars){ Comment("ERROR: "+sAUDUSD+" is "+iBars(sAUDUSD,0)); return(-1);}
   if(iBars(sUSDCAD,0)<MaxBars){ Comment("ERROR: "+sUSDCAD+" is "+iBars(sUSDCAD,0)); return(-1);}
   if(iBars(sNZDUSD,0)<MaxBars){ Comment("ERROR: "+sNZDUSD+" is "+iBars(sNZDUSD,0)); return(-1);}
   
   
   //いずれかの通貨ペアのバーの本数が2本以上増えたら、すべて再描画する。
   static int EURUSDbar=0,USDJPYbar=0,USDCHFbar=0,GBPUSDbar=0,AUDUSDbar=0,USDCADbar=0,NZDUSDbar=0;
   
   bool RefreshChart = false;
   if(iBars(sEURUSD,0)-EURUSDbar > 1) RefreshChart = true;
   if(iBars(sUSDJPY,0)-USDJPYbar > 1) RefreshChart = true;   
   if(iBars(sUSDCHF,0)-USDCHFbar > 1) RefreshChart = true;
   if(iBars(sGBPUSD,0)-GBPUSDbar > 1) RefreshChart = true;
   if(iBars(sAUDUSD,0)-AUDUSDbar > 1) RefreshChart = true;
   if(iBars(sUSDCAD,0)-USDCADbar > 1) RefreshChart = true;
   if(iBars(sNZDUSD,0)-NZDUSDbar > 1) RefreshChart = true;
   
   EURUSDbar = iBars(sEURUSD,0);
   USDJPYbar = iBars(sUSDJPY,0);
   USDCHFbar = iBars(sUSDCHF,0);
   GBPUSDbar = iBars(sGBPUSD,0);
   AUDUSDbar = iBars(sAUDUSD,0);
   USDCADbar = iBars(sUSDCAD,0);
   NZDUSDbar = iBars(sNZDUSD,0);
   
   if(RefreshChart) { Comment("KU-CHART Refreshed..");return(2);}
   
   Comment("");
   return(1);
}
  
//+------------------------------------------------------------------+

int WriteHistoryHeader(string MySymbol)
{
   // hst ファイルのヘッダを書く
   string c_copyright;
   int    i_digits = 2;
   int    i_unused[13] = {0};
   int    version = 400;   

   int FileHandle = FileOpenHistory(MySymbol + Period()+".hst", FILE_BIN|FILE_WRITE);
   c_copyright = "(C)opyright 2003, MetaQuotes Software Corp.";
   FileWriteInteger(FileHandle, version, LONG_VALUE);
   FileWriteString(FileHandle, c_copyright, 64);
   FileWriteString(FileHandle, MySymbol, 12);
   FileWriteInteger(FileHandle, Period(), LONG_VALUE);
   FileWriteInteger(FileHandle, i_digits, LONG_VALUE);
   FileWriteInteger(FileHandle, 0, LONG_VALUE);       //timesign
   FileWriteInteger(FileHandle, 0, LONG_VALUE);       //last_sync
   FileWriteArray(FileHandle, i_unused, 0, ArraySize(i_unused));
   FileFlush(FileHandle);
   FileClose(FileHandle);
   return (0);
}

//+------------------------------------------------------------------+
int WriteHistoryAll(string MySymbol,double &data[])
{
   // 初回は、全データを書き出す
   int FileHandle = FileOpenHistory(MySymbol + Period()+".hst", FILE_BIN|FILE_WRITE|FILE_READ);

   FileSeek(FileHandle,FileSize(FileHandle), SEEK_CUR);

   for(int i=MaxBars;i>=0;i--){
      FileWriteInteger(FileHandle, Time[i], LONG_VALUE);//4
      FileWriteDouble(FileHandle, data[i], DOUBLE_VALUE);//8
      FileWriteDouble(FileHandle, data[i], DOUBLE_VALUE);
      FileWriteDouble(FileHandle, data[i], DOUBLE_VALUE);
      FileWriteDouble(FileHandle, data[i], DOUBLE_VALUE);
      FileWriteDouble(FileHandle, Volume[i], DOUBLE_VALUE);
   }
   FileFlush(FileHandle);
   FileClose(FileHandle);
   return (0);
}
//+------------------------------------------------------------------+
int WriteHistory(string MySymbol,double &data[],int back)
{
   // 2回目からは少し戻って上書きしつつ書き足す
   int FileHandle = FileOpenHistory(MySymbol + Period()+".hst", FILE_BIN|FILE_WRITE|FILE_READ);
   FileSeek(FileHandle,FileSize(FileHandle)-DATA_BYTE*back, SEEK_CUR);

   for(int i=1;i>=0;i--){
      FileWriteInteger(FileHandle, Time[i], LONG_VALUE);
      FileWriteDouble(FileHandle, data[i], DOUBLE_VALUE);
      FileWriteDouble(FileHandle, data[i], DOUBLE_VALUE);
      FileWriteDouble(FileHandle, data[i], DOUBLE_VALUE);
      FileWriteDouble(FileHandle, data[i], DOUBLE_VALUE);
      FileWriteDouble(FileHandle, Volume[i], DOUBLE_VALUE);
   }
   FileFlush(FileHandle);
   FileClose(FileHandle);
   return (0);
}

//+------------------------------------------------------------------+
int UpdateChartWindow(string MySymbol)
{
   int hwnd = 0;

   hwnd = WindowHandle(MySymbol, Period());
   if(hwnd!= 0) {
      if (IsDllsAllowed() == false) {
         //DLL calls must be allowed
         Alert("ERROR: [Allow DLL imports] NOT Checked.");
         return (-1);
      }
      if (PostMessageA(hwnd,WM_COMMAND,CHART_CMD_UPDATE_DATA,0) == 0) {
         //PostMessage failed, chart window closed
         hwnd = 0;
      } else {
         //PostMessage succeed
         return (0);
      }
   }
   //window not found or PostMessage failed
   return (-1);
}
//+------------------------------------------------------------------+







