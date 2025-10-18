

//+------------------------------------------------------------------+
//| Fibonacci-Erstellen                                              |
//+------------------------------------------------------------------+
struct fibonacci {
    double fibo[19];
}
fibonacci set_fibo(double top, double down){
    
    // fibo rechner
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
//| update zigzag history                                            |
//+------------------------------------------------------------------+
update_zigzag_history(methode)
{
    int i = 1;
    int shift=1;
    for(uchar j=1; j<ArraySize(MyZig); j++)
    {
        do{
            if (methode=="MyZigZag") MyZig[j]=iCustom(Symbol(), timeframe, "MyZigZag",6, 0, shift);
            else MyZig[j]=iCustom(Symbol(), timeframe, "ZigZag", 12, 5, 3, 0, shift);
            shift++;
            i++;
        }while (MyZig[j]==0);

        MyZig_Bar[j]=shift-1;
            
        MyZig_Interval[j-1]=i-1;
        i=1;
    }

    // recalculte if ZigZag's Points are truely marked
    for(uchar j=2; j<ArraySize(MyZig); j++) {
        if((MyZig[j-2]>MyZig[j-1] && MyZig[j-1]>MyZig[j])
            ||(MyZig[j-2]>0 && MyZig[j-2]<MyZig[j-1] && MyZig[j-1]<MyZig[j]))
        {
            MyZig[j-1]=MyZig[j];
            MyZig_Bar[j-1]=MyZig_Bar[j];
            MyZig_Interval[j-2]+=MyZig_Interval[j-1];
            for(uchar k=j; k<ArraySize(MyZig_Interval)-1; k++){
                MyZig[k]=MyZig[k+1];
                MyZig_Bar[k]=MyZig_Bar[k+1];
                MyZig_Interval[k-1]=MyZig_Interval[k];
            }
        }
    }
    // extract extra high and lows:
    shift = 0;
    for(uchar j=0; j<ArraySize(MyZig_High); j++)
    {
        do{
            if (methode=="MyZigZag") MyZig_High[j]=iCustom(Symbol(), timeframe, "MyZigZag",6, 1, shift);
            else MyZig_High[j]=iCustom(Symbol(), timeframe, "ZigZag", 12, 5, 3, 1, shift);
            shift++;
        }while (MyZig_High[j]==0);
    }

    shift = 0;
    for(uchar j=0; j<ArraySize(MyZig_Low); j++){
        do{
            if (methode=="MyZigZag") MyZig_Low[j]=iCustom(Symbol(), timeframe, "MyZigZag",6, 2, shift);
            else MyZig_Low[j]=iCustom(Symbol(), timeframe, "ZigZag", 12, 5, 3, 2, shift);
            shift++;
        }while (MyZig_Low[j]==0);
    }
}


class sensors{
    private:
        double zig_zag [10];
        double zig_zag_sensitive [10];
        int update_zig_bar;
        int update_zig_bar_sensitive;

    public:
        // public Methode
        void init_Leo(int, int, int);
        void update(void);
        int timeframe;

        // public variable
        fibonacci fibo_zig[3];
        fibonacci fibo_zig_sensitive[3];
        fibonacci fibo_candel[3];

        posFibo zig[3];
        posFibo zig_sen[3];
        posFibo candel[3];

};
    void sensors::init_sensors(int tf, int trend, int cut)
    {
        timeframe=tf;

        MA_TREND_PERIOD=trend;
        MA_CUT_PERIOD=cut;

        MyZigUpdateBar=iBars(Symbol(), timeframe);
        if(zm!=""){
            updateMyZigHistory();
            zigFibos();       // update Fibo Levels by start
            lastFibLevValue=0; // invalid fibo level value
        }
        lastFibLevValue_candel=0;
    }