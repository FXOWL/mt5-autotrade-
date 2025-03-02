//+------------------------------------------------------------------+
//|                                          TradeController.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
// #include "IEntryRule.mqh"  // インターフェースの代わりにダックタイピングを使用

//+------------------------------------------------------------------+
//| トレード操作を管理するコントローラークラス                       |
//+------------------------------------------------------------------+
class TradeController
{
private:
    CTrade      m_trade;          // トレード操作オブジェクト
    void       *m_buyRules;       // 買いエントリールール
    void       *m_sellRules;      // 売りエントリールール
    void       *m_trailingRules;  // トレーリングストップルール
    
    ulong       m_lastTickTime;   // 最後のティック時間
    bool        m_isNewBar;       // 新しいバーが開いたかどうか
    datetime    m_lastBarTime;    // 最後のバーの時間
    
    // サポートされているフィリングモードを取得
    ENUM_ORDER_TYPE_FILLING GetSupportedFillingMode()
    {
        uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
        
        if(filling == 0) {
            // サポートがない場合はIOCモードを試用
            return ORDER_FILLING_IOC;
        } else {
            // サポートされているモードを選択（優先順位: FOK > IOC > RETURN）
            if((filling & SYMBOL_FILLING_FOK) != 0) {
                return ORDER_FILLING_FOK;
            } else if((filling & SYMBOL_FILLING_IOC) != 0) {
                return ORDER_FILLING_IOC;
            } else {
                return ORDER_FILLING_RETURN;
            }
        }
    }
    
    // 新しいバーが開いたかどうかをチェック
    bool IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        datetime currentBarTime = iTime(symbol, timeframe, 0);
        
        if(currentBarTime != m_lastBarTime)
        {
            m_lastBarTime = currentBarTime;
            return true;
        }
        
        return false;
    }
    
public:
    // コンストラクタ
    TradeController()
    {
        m_buyRules = NULL;
        m_sellRules = NULL;
        m_trailingRules = NULL;
        m_lastTickTime = 0;
        m_isNewBar = false;
        m_lastBarTime = 0;
        
        // フィリングモードの設定
        m_trade.SetTypeFilling(GetSupportedFillingMode());
        
        // マジックナンバーの設定
        m_trade.SetExpertMagicNumber(123456);
    }
    
    // デストラクタ
    ~TradeController()
    {
        // 各ルールの解放
        if(m_buyRules != NULL)
        {
            delete m_buyRules;
            m_buyRules = NULL;
        }
        
        if(m_sellRules != NULL)
        {
            delete m_sellRules;
            m_sellRules = NULL;
        }
        
        if(m_trailingRules != NULL)
        {
            delete m_trailingRules;
            m_trailingRules = NULL;
        }
    }
    
    // マジックナンバーの設定
    void SetMagicNumber(int magicNumber)
    {
        m_trade.SetExpertMagicNumber(magicNumber);
    }
    
    // 買いルールの設定
    void SetBuyRules(void *rules)
    {
        if(m_buyRules != NULL)
        {
            delete m_buyRules;
        }
        
        m_buyRules = rules;
    }
    
    // 売りルールの設定
    void SetSellRules(void *rules)
    {
        if(m_sellRules != NULL)
        {
            delete m_sellRules;
        }
        
        m_sellRules = rules;
    }
    
    // トレーリングストップルールの設定
    void SetTrailingRules(void *rules)
    {
        if(m_trailingRules != NULL)
        {
            delete m_trailingRules;
        }
        
        m_trailingRules = rules;
    }
    
    // ティック処理
    void ProcessTick(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        m_isNewBar = IsNewBar(symbol, timeframe);
        
        // バーが変わった場合にのみエントリー条件をチェック
        if(m_isNewBar)
        {
            CheckEntryRules(symbol, timeframe);
        }
        
        // オープンポジションのトレーリングストップを処理
        ProcessTrailingStop(symbol, timeframe);
    }
    
    // エントリー条件のチェック
    void CheckEntryRules(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        // 買いエントリールールのチェック
        if(m_buyRules != NULL && ((MABuyStrategy*)m_buyRules).ShouldEnter(symbol, timeframe))
        {
            // アカウント残高の取得
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            
            // エントリー
            double entryPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
            double sl = ((MABuyStrategy*)m_buyRules).CalculateSL(symbol, ORDER_TYPE_BUY, entryPrice);
            double tp = ((MABuyStrategy*)m_buyRules).CalculateTP(symbol, ORDER_TYPE_BUY, entryPrice);
            double volume = ((MABuyStrategy*)m_buyRules).CalculateLot(symbol, balance);
            
            // 買い注文を送信
            bool result = m_trade.Buy(volume, symbol, 0, sl, tp);
            
            // エラーチェック
            if(!result)
            {
                int lastError = m_trade.ResultRetcode();
                if(lastError == 4756) // Unsupported filling mode
                {
                    // 別のフィリングモードを試す
                    ENUM_ORDER_TYPE_FILLING currentFilling = m_trade.TypeFilling();
                    if(currentFilling == ORDER_FILLING_FOK)
                    {
                        m_trade.SetTypeFilling(ORDER_FILLING_IOC);
                    }
                    else
                    {
                        m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
                    }
                    
                    // 再度注文を送信
                    m_trade.Buy(volume, symbol, 0, sl, tp);
                }
                
                // エラーログ
                Print("Buy order error: ", m_trade.ResultRetcodeDescription());
            }
        }
        
        // 売りエントリールールのチェック
        if(m_sellRules != NULL && ((MASellStrategy*)m_sellRules).ShouldEnter(symbol, timeframe))
        {
            // アカウント残高の取得
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            
            // エントリー
            double entryPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
            double sl = ((MASellStrategy*)m_sellRules).CalculateSL(symbol, ORDER_TYPE_SELL, entryPrice);
            double tp = ((MASellStrategy*)m_sellRules).CalculateTP(symbol, ORDER_TYPE_SELL, entryPrice);
            double volume = ((MASellStrategy*)m_sellRules).CalculateLot(symbol, balance);
            
            // 売り注文を送信
            bool result = m_trade.Sell(volume, symbol, 0, sl, tp);
            
            // エラーチェック
            if(!result)
            {
                int lastError = m_trade.ResultRetcode();
                if(lastError == 4756) // Unsupported filling mode
                {
                    // 別のフィリングモードを試す
                    ENUM_ORDER_TYPE_FILLING currentFilling = m_trade.TypeFilling();
                    if(currentFilling == ORDER_FILLING_FOK)
                    {
                        m_trade.SetTypeFilling(ORDER_FILLING_IOC);
                    }
                    else
                    {
                        m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
                    }
                    
                    // 再度注文を送信
                    m_trade.Sell(volume, symbol, 0, sl, tp);
                }
                
                // エラーログ
                Print("Sell order error: ", m_trade.ResultRetcodeDescription());
            }
        }
    }
    
    // トレーリングストップの処理
    void ProcessTrailingStop(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        if(m_trailingRules == NULL)
            return;
            
        // オープンポジションの取得
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            // ポジション情報の確認省略（コード短縮のため）
            
            // トレーリングストップ条件が満たされている場合
            if(((SimpleTrailingRule*)m_trailingRules).ShouldTrail(symbol, timeframe))
            {
                // トレーリングストップの実行（詳細実装は省略）
            }
        }
    }
}; 