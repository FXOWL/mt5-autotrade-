//+------------------------------------------------------------------+
//|                                          TradeController.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
// #include <Experts\Domain\IEntryRule.mqh>  // インターフェースの代わりにダックタイピングを使用
#include "..\..\Domain\ITrailingRule.mqh"
#include "..\..\Domain\Entry\Price\MABuyStrategy.mqh"
#include "..\..\Domain\Entry\Price\MASellStrategy.mqh"

//+------------------------------------------------------------------+
//| トレード操作を管理するコントローラークラス                       |
//+------------------------------------------------------------------+
class TradeController
{
private:
    CTrade      m_trade;          // トレード操作オブジェクト
    void       *m_buyRules;       // 買いエントリールール
    void       *m_sellRules;      // 売りエントリールール
    ITrailingRule *m_trailingRule;  // トレーリングストップルール
    
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
        m_trailingRule = NULL;
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
        
        if(m_trailingRule != NULL)
        {
            delete m_trailingRule;
            m_trailingRule = NULL;
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
    void SetTrailingRule(ITrailingRule *rule)
    {
        if(m_trailingRule != NULL)
        {
            delete m_trailingRule;
        }
        
        m_trailingRule = rule;
    }
    
    // ティック処理
    void ProcessTick(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        // 新しいバーのチェック
        m_isNewBar = IsNewBar(symbol, timeframe);
        
        // デバッグログの追加
        static int tickCounter = 0;
        if(++tickCounter % 100 == 0) // 100ティックごとにログ出力
        {
            Print("Processing tick #", tickCounter, ", IsNewBar=", m_isNewBar);
        }
        
        // テスト中は常にエントリー条件をチェック
        #ifdef __MQL5__
        if(MQLInfoInteger(MQL_TESTER))
        {
            // テスト中は毎ティックでチェック
            CheckEntryRules(symbol, timeframe);
        }
        else
        {
            // 通常の運用ではバーが変わった場合にのみチェック
            if(m_isNewBar)
            {
                CheckEntryRules(symbol, timeframe);
            }
        }
        #else
            // MQL4の場合または条件分岐できない場合は常にチェック
            CheckEntryRules(symbol, timeframe);
        #endif
        
        // オープンポジションのトレーリングストップを処理
        ProcessTrailingStop(symbol, timeframe);
    }
    
    // エントリー条件のチェック
    void CheckEntryRules(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        Print("CheckEntryRules called: symbol=", symbol, ", timeframe=", EnumToString(timeframe));
        
        // 買いエントリールールのチェック
        if(m_buyRules != NULL)
        {
            Print("Checking buy rules...");
            bool shouldEnter = ((MABuyStrategy*)m_buyRules).ShouldEnter(symbol, timeframe);
            Print("Buy rules result: ", shouldEnter ? "TRUE - Should enter" : "FALSE - Should not enter");
            
            if(shouldEnter)
            {
                // アカウント残高の取得
                double balance = AccountInfoDouble(ACCOUNT_BALANCE);
                
                // エントリー
                double entryPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
                double sl = ((MABuyStrategy*)m_buyRules).CalculateSL(symbol, ORDER_TYPE_BUY, entryPrice);
                double tp = ((MABuyStrategy*)m_buyRules).CalculateTP(symbol, ORDER_TYPE_BUY, entryPrice);
                double volume = ((MABuyStrategy*)m_buyRules).CalculateLot(symbol, balance);
                
                Print("Placing BUY order: Price=", entryPrice, ", SL=", sl, ", TP=", tp, ", Volume=", volume);
                
                // 買い注文を送信
                bool result = m_trade.Buy(volume, symbol, 0, sl, tp);
                
                // エラーチェック
                if(!result)
                {
                    int lastError = (int)m_trade.ResultRetcode();
                    Print("Buy order failed with error code: ", lastError, " (", m_trade.ResultRetcodeDescription(), ")");
                    if(lastError == 4756) // Unsupported filling mode
                    {
                        // 別のフィリングモードを試す
                        MqlTradeRequest request = {};
                        m_trade.Request(request);
                        ENUM_ORDER_TYPE_FILLING currentFilling = (ENUM_ORDER_TYPE_FILLING)request.type_filling;
                        if(currentFilling == ORDER_FILLING_FOK)
                        {
                            m_trade.SetTypeFilling(ORDER_FILLING_IOC);
                            Print("Switching filling mode from FOK to IOC");
                        }
                        else
                        {
                            m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
                            Print("Switching filling mode to RETURN");
                        }
                        
                        // 再度注文を送信
                        result = m_trade.Buy(volume, symbol, 0, sl, tp);
                        Print("Second buy attempt result: ", result ? "SUCCESS" : "FAILED");
                    }
                    
                    // エラーログ
                    Print("Buy order error: ", m_trade.ResultRetcodeDescription());
                }
                else
                {
                    Print("Buy order placed successfully");
                }
            }
        }
        else
        {
            Print("Buy rules not set");
        }
        
        // 売りエントリールールのチェック
        if(m_sellRules != NULL)
        {
            Print("Checking sell rules...");
            bool shouldEnter = ((MASellStrategy*)m_sellRules).ShouldEnter(symbol, timeframe);
            Print("Sell rules result: ", shouldEnter ? "TRUE - Should enter" : "FALSE - Should not enter");
            
            if(shouldEnter)
            {
                // アカウント残高の取得
                double balance = AccountInfoDouble(ACCOUNT_BALANCE);
                
                // エントリー
                double entryPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
                double sl = ((MASellStrategy*)m_sellRules).CalculateSL(symbol, ORDER_TYPE_SELL, entryPrice);
                double tp = ((MASellStrategy*)m_sellRules).CalculateTP(symbol, ORDER_TYPE_SELL, entryPrice);
                double volume = ((MASellStrategy*)m_sellRules).CalculateLot(symbol, balance);
                
                Print("Placing SELL order: Price=", entryPrice, ", SL=", sl, ", TP=", tp, ", Volume=", volume);
                
                // 売り注文を送信
                bool result = m_trade.Sell(volume, symbol, 0, sl, tp);
                
                // エラーチェック
                if(!result)
                {
                    int lastError = (int)m_trade.ResultRetcode();
                    Print("Sell order failed with error code: ", lastError, " (", m_trade.ResultRetcodeDescription(), ")");
                    if(lastError == 4756) // Unsupported filling mode
                    {
                        // 別のフィリングモードを試す
                        MqlTradeRequest request = {};
                        m_trade.Request(request);
                        ENUM_ORDER_TYPE_FILLING currentFilling = (ENUM_ORDER_TYPE_FILLING)request.type_filling;
                        if(currentFilling == ORDER_FILLING_FOK)
                        {
                            m_trade.SetTypeFilling(ORDER_FILLING_IOC);
                            Print("Switching filling mode from FOK to IOC");
                        }
                        else
                        {
                            m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
                            Print("Switching filling mode to RETURN");
                        }
                        
                        // 再度注文を送信
                        result = m_trade.Sell(volume, symbol, 0, sl, tp);
                        Print("Second sell attempt result: ", result ? "SUCCESS" : "FAILED");
                    }
                    
                    // エラーログ
                    Print("Sell order error: ", m_trade.ResultRetcodeDescription());
                }
                else
                {
                    Print("Sell order placed successfully");
                }
            }
        }
        else
        {
            Print("Sell rules not set");
        }
    }
    
    // トレーリングストップの処理
    void ProcessTrailingStop(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        if(m_trailingRule == NULL)
            return;
            
        // トレーリングを適用すべきかどうかをチェック
        if(!m_trailingRule.ShouldApplyTrailing(symbol, timeframe))
            return;
            
        // オープンポジションの取得
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if(!PositionSelectByTicket(PositionGetTicket(i)))
                continue;
                
            // 自分のEAで開いたポジションのみを処理
            if(PositionGetInteger(POSITION_MAGIC) != m_trade.RequestMagic())
                continue;
                
            // シンボルが一致するポジションのみを処理
            if(PositionGetString(POSITION_SYMBOL) != symbol)
                continue;
                
            // 現在のポジション情報を取得
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentPrice;
            
            ENUM_ORDER_TYPE orderType;
            if(posType == POSITION_TYPE_BUY)
            {
                currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
                orderType = ORDER_TYPE_BUY;
            }
            else
            {
                currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
                orderType = ORDER_TYPE_SELL;
            }
            
            // 新しいストップロスを計算
            double newSL = m_trailingRule.CalculateTrailingStopPrice(symbol, orderType, currentPrice);
            
            // 買いポジションの場合は現在のSLより高いか、売りポジションの場合は現在のSLより低い場合のみトレーリング
            bool shouldModify = false;
            if(posType == POSITION_TYPE_BUY && (currentSL == 0 || newSL > currentSL))
                shouldModify = true;
            else if(posType == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL))
                shouldModify = true;
                
            // ストップロスの修正
            if(shouldModify)
            {
                m_trade.PositionModify(PositionGetTicket(i), newSL, PositionGetDouble(POSITION_TP));
                
                // エラーチェック
                if(m_trade.ResultRetcode() != TRADE_RETCODE_DONE)
                {
                    Print("Trailing stop modification error: ", m_trade.ResultRetcodeDescription());
                }
            }
        }
    }
}; 