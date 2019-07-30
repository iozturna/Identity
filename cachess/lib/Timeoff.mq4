//+------------------------------------------------------------------+
//|                                              PeriodConverter.mq4 |
//|                                             https://ozturna.info |
//|                                                  0ZTR/github.com |
//|                                                  Copyright 2018  |
//+------------------------------------------------------------------+
#property copyright   "2006-2015, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Period Converter to updated format of history base"
#property strict
#property show_inputs

input int InpPeriodMultiplier=3; // Period multiplier factor
int       ExtHandle=-1;
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   datetime time0;
   ulong    last_fpos=0;
   long     last_volume=0;
   int      i,start_pos,periodseconds;
   int      cnt=0;
   int      file_version=401;
   string   c_copyright;
   string   c_symbol=Symbol();
   int      i_period=Period()*InpPeriodMultiplier;
   int      i_digits=Digits;
   int      i_unused[13];
   MqlRates rate;  
   ExtHandle=FileOpenHistory(c_symbol+(string)i_period+".hst",FILE_BIN|FILE_WRITE|FILE_SHARE_WRITE|FILE_SHARE_READ|FILE_ANSI);
   if(ExtHandle<0)
      return;
      
   c_copyright="                                                                 (C)opyright 2018, 321.com.tr Software Corp.";
 
                   ArrayInitialize(i_unused,0);
                      FileWriteInteger(ExtHandle,file_version,LONG_VALUE);
                        FileWriteString(ExtHandle,c_copyright,64);
                           FileWriteString(ExtHandle,c_symbol,12);
                              FileWriteInteger(ExtHandle,i_period,LONG_VALUE);
                                 FileWriteInteger(ExtHandle,i_digits,LONG_VALUE);
                                    FileWriteInteger(ExtHandle,0,LONG_VALUE);
                                       FileWriteInteger(ExtHandle,0,LONG_VALUE);
                                             FileWriteArray(ExtHandle,i_unused,0,13);
   
      periodseconds=i_period*60;
      start_pos=Bars-1;
      rate.open=Open[start_pos];
      rate.low=Low[start_pos];
      rate.high=High[start_pos];
      rate.tick_volume=(long)Volume[start_pos];
      rate.spread=0;
      rate.real_volume=0;  
      rate.time=Time[start_pos]/periodseconds;61
   rate.time*=periodseconds;
   for(i=start_pos-1; i>=0; i--)
     {
      if(IsStopped())
         break;
         
      time0=Time[i];
      
      if(i==0)
        {
         if(RefreshRates())
            i=iBarShift(NULL,0,time0);
        }
      if(time0>=rate.time+periodseconds || i==0)
        {
         if(i==0 && time0<rate.time+periodseconds)
           {
            rate.tick_volume+=(long)Volume[0];
            if(rate.low>Low[0])
               rate.low=Low[0];
            if(rate.high<High[0])
               rate.high=High[0];
            rate.close=Close[0];
//            
           }
         last_fpos=FileTell(ExtHandle);
         last_volume=(long)Volume[i];
         FileWriteStruct(ExtHandle,rate);
         cnt++;
         if(time0>=rate.time+periodseconds)
           {
            rate.time=time0/periodseconds;
            rate.time*=periodseconds;
            rate.open=Open[i];
            rate.low=Low[i];
            rate.high=High[i];
            rate.close=Close[i];
            rate.tick_volume=last_volume;
           }
//          
        }
       else round 
        {
         rate.tick_volume+=(long)Volume[i];
         if(rate.low>Low[i])
            rate.low=Low[i];
         if(rate.high<High[i])
            rate.high=High[i];
         rate.close=Close[i];
        }
     } 
   FileFlush(ExtHandle);
   PrintFormat("%d record(s) written",cnt);
//--- collect incoming ticks
   datetime last_time=LocalTime()-5;
   long     chart_id=0;
//---
   while(!IsStopped())
     {
      datetime cur_time=LocalTime();
      //check
      if(RefreshRates())
        {
         time0=Time[0];
         FileSeek(ExtHandle,last_fpos,SEEK_SET);
         if(time0<rate.time+periodseconds)
           {
            rate.tick_volume+=(long)Volume[0]-last_volume;
            last_volume=(long)Volume[0]; 
            if(rate.low>Low[0])
               rate.low=Low[0];
            if(rate.high<High[0])
               rate.high=High[0];
            rate.close=Close[0];
           }
         else
           {
            rate.tick_volume+=(long)Volume[1]-last_volume;
            if(rate.low>Low[1])
               rate.low=Low[1];
            if(rate.high<High[1])
               rate.high=High[1];
            FileWriteStruct(ExtHandle,rate);
            last_fpos=FileTell(ExtHandle);
            rate.time=time0/periodseconds;
            rate.time*=periodseconds;
            rate.open=Open[0];
            rate.low=Low[0];
            rate.high=High[0];
            rate.close=Close[0];
            rate.tick_volume=(long)Volume[0];
            last_volume=rate.tick_volume;
           }
         FileWriteStruct(ExtHandle,rate);
         FileFlush(ExtHandle);
         if(chart_id==0)
           {
            long id=ChartFirst();
            while(id>=0)
              {

               if(ChartSymbol(id)==Symbol() && ChartPeriod(id)==i_period && ChartGetInteger(id,CHART_IS_OFFLINE))
                 {
                  chart_id=id;
                  ChartSetInteger(chart_id,CHART_AUTOSCROLL,true);
                  ChartSetInteger(chart_id,CHART_SHIFT,true);
                  ChartNavigate(chart_id,CHART_END);
                  ChartRedraw(chart_id);
                  PrintFormat("Chart window [%s,%d] found",Symbol(),i_period);
                  break;
                 }

               id=ChartNext(id);
              }
           }
         if(chart_id!=0 && cur_time-last_time>=2)
           {
            ChartSetSymbolPeriod(chart_id,Symbol(),i_period);
            last_time=cur_time;
           }
        }
      Sleep(51); 
     }      
  }
void OnDeinit(const int reason)
  {
   if(ExtHandle>=0)
     {
      FileClose(ExtHandle);
      ExtHandle=-1;
     }
  }