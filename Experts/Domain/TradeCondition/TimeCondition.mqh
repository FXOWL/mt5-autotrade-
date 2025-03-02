//+------------------------------------------------------------------+
//|                                              TimeCondition.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"

#include "ITradeCondition.mqh"
#include "../../Infrastructure/Utils/DateTimeExt.mqh"

/**
 * @brief 時間条件クラス
 */
class CTimeCondition : public ITradeCondition
{
private:
    int m_tradeHour;           // 取引を行う時間
    string m_failureMessage;   // 条件不成立時のメッセージ

public:
    /**
     * @brief コンストラクタ
     * @param tradeHour 取引を行う時間（0-23）
     */
    CTimeCondition(const int tradeHour) : m_tradeHour(tradeHour), m_failureMessage("") {}
    
    /**
     * @brief 現在の時間が取引時間内かチェック
     * @param symbol 通貨ペア
     * @param timeframe 時間枠
     * @return bool 取引時間内ならtrue
     */
    bool Check(const string symbol, const ENUM_TIMEFRAMES timeframe)
    {
        // ローカル時間を取得し、設定した取引時間に調整
        CDateTimeExt dt_local;
        dt_local.DateTime(TimeLocal());
        dt_local.Hour(m_tradeHour);
        
        // サーバー時間に変換
        CDateTimeExt dt_srv = dt_local.ToMtServerStruct();
        
        // 直前の完成バーの時間を取得
        datetime lastBarTime = iTime(symbol, timeframe, 1);
        MqlDateTime lastBarStruct;
        TimeToStruct(lastBarTime, lastBarStruct);
        
        // サーバー時間の時と直前バーの時間が一致するかチェック
        if(dt_srv.Hour() == lastBarStruct.hour)
            return true;
            
        m_failureMessage = StringFormat(
            "現在の時間が取引時間外です。| 設定時間: %d時 | 現在のサーバー時間: %s",
            m_tradeHour, dt_srv.ToStrings()
        );
        return false;
    }
    
    /**
     * @brief 条件不成立時のメッセージを取得
     * @return string メッセージ
     */
    string GetFailureMessage()
    {
        return m_failureMessage;
    }
}; 