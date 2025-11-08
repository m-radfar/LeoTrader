//+------------------------------------------------------------------+
//|                                                    expertLEO.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <stdlib.mqh>

#import "kernel32.dll"
   bool  CreateDirectoryA(string lpPathName, int lpSecurityAttributes);
   uint  GetLastError();
#import

#define CLOSE_BUY 6
#define CLOSE_SELL 7


//+------------------------------------------------------------------+
//| Fibonacci-Erstellen                                              |
//+------------------------------------------------------------------+
struct fibonacci {
    double fibo[19];
};
fibonacci set_fibo(double top, double down){
    
    // fibo rechner
    if (down>top){
        double tmp = down;
        down = top;
        top = tmp;
    }
    fibonacci fibos;
    double length = top-down;
    fibos.fibo[0] = top-(17.944*length);
    fibos.fibo[1] = top-(11.09*length);
    fibos.fibo[2] = top-(6.854*length);
    fibos.fibo[3] = top-(4.236*length);
    fibos.fibo[4] = top-(2.618*length);
    fibos.fibo[5] = top-(1.618*length);
    fibos.fibo[6] = down; // LDown
    fibos.fibo[7] = down+(0.236*length);
    fibos.fibo[8] = top-(0.618*length);
    fibos.fibo[9] = top-(0.5*length); // 50%
    fibos.fibo[10]= top-(0.382*length);
    fibos.fibo[11]= top-(0.236*length);
    fibos.fibo[12]= top; // LTop
    fibos.fibo[13]= down+(1.618*length);
    fibos.fibo[14]= down+(2.618*length);
    fibos.fibo[15]= down+(4.236*length);
    fibos.fibo[16]= down+(6.854*length);
    fibos.fibo[17]= down+(11.09*length);
    fibos.fibo[18]= down+(17.944*length); 
    return fibos;
}


//+------------------------------------------------------------------+
//| Position information in fibonacci_range                          |
//+------------------------------------------------------------------+
struct posFibo{
    double fibo_support;
    double fibo_resistance;
    int fibo_index_support;
    int fibo_index_resistance;

    double aktive_limit_fibo_top;
    double aktive_limit_fibo_down;
    bool fibo_line_is_aktive;
    bool fibo_half_line_is_aktive;

    int aktive_fibo_index;

};
posFibo pos_in_fibo(double value, fibonacci& fibos){

    posFibo pf;
    pf.fibo_support=0;
    pf.fibo_resistance=0;
    pf.fibo_index_support=0;
    pf.fibo_index_resistance=0;

    pf.aktive_limit_fibo_top=0;
    pf.aktive_limit_fibo_down=0;
    pf.fibo_line_is_aktive=false;
    pf.fibo_half_line_is_aktive=false;

    pf.aktive_fibo_index=-1;
    
    for(int i=1; i<18; i++){
        double lowerRef = fibos.fibo[i]-fibos.fibo[i-1];
        double uperRef = fibos.fibo[i+1]-fibos.fibo[i];
        
        double limit_top=fibos.fibo[i]+(0.15*uperRef);
        double limit_down=fibos.fibo[i]-(0.15*lowerRef);

        double fiboHUp=fibos.fibo[i]+(0.25*uperRef);
        double fiboHDown=fibos.fibo[i]-(0.25*lowerRef);

        if(value<limit_top && value>limit_down){
            pf.aktive_limit_fibo_top=limit_top;
            pf.aktive_limit_fibo_down=limit_down;
            pf.aktive_fibo_index=i;
            pf.fibo_index_support=i-1;
            pf.fibo_index_resistance=i+1;
            pf.fibo_support=fibos.fibo[pf.fibo_index_support];
            pf.fibo_resistance=fibos.fibo[pf.fibo_index_resistance];
            pf.fibo_line_is_aktive=true;
            break;
        }
        else if(value<=fiboHUp && value>=fiboHDown){
            pf.fibo_index_support=i-1;
            pf.fibo_index_resistance=i;
            pf.fibo_support=fibos.fibo[pf.fibo_index_support];
            pf.fibo_resistance=fibos.fibo[pf.fibo_index_resistance];
            pf.fibo_half_line_is_aktive=true;
            break;
        }
    }

    return pf;
}

//+------------------------------------------------------------------+
//| class LeoSensors (diverse informationen in bestimmte Zeitframe)  |
//+------------------------------------------------------------------+
class LeoSensors{
    private:
        // private methode
        void update_zigzag_history(void);
        void update_zigFibos(void);
        void update_candelFibos(void);

        // private variable
        int update_indicator_bar;
        int MA_TREND_PERIOD;
        int MA_CUT_PERIOD;

    public:
        // public methode
        void init_Leo(int, int, int);
        void updateLeo(void);
        
        // public variable
        int timeframe;
        
        double zig_zag [10];
        double zig_zag_sensitive [10];

        fibonacci fibo_zig[3];
        fibonacci fibo_zig_sensitive[3];
        fibonacci fibo_candel[3];

        posFibo posFibo_zig[3];
        posFibo posFibo_zig_sen[3];
        posFibo posFibo_candel[3];

        double ma_trend[15];
        double ma_cut[15];

        double macd_sig[15];
        double macd_main[15];

        double stoch_sig[15];
        double stoch_main[15];

        double rsi[15];
        double atr[15];
        long volume[10];
};
void LeoSensors::init_Leo(int tf, int trend, int cut){
    timeframe=tf;

    MA_TREND_PERIOD=trend;
    MA_CUT_PERIOD=cut;

    update_indicator_bar = iBars(Symbol(), timeframe);
    update_zigzag_history();
    int i = 0;
    // init zigzags-fibos by start
    for (i = 0; i<ArraySize(fibo_zig); i++){
        fibo_zig[i] = set_fibo(zig_zag[i+3], zig_zag[i+2]);
    }
    for (i = 0; i<ArraySize(fibo_zig_sensitive); i++){
        fibo_zig_sensitive[i] = set_fibo(zig_zag_sensitive[i+3], zig_zag_sensitive[i+2]);
    }
    
    // init candels-fibos by start 
    for (i = 0; i<ArraySize(fibo_candel); i++){
        fibo_candel[i] = set_fibo(iHigh(Symbol(), timeframe, i+1), iLow(Symbol(), timeframe, i+1));
    }

    // init posFibos
    for (i = 0; i<ArraySize(posFibo_zig); i++)
        posFibo_zig[i]=pos_in_fibo(iClose(Symbol(), timeframe, 0), fibo_zig[i]);

    for (i = 0; i<ArraySize(posFibo_zig_sen); i++)
        posFibo_zig_sen[i]=pos_in_fibo(iClose(Symbol(), timeframe, 0), fibo_zig_sensitive[i]);

    for (i = 0; i<ArraySize(posFibo_zig); i++)
        posFibo_candel[i]=pos_in_fibo(iClose(Symbol(), timeframe, 0), fibo_candel[i]);

    // ------ init indicators ------
    // MA
    for (i = 0 ; i<ArraySize(ma_trend); i++){
        ma_trend[i] = iMA(Symbol(), timeframe, MA_TREND_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, i);
        ma_cut[i] = iMA(Symbol(), timeframe, MA_CUT_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, i); 
    }
    // MACD
    for (i = 0 ; i<ArraySize(macd_main); i++){
        macd_main[i] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, i);
        macd_sig[i] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, i);
    }
    // Stochastic
    for (i = 0 ; i<ArraySize(stoch_sig); i++){
        stoch_main[i] = iStochastic(Symbol(),timeframe,5,3,3,MODE_SMA,0,MODE_MAIN,i);
        stoch_sig[i] = iStochastic(Symbol(),timeframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,i);
    }
    // RSI
    for (i = 0 ; i<ArraySize(rsi); i++){
        rsi[i] = iRSI(Symbol(), timeframe, 14, PRICE_CLOSE, i);
    }
    // ATR
    for (i = 0 ; i<ArraySize(atr); i++){
        atr[i] = iATR(Symbol(), timeframe, 14, i);
    }
    // Volume
    for (i = 0 ; i<ArraySize(volume); i++){
        volume[i] = iVolume(Symbol(), timeframe, i);
    }
}

void LeoSensors::update_zigzag_history(void){
    int shift=0;
    // update zig_zag
    int j=1;
    for(j=1; j<ArraySize(zig_zag); j++)
    {
        do{
            zig_zag[j]=iCustom(Symbol(), timeframe, "ZigZag", 12, 5, 3, 0, shift);
            shift++;
        }while (zig_zag[j]==0);
    }

    // update zig_zag_sensitive
    shift=0;
    for(j=1; j<ArraySize(zig_zag_sensitive); j++)
    {
        do{
            zig_zag_sensitive[j]=iCustom(Symbol(), timeframe, "MyZigZag",6, 0, shift);
            shift++;
        }while (zig_zag_sensitive[j]==0);

    }

}

void LeoSensors::update_zigFibos(void){
    int i=0;
    for(i = ArraySize(fibo_zig)-1; i>0; i--)
        fibo_zig[i] = fibo_zig[i-1];
    
    for(i = ArraySize(fibo_zig_sensitive)-1; i>0; i--)
        fibo_zig_sensitive[i] = fibo_zig_sensitive[i-1];
    
    fibo_zig[0] = set_fibo(zig_zag[3], zig_zag[2]);
    fibo_zig_sensitive[0] = set_fibo(zig_zag_sensitive[3], zig_zag_sensitive[2]);
}

void LeoSensors::update_candelFibos(void){
    for (int i = ArraySize(fibo_candel)-1; i>0; i--)
        fibo_candel[i] = fibo_candel[i-1];
    fibo_candel[0] = set_fibo(iHigh(Symbol(), timeframe, 1), iLow(Symbol(), timeframe, 1));
}

void LeoSensors::updateLeo(void){
    int currentBar = iBars(Symbol(),timeframe);
    if (currentBar == update_indicator_bar){
        // MA
        ma_trend[0] = iMA(Symbol(), timeframe, MA_TREND_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 0);
        ma_cut[0] = iMA(Symbol(), timeframe, MA_CUT_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 0); 
        
        // MACD
        macd_main[0] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
        macd_sig[0] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
        
        // Stochastic
        stoch_main[0] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_MAIN, 0);
        stoch_sig[0] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_SIGNAL, 0);
        
        // RSI
        rsi[0] = iRSI(Symbol(), timeframe, 14, PRICE_CLOSE, 0);
        
        // ATR
        atr[0] = iATR(Symbol(), timeframe, 14, 0);
        
        // Volume
        volume[0] = iVolume(Symbol(), timeframe, 0);

        update_candelFibos();
        update_zigFibos();
        
    }
    else {

        double tmpZZ=iCustom(Symbol(), timeframe, "ZigZag", 12, 5, 3, 0, 0);
        double tmpZZ_sensitive=iCustom(Symbol(), timeframe, "MyZigZag",6, 0, 0);
        if((tmpZZ!=zig_zag[0]) || (tmpZZ_sensitive!=zig_zag_sensitive[0])) update_zigzag_history();
        
        int i = 0;
        // MA
        for (i = ArraySize(ma_cut)-1; i>0; i--){
            ma_trend[i] = ma_trend[i-1];
            ma_cut[i] = ma_cut[i-1];
        }
        ma_trend[1] = iMA(Symbol(), timeframe, MA_TREND_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 1);
        ma_cut[1] = iMA(Symbol(), timeframe, MA_CUT_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 1); 
        ma_trend[0] = iMA(Symbol(), timeframe, MA_TREND_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 0);
        ma_cut[0] = iMA(Symbol(), timeframe, MA_CUT_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 0); 
        
        
        // MACD
        for (i = ArraySize(macd_main)-1; i>0; i--){
            macd_main[i] = macd_main[i-1];
            macd_sig[i] = macd_sig[i-1];
        }
        macd_main[1] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
        macd_sig[1] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 1);
        macd_main[0] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
        macd_sig[0] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
        
        // Stochastic
        for (i = ArraySize(stoch_sig)-1; i>0; i--){
            stoch_main[i] = stoch_main[i-1];
            stoch_sig[i] = stoch_sig[i-1];
        }
        stoch_main[1] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_MAIN, 1);
        stoch_sig[1] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_SIGNAL, 1);
        stoch_main[0] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_MAIN, 0);
        stoch_sig[0] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_SIGNAL, 0);
        
        // RSI
        for (i = ArraySize(rsi)-1; i>0; i--){
            rsi[i] = rsi[i-1];
        }
        rsi[1] = iRSI(Symbol(), timeframe, 14, PRICE_CLOSE, 1);
        rsi[0] = iRSI(Symbol(), timeframe, 14, PRICE_CLOSE, 0);
        
        // ATR
        for (i = ArraySize(atr)-1; i>0; i--){
            atr[i] = atr[i-1];
        }
        atr[1] = iATR(Symbol(), timeframe, 14, 1);
        atr[0] = iATR(Symbol(), timeframe, 14, 0);
        
        // Volume
        for (i = ArraySize(volume)-1; i>0; i--){
            volume[i] = volume[i-1];
        }
        volume[1] = iVolume(Symbol(), timeframe, 1);
        volume[0] = iVolume(Symbol(), timeframe, 0);

        update_indicator_bar = currentBar;
    }
}


//+------------------------------------------------------------------+
//| Order Histories                                                  |
//+------------------------------------------------------------------+
struct MyOrder{
    int ticketNr;
    int type;
    double openPrice;
    double closePrice;
    double TakeProfit;
    double StopLoss;
    double ProfitPoints;
    double Profit;
    datetime openTime;
    datetime closeTime;

} user[10], currRobotBuf, buy_limit, buy_stop, sell_limit, sell_stop, robotHist[10];


// --  Market Informationen
datetime currentTime;
double currentPrice;
double pipValue= 0;
double minStopLevel;
double spread=0;
double lastAsk=0;
double lastBid=0;
double lots;
double minLot;
int vdigits  = 0;

// -- Trade-Steuerungsparameter 
double dontSell_up;
double dontSell_down;
double dontBuy_up;
double dontBuy_down;

double m_buy_limit;
double m_buy_stop;
double m_sell_limit;
double m_sell_stop;

double m_buy_limit_small;
double m_buy_stop_small;
double m_sell_limit_small;
double m_sell_stop_small;

// double buy_limit;
// double buy_stop;
// double sell_limit;
// double sell_stop;
// double atr;

double SecureVol;
input double inpSecureVol = 190;
datetime SecureVolUpdateTime;


bool look4Buy;
bool look4Sell;


// -- Risikomanagement
input double RiskRatio    =   0.02;
input bool ROBOTTRADE = true;
bool buyAllowed =true;
bool sellAllowed =true;


double dailyMaxRisk;
double WeeklyMaxRisk;
datetime weeklyTime;
double totalRiskToday;
double totalProfitToday;
double totalRiskWeek;
double totalProfitWeek;



// -- order
int MAGIC_NO    =   0;
int userOrderTotal = 0;


LeoSensors LS_H4, LS_H1, LS_M30, LS_M15, LS_M5;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //---
    currentTime=TimeCurrent();
    currentPrice = (Ask+Bid)/2;

    Print ("OnInit");
    char x[10]; // to creat magic number based on symbol name
    pipValue   = MarketInfo(Symbol(),MODE_POINT); 
    Print("pipValue:", pipValue);
    minStopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL)*pipValue;  // Mindestabstand zum Stop-Loss

    vdigits = (int)MarketInfo(Symbol(),MODE_DIGITS); 
    minLot = MarketInfo(Symbol(), MODE_MINLOT);
    
    LS_H4.init_Leo(PERIOD_H4, 8, 3);
    LS_H1.init_Leo(PERIOD_H1, 8, 3);

    LS_M30.init_Leo(PERIOD_M30, 8, 3);
    LS_M15.init_Leo(PERIOD_M15, 8, 3);
    LS_M5.init_Leo(PERIOD_M5, 8, 3);


    lastAsk=Ask;
    lastBid=Bid;

    // set a magic number based on Symbol name
    StringToCharArray(Symbol(),x,0,StringLen(Symbol()));

    for (int i=0; i<StringLen(Symbol()); i++)
        MAGIC_NO+=int(x[i])*(int)MathPow(2,i);

    rst_Order_State();
    check_orders_on_init();
    recalcSecureVol();
    updateSensors();
    
    Print("On Init is done");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //---
    Print (MQLInfoString(MQL_PROGRAM_NAME)+" Removed");
   
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    spread = (int)MarketInfo(Symbol(),MODE_SPREAD) * Point;
    currentPrice = (Ask+Bid)/2;
    currentTime = TimeCurrent();
    if(DayDiff(SecureVolUpdateTime,currentTime)>=2 || SecureVol==0) recalcSecureVol();
    
    
    // check, ob die letzte Position immmer noch offen ist 
    if (currRobotBuf.ticketNr>-1) check_order(currRobotBuf);
    updateSensors();
    lastAsk=Ask;
    lastBid=Bid;

    if(TimeDay(robotHist[0].closeTime) != TimeDay(currentTime)){
        totalRiskToday=0;
        totalProfitToday=0;
        buyAllowed=true;
        sellAllowed=true;
    }
    
    if(DayDiff(weeklyTime,currentTime)>7){
        weeklyTime=currentTime;
        totalRiskWeek=0;
        totalProfitWeek=0;
    }

    if (currRobotBuf.ticketNr>-1) checkClose();
    else { //if(currRobotBuf.openTime==0){
        int ticket=0;
        switch(getCMD()){
            /*
            int  OrderSend( 
                        string   symbol,              // symbol 
                        int      cmd,                 // operation 
                        double   volume,              // volume 
                        double   price,               // price 
                        int      slippage,            // slippage 
                        double   stoploss,            // stop loss 
                        double   takeprofit,          // take profit 
                        string   comment=NULL,        // comment 
                        int      magic=0,             // magic number 
                        datetime expiration=0,        // pending order expiration 
                        color    arrow_color=clrNONE  // color 
                        );
                        */
        case OP_BUY:
            if(buyAllowed && ROBOTTRADE &&  currRobotBuf.StopLoss>0){ 
                currRobotBuf.TakeProfit=NormalizeDouble(currRobotBuf.TakeProfit, vdigits);
                currRobotBuf.StopLoss=NormalizeDouble(currRobotBuf.StopLoss, vdigits);
                // currRobotBuf.ticketNr=OrderSend(symbol=Symbol(), cmd=OP_BUY, volume=lots, price=Ask,
                //                                 slippage=3, stoploss=currRobotBuf.StopLoss, takeprofit=currRobotBuf.TakeProfit,
                //                                 comment="AI", magic=MAGIC_NO, expiration=0, arrow_color=Blue);
                currRobotBuf.ticketNr=OrderSend(Symbol(), OP_BUY, lots, Ask,
                                                3, currRobotBuf.StopLoss, currRobotBuf.TakeProfit,
                                                "LeoTrader", MAGIC_NO, 0, Blue);
                Print("ticket: ", ticket);
                if(currRobotBuf.ticketNr<0){
                    Print(GetLastError());
                    PrintFormat("OP_BUY with lots: %f, Ask: %f, StopLoss: %f, TakeProfit: %f ", lots, Ask, currRobotBuf.StopLoss, currRobotBuf.TakeProfit);
                }
                else {
                    currRobotBuf.openPrice=Ask;
                    currRobotBuf.type = OP_BUY;
                }
            }
            else Print("OP_BUY is muted");
            break;

        case OP_SELL:
            if(sellAllowed &&  ROBOTTRADE &&  currRobotBuf.StopLoss>0){ 
                currRobotBuf.TakeProfit=NormalizeDouble(currRobotBuf.TakeProfit, vdigits);
                currRobotBuf.StopLoss=NormalizeDouble(currRobotBuf.StopLoss, vdigits);
                // currRobotBuf.ticketNr=OrderSend(Symbol(),OP_SELL,lots,Bid,3,currRobotBuf.StopLoss,currRobotBuf.TakeProfit,"AI",MAGIC_NO,0,Red);
                currRobotBuf.ticketNr=OrderSend(Symbol(), OP_SELL, lots, Bid,
                                                3, currRobotBuf.StopLoss, currRobotBuf.TakeProfit,
                                                "LeoTrader", MAGIC_NO, 0, Red);
                if(currRobotBuf.ticketNr<0){
                    Print(GetLastError());
                    PrintFormat("OP_SELL with lots: %f, Bid: %f, StopLoss: %f, TakeProfit: %f ", lots, Bid, currRobotBuf.StopLoss, currRobotBuf.TakeProfit);
                }
                else {
                    currRobotBuf.openPrice=Bid;
                    currRobotBuf.type = OP_SELL;
                }
            }
            else Print("OP_SELL is muted");
                
            break;

        case 6:
            break;
        }
    }
    
}


//+------------------------------------------------------------------+
//| update profit                                                    |
//+------------------------------------------------------------------+
void profitUpdate()
{
}

//+------------------------------------------------------------------+
//| update defiened Leo-Sensor                                       |
//+------------------------------------------------------------------+
void updateSensors()
{
    
    LS_H4.updateLeo();
    LS_H1.updateLeo();
    LS_M30.updateLeo();
    LS_M15.updateLeo();
    LS_M5.updateLeo();
    

    Draw();
}

//+------------------------------------------------------------------+
//| care to close or adjust TP/SL                                    |
//+------------------------------------------------------------------+
void checkClose()
{  
    bool needModify=false;
    bool closePos=false;

    if (currRobotBuf.type!=6){
        
        if (currRobotBuf.type==OP_BUY){
            
            
        }

        else if(currRobotBuf.type==OP_SELL){
           
        }

    }// ende Robot


    for (int i=0; i<userOrderTotal; i++){ // for manual opened positions (maybe later will developed)
        if (user[i].type==OP_BUY){
            
        }

        else if(user[i].type==OP_SELL){
            
        }
    }
    
}

//+------------------------------------------------------------------+
//| give command to open or close                                    |
//+------------------------------------------------------------------+
int getCMD()
{
    
    int CMD=6; // CMD=6 : No Action
    /*
        enum        |   value   |  describtion 
        ____________|___________|__________________________      
        OP_BUY      |   0       |  Buy operation
        ____________|___________|__________________________
        OP_SELL     |   1       |  Sell operation
        ____________|___________|__________________________
        OP_BUYLIMIT |   2       |  Buy limit pending order
        ____________|___________|__________________________
        OP_SELLLIMIT|   3       |  Sell limit pending order
        ____________|___________|__________________________
        OP_BUYSTOP  |   4       |  Buy stop pending order
        ____________|___________|__________________________
        OP_SELLSTOP |   5       |  Sell stop pending order
        ____________|___________|__________________________
        ----------- |   6       |  No Action
        ____________|___________|__________________________
    */ 

    // Select CMD
    // ----------
    if(!weekend() && TimeHour(currentTime)<=21 && TimeHour(currentTime)>=1){
        
        // Buy
        // ---
        
        int NRisk=1;

        
        // Sell 
        // ----

        lots = NormalizeDouble(AccountFreeMargin()*RiskRatio*NRisk/(1000.0), 2);
        if(lots<minLot) lots=minLot;
        
    }
    
    return CMD;
}

//+------------------------------------------------------------------+
//| --- find minimum secure volume based on PERIOD_H4 for PERIOD_M5  |
//+------------------------------------------------------------------+
void recalcSecureVol(){
    long sortVol_H4[360];
    int i;
    int arrSize=ArraySize(sortVol_H4);
    int sampelSize=arrSize*3/5;
    for(i=1; i<arrSize; i++)
        sortVol_H4[i]=iVolume(Symbol(), PERIOD_H4, i);
    ArraySort(sortVol_H4); //sort increasingly
    long aveLowVol=0;
    i=0;
    for(int j=0; j<arrSize && i<sampelSize; j++){
        if(sortVol_H4[j]>40){
            aveLowVol+=sortVol_H4[j];
            i++;
        }
    } 

    SecureVol=(double)(aveLowVol/i);
    if(SecureVol>0){
        Print("aveLowVol = ", SecureVol);
        SecureVol/=48;
        Print("SecureVol = ", SecureVol); 
    }
    else{
        SecureVol=inpSecureVol;
    }

    SecureVolUpdateTime=currentTime;
        
}

//+------------------------------------------------------------------+
//| --- calculate time differencies between two datetime             |
//+------------------------------------------------------------------+
int DayDiff(datetime t1, datetime t2)
{
    return ((int)(t2 - t1) / 86400);
}

int HourDiff(datetime t1, datetime t2)
{
    return ((int)(t2 - t1) / 3600);
}

int MinutesDiff(datetime t1, datetime t2)
{
    return ((int)(t2 - t1) / 60);
}

//+------------------------------------------------------------------+
//| --- check if it's going to weekend or market time with low activity|
//+------------------------------------------------------------------+
bool weekend(){
    bool ret=false;
    if(TimeHour(currentTime)>=21 && TimeDayOfWeek(currentTime)==5) ret=true;
    return ret;
}

//+------------------------------------------------------------------+
//| --- visualising object support & resistance                      |
//+------------------------------------------------------------------+
void Draw()
{
    
}

//+------------------------------------------------------------------+
//| check defined order                                              |
//+------------------------------------------------------------------+
void check_order(MyOrder& TargetOrder)
{
    if(OrderSelect(TargetOrder.ticketNr,SELECT_BY_TICKET)==false)
    {
        Print("ERROR - Unable to select the order in check_order() - ",GetLastError());
    }
    else if (TargetOrder.type == OP_BUY || TargetOrder.type == OP_SELL)
    { // open order
        if(TargetOrder.openTime==0)TargetOrder.openTime=OrderOpenTime();
        datetime ctm=OrderCloseTime();
        // sobald die position geschlossen ist, einmal folgendes ausführen  
        if(ctm>0){
            TargetOrder.closeTime=ctm;
            TargetOrder.closePrice = OrderClosePrice();
            TargetOrder.Profit = OrderProfit();
            if(TargetOrder.type==OP_BUY){
                TargetOrder.ProfitPoints=(TargetOrder.closePrice-TargetOrder.openPrice);
            }
            else { // OP_SELL
                TargetOrder.ProfitPoints=(TargetOrder.openPrice-TargetOrder.closePrice);
            }
            // history gewinn und verlust aktualisieren
            reorderPosHistory();
            // profitUpdate();
        }
    }
    
    else{ // pending order

    }
}

//+------------------------------------------------------------------+
//| check orders and positions                                       |
//+------------------------------------------------------------------+
void check_orders_on_init()
{
    int iUser=0;
    for(int i=(OrdersTotal()-1);i>=0;i--)
    {
        
        //If the order cannot be selected throw and log an error
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
        {
            Print("ERROR - Unable to select the order - ",GetLastError());
            break;
        }
        else if(OrderSymbol()==Symbol() && OrderCloseTime()==0)
        {
            int orderType = OrderType();
            // opened orders
            if(orderType==OP_BUY || orderType==OP_SELL){
                if(OrderMagicNumber()==MAGIC_NO){
                    currRobotBuf.ticketNr=OrderTicket();
                    currRobotBuf.openTime=OrderOpenTime();
                    currRobotBuf.type=orderType;
                    currRobotBuf.openPrice=OrderOpenPrice();
                    currRobotBuf.TakeProfit=OrderTakeProfit();
                    currRobotBuf.StopLoss=OrderStopLoss();
                    currRobotBuf.Profit=OrderProfit();
                    
                }
                else{
                    user[iUser].ticketNr=OrderTicket();
                    user[iUser].openTime=OrderOpenTime();
                    user[iUser].type=orderType;
                    user[iUser].openPrice=OrderOpenPrice();
                    user[iUser].TakeProfit=OrderTakeProfit();
                    user[iUser].StopLoss=OrderStopLoss();
                    user[iUser].Profit=OrderProfit();
                    
                    iUser++;
                }
            }

            // pending orders
            else{
                MyOrder temp;
                temp.ticketNr=OrderTicket();
                temp.openTime=OrderOpenTime();
                temp.type=orderType;
                temp.openPrice=OrderOpenPrice();
                temp.TakeProfit=OrderTakeProfit();
                temp.StopLoss=OrderStopLoss();
                temp.Profit=OrderProfit();
                if (orderType==OP_BUYLIMIT) buy_limit=temp;
                else if(orderType==OP_SELLLIMIT) sell_limit=temp;
                else if(orderType==OP_BUYSTOP) buy_stop=temp;
                else if(orderType==OP_SELLSTOP) sell_stop=temp;
            }
            
                
        }       
    }
    userOrderTotal=iUser;
}


//+------------------------------------------------------------------+
//| reorder robotHist array                                          |
//+------------------------------------------------------------------+
void reorderPosHistory(){
    for(int i = ArraySize(robotHist)-1; i>0; i--){
        robotHist[i]=robotHist[i-1];
    }
    robotHist[0]=currRobotBuf;
    rst_Order_State();
}

//+------------------------------------------------------------------+
//| reset order monitoring states                                    |
//+------------------------------------------------------------------+
void rst_Order_State()
{
    currRobotBuf.ticketNr=-1;
    currRobotBuf.openTime=0;
    currRobotBuf.closeTime=0;
    currRobotBuf.type=6;
    currRobotBuf.openPrice=0;
    currRobotBuf.closePrice=0;
    currRobotBuf.TakeProfit=0;
    currRobotBuf.StopLoss=0;
    currRobotBuf.Profit=0;
    currRobotBuf.ProfitPoints=0;
}

void rst_User_Order_State()
{
    for(int i=0; i<userOrderTotal; i++){
        user[i].ticketNr=-1;
        user[i].openTime=0;
        user[i].closeTime=0;
        user[i].type=6;
        user[i].openPrice=0;
        user[i].closePrice=0;
        user[i].TakeProfit=0;
        user[i].StopLoss=0;
        user[i].Profit=0;
        user[i].ProfitPoints=0;
    }

}

//+------------------------------------------------------------------+
//| Close/Modify/delete Orders or set SL & TP                        |
//+------------------------------------------------------------------+
void ModifyTP(int cmd, MyOrder& TargetOrder)
{
    if(OrderSelect(TargetOrder.ticketNr,SELECT_BY_TICKET)==false)
    {
        Print("ERROR - Unable to select the order in ModifyTP() - ",GetLastError());
    }
    else
    {
        double SL=0;
        double TP=0;

        double LastTP=OrderTakeProfit();
        double LastSL=OrderStopLoss();

        if((cmd == OP_BUY) && (OrderType() == OP_BUY)){ // edit TP and SL

            if(TargetOrder.TakeProfit>0)        
                TP = TargetOrder.TakeProfit;
            else
                TP=LastTP;
            if(TargetOrder.StopLoss>0)
                SL=TargetOrder.StopLoss;
            else
                SL=LastSL;
            
            SL=NormalizeDouble(SL, vdigits);
            TP=NormalizeDouble(TP, vdigits);
            if(SL!=LastSL||TP!=LastTP){
                if(!OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP,OrderExpiration(),Blue)){
                int errNr=GetLastError();
                if(errNr==1) ResetLastError();
                else{
                    PrintFormat("Error in TP/SL Modifying for Buy postion. Error code= %d on TargetOrder.ticketNr: %d",errNr, TargetOrder.ticketNr);
                    Print(ErrorDescription(errNr));
                    PrintFormat("Bid= %f and SL= %f", Bid, SL);
                    PrintFormat("Ask= %f and TP= %f", Ask, TP);
                    PrintFormat("Spread= %f", spread);
                    PrintFormat("Vdigits= %d", vdigits);
                }
                } 
            }
        }

        else if((cmd== OP_SELL)&&(OrderType() == OP_SELL)){// edit TP and SL
            if(TargetOrder.TakeProfit>0)        
                TP = TargetOrder.TakeProfit;
            else
                TP=LastTP;
            if(TargetOrder.StopLoss>0)
                SL=TargetOrder.StopLoss;
            else
                SL=LastSL;
            SL=NormalizeDouble(SL, vdigits);
            TP=NormalizeDouble(TP, vdigits);
            if(SL!=LastSL||TP!=LastTP){    
                if(!OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP,OrderExpiration(),Red)){
                int errNr=GetLastError();
                if(errNr==1) ResetLastError();
                else{
                    PrintFormat("Error in TP/SL Modifying for Sell postion. Error code= %d on TargetOrder.ticketNr: %d",errNr, TargetOrder.ticketNr);
                    Print(ErrorDescription(errNr));
                    PrintFormat("Ask= %f and SL= %f", Ask, SL);
                    PrintFormat("Bid= %f and TP= %f", Bid, TP);
                    PrintFormat("Spread= %f", spread);
                    PrintFormat("Vdigits= %d", vdigits);
                }
                }
            }
        }

        else if (cmd == CLOSE_BUY)
        {
        if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
            Print("OrderClose error ",GetLastError());
        
        }

        else if (cmd == CLOSE_SELL)
        {
        if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
            Print("OrderClose error ",GetLastError());
        
        }
    }

}

