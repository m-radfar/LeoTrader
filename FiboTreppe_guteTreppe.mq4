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
#import

#define CLOSE_BUY 6
#define CLOSE_SELL 7
#define DELETE_PENDING 8
#define MODIFY_PENDING 9

#define max_robo_pos 3

#define DIR_SELL -1
#define DIR_NONE 0
#define DIR_BUY  1

#define PLAN_NONE        0
#define PLAN_BREAKOUT    1
#define PLAN_RETEST      2
#define PLAN_RANGE_SWING 3
#define PLAN_TREND_CONT  4

#define SIG_NONE             0
#define SIG_TREND_ALIGN      1
#define SIG_BREAKOUT         2
#define SIG_RETEST           3
#define SIG_EXHAUSTION       4
#define SIG_RANGE_BOUNCE     5
#define SIG_FALSE_BREAKOUT   6
#define SIG_CONTINUATION     7


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
    zig_zag[0]=iCustom(Symbol(), timeframe, "ZigZag", 12, 5, 3, 0, shift);
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
    zig_zag_sensitive[0]=iCustom(Symbol(), timeframe, "MyZigZag",6, 0, shift);
    for(j=1; j<ArraySize(zig_zag_sensitive); j++)
    {
        do{
            zig_zag_sensitive[j]=iCustom(Symbol(), timeframe, "MyZigZag",6, 0, shift);
            shift++;
        }while (zig_zag_sensitive[j]==0);

    }

}


void LeoSensors::updateLeo(void){
    double tmpZZ=iCustom(Symbol(), timeframe, "ZigZag", 12, 5, 3, 0, 0);
    double tmpZZ_sensitive=iCustom(Symbol(), timeframe, "MyZigZag",6, 0, 0);
    if((tmpZZ!=zig_zag[0]) || (tmpZZ_sensitive!=zig_zag_sensitive[0])) update_zigzag_history();

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

        // update_candelFibos
        fibo_candel[0] = set_fibo(iHigh(Symbol(), timeframe, 1), iLow(Symbol(), timeframe, 1));
        posFibo_candel[0]=pos_in_fibo(currentPrice, fibo_candel[0]);
        
        // update_zigFibos
        fibo_zig[0] = set_fibo(zig_zag[3], zig_zag[2]);
        posFibo_zig[0]=pos_in_fibo(currentPrice, fibo_zig[0]);
        fibo_zig_sensitive[0] = set_fibo(zig_zag_sensitive[3], zig_zag_sensitive[2]);
        posFibo_zig_sen[0]=pos_in_fibo(currentPrice, fibo_zig_sensitive[0]);
        
    }
    else {
        int i = 0;

        // update_candelFibos
        for (i = ArraySize(fibo_candel)-1; i>0; i--)
            fibo_candel[i] = fibo_candel[i-1];
        fibo_candel[0] = set_fibo(iHigh(Symbol(), timeframe, 1), iLow(Symbol(), timeframe, 1));
        

        // update_zigFibos
        for(i = ArraySize(fibo_zig)-1; i>0; i--)
            fibo_zig[i] = fibo_zig[i-1];
        fibo_zig[0] = set_fibo(zig_zag[3], zig_zag[2]);
        
        
        for(i = ArraySize(fibo_zig_sensitive)-1; i>0; i--)
            fibo_zig_sensitive[i] = fibo_zig_sensitive[i-1];
        fibo_zig_sensitive[0] = set_fibo(zig_zag_sensitive[3], zig_zag_sensitive[2]);
        

        // update posFibos
        for (i = ArraySize(posFibo_zig)-1; i>0; i--)
            posFibo_zig[i]=posFibo_zig[i-1];
        posFibo_zig[0] = pos_in_fibo(currentPrice, fibo_zig[0]);

        for (i = ArraySize(posFibo_zig_sen)-1; i>0; i--)
            posFibo_zig_sen[i]=posFibo_zig_sen[i-1];
        posFibo_zig_sen[0] = pos_in_fibo(currentPrice, fibo_zig_sensitive[0]);

        for (i = ArraySize(posFibo_candel)-1; i>0; i--)
            posFibo_candel[i]=posFibo_candel[i-1];
        posFibo_candel[0] = pos_in_fibo(currentPrice, fibo_candel[0]);

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

} user[], aktiveRobotOrder, pending_buy_limit, pending_sell_limit, pending_buy_stop, pending_sell_stop, robotHist[10];

struct TFSignal {
    int timeframe;
    int trendDir;
    int breakoutDir;
    int exhaustionDir;
    int swingDir;
    double support;
    double resistance;
    double atr;
    double rsi;
    double stochMain;
    double stochSignal;
    double macdMain;
    double macdSignal;
    double trendScore;
    double breakoutScore;
    double exhaustionScore;
    double fiboScore;
};

struct TFRelation {
    int smallTf;
    int bigTf;
    int trendAgreement;
    int breakoutAgainstBig;
    int pullbackToBig;
    int exhaustionAtBigZone;
    double scoreBuy;
    double scoreSell;
};

struct SignalEvent {
    int type;
    int timeframe;
    int direction;
    double level;
    double invalidLevel;
    double targetLevel;
    double strength;
    datetime time;
    string reason;
};

struct TargetMap {
    double entry;
    double slInitial;
    double slCurrent;
    double tp1;
    double tp2;
    double tp3;
    double trailLevel;
    int activeTarget;
};

struct TradePlan {
    int planType;
    int cmd;
    int direction;
    double confidence;
    SignalEvent triggerSignal;
    SignalEvent invalidationSignal;
    SignalEvent targetSignal;
    SignalEvent managementSignal;
    TargetMap targets;
};


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

double buy_limit;
double buy_stop;
double sell_limit;
double sell_stop;
// double atr;

double SecureVol;
input double inpSecureVol = 190;
datetime SecureVolUpdateTime;


bool look4Buy;
bool look4Sell;


// -- Risikomanagement
input double RiskRatio    =   0.02;
input bool ROBOTTRADE = true;
input double FiboSLBufferATR = 0.60;
input double BreakoutEntryBufferATR = 0.25;
input double MaxPullbackEntryATR = 2.20;
input double TrailStartRiskRatio = 1.00;
input double BreakEvenBufferATR = 0.10;
input bool ExportOptimizationCsv = true;
input string OptimizationCsvName = "fibo_optimierung.csv";
input bool OptimizationCsvUseCommonFolder = false;
input bool UseNewsFilter = true;
input string NewsCsvName = "fibo_news_events.csv";
input int NewsServerUtcOffsetHours = 0;
input bool DeletePendingOrdersBeforeNews = true;
input double NewsRiskMultiplier = 0.0;
input bool OptimizationBreakoutOnly = true;
input double MinPlanRiskM30ATR = 0.80;
input bool EnableRangeRelativeBreakout = false;
input double RangeRelativeMinM30ATR = 0.35;
input double RangeRelativeMaxM30ATR = 0.75;
input double AmbiguousRangeMaxM30ATR = 1.25;
input int MaxDirectionalExhaustionStack = 3;
input bool PendingTrapModifyOncePerM5Bar = true;
input int PendingTrapMinModifySeconds = 300;
input double PendingTrapMinModifyATR = 0.20;
input bool PendingStopAllowCloserEntry = false;
input bool PendingTrapAllowRiskIncrease = false;
input bool AvoidWeakM30FiboTrapZones = true;
input bool AvoidWeakTrapRiskBand = true;
input double WeakTrapRiskBandMinM30ATR = 1.00;
input double WeakTrapRiskBandMaxM30ATR = 1.25;
input bool DeleteOrphanPendingWhenPlanLost = true;
input double OrphanPendingKeepWideRangeM30ATR = 1.25;
input bool AvoidCompressedStopRange = true;
input double CompressedStopRangeMaxM30ATR = 0.50;
input bool AvoidWideNoConfirmStop = true;
input double WideNoConfirmMinM30ATR = 1.25;


double dailyMaxRisk;
double WeeklyMaxRisk;
datetime weeklyTime;
double totalRiskToday;
double totalProfitToday;
double totalRiskWeek;
double totalProfitWeek;



// -- order
int MAGIC_NO    =   0;


LeoSensors LS_H4, LS_H1, LS_M30, LS_M15, LS_M5;

TFSignal sig_H4, sig_H1, sig_M30, sig_M15, sig_M5;
TFRelation rel_H1_H4, rel_M30_H1, rel_M15_M30, rel_M5_M15;
TFRelation rel_M30_H4, rel_M15_H1, rel_M5_M30;
TradePlan robotPlan, activeRobotPlan;
int optimizationCsvHandle = INVALID_HANDLE;
datetime lastOptimizationCsvBarTime = 0;
int lastOptimizationCsvCmd = 6;
double lastOptimizationCsvEntry = 0;
bool optimizationCsvAnnounced = false;
datetime lastBuyLimitModifyBar = 0;
datetime lastSellLimitModifyBar = 0;
datetime lastBuyStopModifyBar = 0;
datetime lastSellStopModifyBar = 0;
datetime lastBuyLimitModifyTime = 0;
datetime lastSellLimitModifyTime = 0;
datetime lastBuyStopModifyTime = 0;
datetime lastSellStopModifyTime = 0;
datetime newsStartTimes[];
datetime newsEndTimes[];
string newsCurrencies[];
string newsImpacts[];
string newsNames[];
int newsModes[];
int newsEventCount = 0;
string activeNewsName = "";
datetime activeNewsUntil = 0;
bool newsCsvAnnounced = false;
string csvFolderName = "";
string csvFolderFullPath = "";
string optimizationCsvPath = "";
string optimizationCsvFullPath = "";
string newsCsvPath = "";

void ResetSignalEvent(SignalEvent& sig);
void ResetTargetMap(TargetMap& targets);
void ResetTradePlan(TradePlan& plan);
double TradeMinDistance();
double FiboRiskBuffer(double atr);
double BreakoutEntryBuffer(double atr);
bool BuyPullbackExpected();
bool SellPullbackExpected();
double BuyFiboTrailCandidate(double maxAllowedSL);
double SellFiboTrailCandidate(double minAllowedSL);
bool StrongCloseInvalidation(int orderType);
void NormalizeTradePlanTargets(TradePlan& plan);
bool TradePlanHasValidTargets(TradePlan& plan);
void AnalyseLeoSensor(LeoSensors& LS, TFSignal& sig);
void BuildTFRelation(TFSignal& smallSig, TFSignal& bigSig, TFRelation& rel);
void BuildTradePlan();
void ApplyTradePlanToOrderSlots();
bool ApplyOrModifyExistingPendingPlan();
bool PendingTrapCanModify(int cmd, MyOrder& existingOrder);
bool PendingPlanNeedsModify(MyOrder& existingOrder);
bool PendingTrapMoveAllowed(int cmd, MyOrder& existingOrder);
void MarkPendingTrapModified(int cmd);
void DeleteRobotPendingOrders();
void DeleteInvalidPendingOrders();
bool PendingSignalStillValid(int cmd);
int CmdDirection(int cmd);
int DirectionalBigTrendStack(int dir);
bool PendingPlanContextStillValid(int cmd);
string CurrentTradeCluster(int cmd);
void ManageRobotTargets();
void ModifyTP(int cmd, MyOrder& TargetOrder);
string OrderCmdName(int cmd);
void ResetOrder(MyOrder& o);
bool OpenOptimizationCsv();
void CloseOptimizationCsv();
void WriteOptimizationCsv(bool force);
bool EnsureCsvFolder();
bool EnsureDefaultNewsCsv();
void LoadNewsEvents();
bool IsNewsWindowActive();
bool IsLimitOrderCmd(int cmd);
bool IsStopOrderCmd(int cmd);
double CurrentPlanRiskM30ATR();
bool OptimizationFiltersAllowPlan(int cmd);
double CurrentM30RangeATR();
int DirectionalBreakoutStack(int dir);
int DirectionalExhaustionStack(int dir);
bool BuildRangeRelativeBreakoutPlan(double buyScore, double sellScore);
void CsvAddString(string& line, string value);
void CsvAddInt(string& line, int value);
void CsvAddLong(string& line, long value);
void CsvAddDouble(string& line, double value);
void CsvAddSensorHeader(string& line, string prefix);
void CsvAddSensorValues(string& line, LeoSensors& LS, TFSignal& sig);

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
    get_orders_on_init();
    recalcSecureVol();
    EnsureCsvFolder();
    if(MQL_TESTER)
        OpenOptimizationCsv();
    LoadNewsEvents();
    updateSensors();
    if(MQL_TESTER)
        WriteOptimizationCsv(true);
    
    Print("On Init is done");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //---
    if(MQL_TESTER){
        WriteOptimizationCsv(true);
        CloseOptimizationCsv();
    }
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
    
    
    // check, ob die letzte(n) Position(en) immmer noch offen ist(/sind) und user keine neue Position geöffnet hat 
    updateOrders();
    if (aktiveRobotOrder.ticketNr>-1) check_order(aktiveRobotOrder);
        
    updateSensors();
    if(MQL_TESTER)
        WriteOptimizationCsv(false);
    lastAsk=Ask;
    lastBid=Bid;
    if(IsNewsWindowActive() && DeletePendingOrdersBeforeNews)
        DeleteRobotPendingOrders();
    if (aktiveRobotOrder.ticketNr<0)
        DeleteInvalidPendingOrders();

    if(TimeDay(robotHist[0].closeTime) != TimeDay(currentTime)){
        totalRiskToday=0;
        totalProfitToday=0;
    }
    
    if(DayDiff(weeklyTime,currentTime)>7){
        weeklyTime=currentTime;
        totalRiskWeek=0;
        totalProfitWeek=0;
    }

    if (aktiveRobotOrder.ticketNr>-1){
        DeleteRobotPendingOrders();
        checkClose();
    }
    else {
        int ticket=0;
        switch(getCMD()){

        case OP_BUY:
            if(ROBOTTRADE &&  aktiveRobotOrder.StopLoss>0){ 
                aktiveRobotOrder.TakeProfit=NormalizeDouble(aktiveRobotOrder.TakeProfit, vdigits);
                aktiveRobotOrder.StopLoss=NormalizeDouble(aktiveRobotOrder.StopLoss, vdigits);
                aktiveRobotOrder.ticketNr=OrderSend(Symbol(), OP_BUY, lots, Ask,
                                                3, aktiveRobotOrder.StopLoss, aktiveRobotOrder.TakeProfit,
                                                "LeoTrader", MAGIC_NO, 0, Blue);
                Print("ticket: ", ticket);
                if(aktiveRobotOrder.ticketNr<0){
                    LogTradeError("OrderSend", GetLastError(), OP_BUY, aktiveRobotOrder.ticketNr,
                                  lots, Ask, aktiveRobotOrder.StopLoss, aktiveRobotOrder.TakeProfit);
                }
            }
            else Print("OP_BUY is muted");
            break;

        case OP_SELL:
            if(ROBOTTRADE &&  aktiveRobotOrder.StopLoss>0){ 
                aktiveRobotOrder.TakeProfit=NormalizeDouble(aktiveRobotOrder.TakeProfit, vdigits);
                aktiveRobotOrder.StopLoss=NormalizeDouble(aktiveRobotOrder.StopLoss, vdigits);
                aktiveRobotOrder.ticketNr=OrderSend(Symbol(), OP_SELL, lots, Bid,
                                                3, aktiveRobotOrder.StopLoss, aktiveRobotOrder.TakeProfit,
                                                "LeoTrader", MAGIC_NO, 0, Red);
                if(aktiveRobotOrder.ticketNr<0){
                    LogTradeError("OrderSend", GetLastError(), OP_SELL, aktiveRobotOrder.ticketNr,
                                  lots, Bid, aktiveRobotOrder.StopLoss, aktiveRobotOrder.TakeProfit);
                }
            }
            else Print("OP_SELL is muted");
                
            break;

        case OP_BUYLIMIT:
            if(ROBOTTRADE &&  pending_buy_limit.ticketNr < 0){
                pending_buy_limit.TakeProfit=NormalizeDouble(pending_buy_limit.TakeProfit, vdigits);
                pending_buy_limit.StopLoss=NormalizeDouble(pending_buy_limit.StopLoss, vdigits);
                pending_buy_limit.ticketNr=OrderSend(Symbol(), OP_BUYLIMIT, lots, pending_buy_limit.openPrice,
                                                    3, pending_buy_limit.StopLoss, pending_buy_limit.TakeProfit,
                                                    "LeoTrader", MAGIC_NO, 0, Green);
                if(pending_buy_limit.ticketNr<0){
                    LogTradeError("OrderSend", GetLastError(), OP_BUYLIMIT, pending_buy_limit.ticketNr,
                                lots, pending_buy_limit.openPrice, pending_buy_limit.StopLoss, pending_buy_limit.TakeProfit);
                }
                else
                    MarkPendingTrapModified(OP_BUYLIMIT);
            }

            break;
        case OP_SELLLIMIT:
            if(ROBOTTRADE &&  pending_sell_limit.ticketNr < 0){
                pending_sell_limit.TakeProfit=NormalizeDouble(pending_sell_limit.TakeProfit, vdigits);
                pending_sell_limit.StopLoss=NormalizeDouble(pending_sell_limit.StopLoss, vdigits);
                pending_sell_limit.ticketNr=OrderSend(Symbol(), OP_SELLLIMIT, lots, pending_sell_limit.openPrice,
                                                3, pending_sell_limit.StopLoss, pending_sell_limit.TakeProfit,
                                                "LeoTrader", MAGIC_NO, 0, Red);
                if(pending_sell_limit.ticketNr<0){
                    LogTradeError("OrderSend", GetLastError(), OP_SELLLIMIT, pending_sell_limit.ticketNr,
                                lots, pending_sell_limit.openPrice, pending_sell_limit.StopLoss, pending_sell_limit.TakeProfit);
                }
                else
                    MarkPendingTrapModified(OP_SELLLIMIT);
            }

            break;
        case OP_BUYSTOP:
            if(ROBOTTRADE &&  pending_buy_stop.ticketNr < 0){
                pending_buy_stop.TakeProfit=NormalizeDouble(pending_buy_stop.TakeProfit, vdigits);
                pending_buy_stop.StopLoss=NormalizeDouble(pending_buy_stop.StopLoss, vdigits);
                pending_buy_stop.ticketNr=OrderSend(Symbol(), OP_BUYSTOP, lots, pending_buy_stop.openPrice,
                                                    3, pending_buy_stop.StopLoss, pending_buy_stop.TakeProfit,
                                                    "LeoTrader", MAGIC_NO, 0, Green);
                if(pending_buy_stop.ticketNr<0){
                    LogTradeError("OrderSend", GetLastError(), OP_BUYSTOP, pending_buy_stop.ticketNr,
                                lots, pending_buy_stop.openPrice, pending_buy_stop.StopLoss, pending_buy_stop.TakeProfit);
                }
                else
                    MarkPendingTrapModified(OP_BUYSTOP);
            }
            break;
        case OP_SELLSTOP:
            if(ROBOTTRADE &&  pending_sell_stop.ticketNr < 0){
                pending_sell_stop.TakeProfit=NormalizeDouble(pending_sell_stop.TakeProfit, vdigits);
                pending_sell_stop.StopLoss=NormalizeDouble(pending_sell_stop.StopLoss, vdigits);
                pending_sell_stop.ticketNr=OrderSend(Symbol(), OP_SELLSTOP, lots, pending_sell_stop.openPrice,
                                                3, pending_sell_stop.StopLoss, pending_sell_stop.TakeProfit,
                                                "LeoTrader", MAGIC_NO, 0, Red);
                if(pending_sell_stop.ticketNr<0){
                    LogTradeError("OrderSend", GetLastError(), OP_SELLSTOP, pending_sell_stop.ticketNr,
                                  lots, pending_sell_stop.openPrice, pending_sell_stop.StopLoss, pending_sell_stop.TakeProfit);
                }
                else
                    MarkPendingTrapModified(OP_SELLSTOP);
            }
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

bool EnsureCsvFolder()
{
    if(csvFolderName != "")
        return true;

    csvFolderName = Symbol()+"\\"+Symbol()+"_Total";
    newsCsvPath = csvFolderName+"\\"+NewsCsvName;
    optimizationCsvPath = csvFolderName+"\\"+OptimizationCsvName;

    if(MQL_TESTER)
        csvFolderFullPath = TerminalInfoString(TERMINAL_DATA_PATH)+"\\tester\\files\\"+csvFolderName;
    else
        csvFolderFullPath = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files\\"+csvFolderName;

    optimizationCsvFullPath = csvFolderFullPath+"\\"+OptimizationCsvName;

    string rootFolderFullPath;
    if(MQL_TESTER)
        rootFolderFullPath = TerminalInfoString(TERMINAL_DATA_PATH)+"\\tester\\files\\"+Symbol();
    else
        rootFolderFullPath = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files\\"+Symbol();

    CreateDirectoryA(rootFolderFullPath, 0);
    CreateDirectoryA(csvFolderFullPath, 0);

    if(MQL_TESTER)
        PrintFormat("Optimization CSV target: %s", optimizationCsvFullPath);
    else
        Print("Optimization CSV disabled outside Strategy Tester");
    PrintFormat("News CSV folder: %s", csvFolderFullPath);
    return true;
}

bool EnsureDefaultNewsCsv()
{
    if(!UseNewsFilter)
        return false;

    if(!EnsureCsvFolder())
        return false;

    ResetLastError();
    if(!FileIsExist(newsCsvPath)){
        int createHandle = FileOpen(newsCsvPath, FILE_CSV|FILE_WRITE, ";");
        if(createHandle == INVALID_HANDLE){
            PrintFormat("News CSV create failed: %s, error=%d", csvFolderFullPath+"\\"+NewsCsvName, GetLastError());
            return false;
        }
        FileWrite(createHandle, "start_utc", "currency", "impact", "event", "pre_minutes", "post_minutes", "mode");
        FileWrite(createHandle, "2026.05.08 12:30", "USD", "HIGH", "NFP Employment Situation", 90, 120, 0);
        FileWrite(createHandle, "2026.06.05 12:30", "USD", "HIGH", "NFP Employment Situation", 90, 120, 0);
        FileWrite(createHandle, "2026.07.02 12:30", "USD", "HIGH", "NFP Employment Situation", 90, 120, 0);
        FileWrite(createHandle, "2026.08.07 12:30", "USD", "HIGH", "NFP Employment Situation", 90, 120, 0);
        FileWrite(createHandle, "2026.09.04 12:30", "USD", "HIGH", "NFP Employment Situation", 90, 120, 0);
        FileWrite(createHandle, "2026.10.02 12:30", "USD", "HIGH", "NFP Employment Situation", 90, 120, 0);
        FileWrite(createHandle, "2026.11.06 13:30", "USD", "HIGH", "NFP Employment Situation", 90, 120, 0);
        FileWrite(createHandle, "2026.12.04 13:30", "USD", "HIGH", "NFP Employment Situation", 90, 120, 0);
        FileWrite(createHandle, "2026.05.12 12:30", "USD", "HIGH", "CPI", 90, 120, 0);
        FileWrite(createHandle, "2026.06.10 12:30", "USD", "HIGH", "CPI", 90, 120, 0);
        FileWrite(createHandle, "2026.07.14 12:30", "USD", "HIGH", "CPI", 90, 120, 0);
        FileWrite(createHandle, "2026.08.12 12:30", "USD", "HIGH", "CPI", 90, 120, 0);
        FileWrite(createHandle, "2026.09.11 12:30", "USD", "HIGH", "CPI", 90, 120, 0);
        FileWrite(createHandle, "2026.10.14 12:30", "USD", "HIGH", "CPI", 90, 120, 0);
        FileWrite(createHandle, "2026.11.10 13:30", "USD", "HIGH", "CPI", 90, 120, 0);
        FileWrite(createHandle, "2026.12.10 13:30", "USD", "HIGH", "CPI", 90, 120, 0);
        FileWrite(createHandle, "2026.05.13 12:30", "USD", "HIGH", "PPI", 60, 90, 0);
        FileWrite(createHandle, "2026.06.11 12:30", "USD", "HIGH", "PPI", 60, 90, 0);
        FileWrite(createHandle, "2026.07.15 12:30", "USD", "HIGH", "PPI", 60, 90, 0);
        FileWrite(createHandle, "2026.08.13 12:30", "USD", "HIGH", "PPI", 60, 90, 0);
        FileWrite(createHandle, "2026.09.10 12:30", "USD", "HIGH", "PPI", 60, 90, 0);
        FileWrite(createHandle, "2026.10.15 12:30", "USD", "HIGH", "PPI", 60, 90, 0);
        FileWrite(createHandle, "2026.11.13 13:30", "USD", "HIGH", "PPI", 60, 90, 0);
        FileWrite(createHandle, "2026.12.15 13:30", "USD", "HIGH", "PPI", 60, 90, 0);
        FileWrite(createHandle, "2026.05.28 12:30", "USD", "HIGH", "BEA GDP/PCE", 60, 90, 0);
        FileWrite(createHandle, "2026.06.25 12:30", "USD", "HIGH", "BEA GDP/PCE", 60, 90, 0);
        FileWrite(createHandle, "2026.06.17 18:00", "USD", "HIGH", "FOMC Decision/Press Conference", 120, 180, 0);
        FileWrite(createHandle, "2026.07.29 18:00", "USD", "HIGH", "FOMC Decision/Press Conference", 120, 180, 0);
        FileWrite(createHandle, "2026.09.16 18:00", "USD", "HIGH", "FOMC Decision/Press Conference", 120, 180, 0);
        FileWrite(createHandle, "2026.10.28 18:00", "USD", "HIGH", "FOMC Decision/Press Conference", 120, 180, 0);
        FileWrite(createHandle, "2026.12.09 19:00", "USD", "HIGH", "FOMC Decision/Press Conference", 120, 180, 0);
        FileWrite(createHandle, "2026.06.11 12:30", "EUR", "HIGH", "ECB Monetary Policy/Press Conference", 90, 150, 0);
        FileWrite(createHandle, "2026.07.23 12:30", "EUR", "HIGH", "ECB Monetary Policy/Press Conference", 90, 150, 0);
        FileWrite(createHandle, "2026.09.10 12:30", "EUR", "HIGH", "ECB Monetary Policy/Press Conference", 90, 150, 0);
        FileWrite(createHandle, "2026.10.29 12:30", "EUR", "HIGH", "ECB Monetary Policy/Press Conference", 90, 150, 0);
        FileWrite(createHandle, "2026.12.17 13:30", "EUR", "HIGH", "ECB Monetary Policy/Press Conference", 90, 150, 0);
        FileFlush(createHandle);
        FileClose(createHandle);
    }

    int handle = FileOpen(newsCsvPath, FILE_CSV|FILE_READ, ";");
    if(handle == INVALID_HANDLE){
        PrintFormat("News CSV open failed: %s, error=%d", csvFolderFullPath+"\\"+NewsCsvName, GetLastError());
        return false;
    }

    FileClose(handle);
    if(!newsCsvAnnounced){
        PrintFormat("News CSV active: %s", csvFolderFullPath+"\\"+NewsCsvName);
        newsCsvAnnounced = true;
    }
    return true;
}

void LoadNewsEvents()
{
    newsEventCount = 0;
    ArrayResize(newsStartTimes, 0);
    ArrayResize(newsEndTimes, 0);
    ArrayResize(newsCurrencies, 0);
    ArrayResize(newsImpacts, 0);
    ArrayResize(newsNames, 0);
    ArrayResize(newsModes, 0);

    if(!EnsureDefaultNewsCsv())
        return;

    ResetLastError();
    int handle = FileOpen(newsCsvPath, FILE_CSV|FILE_READ, ";");
    if(handle == INVALID_HANDLE){
        PrintFormat("News CSV read failed: %s, error=%d", csvFolderFullPath+"\\"+NewsCsvName, GetLastError());
        return;
    }

    while(!FileIsEnding(handle)){
        string eventTimeText = FileReadString(handle);
        if(FileIsEnding(handle))
            break;

        string currency = FileReadString(handle);
        string impact = FileReadString(handle);
        string eventName = FileReadString(handle);
        int preMinutes = (int)StringToInteger(FileReadString(handle));
        int postMinutes = (int)StringToInteger(FileReadString(handle));
        int mode = (int)StringToInteger(FileReadString(handle));

        if(eventTimeText=="start_utc" || eventTimeText=="")
            continue;

        datetime eventTime = StringToTime(eventTimeText) + NewsServerUtcOffsetHours*3600;
        if(eventTime <= 0)
            continue;

        int idx = newsEventCount;
        newsEventCount++;
        ArrayResize(newsStartTimes, newsEventCount);
        ArrayResize(newsEndTimes, newsEventCount);
        ArrayResize(newsCurrencies, newsEventCount);
        ArrayResize(newsImpacts, newsEventCount);
        ArrayResize(newsNames, newsEventCount);
        ArrayResize(newsModes, newsEventCount);

        newsStartTimes[idx] = eventTime - preMinutes*60;
        newsEndTimes[idx] = eventTime + postMinutes*60;
        newsCurrencies[idx] = currency;
        newsImpacts[idx] = impact;
        newsNames[idx] = eventName;
        newsModes[idx] = mode;
    }

    FileClose(handle);
    PrintFormat("News events loaded: %d, server UTC offset hours=%d", newsEventCount, NewsServerUtcOffsetHours);
}

bool IsNewsWindowActive()
{
    if(!UseNewsFilter)
        return false;

    for(int i=0; i<newsEventCount; i++){
        if(currentTime >= newsStartTimes[i] && currentTime <= newsEndTimes[i]){
            activeNewsName = newsCurrencies[i]+" "+newsNames[i];
            activeNewsUntil = newsEndTimes[i];
            return true;
        }
    }

    activeNewsName = "";
    activeNewsUntil = 0;
    return false;
}

bool IsLimitOrderCmd(int cmd)
{
    return cmd==OP_BUYLIMIT || cmd==OP_SELLLIMIT;
}

bool IsStopOrderCmd(int cmd)
{
    return cmd==OP_BUYSTOP || cmd==OP_SELLSTOP;
}

double CurrentPlanRiskM30ATR()
{
    if(sig_M30.atr <= 0)
        return 0;

    double riskPrice = 0;
    if(robotPlan.direction==DIR_BUY)
        riskPrice = robotPlan.targets.entry - robotPlan.targets.slInitial;
    else if(robotPlan.direction==DIR_SELL)
        riskPrice = robotPlan.targets.slInitial - robotPlan.targets.entry;

    if(riskPrice <= 0)
        return 0;

    return riskPrice/sig_M30.atr;
}

double CurrentM30RangeATR()
{
    if(sig_M30.atr <= 0)
        return 0;

    return (iHigh(Symbol(), PERIOD_M30, 0)-iLow(Symbol(), PERIOD_M30, 0))/sig_M30.atr;
}

int DirectionalBreakoutStack(int dir)
{
    int stack = 0;
    if(dir==DIR_NONE)
        return stack;

    if(sig_M5.breakoutDir==dir)  stack++;
    if(sig_M15.breakoutDir==dir) stack++;
    if(sig_M30.breakoutDir==dir) stack++;
    return stack;
}

int DirectionalExhaustionStack(int dir)
{
    int stack = 0;
    if(dir==DIR_NONE)
        return stack;

    if(sig_M5.exhaustionDir==dir)  stack++;
    if(sig_M15.exhaustionDir==dir) stack++;
    if(sig_M30.exhaustionDir==dir) stack++;
    if(sig_H1.exhaustionDir==dir)  stack++;
    if(sig_H4.exhaustionDir==dir)  stack++;
    return stack;
}

int DirectionalBigTrendStack(int dir)
{
    int stack = 0;
    if(dir==DIR_NONE)
        return stack;

    if(sig_M30.trendDir==dir) stack++;
    if(sig_H1.trendDir==dir)  stack++;
    if(sig_H4.trendDir==dir)  stack++;
    return stack;
}

string CurrentTradeCluster(int cmd)
{
    if(cmd==6 || robotPlan.direction==DIR_NONE)
        return "NO_PLAN";

    if(!IsStopOrderCmd(cmd))
        return "NON_STOP";

    double rangeAtr = CurrentM30RangeATR();
    int breakoutStack = DirectionalBreakoutStack(robotPlan.direction);
    int exhaustionStack = DirectionalExhaustionStack(robotPlan.direction);

    if(rangeAtr > 0 && rangeAtr < CompressedStopRangeMaxM30ATR)
        return "COMPRESSED_RANGE";
    if(rangeAtr >= WideNoConfirmMinM30ATR && breakoutStack==0 && exhaustionStack==0)
        return "WIDE_NO_CONFIRM";
    if(rangeAtr > 0 && rangeAtr < WideNoConfirmMinM30ATR && breakoutStack==0 && exhaustionStack==0)
        return "MID_CHOP_NO_BREAKOUT";
    if(rangeAtr > 0 && rangeAtr < WideNoConfirmMinM30ATR && breakoutStack==0)
        return "MID_RANGE_PULLBACK";
    if(breakoutStack > 0)
        return "CONFIRMED_BREAKOUT";

    return "TREND_TRAP";
}

bool OptimizationFiltersAllowPlan(int cmd)
{
    if(OptimizationBreakoutOnly && IsLimitOrderCmd(cmd))
        return false;

    double riskAtr = 0;
    if(sig_M30.atr > 0)
        riskAtr = CurrentPlanRiskM30ATR();

    if(IsStopOrderCmd(cmd)){
        int activeM30Fibo = LS_M30.posFibo_candel[0].aktive_fibo_index;
        double rangeAtr = CurrentM30RangeATR();
        int breakoutStack = DirectionalBreakoutStack(robotPlan.direction);
        int exhaustionStack = DirectionalExhaustionStack(robotPlan.direction);

        if(AvoidWeakM30FiboTrapZones && (activeM30Fibo==10 || activeM30Fibo==13))
            return false;

        if(AvoidWeakTrapRiskBand && riskAtr >= WeakTrapRiskBandMinM30ATR && riskAtr <= WeakTrapRiskBandMaxM30ATR)
            return false;

        if(AvoidCompressedStopRange && rangeAtr > 0 && rangeAtr < CompressedStopRangeMaxM30ATR)
            return false;

        if(AvoidWideNoConfirmStop && rangeAtr >= WideNoConfirmMinM30ATR && breakoutStack==0 && exhaustionStack==0)
            return false;
    }

    if(EnableRangeRelativeBreakout){
        int breakoutStack = DirectionalBreakoutStack(robotPlan.direction);
        int exhaustionStack = DirectionalExhaustionStack(robotPlan.direction);
        double rangeAtr = CurrentM30RangeATR();

        if(MaxDirectionalExhaustionStack >= 0 && exhaustionStack > MaxDirectionalExhaustionStack)
            return false;

        if(rangeAtr > 0 && breakoutStack==0){
            if(rangeAtr < RangeRelativeMinM30ATR)
                return false;
            if(rangeAtr > RangeRelativeMaxM30ATR && rangeAtr < AmbiguousRangeMaxM30ATR)
                return false;
        }
    }

    if(MinPlanRiskM30ATR > 0 && sig_M30.atr > 0){
        if(riskAtr > 0 && riskAtr < MinPlanRiskM30ATR)
            return false;
    }

    return true;
}

void CsvAddString(string& line, string value)
{
    StringReplace(value, "\r", " ");
    StringReplace(value, "\n", " ");
    StringReplace(value, ";", " ");
    line += value+";";
}

void CsvAddInt(string& line, int value)
{
    line += IntegerToString(value)+";";
}

void CsvAddLong(string& line, long value)
{
    line += DoubleToString((double)value, 0)+";";
}

void CsvAddDouble(string& line, double value)
{
    line += DoubleToString(value, 8)+";";
}

void CsvAddSensorHeader(string& line, string prefix)
{
    CsvAddString(line, prefix+"_ma_trend0");
    CsvAddString(line, prefix+"_ma_trend1");
    CsvAddString(line, prefix+"_ma_cut0");
    CsvAddString(line, prefix+"_macd_main");
    CsvAddString(line, prefix+"_macd_signal");
    CsvAddString(line, prefix+"_stoch_main");
    CsvAddString(line, prefix+"_stoch_signal");
    CsvAddString(line, prefix+"_rsi");
    CsvAddString(line, prefix+"_atr");
    CsvAddString(line, prefix+"_volume");
    CsvAddString(line, prefix+"_zig2");
    CsvAddString(line, prefix+"_zig3");
    CsvAddString(line, prefix+"_zig_sensitive2");
    CsvAddString(line, prefix+"_zig_sensitive3");
    CsvAddString(line, prefix+"_fibo_support");
    CsvAddString(line, prefix+"_fibo_resistance");
    CsvAddString(line, prefix+"_fibo_support_index");
    CsvAddString(line, prefix+"_fibo_resistance_index");
    CsvAddString(line, prefix+"_fibo_active_index");
    CsvAddString(line, prefix+"_fibo_line_active");
    CsvAddString(line, prefix+"_fibo_half_active");
    CsvAddString(line, prefix+"_trend_dir");
    CsvAddString(line, prefix+"_breakout_dir");
    CsvAddString(line, prefix+"_exhaustion_dir");
    CsvAddString(line, prefix+"_swing_dir");
}

void CsvAddSensorValues(string& line, LeoSensors& LS, TFSignal& sig)
{
    CsvAddDouble(line, LS.ma_trend[0]);
    CsvAddDouble(line, LS.ma_trend[1]);
    CsvAddDouble(line, LS.ma_cut[0]);
    CsvAddDouble(line, LS.macd_main[0]);
    CsvAddDouble(line, LS.macd_sig[0]);
    CsvAddDouble(line, LS.stoch_main[0]);
    CsvAddDouble(line, LS.stoch_sig[0]);
    CsvAddDouble(line, LS.rsi[0]);
    CsvAddDouble(line, LS.atr[0]);
    CsvAddLong(line, LS.volume[0]);
    CsvAddDouble(line, LS.zig_zag[2]);
    CsvAddDouble(line, LS.zig_zag[3]);
    CsvAddDouble(line, LS.zig_zag_sensitive[2]);
    CsvAddDouble(line, LS.zig_zag_sensitive[3]);
    CsvAddDouble(line, LS.posFibo_candel[0].fibo_support);
    CsvAddDouble(line, LS.posFibo_candel[0].fibo_resistance);
    CsvAddInt(line, LS.posFibo_candel[0].fibo_index_support);
    CsvAddInt(line, LS.posFibo_candel[0].fibo_index_resistance);
    CsvAddInt(line, LS.posFibo_candel[0].aktive_fibo_index);
    CsvAddInt(line, LS.posFibo_candel[0].fibo_line_is_aktive ? 1 : 0);
    CsvAddInt(line, LS.posFibo_candel[0].fibo_half_line_is_aktive ? 1 : 0);
    CsvAddInt(line, sig.trendDir);
    CsvAddInt(line, sig.breakoutDir);
    CsvAddInt(line, sig.exhaustionDir);
    CsvAddInt(line, sig.swingDir);
}

bool OpenOptimizationCsv()
{
    if(!MQL_TESTER || !ExportOptimizationCsv)
        return false;

    if(optimizationCsvHandle != INVALID_HANDLE)
        return true;

    if(!EnsureCsvFolder())
        return false;

    ResetLastError();
    int flags = FILE_CSV|FILE_WRITE;

    optimizationCsvHandle = FileOpen(optimizationCsvPath, flags, ";");
    if(optimizationCsvHandle == INVALID_HANDLE){
        PrintFormat("Optimization CSV open failed: %s, error=%d", optimizationCsvFullPath, GetLastError());
        return false;
    }

    string header = "";
    CsvAddString(header, "time");
    CsvAddString(header, "m5_bar");
    CsvAddString(header, "symbol");
    CsvAddString(header, "bid");
    CsvAddString(header, "ask");
    CsvAddString(header, "spread_points");
    CsvAddString(header, "m5_open");
    CsvAddString(header, "m5_high");
    CsvAddString(header, "m5_low");
    CsvAddString(header, "m5_close");
    CsvAddString(header, "m15_open");
    CsvAddString(header, "m15_high");
    CsvAddString(header, "m15_low");
    CsvAddString(header, "m15_close");
    CsvAddString(header, "m30_open");
    CsvAddString(header, "m30_high");
    CsvAddString(header, "m30_low");
    CsvAddString(header, "m30_close");
    CsvAddString(header, "h1_open");
    CsvAddString(header, "h1_high");
    CsvAddString(header, "h1_low");
    CsvAddString(header, "h1_close");
    CsvAddString(header, "h4_open");
    CsvAddString(header, "h4_high");
    CsvAddString(header, "h4_low");
    CsvAddString(header, "h4_close");
    CsvAddString(header, "m5_fibo_down");
    CsvAddString(header, "m5_fibo_236");
    CsvAddString(header, "m5_fibo_382");
    CsvAddString(header, "m5_fibo_500");
    CsvAddString(header, "m5_fibo_618");
    CsvAddString(header, "m5_fibo_top");
    CsvAddString(header, "m15_fibo_down");
    CsvAddString(header, "m15_fibo_236");
    CsvAddString(header, "m15_fibo_382");
    CsvAddString(header, "m15_fibo_500");
    CsvAddString(header, "m15_fibo_618");
    CsvAddString(header, "m15_fibo_top");
    CsvAddString(header, "m30_fibo_down");
    CsvAddString(header, "m30_fibo_236");
    CsvAddString(header, "m30_fibo_382");
    CsvAddString(header, "m30_fibo_500");
    CsvAddString(header, "m30_fibo_618");
    CsvAddString(header, "m30_fibo_top");
    CsvAddString(header, "h1_fibo_down");
    CsvAddString(header, "h1_fibo_236");
    CsvAddString(header, "h1_fibo_382");
    CsvAddString(header, "h1_fibo_500");
    CsvAddString(header, "h1_fibo_618");
    CsvAddString(header, "h1_fibo_top");
    CsvAddString(header, "h4_fibo_down");
    CsvAddString(header, "h4_fibo_236");
    CsvAddString(header, "h4_fibo_382");
    CsvAddString(header, "h4_fibo_500");
    CsvAddString(header, "h4_fibo_618");
    CsvAddString(header, "h4_fibo_top");
    CsvAddSensorHeader(header, "m5");
    CsvAddSensorHeader(header, "m15");
    CsvAddSensorHeader(header, "m30");
    CsvAddSensorHeader(header, "h1");
    CsvAddSensorHeader(header, "h4");
    CsvAddString(header, "news_active");
    CsvAddString(header, "news_name");
    CsvAddString(header, "cmd");
    CsvAddString(header, "plan_type");
    CsvAddString(header, "direction");
    CsvAddString(header, "confidence");
    CsvAddString(header, "entry");
    CsvAddString(header, "sl");
    CsvAddString(header, "tp1");
    CsvAddString(header, "tp2");
    CsvAddString(header, "tp3");
    CsvAddString(header, "trail_level");
    CsvAddString(header, "risk_price");
    CsvAddString(header, "reward_price");
    CsvAddString(header, "rr");
    CsvAddString(header, "m30_range_atr");
    CsvAddString(header, "breakout_stack");
    CsvAddString(header, "exhaustion_stack");
    CsvAddString(header, "big_trend_stack");
    CsvAddString(header, "risk_m30_atr");
    CsvAddString(header, "trade_cluster");
    FileWriteString(optimizationCsvHandle, header+"\r\n");
    FileFlush(optimizationCsvHandle);

    if(!optimizationCsvAnnounced){
        PrintFormat("Optimization CSV active: %s", optimizationCsvFullPath);
        optimizationCsvAnnounced = true;
    }
    return true;
}

void CloseOptimizationCsv()
{
    if(optimizationCsvHandle != INVALID_HANDLE){
        FileClose(optimizationCsvHandle);
        optimizationCsvHandle = INVALID_HANDLE;
    }
}

void WriteOptimizationCsv(bool force)
{
    if(!MQL_TESTER || !ExportOptimizationCsv)
        return;

    datetime barTime = iTime(Symbol(), PERIOD_M5, 0);
    bool planChanged = (robotPlan.cmd != lastOptimizationCsvCmd
                        || MathAbs(robotPlan.targets.entry-lastOptimizationCsvEntry) > Point);

    if(!force && barTime == lastOptimizationCsvBarTime && !planChanged)
        return;

    if(!OpenOptimizationCsv())
        return;

    double riskPrice = 0;
    double rewardPrice = 0;
    double rr = 0;

    if(robotPlan.cmd==OP_BUY || robotPlan.cmd==OP_BUYLIMIT || robotPlan.cmd==OP_BUYSTOP){
        riskPrice = robotPlan.targets.entry - robotPlan.targets.slInitial;
        rewardPrice = robotPlan.targets.tp1 - robotPlan.targets.entry;
    }
    else if(robotPlan.cmd==OP_SELL || robotPlan.cmd==OP_SELLLIMIT || robotPlan.cmd==OP_SELLSTOP){
        riskPrice = robotPlan.targets.slInitial - robotPlan.targets.entry;
        rewardPrice = robotPlan.targets.entry - robotPlan.targets.tp1;
    }
    if(riskPrice > 0)
        rr = rewardPrice/riskPrice;

    string planCmdName = "NO_ACTION";
    if(robotPlan.cmd != 6)
        planCmdName = OrderCmdName(robotPlan.cmd);

    bool newsActive = IsNewsWindowActive();

    string line = "";
    CsvAddString(line, TimeToString(currentTime, TIME_DATE|TIME_SECONDS));
    CsvAddString(line, TimeToString(barTime, TIME_DATE|TIME_SECONDS));
    CsvAddString(line, Symbol());
    CsvAddDouble(line, Bid);
    CsvAddDouble(line, Ask);
    CsvAddDouble(line, MarketInfo(Symbol(), MODE_SPREAD));
    CsvAddDouble(line, iOpen(Symbol(), PERIOD_M5, 0));
    CsvAddDouble(line, iHigh(Symbol(), PERIOD_M5, 0));
    CsvAddDouble(line, iLow(Symbol(), PERIOD_M5, 0));
    CsvAddDouble(line, iClose(Symbol(), PERIOD_M5, 0));
    CsvAddDouble(line, iOpen(Symbol(), PERIOD_M15, 0));
    CsvAddDouble(line, iHigh(Symbol(), PERIOD_M15, 0));
    CsvAddDouble(line, iLow(Symbol(), PERIOD_M15, 0));
    CsvAddDouble(line, iClose(Symbol(), PERIOD_M15, 0));
    CsvAddDouble(line, iOpen(Symbol(), PERIOD_M30, 0));
    CsvAddDouble(line, iHigh(Symbol(), PERIOD_M30, 0));
    CsvAddDouble(line, iLow(Symbol(), PERIOD_M30, 0));
    CsvAddDouble(line, iClose(Symbol(), PERIOD_M30, 0));
    CsvAddDouble(line, iOpen(Symbol(), PERIOD_H1, 0));
    CsvAddDouble(line, iHigh(Symbol(), PERIOD_H1, 0));
    CsvAddDouble(line, iLow(Symbol(), PERIOD_H1, 0));
    CsvAddDouble(line, iClose(Symbol(), PERIOD_H1, 0));
    CsvAddDouble(line, iOpen(Symbol(), PERIOD_H4, 0));
    CsvAddDouble(line, iHigh(Symbol(), PERIOD_H4, 0));
    CsvAddDouble(line, iLow(Symbol(), PERIOD_H4, 0));
    CsvAddDouble(line, iClose(Symbol(), PERIOD_H4, 0));
    CsvAddDouble(line, LS_M5.fibo_candel[0].fibo[6]);
    CsvAddDouble(line, LS_M5.fibo_candel[0].fibo[7]);
    CsvAddDouble(line, LS_M5.fibo_candel[0].fibo[8]);
    CsvAddDouble(line, LS_M5.fibo_candel[0].fibo[9]);
    CsvAddDouble(line, LS_M5.fibo_candel[0].fibo[10]);
    CsvAddDouble(line, LS_M5.fibo_candel[0].fibo[12]);
    CsvAddDouble(line, LS_M15.fibo_candel[0].fibo[6]);
    CsvAddDouble(line, LS_M15.fibo_candel[0].fibo[7]);
    CsvAddDouble(line, LS_M15.fibo_candel[0].fibo[8]);
    CsvAddDouble(line, LS_M15.fibo_candel[0].fibo[9]);
    CsvAddDouble(line, LS_M15.fibo_candel[0].fibo[10]);
    CsvAddDouble(line, LS_M15.fibo_candel[0].fibo[12]);
    CsvAddDouble(line, LS_M30.fibo_candel[0].fibo[6]);
    CsvAddDouble(line, LS_M30.fibo_candel[0].fibo[7]);
    CsvAddDouble(line, LS_M30.fibo_candel[0].fibo[8]);
    CsvAddDouble(line, LS_M30.fibo_candel[0].fibo[9]);
    CsvAddDouble(line, LS_M30.fibo_candel[0].fibo[10]);
    CsvAddDouble(line, LS_M30.fibo_candel[0].fibo[12]);
    CsvAddDouble(line, LS_H1.fibo_candel[0].fibo[6]);
    CsvAddDouble(line, LS_H1.fibo_candel[0].fibo[7]);
    CsvAddDouble(line, LS_H1.fibo_candel[0].fibo[8]);
    CsvAddDouble(line, LS_H1.fibo_candel[0].fibo[9]);
    CsvAddDouble(line, LS_H1.fibo_candel[0].fibo[10]);
    CsvAddDouble(line, LS_H1.fibo_candel[0].fibo[12]);
    CsvAddDouble(line, LS_H4.fibo_candel[0].fibo[6]);
    CsvAddDouble(line, LS_H4.fibo_candel[0].fibo[7]);
    CsvAddDouble(line, LS_H4.fibo_candel[0].fibo[8]);
    CsvAddDouble(line, LS_H4.fibo_candel[0].fibo[9]);
    CsvAddDouble(line, LS_H4.fibo_candel[0].fibo[10]);
    CsvAddDouble(line, LS_H4.fibo_candel[0].fibo[12]);
    CsvAddSensorValues(line, LS_M5, sig_M5);
    CsvAddSensorValues(line, LS_M15, sig_M15);
    CsvAddSensorValues(line, LS_M30, sig_M30);
    CsvAddSensorValues(line, LS_H1, sig_H1);
    CsvAddSensorValues(line, LS_H4, sig_H4);
    CsvAddInt(line, newsActive ? 1 : 0);
    CsvAddString(line, activeNewsName);
    CsvAddString(line, planCmdName);
    CsvAddInt(line, robotPlan.planType);
    CsvAddInt(line, robotPlan.direction);
    CsvAddDouble(line, robotPlan.confidence);
    CsvAddDouble(line, robotPlan.targets.entry);
    CsvAddDouble(line, robotPlan.targets.slInitial);
    CsvAddDouble(line, robotPlan.targets.tp1);
    CsvAddDouble(line, robotPlan.targets.tp2);
    CsvAddDouble(line, robotPlan.targets.tp3);
    CsvAddDouble(line, robotPlan.targets.trailLevel);
    CsvAddDouble(line, riskPrice);
    CsvAddDouble(line, rewardPrice);
    CsvAddDouble(line, rr);
    CsvAddDouble(line, CurrentM30RangeATR());
    CsvAddInt(line, DirectionalBreakoutStack(robotPlan.direction));
    CsvAddInt(line, DirectionalExhaustionStack(robotPlan.direction));
    CsvAddInt(line, DirectionalBigTrendStack(robotPlan.direction));
    CsvAddDouble(line, CurrentPlanRiskM30ATR());
    CsvAddString(line, CurrentTradeCluster(robotPlan.cmd));
    FileWriteString(optimizationCsvHandle, line+"\r\n");
    FileFlush(optimizationCsvHandle);

    lastOptimizationCsvBarTime = barTime;
    lastOptimizationCsvCmd = robotPlan.cmd;
    lastOptimizationCsvEntry = robotPlan.targets.entry;
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
    
    AnalyseLeoSensor(LS_H4, sig_H4);
    AnalyseLeoSensor(LS_H1, sig_H1);
    AnalyseLeoSensor(LS_M30, sig_M30);
    AnalyseLeoSensor(LS_M15, sig_M15);
    AnalyseLeoSensor(LS_M5, sig_M5);

    BuildTFRelation(sig_H1, sig_H4, rel_H1_H4);
    BuildTFRelation(sig_M30, sig_H1, rel_M30_H1);
    BuildTFRelation(sig_M15, sig_M30, rel_M15_M30);
    BuildTFRelation(sig_M5, sig_M15, rel_M5_M15);
    BuildTFRelation(sig_M30, sig_H4, rel_M30_H4);
    BuildTFRelation(sig_M15, sig_H1, rel_M15_H1);
    BuildTFRelation(sig_M5, sig_M30, rel_M5_M30);

    BuildTradePlan();

    Draw();
}

//+------------------------------------------------------------------+
//| care to close or adjust TP/SL                                    |
//+------------------------------------------------------------------+
void checkClose()
{  
    bool needModify=false;
    bool closePos=false;

    if (aktiveRobotOrder.type!=6){
        
        if (aktiveRobotOrder.type==OP_BUY){
            
            ManageRobotTargets();
        }

        else if(aktiveRobotOrder.type==OP_SELL){
            ManageRobotTargets();
        }

    }// ende Robot


    for (int i=0; i<ArraySize(user); i++){ // for manual opened positions (maybe later will developed)
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

    

    CMD = robotPlan.cmd;
    if(CMD==6){
        PrintFormat("getCMD blocked: no trade plan. confidence=%f, planType=%d", robotPlan.confidence, robotPlan.planType);
        return CMD;
    }

    NormalizeTradePlanTargets(robotPlan);

    if(!TradePlanHasValidTargets(robotPlan)){
        PrintFormat("getCMD blocked: invalid targets. cmd=%s, dir=%d, entry=%f, SL=%f, TP1=%f, TP2=%f, TP3=%f",
                    OrderCmdName(CMD), robotPlan.direction, robotPlan.targets.entry,
                    robotPlan.targets.slInitial, robotPlan.targets.tp1, robotPlan.targets.tp2, robotPlan.targets.tp3);
        return 6;
    }

    if(!OptimizationFiltersAllowPlan(CMD)){
        static datetime lastOptimizationBlockPrint = 0;
        if(currentTime-lastOptimizationBlockPrint >= 300){
            PrintFormat("getCMD blocked: optimization filter. cmd=%s, riskM30ATR=%f, breakoutOnly=%d",
                        OrderCmdName(CMD), CurrentPlanRiskM30ATR(), OptimizationBreakoutOnly ? 1 : 0);
            lastOptimizationBlockPrint = currentTime;
        }
        return 6;
    }

    if(!ROBOTTRADE){
        PrintFormat("getCMD blocked: ROBOTTRADE=false. cmd=%s", OrderCmdName(CMD));
        return 6;
    }

    bool newsActive = IsNewsWindowActive();
    if(newsActive && DeletePendingOrdersBeforeNews)
        DeleteRobotPendingOrders();

    if(newsActive && NewsRiskMultiplier <= 0){
        static datetime lastNewsBlockPrint = 0;
        if(currentTime-lastNewsBlockPrint >= 300){
            PrintFormat("getCMD blocked: active news window %s until %s",
                        activeNewsName, TimeToString(activeNewsUntil, TIME_DATE|TIME_MINUTES));
            lastNewsBlockPrint = currentTime;
        }
        return 6;
    }

    if(ApplyOrModifyExistingPendingPlan()){
        PrintFormat("getCMD blocked for send: existing pending modified. cmd=%s", OrderCmdName(CMD));
        return 6;
    }

    if((weekend() || TimeHour(currentTime)>21 || TimeHour(currentTime)<1) && (CMD==OP_BUY || CMD==OP_SELL)){
        PrintFormat("getCMD blocked: market order outside trading time. cmd=%s, hour=%d", OrderCmdName(CMD), TimeHour(currentTime));
        return 6;
    }

    int NRisk=1;
    lots = NormalizeDouble(AccountFreeMargin()*RiskRatio*NRisk/(1000.0), 2);
    if(newsActive && NewsRiskMultiplier > 0)
        lots = NormalizeDouble(lots*NewsRiskMultiplier, 2);
    if(lots<minLot) lots=minLot;

    ApplyTradePlanToOrderSlots();
    activeRobotPlan = robotPlan;
    
    return CMD;
}

//+------------------------------------------------------------------+
//| --- find minimum secure volume based on PERIOD_H4 for PERIOD_M5  |
//+------------------------------------------------------------------+
void recalcSecureVol()
{
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

void ResetSignalEvent(SignalEvent& sig)
{
    sig.type = SIG_NONE;
    sig.timeframe = 0;
    sig.direction = DIR_NONE;
    sig.level = 0;
    sig.invalidLevel = 0;
    sig.targetLevel = 0;
    sig.strength = 0;
    sig.time = 0;
    sig.reason = "";
}

void ResetTargetMap(TargetMap& targets)
{
    targets.entry = 0;
    targets.slInitial = 0;
    targets.slCurrent = 0;
    targets.tp1 = 0;
    targets.tp2 = 0;
    targets.tp3 = 0;
    targets.trailLevel = 0;
    targets.activeTarget = 0;
}

void ResetTradePlan(TradePlan& plan)
{
    plan.planType = PLAN_NONE;
    plan.cmd = 6;
    plan.direction = DIR_NONE;
    plan.confidence = 0;
    ResetSignalEvent(plan.triggerSignal);
    ResetSignalEvent(plan.invalidationSignal);
    ResetSignalEvent(plan.targetSignal);
    ResetSignalEvent(plan.managementSignal);
    ResetTargetMap(plan.targets);
}

double TradeMinDistance()
{
    double minDistance = MathMax(minStopLevel + spread, spread*3);
    minDistance = MathMax(minDistance, 10*Point);
    if(sig_M15.atr > 0)
        minDistance = MathMax(minDistance, sig_M15.atr*0.35);
    return minDistance;
}

double FiboRiskBuffer(double atr)
{
    double buffer = MathMax(minStopLevel + spread, spread*3);
    buffer = MathMax(buffer, 10*Point);
    if(atr > 0)
        buffer = MathMax(buffer, atr*FiboSLBufferATR);
    return buffer;
}

double BreakoutEntryBuffer(double atr)
{
    double buffer = MathMax(minStopLevel + spread, spread*3);
    buffer = MathMax(buffer, 10*Point);
    if(atr > 0)
        buffer = MathMax(buffer, atr*BreakoutEntryBufferATR);
    return buffer;
}

bool BuyPullbackExpected()
{
    return sig_M5.exhaustionDir==DIR_BUY
        || sig_M15.exhaustionDir==DIR_BUY
        || sig_M5.swingDir==DIR_SELL
        || sig_M15.swingDir==DIR_SELL
        || (sig_M5.trendDir==DIR_SELL && sig_H1.trendDir==DIR_BUY)
        || (sig_M15.trendDir==DIR_SELL && sig_H1.trendDir==DIR_BUY);
}

bool SellPullbackExpected()
{
    return sig_M5.exhaustionDir==DIR_SELL
        || sig_M15.exhaustionDir==DIR_SELL
        || sig_M5.swingDir==DIR_BUY
        || sig_M15.swingDir==DIR_BUY
        || (sig_M5.trendDir==DIR_BUY && sig_H1.trendDir==DIR_SELL)
        || (sig_M15.trendDir==DIR_BUY && sig_H1.trendDir==DIR_SELL);
}

double BuyFiboTrailCandidate(double maxAllowedSL)
{
    double buffer = FiboRiskBuffer(sig_M15.atr) * BreakEvenBufferATR;
    buffer = MathMax(buffer, minStopLevel + spread);
    double candidate = 0;

    if(sig_M15.support > 0 && sig_M15.support < currentPrice)
        candidate = sig_M15.support - buffer;
    if(sig_M30.support > 0 && sig_M30.support < currentPrice)
        candidate = MathMax(candidate, sig_M30.support - buffer);
    if(sig_H1.support > 0 && sig_H1.support < currentPrice)
        candidate = MathMax(candidate, sig_H1.support - buffer);

    if(candidate > maxAllowedSL)
        candidate = maxAllowedSL;

    return NormalizeDouble(candidate, vdigits);
}

double SellFiboTrailCandidate(double minAllowedSL)
{
    double buffer = FiboRiskBuffer(sig_M15.atr) * BreakEvenBufferATR;
    buffer = MathMax(buffer, minStopLevel + spread);
    double candidate = 0;

    if(sig_M15.resistance > 0 && sig_M15.resistance > currentPrice)
        candidate = sig_M15.resistance + buffer;
    if(sig_M30.resistance > 0 && sig_M30.resistance > currentPrice){
        double level = sig_M30.resistance + buffer;
        candidate = candidate <= 0 ? level : MathMin(candidate, level);
    }
    if(sig_H1.resistance > 0 && sig_H1.resistance > currentPrice){
        double levelH1 = sig_H1.resistance + buffer;
        candidate = candidate <= 0 ? levelH1 : MathMin(candidate, levelH1);
    }

    if(candidate > 0 && candidate < minAllowedSL)
        candidate = minAllowedSL;

    return NormalizeDouble(candidate, vdigits);
}

bool StrongCloseInvalidation(int orderType)
{
    if(orderType==OP_BUY){
        return sig_H1.trendDir==DIR_SELL
            && sig_M30.breakoutDir==DIR_SELL
            && sig_M15.breakoutDir==DIR_SELL
            && activeRobotPlan.targets.entry > 0
            && currentPrice < activeRobotPlan.targets.entry;
    }

    if(orderType==OP_SELL){
        return sig_H1.trendDir==DIR_BUY
            && sig_M30.breakoutDir==DIR_BUY
            && sig_M15.breakoutDir==DIR_BUY
            && activeRobotPlan.targets.entry > 0
            && currentPrice > activeRobotPlan.targets.entry;
    }

    return false;
}

void NormalizeTradePlanTargets(TradePlan& plan)
{
    if(plan.cmd==6 || plan.direction==DIR_NONE)
        return;

    double minDistance = TradeMinDistance();

    if(plan.cmd==OP_BUY)
        plan.targets.entry = Ask;
    else if(plan.cmd==OP_SELL)
        plan.targets.entry = Bid;

    if(plan.direction==DIR_BUY){
        if(plan.targets.slInitial <= 0 || plan.targets.slInitial >= plan.targets.entry)
            plan.targets.slInitial = plan.targets.entry - minDistance;

        if(plan.targets.tp1 <= 0 || plan.targets.tp1 <= plan.targets.entry){
            if(plan.targets.tp2 > plan.targets.entry)
                plan.targets.tp1 = plan.targets.tp2;
            else if(plan.targets.tp3 > plan.targets.entry)
                plan.targets.tp1 = plan.targets.tp3;
            else
                plan.targets.tp1 = plan.targets.entry + 2*minDistance;
        }

        if(plan.targets.tp2 <= 0 || plan.targets.tp2 <= plan.targets.tp1)
            plan.targets.tp2 = plan.targets.entry + 3*minDistance;

        if(plan.targets.tp3 <= 0 || plan.targets.tp3 <= plan.targets.tp2)
            plan.targets.tp3 = plan.targets.entry + 4*minDistance;

        if(plan.targets.trailLevel <= 0 || plan.targets.trailLevel >= plan.targets.entry)
            plan.targets.trailLevel = plan.targets.slInitial;
    }
    else if(plan.direction==DIR_SELL){
        if(plan.targets.slInitial <= 0 || plan.targets.slInitial <= plan.targets.entry)
            plan.targets.slInitial = plan.targets.entry + minDistance;

        if(plan.targets.tp1 <= 0 || plan.targets.tp1 >= plan.targets.entry){
            if(plan.targets.tp2 > 0 && plan.targets.tp2 < plan.targets.entry)
                plan.targets.tp1 = plan.targets.tp2;
            else if(plan.targets.tp3 > 0 && plan.targets.tp3 < plan.targets.entry)
                plan.targets.tp1 = plan.targets.tp3;
            else
                plan.targets.tp1 = plan.targets.entry - 2*minDistance;
        }

        if(plan.targets.tp2 <= 0 || plan.targets.tp2 >= plan.targets.tp1)
            plan.targets.tp2 = plan.targets.entry - 3*minDistance;

        if(plan.targets.tp3 <= 0 || plan.targets.tp3 >= plan.targets.tp2)
            plan.targets.tp3 = plan.targets.entry - 4*minDistance;

        if(plan.targets.trailLevel <= 0 || plan.targets.trailLevel <= plan.targets.entry)
            plan.targets.trailLevel = plan.targets.slInitial;
    }

    plan.targets.entry = NormalizeDouble(plan.targets.entry, vdigits);
    plan.targets.slInitial = NormalizeDouble(plan.targets.slInitial, vdigits);
    plan.targets.slCurrent = plan.targets.slInitial;
    plan.targets.tp1 = NormalizeDouble(plan.targets.tp1, vdigits);
    plan.targets.tp2 = NormalizeDouble(plan.targets.tp2, vdigits);
    plan.targets.tp3 = NormalizeDouble(plan.targets.tp3, vdigits);
    plan.targets.trailLevel = NormalizeDouble(plan.targets.trailLevel, vdigits);
}

bool TradePlanHasValidTargets(TradePlan& plan)
{
    if(plan.cmd==6 || plan.direction==DIR_NONE)
        return false;

    if(plan.targets.entry <= 0 || plan.targets.slInitial <= 0 || plan.targets.tp1 <= 0)
        return false;

    if(plan.direction==DIR_BUY){
        if(plan.targets.slInitial >= plan.targets.entry)
            return false;
        if(plan.targets.tp1 <= plan.targets.entry)
            return false;
    }
    else if(plan.direction==DIR_SELL){
        if(plan.targets.slInitial <= plan.targets.entry)
            return false;
        if(plan.targets.tp1 >= plan.targets.entry)
            return false;
    }

    return true;
}

void AnalyseLeoSensor(LeoSensors& LS, TFSignal& sig)
{
    sig.timeframe = LS.timeframe;
    sig.trendDir = DIR_NONE;
    sig.breakoutDir = DIR_NONE;
    sig.exhaustionDir = DIR_NONE;
    sig.swingDir = DIR_NONE;
    sig.support = LS.posFibo_candel[0].fibo_support;
    sig.resistance = LS.posFibo_candel[0].fibo_resistance;
    sig.atr = LS.atr[0];
    sig.rsi = LS.rsi[0];
    sig.stochMain = LS.stoch_main[0];
    sig.stochSignal = LS.stoch_sig[0];
    sig.macdMain = LS.macd_main[0];
    sig.macdSignal = LS.macd_sig[0];
    sig.trendScore = 0;
    sig.breakoutScore = 0;
    sig.exhaustionScore = 0;
    sig.fiboScore = 0;

    if(LS.ma_trend[0] > LS.ma_trend[1] && LS.ma_cut[0] >= LS.ma_trend[0]){
        sig.trendDir = DIR_BUY;
        sig.trendScore = 1;
    }
    else if(LS.ma_trend[0] < LS.ma_trend[1] && LS.ma_cut[0] <= LS.ma_trend[0]){
        sig.trendDir = DIR_SELL;
        sig.trendScore = 1;
    }

    if(sig.resistance > 0 && currentPrice > sig.resistance){
        sig.breakoutDir = DIR_BUY;
        sig.breakoutScore = 1;
    }
    else if(sig.support > 0 && currentPrice < sig.support){
        sig.breakoutDir = DIR_SELL;
        sig.breakoutScore = 1;
    }

    if(LS.zig_zag[2] > LS.zig_zag[3])
        sig.swingDir = DIR_BUY;
    else if(LS.zig_zag[2] < LS.zig_zag[3])
        sig.swingDir = DIR_SELL;

    if(LS.rsi[0] > 70 || LS.stoch_main[0] > 80)
        sig.exhaustionDir = DIR_BUY;
    else if(LS.rsi[0] < 30 || LS.stoch_main[0] < 20)
        sig.exhaustionDir = DIR_SELL;

    if(LS.posFibo_candel[0].fibo_line_is_aktive || LS.posFibo_candel[0].fibo_half_line_is_aktive)
        sig.fiboScore = 1;
}

void BuildTFRelation(TFSignal& smallSig, TFSignal& bigSig, TFRelation& rel)
{
    rel.smallTf = smallSig.timeframe;
    rel.bigTf = bigSig.timeframe;
    rel.trendAgreement = DIR_NONE;
    rel.breakoutAgainstBig = DIR_NONE;
    rel.pullbackToBig = DIR_NONE;
    rel.exhaustionAtBigZone = DIR_NONE;
    rel.scoreBuy = 0;
    rel.scoreSell = 0;

    if(smallSig.trendDir != DIR_NONE && smallSig.trendDir == bigSig.trendDir){
        rel.trendAgreement = smallSig.trendDir;
        if(rel.trendAgreement == DIR_BUY) rel.scoreBuy += 1;
        else rel.scoreSell += 1;
    }
    else if(smallSig.trendDir != DIR_NONE && bigSig.trendDir != DIR_NONE){
        rel.trendAgreement = -smallSig.trendDir;
    }

    if(bigSig.resistance > 0 && currentPrice > bigSig.resistance)
        rel.breakoutAgainstBig = DIR_BUY;
    else if(bigSig.support > 0 && currentPrice < bigSig.support)
        rel.breakoutAgainstBig = DIR_SELL;

    if(bigSig.trendDir == DIR_BUY && smallSig.exhaustionDir == DIR_SELL && bigSig.support > 0 && currentPrice >= bigSig.support)
        rel.pullbackToBig = DIR_BUY;
    else if(bigSig.trendDir == DIR_SELL && smallSig.exhaustionDir == DIR_BUY && bigSig.resistance > 0 && currentPrice <= bigSig.resistance)
        rel.pullbackToBig = DIR_SELL;

    if(rel.pullbackToBig == DIR_BUY) rel.scoreBuy += 1;
    else if(rel.pullbackToBig == DIR_SELL) rel.scoreSell += 1;

    if(bigSig.support > 0 && MathAbs(currentPrice-bigSig.support) <= smallSig.atr && smallSig.exhaustionDir == DIR_SELL)
        rel.exhaustionAtBigZone = DIR_BUY;
    else if(bigSig.resistance > 0 && MathAbs(currentPrice-bigSig.resistance) <= smallSig.atr && smallSig.exhaustionDir == DIR_BUY)
        rel.exhaustionAtBigZone = DIR_SELL;
}

bool BuildRangeRelativeBreakoutPlan(double buyScore, double sellScore)
{
    if(!EnableRangeRelativeBreakout)
        return false;

    double rangeAtr = CurrentM30RangeATR();
    if(rangeAtr < RangeRelativeMinM30ATR || rangeAtr > RangeRelativeMaxM30ATR)
        return false;

    int dir = DIR_NONE;
    bool buyBias = (sig_H4.trendDir!=DIR_SELL && sig_H1.trendDir!=DIR_SELL
                    && (sig_M30.trendDir==DIR_BUY || sig_M15.trendDir==DIR_BUY || sig_M5.swingDir==DIR_BUY));
    bool sellBias = (sig_H4.trendDir!=DIR_BUY && sig_H1.trendDir!=DIR_BUY
                     && (sig_M30.trendDir==DIR_SELL || sig_M15.trendDir==DIR_SELL || sig_M5.swingDir==DIR_SELL));

    if(buyBias && !sellBias)
        dir = DIR_BUY;
    else if(sellBias && !buyBias)
        dir = DIR_SELL;
    else if(buyBias && sellBias){
        if(buyScore > sellScore + 1)
            dir = DIR_BUY;
        else if(sellScore > buyScore + 1)
            dir = DIR_SELL;
    }

    if(dir==DIR_NONE)
        return false;

    if(MaxDirectionalExhaustionStack >= 0 && DirectionalExhaustionStack(dir) > MaxDirectionalExhaustionStack)
        return false;

    double entry = 0;
    double sl = 0;
    double tp1 = 0;
    double tp2 = 0;
    double tp3 = 0;
    double trail = 0;

    if(dir==DIR_BUY){
        double baseResistance = 0;
        if(sig_M5.resistance > Ask + minStopLevel)
            baseResistance = sig_M5.resistance;
        if(sig_M15.resistance > Ask + minStopLevel && (baseResistance<=0 || sig_M15.resistance < baseResistance))
            baseResistance = sig_M15.resistance;

        if(baseResistance <= 0)
            return false;

        entry = baseResistance + BreakoutEntryBuffer(sig_M5.atr);

        double baseSupport = 0;
        if(sig_M5.support > 0 && sig_M5.support < entry)
            baseSupport = sig_M5.support;
        if(sig_M15.support > 0 && sig_M15.support < entry)
            baseSupport = (baseSupport>0 ? MathMin(baseSupport, sig_M15.support) : sig_M15.support);

        if(baseSupport <= 0)
            return false;

        sl = baseSupport - FiboRiskBuffer(sig_M15.atr);

        if(sig_M30.resistance > entry)
            tp1 = sig_M30.resistance;
        if(sig_H1.resistance > entry && (tp1<=0 || sig_H1.resistance < tp1))
            tp1 = sig_H1.resistance;
        if(tp1 <= entry)
            tp1 = entry + (entry-sl);

        tp2 = sig_H1.resistance > tp1 ? sig_H1.resistance : entry + 1.5*(entry-sl);
        tp3 = sig_H4.resistance > tp2 ? sig_H4.resistance : entry + 2.0*(entry-sl);
        trail = baseSupport;
    }
    else if(dir==DIR_SELL){
        double baseSupportSell = 0;
        if(sig_M5.support > 0 && sig_M5.support < Bid - minStopLevel)
            baseSupportSell = sig_M5.support;
        if(sig_M15.support > 0 && sig_M15.support < Bid - minStopLevel && (baseSupportSell<=0 || sig_M15.support > baseSupportSell))
            baseSupportSell = sig_M15.support;

        if(baseSupportSell <= 0)
            return false;

        entry = baseSupportSell - BreakoutEntryBuffer(sig_M5.atr);

        double baseResistanceSell = 0;
        if(sig_M5.resistance > entry)
            baseResistanceSell = sig_M5.resistance;
        if(sig_M15.resistance > entry)
            baseResistanceSell = (baseResistanceSell>0 ? MathMax(baseResistanceSell, sig_M15.resistance) : sig_M15.resistance);

        if(baseResistanceSell <= 0)
            return false;

        sl = baseResistanceSell + FiboRiskBuffer(sig_M15.atr);

        if(sig_M30.support > 0 && sig_M30.support < entry)
            tp1 = sig_M30.support;
        if(sig_H1.support > 0 && sig_H1.support < entry && (tp1<=0 || sig_H1.support > tp1))
            tp1 = sig_H1.support;
        if(tp1 <= 0 || tp1 >= entry)
            tp1 = entry - (sl-entry);

        tp2 = sig_H1.support > 0 && sig_H1.support < tp1 ? sig_H1.support : entry - 1.5*(sl-entry);
        tp3 = sig_H4.support > 0 && sig_H4.support < tp2 ? sig_H4.support : entry - 2.0*(sl-entry);
        trail = baseResistanceSell;
    }

    ResetTradePlan(robotPlan);
    robotPlan.planType = PLAN_RANGE_SWING;
    robotPlan.cmd = (dir==DIR_BUY ? OP_BUYSTOP : OP_SELLSTOP);
    robotPlan.direction = dir;
    robotPlan.confidence = (dir==DIR_BUY ? buyScore : sellScore) + 0.5;
    robotPlan.triggerSignal.type = SIG_RANGE_BOUNCE;
    robotPlan.triggerSignal.timeframe = PERIOD_M15;
    robotPlan.triggerSignal.direction = dir;
    robotPlan.triggerSignal.strength = robotPlan.confidence;
    robotPlan.triggerSignal.time = currentTime;
    robotPlan.triggerSignal.reason = "moderate M30 range with relative M5/M15 fibo breakout trap";
    robotPlan.targets.entry = entry;
    robotPlan.targets.slInitial = sl;
    robotPlan.targets.slCurrent = sl;
    robotPlan.targets.tp1 = tp1;
    robotPlan.targets.tp2 = tp2;
    robotPlan.targets.tp3 = tp3;
    robotPlan.targets.trailLevel = trail;
    robotPlan.targets.activeTarget = 1;

    return true;
}

void BuildTradePlan()
{
    ResetTradePlan(robotPlan);

    double buyScore = 0;
    double sellScore = 0;

    if(sig_H4.trendDir == DIR_BUY) buyScore += 3;
    else if(sig_H4.trendDir == DIR_SELL) sellScore += 3;

    if(sig_H1.trendDir == DIR_BUY) buyScore += 2;
    else if(sig_H1.trendDir == DIR_SELL) sellScore += 2;

    buyScore += rel_M30_H1.scoreBuy + rel_M15_M30.scoreBuy + rel_M5_M15.scoreBuy;
    sellScore += rel_M30_H1.scoreSell + rel_M15_M30.scoreSell + rel_M5_M15.scoreSell;

    if(sig_M30.breakoutDir == DIR_BUY) buyScore += 1;
    else if(sig_M30.breakoutDir == DIR_SELL) sellScore += 1;

    if(sig_M15.breakoutDir == DIR_BUY) buyScore += 1;
    else if(sig_M15.breakoutDir == DIR_SELL) sellScore += 1;

    if(buyScore < 6 && sellScore < 6){
        BuildRangeRelativeBreakoutPlan(buyScore, sellScore);
        return;
    }

    bool mainBuyTrend = (sig_H4.trendDir == DIR_BUY && sig_H1.trendDir == DIR_BUY);
    bool mainSellTrend = (sig_H4.trendDir == DIR_SELL && sig_H1.trendDir == DIR_SELL);

    if(mainBuyTrend && buyScore > sellScore + 1){
        robotPlan.planType = PLAN_TREND_CONT;
        robotPlan.cmd = OP_BUY;
        robotPlan.direction = DIR_BUY;
        robotPlan.confidence = buyScore;

        double buyEntry = 0;
        double buySL = 0;
        double buyTP1 = 0;
        double buyStopEntry = 0;
        double buyStopSL = 0;
        double buyStopTP1 = 0;
        double buyLimitEntry = 0;
        double buyLimitSL = 0;
        double buyLimitTP1 = 0;
        bool buyPullback = BuyPullbackExpected();
        double buyMaxPullback = sig_M30.atr > 0 ? sig_M30.atr*MaxPullbackEntryATR : 0;

        if(sig_M30.resistance > Ask + minStopLevel){
            double buyEntryBufferM30 = BreakoutEntryBuffer(sig_M30.atr);
            double buyStopBufferM30 = FiboRiskBuffer(sig_M30.atr);
            buyStopEntry = sig_M30.resistance + buyEntryBufferM30;
            buyStopSL = sig_M30.support > 0 ? sig_M30.support - buyStopBufferM30 : 0;
            buyStopTP1 = sig_H1.resistance;
        }
        else if(sig_M15.resistance > Ask + minStopLevel){
            double buyEntryBufferM15 = BreakoutEntryBuffer(sig_M15.atr);
            double buyStopBufferM15 = FiboRiskBuffer(sig_M15.atr);
            buyStopEntry = sig_M15.resistance + buyEntryBufferM15;
            buyStopSL = sig_M15.support > 0 ? sig_M15.support - buyStopBufferM15 : 0;
            buyStopTP1 = sig_M30.resistance;
        }

        if(sig_M15.support > 0
           && sig_M15.support < Ask - minStopLevel
           && (buyMaxPullback <= 0 || Ask - sig_M15.support <= buyMaxPullback)){
            double buyLimitBufferM15 = FiboRiskBuffer(sig_M15.atr);
            buyLimitEntry = sig_M15.support;
            buyLimitSL = sig_M15.support - buyLimitBufferM15;
            buyLimitTP1 = sig_M15.resistance > buyLimitEntry ? sig_M15.resistance : sig_M30.resistance;
        }
        else if(sig_M30.support > 0
                && sig_M30.support < Ask - minStopLevel
                && (buyMaxPullback <= 0 || Ask - sig_M30.support <= buyMaxPullback)){
            double buyLimitBufferM30 = FiboRiskBuffer(sig_M30.atr);
            buyLimitEntry = sig_M30.support;
            buyLimitSL = sig_M30.support - buyLimitBufferM30;
            buyLimitTP1 = sig_M30.resistance;
        }

        bool wantBuyLimit = (buyLimitEntry > 0 && (buyPullback || sig_M15.breakoutDir!=DIR_BUY || sig_M5.breakoutDir!=DIR_BUY));
        bool wantBuyStop = (buyStopEntry > 0 && (!buyPullback || pending_buy_limit.ticketNr > -1 || buyLimitEntry <= 0));
        if(OptimizationBreakoutOnly){
            wantBuyLimit = false;
            wantBuyStop = (buyStopEntry > 0);
        }

        if(wantBuyLimit && pending_buy_limit.ticketNr < 0){
            robotPlan.planType = PLAN_RETEST;
            robotPlan.cmd = OP_BUYLIMIT;
            buyEntry = buyLimitEntry;
            buySL = buyLimitSL;
            buyTP1 = buyLimitTP1;
        }
        else if(wantBuyStop && pending_buy_stop.ticketNr < 0){
            robotPlan.planType = PLAN_BREAKOUT;
            robotPlan.cmd = OP_BUYSTOP;
            buyEntry = buyStopEntry;
            buySL = buyStopSL;
            buyTP1 = buyStopTP1;
        }
        else if(wantBuyLimit){
            robotPlan.planType = PLAN_RETEST;
            robotPlan.cmd = OP_BUYLIMIT;
            buyEntry = buyLimitEntry;
            buySL = buyLimitSL;
            buyTP1 = buyLimitTP1;
        }
        else if(wantBuyStop){
            robotPlan.planType = PLAN_BREAKOUT;
            robotPlan.cmd = OP_BUYSTOP;
            buyEntry = buyStopEntry;
            buySL = buyStopSL;
            buyTP1 = buyStopTP1;
        }
        else if(!OptimizationBreakoutOnly && buyLimitEntry > 0){
            robotPlan.planType = PLAN_RETEST;
            robotPlan.cmd = OP_BUYLIMIT;
            buyEntry = buyLimitEntry;
            buySL = buyLimitSL;
            buyTP1 = buyLimitTP1;
        }

        if(buyEntry <= 0){
            if(BuildRangeRelativeBreakoutPlan(buyScore, sellScore))
                return;

            ResetTradePlan(robotPlan);
            return;
        }

        robotPlan.triggerSignal.type = SIG_TREND_ALIGN;
        robotPlan.triggerSignal.timeframe = PERIOD_H1;
        robotPlan.triggerSignal.direction = DIR_BUY;
        robotPlan.triggerSignal.strength = buyScore;
        robotPlan.triggerSignal.time = currentTime;
        robotPlan.triggerSignal.reason = "H4/H1 trend alignment with lower-timeframe confirmation";
        robotPlan.invalidationSignal.type = SIG_BREAKOUT;
        robotPlan.invalidationSignal.timeframe = PERIOD_M30;
        robotPlan.invalidationSignal.direction = DIR_SELL;
        robotPlan.invalidationSignal.level = sig_M30.support;
        robotPlan.targetSignal.type = SIG_CONTINUATION;
        robotPlan.targetSignal.timeframe = PERIOD_H1;
        robotPlan.targetSignal.direction = DIR_BUY;
        robotPlan.targetSignal.targetLevel = sig_H1.resistance;
        if(buyEntry > 0)
            robotPlan.targets.entry = buyEntry;
        else
            robotPlan.targets.entry = Ask;
        robotPlan.targets.slInitial = buySL > 0 ? buySL : (sig_M30.support > 0 ? sig_M30.support - FiboRiskBuffer(sig_M30.atr) : 0);
        robotPlan.targets.slCurrent = robotPlan.targets.slInitial;
        robotPlan.targets.tp1 = buyTP1 > 0 ? buyTP1 : sig_M30.resistance;
        robotPlan.targets.tp2 = sig_H1.resistance;
        robotPlan.targets.tp3 = sig_H4.resistance;
        if(robotPlan.cmd == OP_BUYSTOP && robotPlan.targets.tp1 <= robotPlan.targets.entry){
            robotPlan.targets.tp1 = sig_H1.resistance;
            robotPlan.targets.tp2 = sig_H4.resistance;
        }
        robotPlan.targets.trailLevel = sig_M15.support;
        robotPlan.targets.activeTarget = 1;
    }
    else if(mainSellTrend && sellScore > buyScore + 1){
        robotPlan.planType = PLAN_TREND_CONT;
        robotPlan.cmd = OP_SELL;
        robotPlan.direction = DIR_SELL;
        robotPlan.confidence = sellScore;

        double sellEntry = 0;
        double sellSL = 0;
        double sellTP1 = 0;
        double sellStopEntry = 0;
        double sellStopSL = 0;
        double sellStopTP1 = 0;
        double sellLimitEntry = 0;
        double sellLimitSL = 0;
        double sellLimitTP1 = 0;
        bool sellPullback = SellPullbackExpected();
        double sellMaxPullback = sig_M30.atr > 0 ? sig_M30.atr*MaxPullbackEntryATR : 0;

        if(sig_M30.support > 0 && sig_M30.support < Bid - minStopLevel){
            double sellEntryBufferM30 = BreakoutEntryBuffer(sig_M30.atr);
            double sellStopBufferM30 = FiboRiskBuffer(sig_M30.atr);
            sellStopEntry = sig_M30.support - sellEntryBufferM30;
            sellStopSL = sig_M30.resistance > 0 ? sig_M30.resistance + sellStopBufferM30 : 0;
            sellStopTP1 = sig_H1.support;
        }
        else if(sig_M15.support > 0 && sig_M15.support < Bid - minStopLevel){
            double sellEntryBufferM15 = BreakoutEntryBuffer(sig_M15.atr);
            double sellStopBufferM15 = FiboRiskBuffer(sig_M15.atr);
            sellStopEntry = sig_M15.support - sellEntryBufferM15;
            sellStopSL = sig_M15.resistance > 0 ? sig_M15.resistance + sellStopBufferM15 : 0;
            sellStopTP1 = sig_M30.support;
        }

        if(sig_M15.resistance > Bid + minStopLevel
           && (sellMaxPullback <= 0 || sig_M15.resistance - Bid <= sellMaxPullback)){
            double sellLimitBufferM15 = FiboRiskBuffer(sig_M15.atr);
            sellLimitEntry = sig_M15.resistance;
            sellLimitSL = sig_M15.resistance + sellLimitBufferM15;
            sellLimitTP1 = sig_M15.support > 0 && sig_M15.support < sellLimitEntry ? sig_M15.support : sig_M30.support;
        }
        else if(sig_M30.resistance > Bid + minStopLevel
                && (sellMaxPullback <= 0 || sig_M30.resistance - Bid <= sellMaxPullback)){
            double sellLimitBufferM30 = FiboRiskBuffer(sig_M30.atr);
            sellLimitEntry = sig_M30.resistance;
            sellLimitSL = sig_M30.resistance + sellLimitBufferM30;
            sellLimitTP1 = sig_M30.support;
        }

        bool wantSellLimit = (sellLimitEntry > 0 && (sellPullback || sig_M15.breakoutDir!=DIR_SELL || sig_M5.breakoutDir!=DIR_SELL));
        bool wantSellStop = (sellStopEntry > 0 && (!sellPullback || pending_sell_limit.ticketNr > -1 || sellLimitEntry <= 0));
        if(OptimizationBreakoutOnly){
            wantSellLimit = false;
            wantSellStop = (sellStopEntry > 0);
        }

        if(wantSellLimit && pending_sell_limit.ticketNr < 0){
            robotPlan.planType = PLAN_RETEST;
            robotPlan.cmd = OP_SELLLIMIT;
            sellEntry = sellLimitEntry;
            sellSL = sellLimitSL;
            sellTP1 = sellLimitTP1;
        }
        else if(wantSellStop && pending_sell_stop.ticketNr < 0){
            robotPlan.planType = PLAN_BREAKOUT;
            robotPlan.cmd = OP_SELLSTOP;
            sellEntry = sellStopEntry;
            sellSL = sellStopSL;
            sellTP1 = sellStopTP1;
        }
        else if(wantSellLimit){
            robotPlan.planType = PLAN_RETEST;
            robotPlan.cmd = OP_SELLLIMIT;
            sellEntry = sellLimitEntry;
            sellSL = sellLimitSL;
            sellTP1 = sellLimitTP1;
        }
        else if(wantSellStop){
            robotPlan.planType = PLAN_BREAKOUT;
            robotPlan.cmd = OP_SELLSTOP;
            sellEntry = sellStopEntry;
            sellSL = sellStopSL;
            sellTP1 = sellStopTP1;
        }
        else if(!OptimizationBreakoutOnly && sellLimitEntry > 0){
            robotPlan.planType = PLAN_RETEST;
            robotPlan.cmd = OP_SELLLIMIT;
            sellEntry = sellLimitEntry;
            sellSL = sellLimitSL;
            sellTP1 = sellLimitTP1;
        }

        if(sellEntry <= 0){
            if(BuildRangeRelativeBreakoutPlan(buyScore, sellScore))
                return;

            ResetTradePlan(robotPlan);
            return;
        }

        robotPlan.triggerSignal.type = SIG_TREND_ALIGN;
        robotPlan.triggerSignal.timeframe = PERIOD_H1;
        robotPlan.triggerSignal.direction = DIR_SELL;
        robotPlan.triggerSignal.strength = sellScore;
        robotPlan.triggerSignal.time = currentTime;
        robotPlan.triggerSignal.reason = "H4/H1 trend alignment with lower-timeframe confirmation";
        robotPlan.invalidationSignal.type = SIG_BREAKOUT;
        robotPlan.invalidationSignal.timeframe = PERIOD_M30;
        robotPlan.invalidationSignal.direction = DIR_BUY;
        robotPlan.invalidationSignal.level = sig_M30.resistance;
        robotPlan.targetSignal.type = SIG_CONTINUATION;
        robotPlan.targetSignal.timeframe = PERIOD_H1;
        robotPlan.targetSignal.direction = DIR_SELL;
        robotPlan.targetSignal.targetLevel = sig_H1.support;
        if(sellEntry > 0)
            robotPlan.targets.entry = sellEntry;
        else
            robotPlan.targets.entry = Bid;
        robotPlan.targets.slInitial = sellSL > 0 ? sellSL : (sig_M30.resistance > 0 ? sig_M30.resistance + FiboRiskBuffer(sig_M30.atr) : 0);
        robotPlan.targets.slCurrent = robotPlan.targets.slInitial;
        robotPlan.targets.tp1 = sellTP1 > 0 ? sellTP1 : sig_M30.support;
        robotPlan.targets.tp2 = sig_H1.support;
        robotPlan.targets.tp3 = sig_H4.support;
        if(robotPlan.cmd == OP_SELLSTOP && robotPlan.targets.tp1 >= robotPlan.targets.entry){
            robotPlan.targets.tp1 = sig_H1.support;
            robotPlan.targets.tp2 = sig_H4.support;
        }
        robotPlan.targets.trailLevel = sig_M15.resistance;
        robotPlan.targets.activeTarget = 1;
    }

    if(robotPlan.cmd==6)
        BuildRangeRelativeBreakoutPlan(buyScore, sellScore);
}

void ApplyTradePlanToOrderSlots()
{
    if(robotPlan.cmd==OP_BUY || robotPlan.cmd==OP_SELL){
        aktiveRobotOrder.openPrice = robotPlan.targets.entry;
        aktiveRobotOrder.StopLoss = robotPlan.targets.slInitial;
        aktiveRobotOrder.TakeProfit = robotPlan.targets.tp1;
    }
    else if(robotPlan.cmd==OP_BUYLIMIT){
        pending_buy_limit.openPrice = robotPlan.targets.entry;
        pending_buy_limit.StopLoss = robotPlan.targets.slInitial;
        pending_buy_limit.TakeProfit = robotPlan.targets.tp1;
    }
    else if(robotPlan.cmd==OP_SELLLIMIT){
        pending_sell_limit.openPrice = robotPlan.targets.entry;
        pending_sell_limit.StopLoss = robotPlan.targets.slInitial;
        pending_sell_limit.TakeProfit = robotPlan.targets.tp1;
    }
    else if(robotPlan.cmd==OP_BUYSTOP){
        pending_buy_stop.openPrice = robotPlan.targets.entry;
        pending_buy_stop.StopLoss = robotPlan.targets.slInitial;
        pending_buy_stop.TakeProfit = robotPlan.targets.tp1;
    }
    else if(robotPlan.cmd==OP_SELLSTOP){
        pending_sell_stop.openPrice = robotPlan.targets.entry;
        pending_sell_stop.StopLoss = robotPlan.targets.slInitial;
        pending_sell_stop.TakeProfit = robotPlan.targets.tp1;
    }
}

double PendingTrapMinModifyMove()
{
    double atr = sig_M15.atr;
    if(atr <= 0)
        atr = sig_M30.atr;
    if(atr <= 0)
        atr = Point;

    if(PendingTrapMinModifyATR <= 0)
        return Point;

    return MathMax(Point, atr*PendingTrapMinModifyATR);
}

datetime PendingTrapLastModifyBar(int cmd)
{
    if(cmd==OP_BUYLIMIT)  return lastBuyLimitModifyBar;
    if(cmd==OP_SELLLIMIT) return lastSellLimitModifyBar;
    if(cmd==OP_BUYSTOP)   return lastBuyStopModifyBar;
    if(cmd==OP_SELLSTOP)  return lastSellStopModifyBar;
    return 0;
}

datetime PendingTrapLastModifyTime(int cmd)
{
    if(cmd==OP_BUYLIMIT)  return lastBuyLimitModifyTime;
    if(cmd==OP_SELLLIMIT) return lastSellLimitModifyTime;
    if(cmd==OP_BUYSTOP)   return lastBuyStopModifyTime;
    if(cmd==OP_SELLSTOP)  return lastSellStopModifyTime;
    return 0;
}

bool PendingPlanNeedsModify(MyOrder& existingOrder)
{
    double minMove = PendingTrapMinModifyMove();

    if(MathAbs(existingOrder.openPrice-robotPlan.targets.entry) >= minMove)
        return true;
    if(MathAbs(existingOrder.StopLoss-robotPlan.targets.slInitial) >= minMove)
        return true;
    if(MathAbs(existingOrder.TakeProfit-robotPlan.targets.tp1) >= minMove)
        return true;

    return false;
}

bool PendingTrapMoveAllowed(int cmd, MyOrder& existingOrder)
{
    double minMove = PendingTrapMinModifyMove();
    double newEntry = robotPlan.targets.entry;

    if(!PendingStopAllowCloserEntry){
        if(cmd==OP_BUYSTOP && newEntry < existingOrder.openPrice-minMove)
            return false;
        if(cmd==OP_SELLSTOP && newEntry > existingOrder.openPrice+minMove)
            return false;
    }

    if(!PendingTrapAllowRiskIncrease && IsStopOrderCmd(cmd)){
        double oldRisk = 0;
        double newRisk = 0;

        if(cmd==OP_BUYSTOP){
            oldRisk = existingOrder.openPrice-existingOrder.StopLoss;
            newRisk = robotPlan.targets.entry-robotPlan.targets.slInitial;
        }
        else if(cmd==OP_SELLSTOP){
            oldRisk = existingOrder.StopLoss-existingOrder.openPrice;
            newRisk = robotPlan.targets.slInitial-robotPlan.targets.entry;
        }

        if(oldRisk > 0 && newRisk > oldRisk+minMove)
            return false;
    }

    return true;
}

bool PendingTrapCanModify(int cmd, MyOrder& existingOrder)
{
    if(!PendingPlanNeedsModify(existingOrder))
        return false;

    if(!PendingTrapMoveAllowed(cmd, existingOrder))
        return false;

    datetime barTime = iTime(Symbol(), PERIOD_M5, 0);
    if(PendingTrapModifyOncePerM5Bar && PendingTrapLastModifyBar(cmd)==barTime)
        return false;

    datetime lastModifyTime = PendingTrapLastModifyTime(cmd);
    if(PendingTrapMinModifySeconds > 0 && lastModifyTime > 0 && currentTime-lastModifyTime < PendingTrapMinModifySeconds)
        return false;

    return true;
}

void MarkPendingTrapModified(int cmd)
{
    datetime barTime = iTime(Symbol(), PERIOD_M5, 0);

    if(cmd==OP_BUYLIMIT){
        lastBuyLimitModifyBar = barTime;
        lastBuyLimitModifyTime = currentTime;
    }
    else if(cmd==OP_SELLLIMIT){
        lastSellLimitModifyBar = barTime;
        lastSellLimitModifyTime = currentTime;
    }
    else if(cmd==OP_BUYSTOP){
        lastBuyStopModifyBar = barTime;
        lastBuyStopModifyTime = currentTime;
    }
    else if(cmd==OP_SELLSTOP){
        lastSellStopModifyBar = barTime;
        lastSellStopModifyTime = currentTime;
    }
}

bool ApplyOrModifyExistingPendingPlan()
{
    if(robotPlan.cmd!=OP_BUYLIMIT
       && robotPlan.cmd!=OP_SELLLIMIT
       && robotPlan.cmd!=OP_BUYSTOP
       && robotPlan.cmd!=OP_SELLSTOP)
        return false;

    if(robotPlan.cmd==OP_BUYLIMIT && pending_buy_limit.ticketNr > -1){
        if(!PendingTrapCanModify(OP_BUYLIMIT, pending_buy_limit))
            return true;
        ApplyTradePlanToOrderSlots();
        ModifyTP(MODIFY_PENDING, pending_buy_limit);
        MarkPendingTrapModified(OP_BUYLIMIT);
        activeRobotPlan = robotPlan;
        return true;
    }
    else if(robotPlan.cmd==OP_SELLLIMIT && pending_sell_limit.ticketNr > -1){
        if(!PendingTrapCanModify(OP_SELLLIMIT, pending_sell_limit))
            return true;
        ApplyTradePlanToOrderSlots();
        ModifyTP(MODIFY_PENDING, pending_sell_limit);
        MarkPendingTrapModified(OP_SELLLIMIT);
        activeRobotPlan = robotPlan;
        return true;
    }
    else if(robotPlan.cmd==OP_BUYSTOP && pending_buy_stop.ticketNr > -1){
        if(!PendingTrapCanModify(OP_BUYSTOP, pending_buy_stop))
            return true;
        ApplyTradePlanToOrderSlots();
        ModifyTP(MODIFY_PENDING, pending_buy_stop);
        MarkPendingTrapModified(OP_BUYSTOP);
        activeRobotPlan = robotPlan;
        return true;
    }
    else if(robotPlan.cmd==OP_SELLSTOP && pending_sell_stop.ticketNr > -1){
        if(!PendingTrapCanModify(OP_SELLSTOP, pending_sell_stop))
            return true;
        ApplyTradePlanToOrderSlots();
        ModifyTP(MODIFY_PENDING, pending_sell_stop);
        MarkPendingTrapModified(OP_SELLSTOP);
        activeRobotPlan = robotPlan;
        return true;
    }

    return false;
}

void DeleteRobotPendingOrders()
{
    if(pending_buy_limit.ticketNr > -1){
        ModifyTP(DELETE_PENDING, pending_buy_limit);
        ResetOrder(pending_buy_limit);
    }

    if(pending_sell_limit.ticketNr > -1){
        ModifyTP(DELETE_PENDING, pending_sell_limit);
        ResetOrder(pending_sell_limit);
    }

    if(pending_buy_stop.ticketNr > -1){
        ModifyTP(DELETE_PENDING, pending_buy_stop);
        ResetOrder(pending_buy_stop);
    }

    if(pending_sell_stop.ticketNr > -1){
        ModifyTP(DELETE_PENDING, pending_sell_stop);
        ResetOrder(pending_sell_stop);
    }
}

int CmdDirection(int cmd)
{
    if(cmd==OP_BUY || cmd==OP_BUYLIMIT || cmd==OP_BUYSTOP)
        return DIR_BUY;
    if(cmd==OP_SELL || cmd==OP_SELLLIMIT || cmd==OP_SELLSTOP)
        return DIR_SELL;
    return DIR_NONE;
}

bool PendingPlanContextStillValid(int cmd)
{
    if(!DeleteOrphanPendingWhenPlanLost)
        return true;

    int pendingDir = CmdDirection(cmd);
    if(pendingDir==DIR_NONE)
        return false;

    if(robotPlan.cmd==cmd && robotPlan.direction==pendingDir)
        return true;

    if(robotPlan.direction!=DIR_NONE && robotPlan.direction!=pendingDir)
        return false;

    if(!IsStopOrderCmd(cmd))
        return false;

    double rangeAtr = CurrentM30RangeATR();
    if(rangeAtr >= OrphanPendingKeepWideRangeM30ATR && DirectionalBigTrendStack(pendingDir) >= 2)
        return true;

    return false;
}

bool PendingSignalStillValid(int cmd)
{
    if(cmd==OP_BUYLIMIT){
        if(!PendingPlanContextStillValid(cmd))
            return false;
        if(sig_H4.trendDir==DIR_SELL || sig_H1.trendDir==DIR_SELL)
            return false;
        return (pending_buy_limit.openPrice > 0 && pending_buy_limit.openPrice < Ask - minStopLevel);
    }

    if(cmd==OP_BUYSTOP){
        if(!PendingPlanContextStillValid(cmd))
            return false;
        if(sig_H4.trendDir==DIR_SELL || sig_H1.trendDir==DIR_SELL)
            return false;
        return (pending_buy_stop.openPrice > 0 && pending_buy_stop.openPrice > Ask + minStopLevel);
    }

    if(cmd==OP_SELLLIMIT){
        if(!PendingPlanContextStillValid(cmd))
            return false;
        if(sig_H4.trendDir==DIR_BUY || sig_H1.trendDir==DIR_BUY)
            return false;
        return (pending_sell_limit.openPrice > 0 && pending_sell_limit.openPrice > Bid + minStopLevel);
    }

    if(cmd==OP_SELLSTOP){
        if(!PendingPlanContextStillValid(cmd))
            return false;
        if(sig_H4.trendDir==DIR_BUY || sig_H1.trendDir==DIR_BUY)
            return false;
        return (pending_sell_stop.openPrice > 0 && pending_sell_stop.openPrice < Bid - minStopLevel);
    }

    return false;
}

void DeleteInvalidPendingOrders()
{
    if(pending_buy_limit.ticketNr > -1 && !PendingSignalStillValid(OP_BUYLIMIT)){
        Print("Deleting stale OP_BUYLIMIT: pending signal is no longer valid");
        ModifyTP(DELETE_PENDING, pending_buy_limit);
        ResetOrder(pending_buy_limit);
    }

    if(pending_buy_stop.ticketNr > -1 && !PendingSignalStillValid(OP_BUYSTOP)){
        Print("Deleting stale OP_BUYSTOP: pending signal is no longer valid");
        ModifyTP(DELETE_PENDING, pending_buy_stop);
        ResetOrder(pending_buy_stop);
    }

    if(pending_sell_limit.ticketNr > -1 && !PendingSignalStillValid(OP_SELLLIMIT)){
        Print("Deleting stale OP_SELLLIMIT: pending signal is no longer valid");
        ModifyTP(DELETE_PENDING, pending_sell_limit);
        ResetOrder(pending_sell_limit);
    }

    if(pending_sell_stop.ticketNr > -1 && !PendingSignalStillValid(OP_SELLSTOP)){
        Print("Deleting stale OP_SELLSTOP: pending signal is no longer valid");
        ModifyTP(DELETE_PENDING, pending_sell_stop);
        ResetOrder(pending_sell_stop);
    }
}

void ManageRobotTargets()
{
    if(activeRobotPlan.planType==PLAN_NONE)
        return;

    double minDistance = TradeMinDistance();

    if(aktiveRobotOrder.type==OP_BUY){
        if(StrongCloseInvalidation(OP_BUY)){
            Print("Closing OP_BUY: strong H1/M30/M15 invalidation against active plan");
            ModifyTP(CLOSE_BUY, aktiveRobotOrder);
            return;
        }

        double initialRiskBuy = 0;
        if(activeRobotPlan.targets.entry > 0 && activeRobotPlan.targets.slInitial > 0)
            initialRiskBuy = activeRobotPlan.targets.entry - activeRobotPlan.targets.slInitial;

        double profitDistanceBuy = currentPrice - activeRobotPlan.targets.entry;
        bool allowProtectBuy = (initialRiskBuy > 0 && profitDistanceBuy >= initialRiskBuy*TrailStartRiskRatio);

        if(activeRobotPlan.targets.tp1 > 0 && currentPrice >= activeRobotPlan.targets.tp1 && activeRobotPlan.targets.activeTarget < 2)
            activeRobotPlan.targets.activeTarget = 2;
        if(activeRobotPlan.targets.tp2 > 0 && currentPrice >= activeRobotPlan.targets.tp2 && activeRobotPlan.targets.activeTarget < 3)
            activeRobotPlan.targets.activeTarget = 3;

        if((activeRobotPlan.targets.activeTarget >= 2 || allowProtectBuy) && activeRobotPlan.targets.entry > 0){
            double beBufferBuy = MathMax(minStopLevel + spread, FiboRiskBuffer(sig_M15.atr)*BreakEvenBufferATR);
            double breakEvenBuy = activeRobotPlan.targets.entry + beBufferBuy;
            double maxAllowedBuySL = Bid - minDistance;
            if(breakEvenBuy <= maxAllowedBuySL)
                aktiveRobotOrder.StopLoss = MathMax(aktiveRobotOrder.StopLoss, breakEvenBuy);
        }

        if(activeRobotPlan.targets.activeTarget >= 2 || allowProtectBuy){
            double maxTrailBuy = Bid - minDistance;
            double fiboTrailBuy = BuyFiboTrailCandidate(maxTrailBuy);
            if(fiboTrailBuy > 0 && fiboTrailBuy > aktiveRobotOrder.StopLoss)
                aktiveRobotOrder.StopLoss = fiboTrailBuy;
        }

        if(activeRobotPlan.targets.activeTarget >= 3 && activeRobotPlan.targets.tp3 > 0)
            aktiveRobotOrder.TakeProfit = activeRobotPlan.targets.tp3;
        else if(activeRobotPlan.targets.activeTarget >= 2 && activeRobotPlan.targets.tp2 > 0)
            aktiveRobotOrder.TakeProfit = activeRobotPlan.targets.tp2;

        ModifyTP(OP_BUY, aktiveRobotOrder);
    }
    else if(aktiveRobotOrder.type==OP_SELL){
        if(StrongCloseInvalidation(OP_SELL)){
            Print("Closing OP_SELL: strong H1/M30/M15 invalidation against active plan");
            ModifyTP(CLOSE_SELL, aktiveRobotOrder);
            return;
        }

        double initialRiskSell = 0;
        if(activeRobotPlan.targets.entry > 0 && activeRobotPlan.targets.slInitial > 0)
            initialRiskSell = activeRobotPlan.targets.slInitial - activeRobotPlan.targets.entry;

        double profitDistanceSell = activeRobotPlan.targets.entry - currentPrice;
        bool allowProtectSell = (initialRiskSell > 0 && profitDistanceSell >= initialRiskSell*TrailStartRiskRatio);

        if(activeRobotPlan.targets.tp1 > 0 && currentPrice <= activeRobotPlan.targets.tp1 && activeRobotPlan.targets.activeTarget < 2)
            activeRobotPlan.targets.activeTarget = 2;
        if(activeRobotPlan.targets.tp2 > 0 && currentPrice <= activeRobotPlan.targets.tp2 && activeRobotPlan.targets.activeTarget < 3)
            activeRobotPlan.targets.activeTarget = 3;

        if((activeRobotPlan.targets.activeTarget >= 2 || allowProtectSell) && activeRobotPlan.targets.entry > 0){
            double beBufferSell = MathMax(minStopLevel + spread, FiboRiskBuffer(sig_M15.atr)*BreakEvenBufferATR);
            double breakEvenSell = activeRobotPlan.targets.entry - beBufferSell;
            double minAllowedSellSL = Ask + minDistance;
            if(breakEvenSell >= minAllowedSellSL){
                if(aktiveRobotOrder.StopLoss <= 0)
                    aktiveRobotOrder.StopLoss = breakEvenSell;
                else
                    aktiveRobotOrder.StopLoss = MathMin(aktiveRobotOrder.StopLoss, breakEvenSell);
            }
        }

        if(activeRobotPlan.targets.activeTarget >= 2 || allowProtectSell){
            double minTrailSell = Ask + minDistance;
            double fiboTrailSell = SellFiboTrailCandidate(minTrailSell);
            if(fiboTrailSell > 0){
                if(aktiveRobotOrder.StopLoss <= 0)
                    aktiveRobotOrder.StopLoss = fiboTrailSell;
                else if(fiboTrailSell < aktiveRobotOrder.StopLoss)
                    aktiveRobotOrder.StopLoss = fiboTrailSell;
            }
        }

        if(activeRobotPlan.targets.activeTarget >= 3 && activeRobotPlan.targets.tp3 > 0)
            aktiveRobotOrder.TakeProfit = activeRobotPlan.targets.tp3;
        else if(activeRobotPlan.targets.activeTarget >= 2 && activeRobotPlan.targets.tp2 > 0)
            aktiveRobotOrder.TakeProfit = activeRobotPlan.targets.tp2;

        ModifyTP(OP_SELL, aktiveRobotOrder);
    }
}

//+------------------------------------------------------------------+
//| --- check if it's going to weekend or market time with low activity|
//+------------------------------------------------------------------+
bool weekend()
{
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
//| updated all orders                                               |
//+------------------------------------------------------------------+
void updateOrders()
{
    // reset user snapshot and pending orders; keep aktiveRobotOrder until checked by check_order()
    if(ArraySize(user)>0) rst_User_Order_State();

    // reset pending placeholders
    ResetPendingOrders();

    int iUser = 0;
    for(int i=(OrdersTotal()-1); i>=0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)==false)
        {
            Print("ERROR - Unable to select the order - ", GetLastError());
            break;
        }
        if(OrderSymbol()!=Symbol())
            continue;

        int orderType = OrderType();
        // opened market orders
        if(orderType==OP_BUY || orderType==OP_SELL)
        {
            if(OrderMagicNumber()==MAGIC_NO)
            {
                // active robot order snapshot
                aktiveRobotOrder.ticketNr   = OrderTicket();
                aktiveRobotOrder.openTime   = OrderOpenTime();
                aktiveRobotOrder.type       = orderType;
                aktiveRobotOrder.openPrice  = OrderOpenPrice();
                aktiveRobotOrder.TakeProfit = OrderTakeProfit();
                aktiveRobotOrder.StopLoss   = OrderStopLoss();
                aktiveRobotOrder.Profit     = OrderProfit();
            }
            else
            {
                // manual user orders
                ArrayResize(user, iUser+1);
                user[iUser].ticketNr   = OrderTicket();
                user[iUser].openTime   = OrderOpenTime();
                user[iUser].type       = orderType;
                user[iUser].openPrice  = OrderOpenPrice();
                user[iUser].TakeProfit = OrderTakeProfit();
                user[iUser].StopLoss   = OrderStopLoss();
                user[iUser].Profit     = OrderProfit();
                iUser++;
            }
        }
        // pending orders
        else
        {
            if(OrderMagicNumber()==MAGIC_NO){
                MyOrder temp;
                temp.ticketNr   = OrderTicket();
                temp.openTime   = OrderOpenTime();
                temp.type       = orderType;
                temp.openPrice  = OrderOpenPrice();
                temp.TakeProfit = OrderTakeProfit();
                temp.StopLoss   = OrderStopLoss();
                temp.Profit     = OrderProfit();

                if(orderType==OP_BUYLIMIT)       pending_buy_limit = temp;
                else if(orderType==OP_SELLLIMIT) pending_sell_limit = temp;
                else if(orderType==OP_BUYSTOP)   pending_buy_stop = temp;
                else if(orderType==OP_SELLSTOP)  pending_sell_stop = temp;
            }
            
        }
    }
    
}

//+------------------------------------------------------------------+
//| check defined order                                              |
//+------------------------------------------------------------------+
void check_order(MyOrder& o)
{
    if(OrderSelect(o.ticketNr,SELECT_BY_TICKET)==false)
    {
        Print("ERROR - Unable to select the order in check_order() - ",GetLastError());
    }
    else if (o.type == OP_BUY || o.type == OP_SELL)
    { // open order
        if(o.openTime==0)o.openTime=OrderOpenTime();
        datetime ctm=OrderCloseTime();
        // sobald die position geschlossen ist, einmal folgendes ausführen  
        if(ctm>0){
            o.closeTime=ctm;
            o.closePrice = OrderClosePrice();
            o.Profit = OrderProfit();
            if(o.type==OP_BUY){
                o.ProfitPoints=(o.closePrice-o.openPrice);
            }
            else { // OP_SELL
                o.ProfitPoints=(o.openPrice-o.closePrice);
            }
            // history gewinn und verlust aktualisieren
            reorderPosHistory();
            profitUpdate();
        }
    }
    
    else{ // pending order

    }
}

//+------------------------------------------------------------------+
//| check orders and positions                                       |
//+------------------------------------------------------------------+
void get_orders_on_init()
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
                    aktiveRobotOrder.ticketNr=OrderTicket();
                    aktiveRobotOrder.openTime=OrderOpenTime();
                    aktiveRobotOrder.type=orderType;
                    aktiveRobotOrder.openPrice=OrderOpenPrice();
                    aktiveRobotOrder.TakeProfit=OrderTakeProfit();
                    aktiveRobotOrder.StopLoss=OrderStopLoss();
                    aktiveRobotOrder.Profit=OrderProfit();
                    
                }
                else{
                    ArrayResize(user, iUser+1);
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
                if(OrderMagicNumber()==MAGIC_NO){
                    MyOrder temp;
                    temp.ticketNr=OrderTicket();
                    temp.openTime=OrderOpenTime();
                    temp.type=orderType;
                    temp.openPrice=OrderOpenPrice();
                    temp.TakeProfit=OrderTakeProfit();
                    temp.StopLoss=OrderStopLoss();
                    temp.Profit=OrderProfit();
                    if (orderType==OP_BUYLIMIT) pending_buy_limit=temp;
                    else if(orderType==OP_SELLLIMIT) pending_sell_limit=temp;
                    else if(orderType==OP_BUYSTOP) pending_buy_stop=temp;
                    else if(orderType==OP_SELLSTOP) pending_sell_stop=temp;
                }
                
            }
            
                
        }       
    }
}

//+------------------------------------------------------------------+
//| reorder robotHist array                                          |
//+------------------------------------------------------------------+
void reorderPosHistory()
{
    for(int i = ArraySize(robotHist)-1; i>0; i--){
        robotHist[i]=robotHist[i-1];
    }
    robotHist[0]=aktiveRobotOrder;
    rst_Order_State();
}

//+------------------------------------------------------------------+
//| reset order monitoring states                                    |
//+------------------------------------------------------------------+
void ResetOrder(MyOrder& o)
{
    o.ticketNr = -1;
    o.openTime = 0;
    o.closeTime = 0;
    o.type = 6;
    o.openPrice = 0;
    o.closePrice = 0;
    o.TakeProfit = 0;
    o.StopLoss = 0;
    o.Profit = 0;
    o.ProfitPoints = 0;
}

void rst_Order_State()
{
    ResetOrder(aktiveRobotOrder);
    ResetTradePlan(activeRobotPlan);
}

void rst_User_Order_State()
{
    for(int i=0; i<ArraySize(user); i++){
        ResetOrder(user[i]);
    }
}

void ResetPendingOrders()
{
    ResetOrder(pending_buy_limit);
    ResetOrder(pending_sell_limit);
    ResetOrder(pending_buy_stop);
    ResetOrder(pending_sell_stop);
}

bool HasRobotPendingOrder()
{
    return pending_buy_limit.ticketNr > -1
        || pending_sell_limit.ticketNr > -1
        || pending_buy_stop.ticketNr > -1
        || pending_sell_stop.ticketNr > -1;
}

string OrderCmdName(int cmd)
{
    if(cmd==OP_BUY)       return "OP_BUY";
    if(cmd==OP_SELL)      return "OP_SELL";
    if(cmd==OP_BUYLIMIT)  return "OP_BUYLIMIT";
    if(cmd==OP_SELLLIMIT) return "OP_SELLLIMIT";
    if(cmd==OP_BUYSTOP)   return "OP_BUYSTOP";
    if(cmd==OP_SELLSTOP)  return "OP_SELLSTOP";
    if(cmd==CLOSE_BUY)    return "CLOSE_BUY";
    if(cmd==CLOSE_SELL)   return "CLOSE_SELL";
    if(cmd==DELETE_PENDING) return "DELETE_PENDING";
    if(cmd==MODIFY_PENDING) return "MODIFY_PENDING";
    return "UNKNOWN_CMD";
}

void LogTradeError(string action, int errNr, int cmd, int ticket, double volume, double price, double sl, double tp)
{
    if(errNr==1){
        ResetLastError();
        return;
    }

    PrintFormat("%s failed. Error=%d (%s), cmd=%s, ticket=%d",
                action, errNr, ErrorDescription(errNr), OrderCmdName(cmd), ticket);
    PrintFormat("Symbol=%s, Magic=%d, Lots=%f, Price=%f, SL=%f, TP=%f",
                Symbol(), MAGIC_NO, volume, price, sl, tp);
    PrintFormat("Bid=%f, Ask=%f, Spread=%f, StopLevel=%f, Digits=%d",
                Bid, Ask, spread, minStopLevel, vdigits);
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
                    LogTradeError("OrderModify", GetLastError(), OP_BUY, OrderTicket(),
                                  OrderLots(), OrderOpenPrice(), SL, TP);
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
                    LogTradeError("OrderModify", GetLastError(), OP_SELL, OrderTicket(),
                                  OrderLots(), OrderOpenPrice(), SL, TP);
                }
            }
        }

        else if (cmd == CLOSE_BUY)
        {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White)){
                LogTradeError("OrderClose", GetLastError(), CLOSE_BUY, OrderTicket(),
                              OrderLots(), Bid, OrderStopLoss(), OrderTakeProfit());
            }
        }

        else if (cmd == CLOSE_SELL)
        {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White)){
                LogTradeError("OrderClose", GetLastError(), CLOSE_SELL, OrderTicket(),
                              OrderLots(), Ask, OrderStopLoss(), OrderTakeProfit());
            }
        }

        else if (cmd == DELETE_PENDING)
        {
            int type = OrderType();
            if(type==OP_BUYLIMIT || type==OP_SELLLIMIT || type==OP_BUYSTOP || type==OP_SELLSTOP)
            {
                if(!OrderDelete(OrderTicket())){
                    LogTradeError("OrderDelete", GetLastError(), DELETE_PENDING, OrderTicket(),
                                  OrderLots(), OrderOpenPrice(), OrderStopLoss(), OrderTakeProfit());
                }
            }
        }

         else if (cmd == MODIFY_PENDING)
        {
            int type = OrderType();
            if(type!=OP_BUYLIMIT && type!=OP_SELLLIMIT && type!=OP_BUYSTOP && type!=OP_SELLSTOP)
                return;

            double price = TargetOrder.openPrice;
            SL = TargetOrder.StopLoss;
            TP = TargetOrder.TakeProfit;

            if(price <= 0) price = OrderOpenPrice();
            if(SL <= 0)    SL = OrderStopLoss();
            if(TP <= 0)    TP = OrderTakeProfit();

            price = NormalizeDouble(price, vdigits);
            SL = NormalizeDouble(SL, vdigits);
            TP = NormalizeDouble(TP, vdigits);

            if(price != OrderOpenPrice() || SL != OrderStopLoss() || TP != OrderTakeProfit())
            {
                if(!OrderModify(OrderTicket(), price, SL, TP, OrderExpiration(), clrYellow)){
                    LogTradeError("OrderModify", GetLastError(), MODIFY_PENDING, OrderTicket(),
                                  OrderLots(), price, SL, TP);
                }
            }
        }
    }

}
