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

#define DIR_SELL -1
#define DIR_NONE 0
#define DIR_BUY  1


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
        void update_candel_brakout_dir(void);
        int fiboBreakoutDirection(posFibo& , posFibo& );
        void evaluate_zigzag(double& zz[], bool& trendBuy, bool& trendSell,
                             bool& buy, bool& sell, bool& corrInBuy, bool& corrInSell,
                             bool& fluctuation, double& fluctSupport, double& fluctResistance,
                             int& fluctPairIndex, double& nextSupport, double& nextResistance);
        void trendAnalysis(void);

        // private variable
        int update_indicator_bar;
        int MA_TREND_PERIOD;
        int MA_CUT_PERIOD;
        double stoRange;

    public:
        // public methode
        void init_Leo(int, int, int);
        void updateLeo(void);
        
        // public variable
        int timeframe;
        
        double zig_zag[10];
        int zig_zag_interval[9];
        double zig_zag_tilt[7];
        double zig_zag_sensitive[10];
        int zig_zag_sensitive_interval[9];
        double zig_zag_sensitive_tilt[7];


        bool zigTrendBuy;
        bool zigTrendSell;
        bool zigBuy;
        bool zigSell;
        bool zigCorrInBuy;
        bool zigCorrInSell;
        bool zigFluctuation;
        double zigFluctSupport;
        double zigFluctResistance;
        int zigFluctPairIndex;
        double nextZigResistance;
        double nextZigSupport;

        bool zigSenTrendBuy;
        bool zigSenTrendSell;
        bool zigSenBuy;
        bool zigSenSell;
        bool zigSenCorrInBuy;
        bool zigSenCorrInSell;
        bool zigSenFluctuation;
        double zigSenFluctSupport;
        double zigSenFluctResistance;
        int zigSenFluctPairIndex;
        double nextZigResistance_sensitive;
        double nextZigSupport_sensitive;

        fibonacci fibo_zig[3];
        fibonacci fibo_zig_sensitive[3];
        fibonacci fibo_candel[3];

        posFibo posFibo_zig[3];
        posFibo posFibo_zig_sen[3];
        posFibo posFibo_candel[3];

        int breakoutDirCandel;
        int breakoutFiboDirZig;
        int breakoutFiboDirZigSensitive;
        int breakoutFiboDirCandel;
        int breakoutDir;

        double ma_trend[15];
        double ma_cut[15];
        bool MAbuy;
        bool MAsell;

        double macd_sig[15];
        double macd_main[15];

        double stoch_sig[15];
        double stoch_main[15];

        bool StoBuy;                  // rewritabel to true if it was clear due to noisy sto 
        bool StoSell;                 // rewritabel to true if it was clear due to noisy sto
        


        double rsi[15];
        bool exhaustionBuy;
        bool exhaustionSell;
        
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
        zig_zag_interval[j-1]=shift;
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
        zig_zag_sensitive_interval[j-1]=shift;
    }

    for(j=0; j<ArraySize(zig_zag_tilt); j++)
        zig_zag_tilt[j]=(zig_zag_interval[j]==0 || (zig_zag[j]==0 && zig_zag[j+1]==0)) ? 0 : (zig_zag[j]-zig_zag[j+1])/zig_zag_interval[j];

    for(j=0; j<ArraySize(zig_zag_sensitive_tilt); j++)
        zig_zag_sensitive_tilt[j]=(zig_zag_sensitive_interval[j]==0 || (zig_zag_sensitive[j]==0 && zig_zag_sensitive[j+1]==0)) ? 0 : (zig_zag_sensitive[j]-zig_zag_sensitive[j+1])/zig_zag_sensitive_interval[j];

    // zig_zag Evaluation:
    // -------------------
    evaluate_zigzag(zig_zag, zigTrendBuy, zigTrendSell,
                    zigBuy, zigSell, zigCorrInBuy, zigCorrInSell,
                    zigFluctuation, zigFluctSupport, zigFluctResistance,
                    zigFluctPairIndex, nextZigSupport, nextZigResistance);

    evaluate_zigzag(zig_zag_sensitive, zigSenTrendBuy, zigSenTrendSell,
                    zigSenBuy, zigSenSell, zigSenCorrInBuy, zigSenCorrInSell,
                    zigSenFluctuation, zigSenFluctSupport, zigSenFluctResistance,
                    zigSenFluctPairIndex, nextZigSupport_sensitive, nextZigResistance_sensitive);

}

void LeoSensors::update_candel_brakout_dir(void){
    breakoutDirCandel = DIR_NONE;
    bool buyBreakout = (fibo_candel[0].fibo[12] > 0 && iHigh(Symbol(), timeframe, 0) > fibo_candel[0].fibo[12] + minMove);
        
    bool sellBreakout = (fibo_candel[0].fibo[6] > 0 && iLow(Symbol(), timeframe, 0) < fibo_candel[0].fibo[6] - minMove);
    
    if(buyBreakout && !sellBreakout)
        breakoutDirCandel = DIR_BUY;
    else if(sellBreakout && !buyBreakout)
        breakoutDirCandel = DIR_SELL;
    else if(buyBreakout && sellBreakout){
        double resistanceMove = iHigh(Symbol(), timeframe, 0) - fibo_candel[0].fibo[12];
        double supportMove = fibo_candel[0].fibo[6] - iLow(Symbol(), timeframe, 0);
        if(resistanceMove > supportMove + minMove && iClose(Symbol(), timeframe, 0) > fibo_candel[0].fibo[10])
            breakoutDirCandel = DIR_BUY;
        else if(supportMove > resistanceMove + minMove && iClose(Symbol(), timeframe, 0) < fibo_candel[0].fibo[8])
            breakoutDirCandel = DIR_SELL;
        else
            breakoutDirCandel = DIR_NONE;
    }
    else
        breakoutDirCandel = DIR_NONE;
}

int LeoSensors::fiboBreakoutDirection(posFibo& currentFibo, posFibo& previousFibo)
{
    bool buyBreakout = (currentFibo.fibo_resistance > 0
                        && previousFibo.fibo_resistance > 0
                        && currentFibo.fibo_resistance > previousFibo.fibo_resistance + minMove);
    bool sellBreakout = (currentFibo.fibo_support > 0
                         && previousFibo.fibo_support > 0
                         && currentFibo.fibo_support < previousFibo.fibo_support - minMove);

    if(buyBreakout && !sellBreakout)
        return DIR_BUY;
    if(sellBreakout && !buyBreakout)
        return DIR_SELL;

    if(buyBreakout && sellBreakout){
        double resistanceMove = currentFibo.fibo_resistance - previousFibo.fibo_resistance;
        double supportMove = previousFibo.fibo_support - currentFibo.fibo_support;
        if(resistanceMove > supportMove + minMove)
            return DIR_BUY;
        if(supportMove > resistanceMove + minMove)
            return DIR_SELL;
    }

    return DIR_NONE;
}

void LeoSensors::evaluate_zigzag(double& zz[], bool& trendBuy, bool& trendSell,
                                 bool& buy, bool& sell, bool& corrInBuy, bool& corrInSell,
                                 bool& fluctuation, double& fluctSupport, double& fluctResistance,
                                 int& fluctPairIndex, double& nextSupport, double& nextResistance)
{
    trendBuy=false;
    trendSell=false;
    buy=false;
    sell=false;
    corrInBuy=false;
    corrInSell=false;
    fluctuation=false;
    fluctSupport=0;
    fluctResistance=0;
    fluctPairIndex=-1;
    nextSupport=0;
    nextResistance=0;

    if(ArraySize(zz) < 3 || zz[1] <= 0 || zz[2] <= 0)
        return;

    if(ArraySize(zz) > 4 && zz[1] > 0 && zz[2] > 0 && zz[3] > 0 && zz[4] > 0){
        if((zz[2] > zz[4]) && (zz[1] > zz[3]))
            trendBuy=true;
        else if((zz[2] < zz[4]) && (zz[1] < zz[3]))
            trendSell=true;
    }

    if(zz[0] > 0){
        if(zz[0] > zz[1])
            buy=true;
        else if(zz[0] < zz[1])
            sell=true;
    }
    else{
        if(zz[1] > zz[2])
            corrInBuy=true;
        else if(zz[1] < zz[2])
            corrInSell=true;
    }

    double bestWidth=0;
    int startIdx = (zz[0] > 0 ? 0 : 1);
    for(int i=startIdx; i<ArraySize(zz)-1; i++){
        if(zz[i] <= 0 || zz[i+1] <= 0)
            continue;

        double zoneLow = MathMin(zz[i], zz[i+1]);
        double zoneHigh = MathMax(zz[i], zz[i+1]);
        double zoneWidth = zoneHigh-zoneLow;
        if(zoneWidth <= minMove)
            continue;

        if(currentPrice >= zoneLow && currentPrice <= zoneHigh){
            if(!fluctuation || zoneWidth < bestWidth){
                fluctuation=true;
                fluctSupport=zoneLow;
                fluctResistance=zoneHigh;
                fluctPairIndex=i;
                bestWidth=zoneWidth;
            }
        }
    }

    if(zz[0] <= 0 && ArraySize(zz) > 3){
        double upMove=0;
        double downMove=0;
        int upCount=0;
        int downCount=0;

        for(int i=1; i<ArraySize(zz)-1; i++){
            if(zz[i] <= 0 || zz[i+1] <= 0)
                break;

            double move = zz[i]-zz[i+1];
            if(move > minMove){
                upMove += move;
                upCount++;
            }
            else if(move < -minMove){
                downMove -= move;
                downCount++;
            }
        }

        if(zz[1] > zz[2] && downCount > 0){
            nextSupport = zz[1]-(downMove/downCount);
            if(currentPrice <= nextSupport+minMove)
                sell=true;
        }
        else if(zz[1] < zz[2] && upCount > 0){
            nextResistance = zz[1]+(upMove/upCount);
            if(currentPrice >= nextResistance-minMove)
                buy=true;
        }
    }
}

// Clasical trendAnalysis                             
void LeoSensors::trendAnalysis(void)
{
    
    // MaAnalysis:
    // -----------
    MAbuy=false;
    MAsell=false;

    // MaAnalysis buy:
    if(iOpen(Symbol(),timeframe,0)>iOpen(Symbol(),timeframe,1) &&
        ((ma_cut[0]>ma_trend[0] && currentPrice>ma_cut[0]) || 
        (currentPrice>ma_trend[0] && iOpen(Symbol(),timeframe,0)<ma_trend[0])))
        MAbuy=true;
    

    // MaAnalysis sell:
    if(iOpen(Symbol(),timeframe,0)<iOpen(Symbol(),timeframe,1) &&
        ((ma_cut[0]<ma_trend[0] && currentPrice<ma_cut[0]) || 
        (currentPrice<ma_trend[0] && iOpen(Symbol(),timeframe,0)>ma_trend[0])))
        MAsell=true;


    // Sto Evaluation:
    // ---------------
    StoBuy=false;
    StoSell=false;

    bool stochBuyExuhstion = false;
    bool stochSellExuhstion = false;

    // Stochastic buy:
    if((stoch_main[0]-stoRange>stoch_sig[0] && (stoch_sig[0]>stoch_sig[1] || (stoch_main[0]>stoch_main[1] && stoch_main[0]>stoch_sig[1]))) 
        || (stoch_main[0]>stoch_sig[0] && stoch_main[1]>stoch_sig[1] && stoch_sig[0]>stoch_sig[1])) StoBuy=true;
    
    // Stochastic sell:
    if((stoch_main[0]+stoRange<stoch_sig[0] && (stoch_sig[0]<stoch_sig[1] || (stoch_main[0]<stoch_main[1] && stoch_main[0]<stoch_sig[1]))) 
        || (stoch_main[0]<stoch_sig[0] && stoch_main[1]<stoch_sig[1] && stoch_sig[0]<stoch_sig[1])) StoSell=true;
    
    if (stoch_main[0] > 80 && stoch_sig[0] > 80) stochBuyExuhstion = true;  // Überkauft
    else if (stoch_main[0] < 20 && stoch_sig[0] < 20) stochSellExuhstion = true;  // Überverkauft


    // RSI (exhaustion) Evaluation:
    // ---------------
    exhaustionBuy=false;
    exhaustionSell=false;

    if(rsi[0] > 70 || stochBuyExuhstion)
        exhaustionBuy = true;
    else if(rsi[0] < 30 || stochSellExuhstion)
        exhaustionSell = true;
    
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
        // fibo_candel[0] = set_fibo(iHigh(Symbol(), timeframe, 1), iLow(Symbol(), timeframe, 1));
        posFibo t0_posFibo_candel_0 = posFibo_candel[0];
        posFibo_candel[0]=pos_in_fibo(currentPrice, fibo_candel[0]);
        
        // update_zigFibos
        // fibo_zig[0] = set_fibo(zig_zag[3], zig_zag[2]);
        posFibo t0_posFibo_zig_0 = posFibo_zig[0];
        posFibo_zig[0]=pos_in_fibo(currentPrice, fibo_zig[0]);
        // fibo_zig_sensitive[0] = set_fibo(zig_zag_sensitive[3], zig_zag_sensitive[2]);
        posFibo t0_posFibo_zig_sen_0 = posFibo_zig_sen[0];
        posFibo_zig_sen[0]=pos_in_fibo(currentPrice, fibo_zig_sensitive[0]);

        update_candel_brakout_dir();
        if (t0_posFibo_candel_0.fibo_resistance != posFibo_candel[0].fibo_resistance || t0_posFibo_candel_0.fibo_support != posFibo_candel[0].fibo_support)
            breakoutFiboDirCandel = fiboBreakoutDirection(posFibo_candel[0], posFibo_candel[1]);
        
        if (t0_posFibo_zig_0.fibo_resistance != posFibo_zig[0].fibo_resistance || t0_posFibo_zig_0.fibo_support != posFibo_zig[0].fibo_support)
            breakoutFiboDirZig = fiboBreakoutDirection(posFibo_zig[0], posFibo_zig[1]);
        
        if (t0_posFibo_zig_sen_0.fibo_resistance != posFibo_zig_sen[0].fibo_resistance || t0_posFibo_zig_sen_0.fibo_support != posFibo_zig_sen[0].fibo_support)
            breakoutFiboDirZigSensitive = fiboBreakoutDirection(posFibo_zig_sen[0], posFibo_zig_sen[1]);

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

        for (i=1; i<ArraySize(stoch_main); i++){
            stoRange+=MathAbs(stoch_main[i]-stoch_sig[i]);
        }
        stoRange/=(ArraySize(stoch_main)-1);
        stoRange*=0.24;
        
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
    trendAnalysis();
}

//+------------------------------------------------------------------+
//| Order Histories                                                  |
//+------------------------------------------------------------------+
struct MyOrder{
    int ticketNr;
    int type;
    double lots;
    double openPrice;
    double closePrice;
    double TakeProfit;
    double StopLoss;
    double ProfitPoints;
    double Profit;
    datetime openTime;
    datetime closeTime;

} user[], aktiveRobotOrder, pending_buy_limit, pending_sell_limit, pending_buy_stop, pending_sell_stop, pending_sell_stop_against_reverse_kurs, pending_buy_stop_against_reverse_kurs, robotHist[10];

//+------------------------------------------------------------------+
//| Signal Analysis Information                                      |
//+------------------------------------------------------------------+
struct TFRelation {
    // big TFs
    int bigTrendDir; // DIR_NONE, DIR_BUY, DIR_SELL
    double bigLimitTop;
    double bigLimitDown;
    bool bigLimitTouched;

    double reversalRiskScore;
    double continuationScore;
    double triggerQualityScore;

    
    MyOrder buy_limit;
    MyOrder buy_stop;
    MyOrder break_out_sell_stop; // stop für breakout in opposite direction of big TF trend
    
    MyOrder sell_limit;
    MyOrder sell_stop;
    MyOrder break_out_buy_stop; // stop für breakout in opposite direction of big TF trend
};


// --  Market Informationen
datetime currentTime;
double currentPrice;
double pipValue= 0;
double minStopLevel;
double spread=0;
double minMove=0;
double lastAsk=0;
double lastBid=0;
double lots;
double minLot;
int vdigits  = 0;

double supports[15];
double resistances[15];
double all_fibos[855];



// -- Trade-Steuerungsparameter 
double SecureVol;
input double inpSecureVol = 190;
datetime SecureVolUpdateTime;



// -- Risikomanagement
input double RiskRatio    =   0.02;
input bool ROBOTTRADE = true;


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
TFRelation rel_H1_H4, rel_M30_H4, rel_M15_H4, rel_M5_H4;
TFRelation rel_M30_H1, rel_M15_H1, rel_M5_H1;
TFRelation rel_M15_M30, rel_M5_M30, rel_M5_M15;

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
    minMove = MathMax(Point, minStopLevel);
    if(DayDiff(SecureVolUpdateTime,currentTime)>=2 || SecureVol==0) recalcSecureVol();
    
    
    // check, ob die letzte(n) Position(en) immmer noch offen ist(/sind) und user keine neue Position geöffnet hat 
    updateOrders();
    if (aktiveRobotOrder.ticketNr>-1) check_order(aktiveRobotOrder);
        
    updateSensors();
    lastAsk=Ask;
    lastBid=Bid;

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
        if (pending_buy_limit.ticketNr > -1) ModifyTP(DELETE_PENDING, pending_buy_limit);
        if (pending_sell_limit.ticketNr > -1) ModifyTP(DELETE_PENDING, pending_sell_limit);
        if (pending_buy_stop.ticketNr > -1) ModifyTP(DELETE_PENDING, pending_buy_stop);
        if (pending_sell_stop.ticketNr > -1) ModifyTP(DELETE_PENDING, pending_sell_stop);
        if (pending_sell_stop_against_reverse_kurs.ticketNr > -1) ModifyTP(DELETE_PENDING, pending_sell_stop_against_reverse_kurs);
        if (pending_buy_stop_against_reverse_kurs.ticketNr > -1) ModifyTP(DELETE_PENDING, pending_buy_stop_against_reverse_kurs);

        checkClose();
    }
    else 
        getCMD();
    
}

//+------------------------------------------------------------------+
//| update profit                                                    |
//+------------------------------------------------------------------+
void profitUpdate()
{
}

//+------------------------------------------------------------------+
//| update defiened Leo-Sensor & analyse sensors values              |
//+------------------------------------------------------------------+
double ClampDouble(double value, double minValue, double maxValue)
{
    if(value < minValue)
        return minValue;
    if(value > maxValue)
        return maxValue;
    return value;
}

double MaxPositive(double a, double b, double c, double d)
{
    double result=0;
    if(a > result) result=a;
    if(b > result) result=b;
    if(c > result) result=c;
    if(d > result) result=d;
    return result;
}

double MinPositive(double a, double b, double c, double d)
{
    double result=0;
    if(a > 0) result=a;
    if(b > 0 && (result == 0 || b < result)) result=b;
    if(c > 0 && (result == 0 || c < result)) result=c;
    if(d > 0 && (result == 0 || d < result)) result=d;
    return result;
}

double NextFiboAbove(double price)
{
    for(int i=0; i<ArraySize(all_fibos); i++){
        if(all_fibos[i] > price+minMove)
            return all_fibos[i];
    }
    return 0;
}

double NextFiboBelow(double price)
{
    for(int i=ArraySize(all_fibos)-1; i>=0; i--){
        if(all_fibos[i] > 0 && all_fibos[i] < price-minMove)
            return all_fibos[i];
    }
    return 0;
}

double NextFiboAboveIn(fibonacci& fibos, double price)
{
    for(int i=0; i<ArraySize(fibos.fibo); i++){
        if(fibos.fibo[i] > price+minMove)
            return fibos.fibo[i];
    }
    return 0;
}

double NextFiboBelowIn(fibonacci& fibos, double price)
{
    for(int i=ArraySize(fibos.fibo)-1; i>=0; i--){
        if(fibos.fibo[i] > 0 && fibos.fibo[i] < price-minMove)
            return fibos.fibo[i];
    }
    return 0;
}

double AvgAbsTilt3(double a, double b, double c)
{
    int count=0;
    double sum=0;
    if(a != 0){ sum += MathAbs(a); count++; }
    if(b != 0){ sum += MathAbs(b); count++; }
    if(c != 0){ sum += MathAbs(c); count++; }
    if(count == 0)
        return 0;
    return sum/count;
}

double TfRatio(int bigTf, int smallTf)
{
    if(smallTf <= 0)
        return 1;
    double ratio = (double)bigTf/(double)smallTf;
    if(ratio < 1)
        ratio = 1;
    return ratio;
}

double NearestAbove(double a, double b, double c, double reference)
{
    double result=0;
    if(a > reference && (result == 0 || a < result)) result=a;
    if(b > reference && (result == 0 || b < result)) result=b;
    if(c > reference && (result == 0 || c < result)) result=c;
    return result;
}

double NearestBelow(double a, double b, double c, double reference)
{
    double result=0;
    if(a > 0 && a < reference && a > result) result=a;
    if(b > 0 && b < reference && b > result) result=b;
    if(c > 0 && c < reference && c > result) result=c;
    return result;
}

int TrendDir(LeoSensors& sig)
{
    int buyScore=0;
    int sellScore=0;

    if(sig.zigTrendBuy) buyScore += 3;
    if(sig.zigTrendSell) sellScore += 3;

    if(sig.zigSenTrendBuy) buyScore += 2;
    if(sig.zigSenTrendSell) sellScore += 2;

    if(sig.MAbuy) buyScore += 2;
    if(sig.MAsell) sellScore += 2;

    if(sig.breakoutFiboDirZig == DIR_BUY) buyScore += 2;
    if(sig.breakoutFiboDirZig == DIR_SELL) sellScore += 2;

    if(sig.breakoutFiboDirZigSensitive == DIR_BUY) buyScore += 1;
    if(sig.breakoutFiboDirZigSensitive == DIR_SELL) sellScore += 1;

    if(buyScore >= sellScore+2)
        return DIR_BUY;
    if(sellScore >= buyScore+2)
        return DIR_SELL;

    return DIR_NONE;
}

void CalcSmallScores(LeoSensors& sig, double& buyScore, double& sellScore)
{
    buyScore=0;
    sellScore=0;

    if(sig.zigBuy) buyScore += 18;
    if(sig.zigSell) sellScore += 18;
    if(sig.zigSenBuy) buyScore += 22;
    if(sig.zigSenSell) sellScore += 22;
    if(sig.MAbuy) buyScore += 12;
    if(sig.MAsell) sellScore += 12;
    if(sig.StoBuy) buyScore += 10;
    if(sig.StoSell) sellScore += 10;
    if(sig.breakoutFiboDirZig == DIR_BUY) buyScore += 14;
    if(sig.breakoutFiboDirZig == DIR_SELL) sellScore += 14;
    if(sig.breakoutFiboDirZigSensitive == DIR_BUY) buyScore += 18;
    if(sig.breakoutFiboDirZigSensitive == DIR_SELL) sellScore += 18;
    if(sig.breakoutDirCandel == DIR_BUY) buyScore += 10;
    if(sig.breakoutDirCandel == DIR_SELL) sellScore += 10;
    if(sig.exhaustionSell) buyScore += 8;
    if(sig.exhaustionBuy) sellScore += 8;

    if(sig.stoch_main[0] > sig.stoch_main[1] && sig.stoch_sig[0] > sig.stoch_sig[1]) buyScore += 8;
    if(sig.stoch_main[0] < sig.stoch_main[1] && sig.stoch_sig[0] < sig.stoch_sig[1]) sellScore += 8;
    if(sig.rsi[0] > sig.rsi[1]) buyScore += 6;
    if(sig.rsi[0] < sig.rsi[1]) sellScore += 6;

    buyScore = ClampDouble(buyScore, 0, 100);
    sellScore = ClampDouble(sellScore, 0, 100);
}



void BuildTFRelation(LeoSensors& smallSig, LeoSensors& bigSig, TFRelation& rel)
{
    bool wasTouched = rel.bigLimitTouched;

    // Reset relation state and keep previous touch state for zone memory.
    rel.bigTrendDir = TrendDir(bigSig);

    rel.bigLimitTop = 0;
    rel.bigLimitDown = 0;
    rel.bigLimitTouched = false;

    rel.reversalRiskScore = 0;
    rel.continuationScore = 0;
    rel.triggerQualityScore = 0;

    ResetOrder(rel.buy_limit);
    ResetOrder(rel.sell_limit);
    ResetOrder(rel.buy_stop);
    ResetOrder(rel.sell_stop);
    ResetOrder(rel.break_out_sell_stop);
    ResetOrder(rel.break_out_buy_stop);

    // Local analysis values used only while building this relation.
    double smallBuyScore = 0;
    double smallSellScore = 0;
    double smallGrowthAgainstBigScore = 0;
    double tiltBigInSmall = 0;
    double corrTiltBigInSmall = 0;
    double currentSmallTilt = MathAbs(smallSig.zig_zag_tilt[0]);
    if(currentSmallTilt == 0)
        currentSmallTilt = MathAbs(smallSig.zig_zag_sensitive_tilt[0]);
    double correctionTiltScore = 0;
    double fastStop = 0;
    double stableStop = 0;

    CalcSmallScores(smallSig, smallBuyScore, smallSellScore);

    // Compare current small-TF correction speed with big-TF correction speed.
    double ratio = TfRatio(bigSig.timeframe, smallSig.timeframe);
    tiltBigInSmall = AvgAbsTilt3(bigSig.zig_zag_tilt[1], bigSig.zig_zag_tilt[3], bigSig.zig_zag_tilt[5])/ratio;
    corrTiltBigInSmall = AvgAbsTilt3(bigSig.zig_zag_tilt[2], bigSig.zig_zag_tilt[4], bigSig.zig_zag_tilt[6])/ratio;

    if(corrTiltBigInSmall > 0){
        double tiltDiff = MathAbs(currentSmallTilt-corrTiltBigInSmall);
        correctionTiltScore = ClampDouble(100-(tiltDiff/corrTiltBigInSmall*100), 0, 100);
    }

    if(rel.bigTrendDir == DIR_BUY){
        // Build big-TF buy pullback zone from available support levels.
        rel.bigLimitTop = MaxPositive(MaxPositive(bigSig.posFibo_zig[0].fibo_support,
                                                  bigSig.posFibo_zig_sen[0].fibo_support,
                                                  bigSig.posFibo_candel[0].fibo_support,
                                                  bigSig.nextZigSupport),
                                      bigSig.nextZigSupport_sensitive,
                                      0,
                                      0);
        rel.bigLimitDown = NextFiboBelow(rel.bigLimitTop);
        if(rel.bigLimitDown <= 0 && rel.bigLimitTop > 0)
            rel.bigLimitDown = rel.bigLimitTop-bigSig.atr[0];

        // Initialize buy-limit candidate at the lower edge of the big pullback zone.
        rel.buy_limit.type = OP_BUYLIMIT;
        rel.buy_limit.openPrice = rel.bigLimitDown;

        // Initialize buy-stop candidate from fast and stable small-TF resistance triggers.
        fastStop = NearestAbove(smallSig.nextZigResistance_sensitive,
                                smallSig.fibo_candel[0].fibo[13],
                                smallSig.posFibo_zig_sen[0].fibo_resistance,
                                currentPrice);
        stableStop = NearestAbove(smallSig.nextZigResistance,
                                  smallSig.fibo_zig[0].fibo[13],
                                  smallSig.posFibo_zig[0].fibo_resistance,
                                  currentPrice);
        bool buyStopUsesFastSource = (fastStop > 0);
        bool buyStopUsesCandelSource = (buyStopUsesFastSource && MathAbs(fastStop-smallSig.fibo_candel[0].fibo[13]) <= minMove);
        double buyTarget = buyStopUsesFastSource ? smallSig.nextZigResistance_sensitive : smallSig.nextZigResistance;
        double buyLimitSL = buyStopUsesCandelSource
                            ? NextFiboBelowIn(smallSig.fibo_candel[0], rel.buy_limit.openPrice)
                            : (buyStopUsesFastSource
                               ? NextFiboBelowIn(smallSig.fibo_zig_sensitive[0], rel.buy_limit.openPrice)
                               : NextFiboBelowIn(smallSig.fibo_zig[0], rel.buy_limit.openPrice));
        if(buyLimitSL <= 0 && buyStopUsesFastSource)
            buyLimitSL = NextFiboBelowIn(smallSig.fibo_candel[0], rel.buy_limit.openPrice);
        rel.buy_stop.type = OP_BUYSTOP;
        rel.buy_stop.openPrice = fastStop;
        if(rel.buy_stop.openPrice <= 0)
            rel.buy_stop.openPrice = stableStop;
        if(buyTarget <= 0)
            buyTarget = buyStopUsesFastSource
                        ? NextFiboAboveIn(smallSig.fibo_zig_sensitive[0], rel.buy_stop.openPrice)
                        : NextFiboAboveIn(smallSig.fibo_zig[0], rel.buy_stop.openPrice);

        // Score trigger quality by agreement between fast and stable stop triggers.
        if(fastStop > 0 && stableStop <= 0)
            rel.triggerQualityScore = 70;
        else if(fastStop <= 0 && stableStop > 0)
            rel.triggerQualityScore = 60;
        else if(stableStop > 0){
            double triggerDistance = MathAbs(fastStop-stableStop);
            double triggerTolerance = MathMax(minMove*2, smallSig.atr[0]*0.5);
            if(triggerDistance <= triggerTolerance){
                rel.triggerQualityScore = 100;
                rel.continuationScore += 15;
            }
            else{
                rel.triggerQualityScore = ClampDouble(100-(triggerDistance/MathMax(triggerTolerance, minMove)*25), 0, 100);
                rel.reversalRiskScore += 8;
            }
        }

        // Track whether price is inside or has recently touched the big buy zone.
        bool validBigLimitZone = (rel.bigLimitDown > 0 && rel.bigLimitTop > 0);
        bool priceInBigLimitZone = (validBigLimitZone
                                    && currentPrice >= rel.bigLimitDown
                                    && currentPrice <= rel.bigLimitTop);
        rel.bigLimitTouched = validBigLimitZone
                              && (priceInBigLimitZone || (wasTouched && currentPrice >= rel.bigLimitDown-minMove));

        
        // Measure small-TF pressure against the big buy direction.
        smallGrowthAgainstBigScore = smallSellScore;
        if(smallSig.breakoutDirCandel == DIR_SELL || smallSig.exhaustionSell)
            smallGrowthAgainstBigScore += 10;

        // If small-TF sell pressure is stronger than buy pressure, increase reversal risk.
        if(smallGrowthAgainstBigScore > smallBuyScore+25)
            rel.reversalRiskScore += 25;
        // A big-TF sell breakout contradicts the buy plan and increases reversal risk.
        if(bigSig.breakoutFiboDirZig == DIR_SELL || bigSig.breakoutFiboDirZigSensitive == DIR_SELL)
            rel.reversalRiskScore += 30;
        // If price falls below the big buy zone, the pullback may be breaking down.
        if(currentPrice < rel.bigLimitDown-minMove)
            rel.reversalRiskScore += 35;
        // Fast small-TF movement against the big trend increases reversal risk.
        if(tiltBigInSmall > 0 && currentSmallTilt > tiltBigInSmall*1.35 && smallSellScore > smallBuyScore)
            rel.reversalRiskScore += 20;

        // Continuation score favors small-TF buy pressure and similar correction speed.
        rel.continuationScore += smallBuyScore + correctionTiltScore*0.25 - rel.reversalRiskScore;
        if(smallSig.exhaustionSell) rel.continuationScore += 12;
        if(smallSig.StoBuy) rel.continuationScore += 8;

        // Complete buy-stop candidate with SL below the zone/support and TP above entry.
        if(rel.buy_stop.openPrice > 0){
            rel.buy_stop.StopLoss = buyLimitSL;
            if(rel.buy_stop.StopLoss <= 0)
                rel.buy_stop.StopLoss = rel.bigLimitDown-smallSig.atr[0];
            rel.buy_stop.TakeProfit = buyTarget;
            if(rel.buy_stop.TakeProfit <= 0)
                rel.buy_stop.TakeProfit = bigSig.posFibo_zig[0].fibo_resistance;
        }
        // Complete buy-limit candidate with SL from the trigger fibo source and TP from the next zig target.
        if(rel.buy_limit.openPrice > 0){
            rel.buy_limit.StopLoss = buyLimitSL;
            if(rel.buy_limit.StopLoss <= 0)
                rel.buy_limit.StopLoss = rel.buy_limit.openPrice-smallSig.atr[0];
            rel.buy_limit.TakeProfit = buyTarget;
            if(rel.buy_limit.TakeProfit <= 0)
                rel.buy_limit.TakeProfit = bigSig.posFibo_zig[0].fibo_resistance;
        }
        // Initialize opposite breakout sell-stop well below the buy zone.
        if(rel.bigLimitDown > 0){
            rel.break_out_sell_stop.type = OP_SELLSTOP;
            rel.break_out_sell_stop.openPrice = NextFiboBelow(MathMin(rel.bigLimitDown, rel.buy_limit.StopLoss));
            if(rel.break_out_sell_stop.openPrice <= 0)
                rel.break_out_sell_stop.openPrice = rel.bigLimitDown-MathMax(bigSig.atr[0], smallSig.atr[0]);
            rel.break_out_sell_stop.StopLoss = NextFiboAboveIn(bigSig.fibo_zig[0], rel.break_out_sell_stop.openPrice);
            if(rel.break_out_sell_stop.StopLoss <= 0)
                rel.break_out_sell_stop.StopLoss = rel.bigLimitTop;
            rel.break_out_sell_stop.TakeProfit = bigSig.nextZigSupport-(bigSig.nextZigResistance-bigSig.nextZigSupport);
            if(rel.break_out_sell_stop.TakeProfit <= 0 || rel.break_out_sell_stop.TakeProfit >= rel.break_out_sell_stop.openPrice)
                rel.break_out_sell_stop.TakeProfit = rel.break_out_sell_stop.openPrice-MathMax(bigSig.atr[0], smallSig.atr[0]);
        }
    }
    else if(rel.bigTrendDir == DIR_SELL){
        // Build big-TF sell pullback zone from available resistance levels.
        rel.bigLimitDown = MinPositive(MinPositive(bigSig.posFibo_zig[0].fibo_resistance,
                                                   bigSig.posFibo_zig_sen[0].fibo_resistance,
                                                   bigSig.posFibo_candel[0].fibo_resistance,
                                                   bigSig.nextZigResistance),
                                       bigSig.nextZigResistance_sensitive,
                                       0,
                                       0);
        if(rel.bigLimitDown > 0)
            rel.bigLimitTop = NextFiboAbove(rel.bigLimitDown);
        if(rel.bigLimitTop <= 0 && rel.bigLimitDown > 0)
            rel.bigLimitTop = rel.bigLimitDown+bigSig.atr[0];

        // Initialize sell-limit candidate at the upper edge of the big pullback zone.
        rel.sell_limit.type = OP_SELLLIMIT;
        rel.sell_limit.openPrice = rel.bigLimitTop;

        // Initialize sell-stop candidate from fast and stable small-TF support triggers.
        fastStop = NearestBelow(smallSig.nextZigSupport_sensitive,
                                smallSig.fibo_candel[0].fibo[5],
                                smallSig.posFibo_zig_sen[0].fibo_support,
                                currentPrice);
        stableStop = NearestBelow(smallSig.nextZigSupport,
                                  smallSig.fibo_zig[0].fibo[5],
                                  smallSig.posFibo_zig[0].fibo_support,
                                  currentPrice);
        bool sellStopUsesFastSource = (fastStop > 0);
        bool sellStopUsesCandelSource = (sellStopUsesFastSource && MathAbs(fastStop-smallSig.fibo_candel[0].fibo[5]) <= minMove);
        double sellTarget = sellStopUsesFastSource ? smallSig.nextZigSupport_sensitive : smallSig.nextZigSupport;
        double sellLimitSL = sellStopUsesCandelSource
                             ? NextFiboAboveIn(smallSig.fibo_candel[0], rel.sell_limit.openPrice)
                             : (sellStopUsesFastSource
                                ? NextFiboAboveIn(smallSig.fibo_zig_sensitive[0], rel.sell_limit.openPrice)
                                : NextFiboAboveIn(smallSig.fibo_zig[0], rel.sell_limit.openPrice));
        if(sellLimitSL <= 0 && sellStopUsesFastSource)
            sellLimitSL = NextFiboAboveIn(smallSig.fibo_candel[0], rel.sell_limit.openPrice);
        rel.sell_stop.type = OP_SELLSTOP;
        rel.sell_stop.openPrice = fastStop;
        if(rel.sell_stop.openPrice <= 0)
            rel.sell_stop.openPrice = stableStop;
        if(sellTarget <= 0)
            sellTarget = sellStopUsesFastSource
                         ? NextFiboBelowIn(smallSig.fibo_zig_sensitive[0], rel.sell_stop.openPrice)
                         : NextFiboBelowIn(smallSig.fibo_zig[0], rel.sell_stop.openPrice);

        // Score trigger quality by agreement between fast and stable stop triggers.
        if(fastStop > 0 && stableStop <= 0)
            rel.triggerQualityScore = 70;
        else if(fastStop <= 0 && stableStop > 0)
            rel.triggerQualityScore = 60;
        else if(stableStop > 0){
            double triggerDistance = MathAbs(fastStop-stableStop);
            double triggerTolerance = MathMax(minMove*2, smallSig.atr[0]*0.5);
            if(triggerDistance <= triggerTolerance){
                rel.triggerQualityScore = 100;
                rel.continuationScore += 15;
            }
            else{
                rel.triggerQualityScore = ClampDouble(100-(triggerDistance/MathMax(triggerTolerance, minMove)*25), 0, 100);
                rel.reversalRiskScore += 8;
            }
        }

        // Track whether price is inside or has recently touched the big sell zone.
        bool validBigLimitZone = (rel.bigLimitDown > 0 && rel.bigLimitTop > 0);
        bool priceInBigLimitZone = (validBigLimitZone
                                    && currentPrice >= rel.bigLimitDown
                                    && currentPrice <= rel.bigLimitTop);
        rel.bigLimitTouched = validBigLimitZone
                              && (priceInBigLimitZone || (wasTouched && currentPrice <= rel.bigLimitTop+minMove));

        // Measure small-TF pressure against the big sell direction.
        smallGrowthAgainstBigScore = smallBuyScore;
        if(smallSig.breakoutDirCandel == DIR_BUY || smallSig.exhaustionBuy)
            smallGrowthAgainstBigScore += 10;

        // If small-TF buy pressure is stronger than sell pressure, increase reversal risk.
        if(smallGrowthAgainstBigScore > smallSellScore+25)
            rel.reversalRiskScore += 25;
        // A big-TF buy breakout contradicts the sell plan and increases reversal risk.
        if(bigSig.breakoutFiboDirZig == DIR_BUY || bigSig.breakoutFiboDirZigSensitive == DIR_BUY)
            rel.reversalRiskScore += 30;
        // If price rises above the big sell zone, the pullback may be breaking down.
        if(currentPrice > rel.bigLimitTop+minMove)
            rel.reversalRiskScore += 35;
        // Fast small-TF movement against the big trend increases reversal risk.
        if(tiltBigInSmall > 0 && currentSmallTilt > tiltBigInSmall*1.35 && smallBuyScore > smallSellScore)
            rel.reversalRiskScore += 20;

        // Continuation score favors small-TF sell pressure and similar correction speed.
        rel.continuationScore += smallSellScore + correctionTiltScore*0.25 - rel.reversalRiskScore;
        if(smallSig.exhaustionBuy) rel.continuationScore += 12;
        if(smallSig.StoSell) rel.continuationScore += 8;

        // Complete sell-stop candidate with SL above the zone/resistance and TP below entry.
        if(rel.sell_stop.openPrice > 0){
            rel.sell_stop.StopLoss = sellLimitSL;
            if(rel.sell_stop.StopLoss <= 0)
                rel.sell_stop.StopLoss = rel.bigLimitTop+smallSig.atr[0];
            rel.sell_stop.TakeProfit = sellTarget;
            if(rel.sell_stop.TakeProfit <= 0)
                rel.sell_stop.TakeProfit = bigSig.posFibo_zig[0].fibo_support;
        }
        // Complete sell-limit candidate with SL from the trigger fibo source and TP from the next zig target.
        if(rel.sell_limit.openPrice > 0){
            rel.sell_limit.StopLoss = sellLimitSL;
            if(rel.sell_limit.StopLoss <= 0)
                rel.sell_limit.StopLoss = rel.sell_limit.openPrice+smallSig.atr[0];
            rel.sell_limit.TakeProfit = sellTarget;
            if(rel.sell_limit.TakeProfit <= 0)
                rel.sell_limit.TakeProfit = bigSig.posFibo_zig[0].fibo_support;
        }
        // Initialize opposite breakout buy-stop well above the sell zone.
        if(rel.bigLimitTop > 0){
            rel.break_out_buy_stop.type = OP_BUYSTOP;
            rel.break_out_buy_stop.openPrice = NextFiboAbove(MathMax(rel.bigLimitTop, rel.sell_limit.StopLoss));
            if(rel.break_out_buy_stop.openPrice <= 0)
                rel.break_out_buy_stop.openPrice = rel.bigLimitTop+MathMax(bigSig.atr[0], smallSig.atr[0]);
            rel.break_out_buy_stop.StopLoss = NextFiboBelowIn(bigSig.fibo_zig[0], rel.break_out_buy_stop.openPrice);
            if(rel.break_out_buy_stop.StopLoss <= 0)
                rel.break_out_buy_stop.StopLoss = rel.bigLimitDown;
            rel.break_out_buy_stop.TakeProfit = bigSig.nextZigResistance+(bigSig.nextZigResistance-bigSig.nextZigSupport);
            if(rel.break_out_buy_stop.TakeProfit <= 0 || rel.break_out_buy_stop.TakeProfit <= rel.break_out_buy_stop.openPrice)
                rel.break_out_buy_stop.TakeProfit = rel.break_out_buy_stop.openPrice+MathMax(bigSig.atr[0], smallSig.atr[0]);
        }
    }

    // Clamp scores consumed later by candidate selection.
    rel.reversalRiskScore = ClampDouble(rel.reversalRiskScore, 0, 100);
    rel.continuationScore = ClampDouble(rel.continuationScore, 0, 100);
}

void updateSensors()
{
    LS_H4.updateLeo();
    LS_H1.updateLeo();
    LS_M30.updateLeo();
    LS_M15.updateLeo();
    LS_M5.updateLeo();

    // update supports[] and resistances[] arrays
        supports[0] = LS_H4.posFibo_candel[0].fibo_support;
        supports[1] = LS_H4.posFibo_zig[0].fibo_support;
        supports[2] = LS_H4.posFibo_zig_sen[0].fibo_support;
        supports[3] = LS_H1.posFibo_candel[0].fibo_support;
        supports[4] = LS_H1.posFibo_zig[0].fibo_support;
        supports[5] = LS_H1.posFibo_zig_sen[0].fibo_support;
        supports[6] = LS_M30.posFibo_candel[0].fibo_support;
        supports[7] = LS_M30.posFibo_zig[0].fibo_support;
        supports[8] = LS_M30.posFibo_zig_sen[0].fibo_support;
        supports[9] = LS_M15.posFibo_candel[0].fibo_support;
        supports[10] = LS_M15.posFibo_zig[0].fibo_support;
        supports[11] = LS_M15.posFibo_zig_sen[0].fibo_support;
        supports[12] = LS_M5.posFibo_candel[0].fibo_support;
        supports[13] = LS_M5.posFibo_zig[0].fibo_support;
        supports[14] = LS_M5.posFibo_zig_sen[0].fibo_support;

        resistances[0] = LS_M5.posFibo_candel[0].fibo_resistance;
        resistances[1] = LS_M5.posFibo_zig[0].fibo_resistance;
        resistances[2] = LS_M5.posFibo_zig_sen[0].fibo_resistance;
        resistances[3] = LS_M15.posFibo_candel[0].fibo_resistance;
        resistances[4] = LS_M15.posFibo_zig[0].fibo_resistance;
        resistances[5] = LS_M15.posFibo_zig_sen[0].fibo_resistance;
        resistances[6] = LS_M30.posFibo_candel[0].fibo_resistance;
        resistances[7] = LS_M30.posFibo_zig[0].fibo_resistance;
        resistances[8] = LS_M30.posFibo_zig_sen[0].fibo_resistance;
        resistances[9] = LS_H1.posFibo_candel[0].fibo_resistance;
        resistances[10] = LS_H1.posFibo_zig[0].fibo_resistance;
        resistances[11] = LS_H1.posFibo_zig_sen[0].fibo_resistance;
        resistances[12] = LS_H4.posFibo_candel[0].fibo_resistance;
        resistances[13] = LS_H4.posFibo_zig[0].fibo_resistance;
        resistances[14] = LS_H4.posFibo_zig_sen[0].fibo_resistance;

    // suche nach aktive fibo_line und 

    // sort supports desending and resistances ascending
    ArraySort(supports, WHOLE_ARRAY, 0, MODE_DESCEND);
    ArraySort(resistances, WHOLE_ARRAY, 0, MODE_ASCEND);

    // list all fibos from all sensors into all_fibos[] array and sort it
    int fiboCount = 0;
    for (int j = 0; j < 3; j++){
        for(int i = 0; i < 19; i++){
            all_fibos[fiboCount++] = LS_H4.fibo_zig[j].fibo[i];
            all_fibos[fiboCount++] = LS_H4.fibo_zig_sensitive[j].fibo[i];
            all_fibos[fiboCount++] = LS_H4.fibo_candel[j].fibo[i];
            all_fibos[fiboCount++] = LS_H1.fibo_candel[j].fibo[i];
            all_fibos[fiboCount++] = LS_H1.fibo_zig[j].fibo[i];
            all_fibos[fiboCount++] = LS_H1.fibo_zig_sensitive[j].fibo[i];
            all_fibos[fiboCount++] = LS_M30.fibo_candel[j].fibo[i];
            all_fibos[fiboCount++] = LS_M30.fibo_zig[j].fibo[i];
            all_fibos[fiboCount++] = LS_M30.fibo_zig_sensitive[j].fibo[i];
            all_fibos[fiboCount++] = LS_M15.fibo_candel[j].fibo[i];
            all_fibos[fiboCount++] = LS_M15.fibo_zig[j].fibo[i];
            all_fibos[fiboCount++] = LS_M15.fibo_zig_sensitive[j].fibo[i];
            all_fibos[fiboCount++] = LS_M5.fibo_candel[j].fibo[i];
            all_fibos[fiboCount++] = LS_M5.fibo_zig[j].fibo[i];
            all_fibos[fiboCount++] = LS_M5.fibo_zig_sensitive[j].fibo[i];
        }
    }
    
    ArraySort(all_fibos, WHOLE_ARRAY, 0, MODE_ASCEND);

    BuildTFRelation(LS_H1, LS_H4, rel_H1_H4);
    BuildTFRelation(LS_M30, LS_H4, rel_M30_H4);
    BuildTFRelation(LS_M15, LS_H4, rel_M15_H4);
    BuildTFRelation(LS_M5, LS_H4, rel_M5_H4);
    BuildTFRelation(LS_M30, LS_H1, rel_M30_H1);
    BuildTFRelation(LS_M15, LS_H1, rel_M15_H1);
    BuildTFRelation(LS_M5, LS_H1, rel_M5_H1);
    BuildTFRelation(LS_M15, LS_M30, rel_M15_M30);
    BuildTFRelation(LS_M5, LS_M30, rel_M5_M30);
    BuildTFRelation(LS_M5, LS_M15, rel_M5_M15);


    // BuildTradePlan();
    

    Draw();
}

//+------------------------------------------------------------------+
//| care to close or adjust TP/SL                                    |
//+------------------------------------------------------------------+
void AccumulateDirectionalScores(TFRelation& rel, double& buyScore, double& sellScore)
{
    if(rel.buy_stop.openPrice > 0 || rel.buy_limit.openPrice > 0)
        buyScore = MathMax(buyScore, rel.continuationScore);
    if(rel.sell_stop.openPrice > 0 || rel.sell_limit.openPrice > 0)
        sellScore = MathMax(sellScore, rel.continuationScore);
}

void BestDirectionalScores(double& buyScore, double& sellScore)
{
    buyScore = 0;
    sellScore = 0;

    AccumulateDirectionalScores(rel_H1_H4, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M30_H4, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M15_H4, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M5_H4, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M30_H1, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M15_H1, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M5_H1, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M15_M30, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M5_M30, buyScore, sellScore);
    AccumulateDirectionalScores(rel_M5_M15, buyScore, sellScore);
}

void checkClose()
{  
    if (aktiveRobotOrder.type!=6){
        double buyPlanScore=0;
        double sellPlanScore=0;
        BestDirectionalScores(buyPlanScore, sellPlanScore);
        
        if (aktiveRobotOrder.type==OP_BUY){
            double buyProfit = Bid-aktiveRobotOrder.openPrice;
            double buyInitialRisk = aktiveRobotOrder.openPrice-aktiveRobotOrder.StopLoss;
            if(buyInitialRisk <= minMove)
                buyInitialRisk = MathMax(minStopLevel*2, spread*2);
            double buyProtectTrigger = MathMax(buyInitialRisk*0.35, MathMax(minStopLevel*2, spread*3));
            double buyTrailTrigger = MathMax(buyInitialRisk*0.80, MathMax(LS_M5.atr[0]*0.45, minStopLevel*3));

            bool closeBuy = false;
            bool hardSellSignal = (LS_H1.breakoutFiboDirZig == DIR_SELL
                                   && LS_M15.breakoutFiboDirZigSensitive == DIR_SELL
                                   && sellPlanScore > buyPlanScore+60);
            if(hardSellSignal && buyProfit < buyProtectTrigger)
                closeBuy = true;

            if(closeBuy){
                ModifyTP(CLOSE_BUY, aktiveRobotOrder);
                return;
            }

            if(buyProfit >= buyProtectTrigger){
                double buyBreakEvenSL = aktiveRobotOrder.openPrice+MathMax(spread, minMove);
                if(buyBreakEvenSL > aktiveRobotOrder.StopLoss+minMove && buyBreakEvenSL < Bid-minStopLevel){
                    aktiveRobotOrder.StopLoss = buyBreakEvenSL;
                    ModifyTP(OP_BUY, aktiveRobotOrder);
                }
            }

            double buyTrailSL = NextFiboBelow(currentPrice);
            double buyAtrTrailSL = currentPrice-MathMax(LS_M5.atr[0]*0.75, minStopLevel*2);
            if(buyTrailSL <= aktiveRobotOrder.openPrice || buyTrailSL > Bid-minStopLevel)
                buyTrailSL = buyAtrTrailSL;
            else if(buyAtrTrailSL > buyTrailSL)
                buyTrailSL = buyAtrTrailSL;
            if(buyProfit >= buyTrailTrigger
               && buyTrailSL > aktiveRobotOrder.StopLoss+minMove
               && buyTrailSL < Bid-minStopLevel){
                aktiveRobotOrder.StopLoss = buyTrailSL;
                ModifyTP(OP_BUY, aktiveRobotOrder);
            }

            double nextTP = NextFiboAbove(currentPrice);
            if(nextTP > currentPrice+minStopLevel
               && (aktiveRobotOrder.TakeProfit <= 0 || nextTP > aktiveRobotOrder.TakeProfit+minMove)){
                aktiveRobotOrder.TakeProfit = nextTP;
                ModifyTP(OP_BUY, aktiveRobotOrder);
            }
        }

        else if(aktiveRobotOrder.type==OP_SELL){
            double sellProfit = aktiveRobotOrder.openPrice-Ask;
            double sellInitialRisk = aktiveRobotOrder.StopLoss-aktiveRobotOrder.openPrice;
            if(sellInitialRisk <= minMove)
                sellInitialRisk = MathMax(minStopLevel*2, spread*2);
            double sellProtectTrigger = MathMax(sellInitialRisk*0.35, MathMax(minStopLevel*2, spread*3));
            double sellTrailTrigger = MathMax(sellInitialRisk*0.80, MathMax(LS_M5.atr[0]*0.45, minStopLevel*3));

            bool closeSell = false;
            bool hardBuySignal = (LS_H1.breakoutFiboDirZig == DIR_BUY
                                  && LS_M15.breakoutFiboDirZigSensitive == DIR_BUY
                                  && buyPlanScore > sellPlanScore+60);
            if(hardBuySignal && sellProfit < sellProtectTrigger)
                closeSell = true;

            if(closeSell){
                ModifyTP(CLOSE_SELL, aktiveRobotOrder);
                return;
            }

            if(sellProfit >= sellProtectTrigger){
                double sellBreakEvenSL = aktiveRobotOrder.openPrice-MathMax(spread, minMove);
                if((aktiveRobotOrder.StopLoss <= 0 || sellBreakEvenSL < aktiveRobotOrder.StopLoss-minMove)
                   && sellBreakEvenSL > Ask+minStopLevel){
                    aktiveRobotOrder.StopLoss = sellBreakEvenSL;
                    ModifyTP(OP_SELL, aktiveRobotOrder);
                }
            }

            double sellTrailSL = NextFiboAbove(currentPrice);
            double sellAtrTrailSL = currentPrice+MathMax(LS_M5.atr[0]*0.75, minStopLevel*2);
            if(sellTrailSL <= 0 || sellTrailSL >= aktiveRobotOrder.openPrice || sellTrailSL < Ask+minStopLevel)
                sellTrailSL = sellAtrTrailSL;
            else if(sellAtrTrailSL < sellTrailSL)
                sellTrailSL = sellAtrTrailSL;
            if(sellProfit >= sellTrailTrigger
               && sellTrailSL > 0
               && (aktiveRobotOrder.StopLoss <= 0 || sellTrailSL < aktiveRobotOrder.StopLoss-minMove)
               && sellTrailSL > Ask+minStopLevel){
                aktiveRobotOrder.StopLoss = sellTrailSL;
                ModifyTP(OP_SELL, aktiveRobotOrder);
            }

            double nextTP = NextFiboBelow(currentPrice);
            if(nextTP > 0
               && nextTP < currentPrice-minStopLevel
               && (aktiveRobotOrder.TakeProfit <= 0 || nextTP < aktiveRobotOrder.TakeProfit-minMove)){
                aktiveRobotOrder.TakeProfit = nextTP;
                ModifyTP(OP_SELL, aktiveRobotOrder);
            }
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
//| give command to send order                                       |
//+------------------------------------------------------------------+
double LotsByRisk(double entry, double sl)
{
    double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    double riskPoints = MathAbs(entry-sl)/Point;

    if(tickValue <= 0 || riskPoints <= 0 || lotStep <= 0)
        return NormalizeDouble(MathMax(minLot, AccountFreeMargin()*RiskRatio/(1000.0)), 2);

    double riskMoney = AccountFreeMargin()*RiskRatio;
    double result = riskMoney/(riskPoints*tickValue);
    if(maxLot > 0)
        result = MathMin(result, maxLot);
    result = MathMax(result, minLot);
    result = MathFloor(result/lotStep)*lotStep;
    return NormalizeDouble(result, 2);
}


bool PendingEntryIsBetter(int type, double currentEntry, double newEntry)
{
    if(currentEntry <= 0 || newEntry <= 0)
        return true;

    if(type == OP_BUYSTOP)
        return (newEntry < currentEntry);
    if(type == OP_SELLSTOP)
        return (newEntry > currentEntry);

    return false;
}

void SetPendingPlan(MyOrder& target, int type, double lotsValue, double entry, double sl, double tp)
{
    target.type = type;
    target.lots = lotsValue;
    target.openPrice = entry;
    target.StopLoss = sl;
    target.TakeProfit = tp;
}

double FiboSLBetween(int orderType, double entry, double localSL, double bigSL)
{
    double minDistance = MathMax(minStopLevel*2, MathMax(spread*2, minMove*3));

    if(orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT || orderType == OP_BUY){
        if(localSL <= 0)
            localSL = NextFiboBelow(entry);
        if(bigSL <= 0)
            bigSL = NextFiboBelow(localSL);

        double upper = MathMax(localSL, bigSL);
        double lower = MathMin(localSL, bigSL);
        double maxAllowed = entry-minDistance;
        if(upper > maxAllowed)
            upper = maxAllowed;

        for(int i=ArraySize(all_fibos)-1; i>=0; i--){
            if(all_fibos[i] > 0 && all_fibos[i] <= upper && all_fibos[i] >= lower)
                return all_fibos[i];
        }

        if(lower > 0 && lower < entry-minDistance)
            return lower;
        return NextFiboBelow(entry-minDistance);
    }

    if(orderType == OP_SELLSTOP || orderType == OP_SELLLIMIT || orderType == OP_SELL){
        if(localSL <= 0)
            localSL = NextFiboAbove(entry);
        if(bigSL <= 0)
            bigSL = NextFiboAbove(localSL);

        double lower = MathMin(localSL, bigSL);
        double upper = MathMax(localSL, bigSL);
        double minAllowed = entry+minDistance;
        if(lower < minAllowed)
            lower = minAllowed;

        for(int i=0; i<ArraySize(all_fibos); i++){
            if(all_fibos[i] >= lower && all_fibos[i] <= upper)
                return all_fibos[i];
        }

        if(upper > entry+minDistance)
            return upper;
        return NextFiboAbove(entry+minDistance);
    }

    return localSL;
}

void ConsiderPendingPlanByType(TFRelation& rel, int orderType, int& bestType, double& bestEntry,
                               double& bestSL, double& bestTP, double& bestScore)
{
    MyOrder candidate;
    ResetOrder(candidate);
    bool hasCandidate = false;
    double score=0;

    if(orderType == OP_BUYSTOP && rel.bigTrendDir == DIR_BUY){
        candidate = rel.buy_stop;
        hasCandidate = true;
        score = rel.continuationScore + rel.triggerQualityScore*0.1 - rel.reversalRiskScore*0.25;
    }
    else if(orderType == OP_SELLSTOP && rel.bigTrendDir == DIR_SELL){
        candidate = rel.sell_stop;
        hasCandidate = true;
        score = rel.continuationScore + rel.triggerQualityScore*0.1 - rel.reversalRiskScore*0.25;
    }
    else if(orderType == OP_BUYLIMIT && rel.bigTrendDir == DIR_BUY){
        candidate = rel.buy_limit;
        hasCandidate = true;
        score = rel.continuationScore - rel.reversalRiskScore*0.35;
    }
    else if(orderType == OP_SELLLIMIT && rel.bigTrendDir == DIR_SELL){
        candidate = rel.sell_limit;
        hasCandidate = true;
        score = rel.continuationScore - rel.reversalRiskScore*0.35;
    }

    if(!hasCandidate)
        return;

    double entry = candidate.openPrice;
    double sl = candidate.StopLoss;
    double tp = candidate.TakeProfit;

    if(entry <= 0 || sl <= 0 || tp <= 0)
        return;

    double bigSL=0;
    if(orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT){
        if(rel.bigLimitDown > 0)
            bigSL = NextFiboBelow(rel.bigLimitDown);
        if(bigSL <= 0 && rel.bigLimitDown > 0)
            bigSL = rel.bigLimitDown-MathMax(minStopLevel*2, minMove*3);
        sl = FiboSLBetween(orderType, entry, sl, bigSL);
    }
    else if(orderType == OP_SELLSTOP || orderType == OP_SELLLIMIT){
        if(rel.bigLimitTop > 0)
            bigSL = NextFiboAbove(rel.bigLimitTop);
        if(bigSL <= 0 && rel.bigLimitTop > 0)
            bigSL = rel.bigLimitTop+MathMax(minStopLevel*2, minMove*3);
        sl = FiboSLBetween(orderType, entry, sl, bigSL);
    }

    if(sl <= 0)
        return;

    bool strongStopTrigger = ((orderType == OP_BUYSTOP || orderType == OP_SELLSTOP)
                              && rel.triggerQualityScore >= 60
                              && rel.continuationScore > rel.reversalRiskScore+10);
    if(!rel.bigLimitTouched && !strongStopTrigger)
        return;
    if(rel.reversalRiskScore > 80 || score < 15)
        return;

    if(orderType == OP_BUYSTOP && entry <= Ask+minStopLevel)
        return;
    if(orderType == OP_SELLSTOP && entry >= Bid-minStopLevel)
        return;
    if(orderType == OP_BUYLIMIT && entry >= Ask-minStopLevel)
        return;
    if(orderType == OP_SELLLIMIT && entry <= Bid+minStopLevel)
        return;
    double riskReward = TradeRiskReward(orderType, entry, sl, tp);
    if(riskReward < 0.75)
        return;

    score += MathMin(riskReward, 3.0)*8;
    if(score > bestScore){
        bestType = orderType;
        bestEntry = entry;
        bestSL = sl;
        bestTP = tp;
        bestScore = score;
    }
}


double TradeRiskReward(int type, double entry, double sl, double tp)
{
    double risk=0;
    double reward=0;

    if(type==OP_BUYSTOP || type==OP_BUYLIMIT || type==OP_BUY){
        risk = entry-sl;
        reward = tp-entry;
    }
    else if(type==OP_SELLSTOP || type==OP_SELLLIMIT || type==OP_SELL){
        risk = sl-entry;
        reward = entry-tp;
    }

    if(risk <= minMove || reward <= minMove)
        return 0;
    return reward/risk;
}


void BestPendingPlanByType(int orderType, int& bestType, double& bestEntry,
                           double& bestSL, double& bestTP, double& bestScore)
{
    bestType = 6;
    bestEntry = 0;
    bestSL = 0;
    bestTP = 0;
    bestScore = 0;

    ConsiderPendingPlanByType(rel_H1_H4, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M30_H4, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M15_H4, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M5_H4, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M30_H1, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M15_H1, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M5_H1, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M15_M30, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M5_M30, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
    ConsiderPendingPlanByType(rel_M5_M15, orderType, bestType, bestEntry, bestSL, bestTP, bestScore);
}

void getCMD()
{
    
    int CMD=6; // CMD=6 : No Action
    MyOrder newPending_buy_limit = pending_buy_limit;
    MyOrder newPending_sell_limit = pending_sell_limit;
    MyOrder newPending_buy_stop = pending_buy_stop;
    MyOrder newPending_sell_stop = pending_sell_stop;

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

    int NRisk=1;
    lots = NormalizeDouble(AccountFreeMargin()*RiskRatio*NRisk/(1000.0), 2);

    // Select CMD oder setze newPending_buy_limit, newPending_sell_limit, newPending_buy_stop oder newPending_sell_stop 
    // Werte basierend auf der Analyse der Sensoren und der definierten Handelsstrategie. Zum Beispiel:
    // ----------
    //  Direkt
    if(CMD==6 && !weekend() && TimeHour(currentTime)<=21 && TimeHour(currentTime)>=1){
        // Buy
        // ---
        // if(sig_M15.breakoutDir == DIR_BUY && sig_H1.trendDir == DIR_BUY){
        //     CMD = OP_BUY;
        //     aktiveRobotOrder.lots = lots;
        //     aktiveRobotOrder.StopLoss = supports[6];  // SL 20 Pips unter Limit
        //     aktiveRobotOrder.TakeProfit = resistances[10];  // TP 40 Pips über Limit
        // }
                
        // // Sell 
        // // ----
        // if(sig_M15.breakoutDir == DIR_SELL && sig_H1.trendDir == DIR_SELL){
        //     CMD = OP_SELL;
        //     aktiveRobotOrder.lots = lots;
        //     aktiveRobotOrder.StopLoss = resistances[7];  // SL 20 Pips über Limit
        //     aktiveRobotOrder.TakeProfit = supports[4];  // TP 40 Pips unter Limit
        // }

        if(lots<minLot) lots=minLot;    
    }



    int planType=6;
    double buyLimitEntry=0, buyLimitSL=0, buyLimitTP=0, buyLimitScore=0;
    double buyStopEntry=0, buyStopSL=0, buyStopTP=0, buyStopScore=0;
    double sellLimitEntry=0, sellLimitSL=0, sellLimitTP=0, sellLimitScore=0;
    double sellStopEntry=0, sellStopSL=0, sellStopTP=0, sellStopScore=0;
    if(lots<minLot) lots=minLot;

    BestPendingPlanByType(OP_BUYLIMIT, planType, buyLimitEntry, buyLimitSL, buyLimitTP, buyLimitScore);
    bool buyLimitReady = (planType == OP_BUYLIMIT);
    BestPendingPlanByType(OP_BUYSTOP, planType, buyStopEntry, buyStopSL, buyStopTP, buyStopScore);
    bool buyStopReady = (planType == OP_BUYSTOP);
    BestPendingPlanByType(OP_SELLLIMIT, planType, sellLimitEntry, sellLimitSL, sellLimitTP, sellLimitScore);
    bool sellLimitReady = (planType == OP_SELLLIMIT);
    BestPendingPlanByType(OP_SELLSTOP, planType, sellStopEntry, sellStopSL, sellStopTP, sellStopScore);
    bool sellStopReady = (planType == OP_SELLSTOP);

    if(!buyStopReady && buyLimitReady && buyLimitTP > 0){
        buyStopEntry = buyLimitTP;
        buyStopSL = buyLimitSL;
        buyStopTP = NextFiboAbove(buyStopEntry);
        if(buyStopTP <= 0)
            buyStopTP = buyStopEntry+MathMax(minStopLevel*2, minMove*3);
        buyStopScore = buyLimitScore;
        buyStopReady = (buyStopEntry > Ask+minStopLevel && buyStopSL > 0 && buyStopTP > 0);
    }
    if(!buyStopReady && pending_buy_limit.lots > 0 && pending_buy_limit.TakeProfit > 0){
        buyStopEntry = pending_buy_limit.TakeProfit;
        buyStopSL = pending_buy_limit.StopLoss;
        buyStopTP = NextFiboAbove(buyStopEntry);
        if(buyStopTP <= 0)
            buyStopTP = buyStopEntry+MathMax(minStopLevel*2, minMove*3);
        buyStopScore = buyLimitScore;
        buyStopReady = (buyStopEntry > Ask+minStopLevel && buyStopSL > 0 && buyStopTP > 0);
    }
    if(!sellStopReady && sellLimitReady && sellLimitTP > 0){
        sellStopEntry = sellLimitTP;
        sellStopSL = sellLimitSL;
        sellStopTP = NextFiboBelow(sellStopEntry);
        if(sellStopTP <= 0)
            sellStopTP = sellStopEntry-MathMax(minStopLevel*2, minMove*3);
        sellStopScore = sellLimitScore;
        sellStopReady = (sellStopEntry < Bid-minStopLevel && sellStopSL > 0 && sellStopTP > 0);
    }
    if(!sellStopReady && pending_sell_limit.lots > 0 && pending_sell_limit.TakeProfit > 0){
        sellStopEntry = pending_sell_limit.TakeProfit;
        sellStopSL = pending_sell_limit.StopLoss;
        sellStopTP = NextFiboBelow(sellStopEntry);
        if(sellStopTP <= 0)
            sellStopTP = sellStopEntry-MathMax(minStopLevel*2, minMove*3);
        sellStopScore = sellLimitScore;
        sellStopReady = (sellStopEntry < Bid-minStopLevel && sellStopSL > 0 && sellStopTP > 0);
    }

    bool buyReady = buyLimitReady || buyStopReady;
    bool sellReady = sellLimitReady || sellStopReady;
    double buyPairScore = MathMax(buyLimitScore, buyStopScore);
    double sellPairScore = MathMax(sellLimitScore, sellStopScore);
    bool hasBuyPlan = (pending_buy_limit.ticketNr > -1 || pending_buy_stop.ticketNr > -1
                       || pending_buy_limit.lots > 0 || pending_buy_stop.lots > 0);
    bool hasSellPlan = (pending_sell_limit.ticketNr > -1 || pending_sell_stop.ticketNr > -1
                        || pending_sell_limit.lots > 0 || pending_sell_stop.lots > 0);
    double oppositeDominance = 25;

    bool allowBuy = false;
    bool allowSell = false;
    bool dropBuy = false;
    bool dropSell = false;

    if(hasBuyPlan){
        allowBuy = true;
        if(sellReady && sellPairScore > buyPairScore+oppositeDominance){
            allowBuy = false;
            allowSell = true;
            dropBuy = true;
        }
    }
    else if(hasSellPlan){
        allowSell = true;
        if(buyReady && buyPairScore > sellPairScore+oppositeDominance){
            allowSell = false;
            allowBuy = true;
            dropSell = true;
        }
    }
    else if(buyReady || sellReady){
        if(buyReady && (!sellReady || buyPairScore >= sellPairScore))
            allowBuy = true;
        else if(sellReady)
            allowSell = true;
    }

    if(dropBuy){
        ResetOrder(newPending_buy_limit);
        ResetOrder(newPending_buy_stop);
    }
    if(dropSell){
        ResetOrder(newPending_sell_limit);
        ResetOrder(newPending_sell_stop);
    }

    if(allowBuy && buyLimitReady)
        SetPendingPlan(newPending_buy_limit, OP_BUYLIMIT, lots, buyLimitEntry, buyLimitSL, buyLimitTP);
    if(allowBuy && buyStopReady)
        SetPendingPlan(newPending_buy_stop, OP_BUYSTOP, lots, buyStopEntry, buyStopSL, buyStopTP);
    if(allowSell && sellLimitReady)
        SetPendingPlan(newPending_sell_limit, OP_SELLLIMIT, lots, sellLimitEntry, sellLimitSL, sellLimitTP);
    if(allowSell && sellStopReady)
        SetPendingPlan(newPending_sell_stop, OP_SELLSTOP, lots, sellStopEntry, sellStopSL, sellStopTP);
    checkPendingOrdersChange(pending_buy_limit, newPending_buy_limit);
    checkPendingOrdersChange(pending_sell_limit, newPending_sell_limit);
    checkPendingOrdersChange(pending_buy_stop, newPending_buy_stop);
    checkPendingOrdersChange(pending_sell_stop, newPending_sell_stop);
    
    if (CMD == OP_BUY || CMD == OP_SELL) setOrders(CMD);
}

void checkPendingOrdersChange(MyOrder& pendingOrder, MyOrder& newPendingOrder)
{
    if (newPendingOrder.lots == 0 && pendingOrder.ticketNr > -1){
        ModifyTP(DELETE_PENDING, pendingOrder);
        ResetOrder(pendingOrder);
        return;
    }

    if (newPendingOrder.lots == 0){
        ResetOrder(pendingOrder);
        return;
    }

    if(pendingOrder.ticketNr > -1 && pendingOrder.type == newPendingOrder.type){
        int oldTicket = pendingOrder.ticketNr;
        double oldLots = pendingOrder.lots;
        if(!PendingEntryIsBetter(newPendingOrder.type, pendingOrder.openPrice, newPendingOrder.openPrice))
            newPendingOrder.openPrice = pendingOrder.openPrice;
        if(MathAbs(newPendingOrder.openPrice-pendingOrder.openPrice) < minMove
           && MathAbs(newPendingOrder.StopLoss-pendingOrder.StopLoss) < minMove
           && MathAbs(newPendingOrder.TakeProfit-pendingOrder.TakeProfit) < minMove)
            return;
        pendingOrder = newPendingOrder;
        pendingOrder.ticketNr = oldTicket;
        pendingOrder.lots = oldLots;
        newPendingOrder.ticketNr = oldTicket;
        newPendingOrder.lots = oldLots;
        ModifyTP(MODIFY_PENDING, newPendingOrder);
        return;
    }

    pendingOrder = newPendingOrder;
    setOrders(newPendingOrder.type);
}

void setOrders(int CMD)
{
    int ticket=0;
    switch(CMD){

    case OP_BUY:
        if(ROBOTTRADE &&  aktiveRobotOrder.StopLoss>0){ 
            aktiveRobotOrder.TakeProfit=NormalizeDouble(aktiveRobotOrder.TakeProfit, vdigits);
            aktiveRobotOrder.StopLoss=NormalizeDouble(aktiveRobotOrder.StopLoss, vdigits);
            aktiveRobotOrder.ticketNr=OrderSend(Symbol(), OP_BUY, aktiveRobotOrder.lots, Ask,
                                            3, aktiveRobotOrder.StopLoss, aktiveRobotOrder.TakeProfit,
                                            "LeoTrader", MAGIC_NO, 0, Blue);
            Print("ticket: ", ticket);
            if(aktiveRobotOrder.ticketNr<0){
                LogTradeError("OrderSend", GetLastError(), OP_BUY, aktiveRobotOrder.ticketNr,
                                aktiveRobotOrder.lots, Ask, aktiveRobotOrder.StopLoss, aktiveRobotOrder.TakeProfit);
            }
        }
        else Print("OP_BUY is muted");
        break;

    case OP_SELL:
        if(ROBOTTRADE &&  aktiveRobotOrder.StopLoss>0){ 
            aktiveRobotOrder.TakeProfit=NormalizeDouble(aktiveRobotOrder.TakeProfit, vdigits);
            aktiveRobotOrder.StopLoss=NormalizeDouble(aktiveRobotOrder.StopLoss, vdigits);
            aktiveRobotOrder.ticketNr=OrderSend(Symbol(), OP_SELL, aktiveRobotOrder.lots, Bid,
                                            3, aktiveRobotOrder.StopLoss, aktiveRobotOrder.TakeProfit,
                                            "LeoTrader", MAGIC_NO, 0, Red);
            if(aktiveRobotOrder.ticketNr<0){
                LogTradeError("OrderSend", GetLastError(), OP_SELL, aktiveRobotOrder.ticketNr,
                                aktiveRobotOrder.lots, Bid, aktiveRobotOrder.StopLoss, aktiveRobotOrder.TakeProfit);
            }
        }
        else Print("OP_SELL is muted");
            
        break;

    case OP_BUYLIMIT:
        if(ROBOTTRADE &&  pending_buy_limit.ticketNr < 0){
            pending_buy_limit.TakeProfit=NormalizeDouble(pending_buy_limit.TakeProfit, vdigits);
            pending_buy_limit.StopLoss=NormalizeDouble(pending_buy_limit.StopLoss, vdigits);
            pending_buy_limit.ticketNr=OrderSend(Symbol(), OP_BUYLIMIT, pending_buy_limit.lots, pending_buy_limit.openPrice,
                                                3, pending_buy_limit.StopLoss, pending_buy_limit.TakeProfit,
                                                "LeoTrader", MAGIC_NO, 0, Green);
            if(pending_buy_limit.ticketNr<0){
                LogTradeError("OrderSend", GetLastError(), OP_BUYLIMIT, pending_buy_limit.ticketNr,
                            pending_buy_limit.lots, pending_buy_limit.openPrice, pending_buy_limit.StopLoss, pending_buy_limit.TakeProfit);
            }
        }

        break;
    case OP_SELLLIMIT:
        if(ROBOTTRADE &&  pending_sell_limit.ticketNr < 0){
            pending_sell_limit.TakeProfit=NormalizeDouble(pending_sell_limit.TakeProfit, vdigits);
            pending_sell_limit.StopLoss=NormalizeDouble(pending_sell_limit.StopLoss, vdigits);
            pending_sell_limit.ticketNr=OrderSend(Symbol(), OP_SELLLIMIT, pending_sell_limit.lots, pending_sell_limit.openPrice,
                                            3, pending_sell_limit.StopLoss, pending_sell_limit.TakeProfit,
                                            "LeoTrader", MAGIC_NO, 0, Red);
            if(pending_sell_limit.ticketNr<0){
                LogTradeError("OrderSend", GetLastError(), OP_SELLLIMIT, pending_sell_limit.ticketNr,
                            pending_sell_limit.lots, pending_sell_limit.openPrice, pending_sell_limit.StopLoss, pending_sell_limit.TakeProfit);
            }
        }

        break;
    case OP_BUYSTOP:
        if(ROBOTTRADE &&  pending_buy_stop.ticketNr < 0){
            pending_buy_stop.TakeProfit=NormalizeDouble(pending_buy_stop.TakeProfit, vdigits);
            pending_buy_stop.StopLoss=NormalizeDouble(pending_buy_stop.StopLoss, vdigits);
            pending_buy_stop.ticketNr=OrderSend(Symbol(), OP_BUYSTOP, pending_buy_stop.lots, pending_buy_stop.openPrice,
                                                3, pending_buy_stop.StopLoss, pending_buy_stop.TakeProfit,
                                                "LeoTrader", MAGIC_NO, 0, Green);
            if(pending_buy_stop.ticketNr<0){
                LogTradeError("OrderSend", GetLastError(), OP_BUYSTOP, pending_buy_stop.ticketNr,
                            pending_buy_stop.lots, pending_buy_stop.openPrice, pending_buy_stop.StopLoss, pending_buy_stop.TakeProfit);
            }
        }
        break;
    case OP_SELLSTOP:
        if(ROBOTTRADE &&  pending_sell_stop.ticketNr < 0){
            pending_sell_stop.TakeProfit=NormalizeDouble(pending_sell_stop.TakeProfit, vdigits);
            pending_sell_stop.StopLoss=NormalizeDouble(pending_sell_stop.StopLoss, vdigits);
            pending_sell_stop.ticketNr=OrderSend(Symbol(), OP_SELLSTOP, pending_sell_stop.lots, pending_sell_stop.openPrice,
                                            3, pending_sell_stop.StopLoss, pending_sell_stop.TakeProfit,
                                            "LeoTrader", MAGIC_NO, 0, Red);
            if(pending_sell_stop.ticketNr<0){
                LogTradeError("OrderSend", GetLastError(), OP_SELLSTOP, pending_sell_stop.ticketNr,
                                pending_sell_stop.lots, pending_sell_stop.openPrice, pending_sell_stop.StopLoss, pending_sell_stop.TakeProfit);
            }
        }
        break;
    case 6:
        break;
    }
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
    MyOrder robotPendingOrders[];
    int robotPendingCount = 0;
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
                aktiveRobotOrder.lots       = OrderLots();
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
                user[iUser].lots       = OrderLots();
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
                temp.lots       = OrderLots();
                ArrayResize(robotPendingOrders, robotPendingCount+1);
                robotPendingOrders[robotPendingCount] = temp;
                robotPendingCount++;
            }
            
        }
    }

    AssignRobotPendingSnapshot(robotPendingOrders, robotPendingCount);
    
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
            o.lots = OrderLots();
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
    MyOrder robotPendingOrders[];
    int robotPendingCount=0;
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
                    aktiveRobotOrder.lots=OrderLots();
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
                    user[iUser].lots=OrderLots();
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
                    temp.lots=OrderLots();
                    ArrayResize(robotPendingOrders, robotPendingCount+1);
                    robotPendingOrders[robotPendingCount]=temp;
                    robotPendingCount++;
                }
                
            }
            
                
        }       
    }

    AssignRobotPendingSnapshot(robotPendingOrders, robotPendingCount);
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
    o.lots = 0;
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
    ResetOrder(pending_sell_stop_against_reverse_kurs);
    ResetOrder(pending_buy_stop_against_reverse_kurs);
}

bool HasRobotPendingOrder()
{
    return pending_buy_limit.ticketNr > -1
        || pending_sell_limit.ticketNr > -1
        || pending_buy_stop.ticketNr > -1
        || pending_sell_stop.ticketNr > -1
        || pending_sell_stop_against_reverse_kurs.ticketNr > -1
        || pending_buy_stop_against_reverse_kurs.ticketNr > -1;
}

bool OrderSnapshotExists(MyOrder& o)
{
    return (o.ticketNr > -1 || o.lots > 0);
}

void AssignRobotPendingSnapshot(MyOrder& orders[], int orderCount)
{
    ResetPendingOrders();

    for(int i=0; i<orderCount; i++){
        if(orders[i].type == OP_BUYLIMIT)
            pending_buy_limit = orders[i];
        else if(orders[i].type == OP_SELLLIMIT)
            pending_sell_limit = orders[i];
    }

    for(int j=0; j<orderCount; j++){
        if(orders[j].type == OP_BUYSTOP && OrderSnapshotExists(pending_buy_limit) && !OrderSnapshotExists(pending_buy_stop))
            pending_buy_stop = orders[j];
        else if(orders[j].type == OP_SELLSTOP && OrderSnapshotExists(pending_sell_limit) && !OrderSnapshotExists(pending_sell_stop))
            pending_sell_stop = orders[j];
    }

    for(int k=0; k<orderCount; k++){
        if(orders[k].type == OP_SELLSTOP
           && OrderSnapshotExists(pending_buy_limit)
           && OrderSnapshotExists(pending_buy_stop)
           && orders[k].ticketNr != pending_buy_stop.ticketNr)
            pending_sell_stop_against_reverse_kurs = orders[k];
        else if(orders[k].type == OP_BUYSTOP
                && OrderSnapshotExists(pending_sell_limit)
                && OrderSnapshotExists(pending_sell_stop)
                && orders[k].ticketNr != pending_sell_stop.ticketNr)
            pending_buy_stop_against_reverse_kurs = orders[k];
    }

    for(int m=0; m<orderCount; m++){
        if(orders[m].type == OP_BUYSTOP
           && !OrderSnapshotExists(pending_buy_stop)
           && orders[m].ticketNr != pending_buy_stop_against_reverse_kurs.ticketNr)
            pending_buy_stop = orders[m];
        else if(orders[m].type == OP_SELLSTOP
                && !OrderSnapshotExists(pending_sell_stop)
                && orders[m].ticketNr != pending_sell_stop_against_reverse_kurs.ticketNr)
            pending_sell_stop = orders[m];
    }
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
