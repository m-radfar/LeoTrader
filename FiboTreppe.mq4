

//+------------------------------------------------------------------+
//| Fibonacci-Erstellen                                              |
//+------------------------------------------------------------------+
struct fibonacci {
    double fibo[19];
}
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
struct posFibo={
    double fibo_support=0;
    double fibo_resistance=0;
    int fibo_index_support=0;
    int fibo_index_resistance=0;

    double aktive_limit_fibo_top=0;
    double aktive_limit_fibo_down=0;
    bool fibo_line_is_aktive=false;
    bool fibo_half_line_is_aktive=false;

    int aktive_fibo_index=-1;

};
posFibo pos_in_fibo(double value, fibonacci fibos){

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

        fiboHUp=fibos.fibo[i]+(0.25*uperRef);
        fiboHDown=fibos.fibo[i]-(0.25*lowerRef);

        if(value<limit_top && value>limit_down){
            pf.aktive_limit_fibo_top=limit_top;
            pf.aktive_limit_fibo_down=limit_down;
            aktive_fibo_index=i;
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
        void update(void);
        
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
    void LeoSensors::init_sensors(int tf, int trend, int cut){
        timeframe=tf;

        MA_TREND_PERIOD=trend;
        MA_CUT_PERIOD=cut;

        update_indicator_bar = iBars(Symbol(), timeframe);
        update_zigzag_history();
        // init zigzags-fibos by start
        for (uchar i = 0; i<ArraySize(fibo_zig); i++){
            fibo_zig[i] = set_fibo(zig_zag[i+3], zig_zag[i+2]);
        }
        for (uchar i = 0; i<ArraySize(fibo_zig_sensitive); i++){
            fibo_zig_sensitive[i] = set_fibo(fibo_zig_sensitive[i+3], fibo_zig_sensitive[i+2]);
        }
        
        // init candels-fibos by start 
        for (uchar i = 0; i<ArraySize(fibo_candel); i++){
            fibo_candel[i] = set_fibo(iHigh(Symbol(), timeframe, i+1), iLow(Symbol(), timeframe, i+1))
        }

        // init posFibos
        for (uchar i = 0; i<ArraySize(posFibo_zig); i++)
            posFibo_zig[i]=pos_in_fibo(iClose(Symbol(), timeframe, 0), fibo_zig[i]);

        for (uchar i = 0; i<ArraySize(posFibo_zig_sen); i++)
            posFibo_zig_sen[i]=pos_in_fibo(iClose(Symbol(), timeframe, 0), fibo_zig_sensitive[i]);

        for (uchar i = 0; i<ArraySize(posFibo_zig); i++)
            posFibo_candel[i]=pos_in_fibo(iClose(Symbol(), timeframe, 0), fibo_candel[i]);

        // ------ init indicators ------
        // MA
        for (uchar i = 0 ; i<ArraySize(ma_trend); i++){
            ma_trend[i] = iMA(Symbol(), timeframe, MA_TREND_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, i);
            ma_cut[i] = iMA(Symbol(), timeframe, MA_CUT_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, i); 
        }
        // MACD
        for (uchar i = 0 ; i<ArraySize(macd_main); i++){
            macd_main[i] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, i);
            macd_sig[i] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, i);
        }
        // Stochastic
        for (uchar i = 0 ; i<ArraySize(stoch_sig); i++){
            stoch_main[i] = iStochastic(Symbol(),timeframe,5,3,3,MODE_SMA,0,MODE_MAIN,i);
            stoch_sig[i] = iStochastic(Symbol(),timeframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,i);
        }
        // RSI
        for (uchar i = 0 ; i<ArraySize(rsi); i++){
            rsi[i] = iRSI(Symbol(), timeframe, 14, PRICE_CLOSE, i);
        }
        // ATR
        for (uchar i = 0 ; i<ArraySize(atr); i++){
           atr[i] = iATR(Symbol(), timeframe, 14, i);
        }
        // Volume
        for (uchar i = 0 ; i<ArraySize(volume); i++){
            volume[i] = iVolume(Symbol(), timeframe, i);
        }
    }

    void LeoSensors::update_zigzag_history(void){
        int shift=0;
        // update zig_zag
        for(uchar j=1; j<ArraySize(zig_zag); j++)
        {
            do{
                zig_zag[j]=iCustom(Symbol(), timeframe, "ZigZag", 12, 5, 3, 0, shift);
                shift++;
            }while (zig_zag[j]==0);
        }

        // update zig_zag_sensitive
        shift=0;
        for(uchar j=1; j<ArraySize(zig_zag_sensitive); j++)
        {
            do{
                zig_zag_sensitive[j]=iCustom(Symbol(), timeframe, "MyZigZag",6, 0, shift);
                shift++;
            }while (zig_zag_sensitive[j]==0);

        }

    }

    void LeoSensors::update_zigFibos(void){
        for(uchar i = ArraySize(fibo_zig)-1 i>0; i--)
            fibo_zig[i] = fibo_zig[i-1];
        
        for(uchar i = ArraySize(fibo_zig_sensitive)-1 i>0; i--)
            fibo_zig_sensitive[i] = fibo_zig_sensitive[i-1];
        
        fibo_zig[0] = set_fibo(zig_zag[3], zig_zag[2]);
        fibo_zig_sensitive[0] = set_fibo(fibo_zig_sensitive[3], fibo_zig_sensitive[2]);
    }

    void LeoSensors::update_candelFibos(void){
        for (uchar i = ArraySize(fibo_candel)-1; i>0; i--)
            fibo_candel[i] = fibo_candel[i-1];
        fibo_candel[0] = set_fibo(iHigh(Symbol(), timeframe, 1), iLow(Symbol(), timeframe, 1))
    }

    void LeoSensors::update_sensors(void){
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
            

            // MA
            for (uchar i = ArraySize(ma_cut)-1; i>0; i--){
                ma_trend[i] = ma_trend[i-1];
                ma_cut[i] = ma_cut[i-1];
            }
            ma_trend[1] = iMA(Symbol(), timeframe, MA_TREND_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 1);
            ma_cut[1] = iMA(Symbol(), timeframe, MA_CUT_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 1); 
            ma_trend[0] = iMA(Symbol(), timeframe, MA_TREND_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 0);
            ma_cut[0] = iMA(Symbol(), timeframe, MA_CUT_PERIOD, 0, MODE_LWMA, PRICE_WEIGHTED, 0); 
            
            
            // MACD
            for (uchar i = ArraySize(macd_main)-1; i>0; i--){
               macd_main[i] = macd_main[i-1];
               macd_sig[i] = macd_sig[i-1];
            }
            macd_main[1] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
            macd_sig[1] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 1);
            macd_main[0] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
            macd_sig[0] = iMACD(Symbol(), timeframe, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
            
            // Stochastic
            for (uchar i = ArraySize(stoch_sig)-1; i>0; i--){
               stoch_main[i] = stoch_main[i-1];
               stoch_sig[i] = stoch_sig[i-1];
            }
            stoch_main[1] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_MAIN, 1);
            stoch_sig[1] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_SIGNAL, 1);
            stoch_main[0] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_MAIN, 0);
            stoch_sig[0] = iStochastic(Symbol(), timeframe, 5, 3, 3, MODE_SMA, 0 ,MODE_SIGNAL, 0);
            
            // RSI
            for (uchar i = ArraySize(rsi)-1; i>0; i--){
               rsi[i] = rsi[i-1];
            }
            rsi[1] = iRSI(Symbol(), timeframe, 14, PRICE_CLOSE, 1);
            rsi[0] = iRSI(Symbol(), timeframe, 14, PRICE_CLOSE, 0);
            
            // ATR
            for (uchar i = ArraySize(atr)-1; i>0; i--){
               atr[i] = atr[i-1];
            }
            atr[1] = iATR(Symbol(), timeframe, 14, 1);
            atr[0] = iATR(Symbol(), timeframe, 14, 0);
            
            // Volume
            for (uchar i = ArraySize(volume)-1; i>0; i--){
               volume[i] = volume[i-1];
            }
            volume[1] = iVolume(Symbol(), timeframe, 1);
            volume[0] = iVolume(Symbol(), timeframe, 0);

            update_indicator_bar = currentBar;
        }
    }
