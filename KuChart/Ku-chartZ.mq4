//+------------------------------------------------------------------+
//|                                                     Ku-chart.mq4 |
//|                      Copyright © 2010, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_separate_window
#property indicator_buffers 5

extern int MaxBars = 2000;
extern int TimeOffset = 0;
extern double LineLevel = 5;
extern color Color_USD = Orange;
extern color Color_EUR = Red;
extern color Color_GBP = Lime;
extern color Color_CHF = Snow;
extern color Color_JPY = Turquoise;

string sEURUSD = "EURUSD";
string sEURJPY = "EURJPY";
string sEURCHF = "EURCHF";
string sEURGBP = "EURGBP";
string sUSDJPY = "USDJPY";
string sUSDCHF = "USDCHF";
string sGBPUSD = "GBPUSD";
string sCHFJPY = "CHFJPY";
string sGBPCHF = "GBPCHF";
string sGBPJPY = "GBPJPY";

//---- buffers
double EURAV[];
double USDAV[];
double JPYAV[];
double CHFAV[];
double GBPAV[];

string Indicator_Name = " EUR USD JPY  CHF GBP    ";
int Objs = 0;
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
   SetLevelValue(1,0);
   SetLevelValue(2,LineLevel);
   SetLevelValue(3,-LineLevel);
   
   IndicatorShortName(Indicator_Name);

   int cur = 0; 
   int st = 23;// ~‚Ì’·‚³
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
       
       
   //for(int j=0;j<=4;j++)
   //SetIndexLabel(j,NULL);
//----

   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   for(int i = 0; i < Objs; i++)
     {
      if(!ObjectDelete(Indicator_Name + i))
          Print("error: code #", GetLastError());
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int GetWidth(string sym1){
   int index = StringFind(Symbol(),sym1);
   Print(sym1," ",index);
   if(index == -1) return(1);
   return(3);
}

double GetVal(string sym1,datetime t1,datetime t2){
   double v1,v2;

   //v1 = iClose(sym1,0,iBarShift(sym1,0,t1));
   //v2 = iClose(sym1,0,iBarShift(sym1,0,t2));

   v1 = iMA(sym1,NULL,3,0,MODE_LWMA,PRICE_TYPICAL,iBarShift(sym1,0,t1));
   v2 = iMA(sym1,NULL,3,0,MODE_LWMA,PRICE_TYPICAL,iBarShift(sym1,0,t2));

   //v1 = iCustom(sym1,0,"Jurik filter simple 1",10,0,iBarShift(sym1,0,t1));
   //v2 = iCustom(sym1,0,"Jurik filter simple 1",10,0,iBarShift(sym1,0,t2));

   if(v2==0) return(0);
   return(MathLog(v1/v2)*1000);

}

int start()
  {
   static bool startInit= false;
   if(!startInit)  init();
   startInit= true;
  
   int    counted_bars=IndicatorCounted();
   int i;
//----
   double EURUSD,EURJPY,EURCHF,EURGBP,USDJPY,USDCHF,GBPUSD,CHFJPY,GBPCHF,GBPJPY;
   datetime t1,t2;
       
   CheckBars();
   int limit = MathMin(MaxBars,Bars);

   if(limit <1) return;
  
   for(i=Bars-1;i>limit;i--){
      EURAV[i]= EMPTY_VALUE;
      USDAV[i]= EMPTY_VALUE;
      JPYAV[i]= EMPTY_VALUE;
      CHFAV[i]= EMPTY_VALUE;
      GBPAV[i]= EMPTY_VALUE;
   }
  
   for(i=limit;i>=0;i--){
      t1 = Time[i];
      t2 = MathFloor((Time[i]+TimeOffset*60*60)/86400)*86400-TimeOffset*60*60;
      
      if(t1==t2){
         EURAV[i]= EMPTY_VALUE;
         USDAV[i]= EMPTY_VALUE;
         JPYAV[i]= EMPTY_VALUE;
         CHFAV[i]= EMPTY_VALUE;
         GBPAV[i]= EMPTY_VALUE;
         continue;
      }
      
      
      
      EURUSD = GetVal(sEURUSD,t1,t2);
      EURJPY = GetVal(sEURJPY,t1,t2);
      EURCHF = GetVal(sEURCHF,t1,t2);
      EURGBP = GetVal(sEURGBP,t1,t2);
      USDJPY = GetVal(sUSDJPY,t1,t2);
      USDCHF = GetVal(sUSDCHF,t1,t2);
      GBPUSD = GetVal(sGBPUSD,t1,t2);
      CHFJPY = GetVal(sCHFJPY,t1,t2);
      GBPCHF = GetVal(sGBPCHF,t1,t2);
      GBPJPY = GetVal(sGBPJPY,t1,t2);
 
      
      EURAV[i]=( EURUSD+EURJPY+EURCHF+EURGBP)/4;
      USDAV[i]=(-EURUSD+USDJPY+USDCHF-GBPUSD)/4;
      JPYAV[i]=(-EURJPY-USDJPY-CHFJPY-GBPJPY)/4;
      CHFAV[i]=(-EURCHF-USDCHF+CHFJPY-GBPCHF)/4;
      GBPAV[i]=(-EURGBP+GBPUSD+GBPCHF+GBPJPY)/4;
   }
   //double sum = EURAV[0]+USDAV[0]+JPYAV[0]+CHFAV[0]+GBPAV[0];
   //Comment("Red:EUR Orange:USD Mizu:JPY White:CHF Lime:GBP ");
//----
   return(0);
  }
//+------------------------------------------------------------------+
void sl(string sym, int y, color col)
  {
   int window = WindowFind(Indicator_Name);
   string ID = Indicator_Name+Objs;
   Objs++;
   if(ObjectCreate(ID, OBJ_LABEL, window, 0, 0))
     {
       ObjectSet(ID, OBJPROP_XDISTANCE, y +6);
       ObjectSet(ID, OBJPROP_YDISTANCE, 0);
       ObjectSetText(ID, sym, 18, "Arial Black", col);
     }
  }
//+------------------------------------------------------------------+
int CheckBars(){

   int min = MaxBars;
   string msg = " ";
   int b;
   int total=0;
   b = iBars(sEURUSD,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" E$:"+b;total +=MaxBars-b;
   }
   b = iBars(sEURJPY,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" EJ:"+b;total +=MaxBars-b;
   }
   b = iBars(sEURCHF,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" EC:"+b;total +=MaxBars-b;
   }
      b = iBars(sEURGBP,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" EG:"+b;total +=MaxBars-b;
   }
   b = iBars(sUSDJPY,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" $J:"+b;total +=MaxBars-b;
   }
   b = iBars(sUSDCHF,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" $C:"+b;total +=MaxBars-b;
   }
   b = iBars(sGBPUSD,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" G$:"+b;total +=MaxBars-b;
   }
   b = iBars(sCHFJPY,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" CJ:"+b;total +=MaxBars-b;
   }
   b = iBars(sGBPJPY,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" GJ:"+b;total +=MaxBars-b;
   }
   b = iBars(sGBPCHF,0);
   if(b<MaxBars){
      if(b<min) min = b;
      msg = msg+" GC:"+b;total +=MaxBars-b;
   }
   if(total>0) msg = total+msg;
   int window = WindowFind(Indicator_Name);
   string ID = Indicator_Name+"msg";
   ObjectCreate(ID, OBJ_LABEL, window, 0, 0);
   ObjectSet(ID, OBJPROP_XDISTANCE, 2);
   ObjectSet(ID, OBJPROP_YDISTANCE, 24);
   ObjectSetText(ID, msg, 6, "Courier", DeepPink);
   
   return(min);
}

