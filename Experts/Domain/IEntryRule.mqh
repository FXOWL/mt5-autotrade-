//+------------------------------------------------------------------+
//|                                                  IEntryRule.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| エントリールールのインターフェース                              |
//+------------------------------------------------------------------+
interface IEntryRule
{
    // エントリー条件が満たされているかをチェックするメソッド
    bool ShouldEnter(string symbol, ENUM_TIMEFRAMES timeframe);
    
    // エントリーの方向（売り/買い）を返すメソッド
    ENUM_ORDER_TYPE GetOrderType();
    
    // ロット数を計算するメソッド
    double CalculateLot(string symbol, double accountBalance);
    
    // ストップロス価格を計算するメソッド
    double CalculateSL(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice);
    
    // 利確価格を計算するメソッド
    double CalculateTP(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice);
}; 