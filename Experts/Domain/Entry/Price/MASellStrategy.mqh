//+------------------------------------------------------------------+
//|                                            MASellStrategy.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

// #include <Experts\Domain\IEntryRule.mqh>  // インターフェースは使用しない

//+------------------------------------------------------------------+
//| 移動平均線を使用した売りエントリー戦略                          |
//+------------------------------------------------------------------+
class MASellStrategy // インターフェース継承を削除
{
private:
    int     m_maPeriod;        // 移動平均の期間
    int     m_maShift;         // 移動平均のシフト
    int     m_handle;          // インジケーターハンドル
    
public:
    // コンストラクタ
    MASellStrategy(int maPeriod = 12, int maShift = 6)
    {
        m_maPeriod = maPeriod;
        m_maShift = maShift;
        m_handle = INVALID_HANDLE;
    }
    
    // デストラクタ
    ~MASellStrategy()
    {
        if(m_handle != INVALID_HANDLE)
        {
            IndicatorRelease(m_handle);
        }
    }
    
    // 売りエントリー条件をチェック
    bool ShouldEnter(string symbol, ENUM_TIMEFRAMES timeframe) // override削除
    {
        // エントリー判断はsignalメソッドに委譲
        return Signal(symbol, timeframe) == ORDER_TYPE_SELL;
    }
    
    // エントリー方向を取得
    ENUM_ORDER_TYPE GetOrderType() // override削除
    {
        return ORDER_TYPE_SELL;
    }
    
    // ロット数を計算
    double CalculateLot(string symbol, double accountBalance) // override削除
    {
        double maxRisk = 0.02; // 最大リスク率（2%）
        double decreaseFactor = 3; // 連続損失による減少率
        
        // 選択されたシンボルの現在価格を取得
        double price = SymbolInfoDouble(symbol, SYMBOL_BID);
        
        // 1ロットの必要証拠金
        double margin = 0;
        if(!OrderCalcMargin(ORDER_TYPE_SELL, symbol, 1.0, price, margin) || margin <= 0.0)
            return 0.01; // デフォルト値
        
        // 最適ロットサイズの計算
        double lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_FREE) * maxRisk / margin, 2);
        
        // 連続損失回数による調整
        int losses = CalculateConsecutiveLosses();
        if(losses > 1)
            lot = NormalizeDouble(lot - lot * losses / decreaseFactor, 1);
        
        // ロットサイズの制限を適用
        double stepvol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
        lot = stepvol * NormalizeDouble(lot / stepvol, 0);
        
        double minvol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        if(lot < minvol)
            lot = minvol;
        
        double maxvol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        if(lot > maxvol)
            lot = maxvol;
        
        return lot;
    }
    
    // ストップロス価格を計算
    double CalculateSL(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice) // override削除
    {
        // 単純に現在価格から一定距離に設定（より洗練された方法に置き換え可能）
        double points = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double slDistance = 500 * points; // 50pips
        
        return NormalizeDouble(entryPrice + slDistance, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    }
    
    // 利確価格を計算
    double CalculateTP(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice) // override削除
    {
        // 単純に現在価格から一定距離に設定（より洗練された方法に置き換え可能）
        double points = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double tpDistance = 1000 * points; // 100pips
        
        return NormalizeDouble(entryPrice - tpDistance, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    }
    
    // エントリーシグナルを生成するメソッド
    ENUM_ORDER_TYPE Signal(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        // インジケーターハンドルの初期化（必要に応じて）
        if(m_handle == INVALID_HANDLE)
        {
            m_handle = iMA(symbol, timeframe, m_maPeriod, m_maShift, MODE_SMA, PRICE_CLOSE);
            if(m_handle == INVALID_HANDLE)
            {
                Print("Failed to create MA indicator handle");
                return WRONG_VALUE;
            }
        }
        
        // ローソク足データを取得
        MqlRates rates[2];
        if(CopyRates(symbol, timeframe, 0, 2, rates) != 2)
        {
            Print("Failed to get price data");
            return WRONG_VALUE;
        }
        
        // バックテストでは前のバーの完成チェックをスキップする
        #ifdef __MQL5__
        if(!MQLInfoInteger(MQL_TESTER))
        {
            // 一つ前のバーが完成しているかチェック（実際の運用でのみチェック）
            if(rates[1].tick_volume <= 1)
            {
                Print("Previous bar not complete: tick_volume = ", rates[1].tick_volume);
                return WRONG_VALUE;
            }
        }
        #endif
        
        // 移動平均値を取得
        double maValue[1];
        if(CopyBuffer(m_handle, 0, 0, 1, maValue) != 1)
        {
            Print("Failed to get MA values");
            return WRONG_VALUE;
        }
        
        // デバッグログ: 現在の値を出力
        Print("MASellStrategy: symbol=", symbol, ", open=", rates[0].open, ", close=", rates[0].close, ", MA=", maValue[0]);
        
        // 売りシグナルのチェック：ローソク足がMAを上から下にクロス
        if(rates[0].open > maValue[0] && rates[0].close < maValue[0])
        {
            Print("SELL signal generated: open(", rates[0].open, ") > MA(", maValue[0], ") && close(", rates[0].close, ") < MA(", maValue[0], ")");
            return ORDER_TYPE_SELL;
        }
        
        return WRONG_VALUE;
    }
    
private:
    // 連続損失回数を計算
    int CalculateConsecutiveLosses()
    {
        int magicNumber = 123456; // マジックナンバー（実際のEAに合わせて変更）
        
        // 履歴を選択
        HistorySelect(0, TimeCurrent());
        
        int totalDeals = HistoryDealsTotal();
        int losses = 0;
        
        for(int i = totalDeals - 1; i >= 0; i--)
        {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket == 0)
            {
                Print("HistoryDealGetTicket failed");
                break;
            }
            
            // シンボルチェック
            if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol)
                continue;
                
            // マジックナンバーチェック
            if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != magicNumber)
                continue;
                
            // 利益チェック
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(profit > 0.0)
                break;
                
            if(profit < 0.0)
                losses++;
        }
        
        return losses;
    }
}; 