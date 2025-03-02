//+------------------------------------------------------------------+
//|                                                  EATemplate.mq5 |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

// 標準インクルード
#include <Trade\Trade.mqh>

// 自作インクルード
// ドメインモデルのインクルード
#include <Experts\Domain\IEntryRule.mqh>
#include <Experts\Domain\ITrailingRule.mqh>
#include <Experts\Domain\Exit\Trailing\SimpleTrailingRule.mqh>

// アプリケーション層のインクルード
#include <Experts\Application\Composition\CompositeEntryRule.mqh>
#include <Experts\Application\Composition\AndEntryRule.mqh>
#include <Experts\Application\Composition\OrEntryRule.mqh>
#include <Experts\Application\Services\EntryRuleManager.mqh>
#include <Experts\Application\Services\TrailingRuleManager.mqh>
#include <Experts\Application\Controllers\TradeController.mqh>

// 各種戦略インクルード
#include <Experts\Domain\Entry\Price\MABuyStrategy.mqh>
#include <Experts\Domain\Entry\Price\MASellStrategy.mqh>

//--- 入力パラメータ
input string BasicSettingsGroup = "==== 基本設定 ====";  // 基本設定
input string   EA_Name              = "MATrader";         // EA名
input int      Magic_Number         = 123456;             // マジックナンバー
input ENUM_TIMEFRAMES Timeframe     = PERIOD_CURRENT;     // 時間枠

input string TradeSettingsGroup = "==== トレード設定 ====";  // トレード設定
input bool     Allow_Buy            = true;               // 買いトレードを許可
input bool     Allow_Sell           = true;               // 売りトレードを許可
input bool     Use_TrailingStop     = false;              // トレーリングストップを使用
input bool     Close_On_Opposite    = true;               // 反対方向の条件で決済

input string MASettingsGroup = "==== 移動平均設定 ====";  // 移動平均設定
input int      MA_Period            = 12;                 // 移動平均の期間
input int      MA_Shift             = 6;                  // 移動平均のシフト

input string TrailingSettingsGroup = "==== トレーリング設定 ====";  // トレーリング設定
input int      Trailing_Pips        = 200;                // トレーリングストップのpips数

input string ConditionsGroup = "==== 条件選択 ====";  // 条件選択
input string   Buy_Rules            = "MABuy_Simple";     // 買い条件の選択
input string   Sell_Rules           = "MASell_Simple";    // 売り条件の選択
input string   Trailing_Rules       = "SimpleTrailing";   // トレーリング条件の選択

//--- グローバル変数
TradeController *g_tradeController = NULL;        // トレードコントローラー
EntryRuleManager *g_entryRuleManager = NULL;      // エントリールールマネージャー
TrailingRuleManager *g_trailingRuleManager = NULL;// トレーリングルールマネージャー

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // コントローラーとマネージャーの作成
    g_tradeController = new TradeController();
    g_entryRuleManager = new EntryRuleManager();
    g_trailingRuleManager = new TrailingRuleManager();
    
    // マジックナンバーの設定
    g_tradeController.SetMagicNumber(Magic_Number);
    
    // 戦略の登録
    if(!RegisterStrategies())
    {
        Print("戦略の登録に失敗しました");
        return INIT_FAILED;
    }
    
    // 買い条件の設定
    if(Allow_Buy)
    {
        // 変数を使わずに直接関数の結果を使用
        g_tradeController.SetBuyRules(g_entryRuleManager.GetRule(Buy_Rules));
        Print("買い条件が設定されました: ", Buy_Rules);
    }
    
    // 売り条件の設定
    if(Allow_Sell)
    {
        // 変数を使わずに直接関数の結果を使用
        g_tradeController.SetSellRules(g_entryRuleManager.GetRule(Sell_Rules));
        Print("売り条件が設定されました: ", Sell_Rules);
    }
    
    // トレーリングストップ条件の設定
    if(Use_TrailingStop)
    {
        // 新しいトレーリングルールマネージャーを使用
        ITrailingRule* trailingRule = g_trailingRuleManager.GetRule(Trailing_Rules);
        if(trailingRule != NULL)
        {
            g_tradeController.SetTrailingRule(trailingRule);
            Print("トレーリングストップ条件が設定されました: ", Trailing_Rules);
        }
    }
    
    Print("MATrader initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // コントローラーの解放
    if(g_tradeController != NULL)
    {
        delete g_tradeController;
        g_tradeController = NULL;
    }
    
    // エントリールールマネージャーの解放
    if(g_entryRuleManager != NULL)
    {
        delete g_entryRuleManager;
        g_entryRuleManager = NULL;
    }
    
    // トレーリングルールマネージャーの解放
    if(g_trailingRuleManager != NULL)
    {
        delete g_trailingRuleManager;
        g_trailingRuleManager = NULL;
    }
    
    Print("MATrader deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // ティック処理をコントローラーに委譲
    if(g_tradeController != NULL)
    {
        g_tradeController.ProcessTick(_Symbol, Timeframe);
    }
}

//+------------------------------------------------------------------+
//| 戦略の登録                                                        |
//+------------------------------------------------------------------+
bool RegisterStrategies()
{
    // 移動平均戦略の登録
    g_entryRuleManager.RegisterRule(new MABuyStrategy(MA_Period, MA_Shift), "MABuy_Simple");
    g_entryRuleManager.RegisterRule(new MASellStrategy(MA_Period, MA_Shift), "MASell_Simple");
    
    // 複合ルールの例
    // MAとRSIを組み合わせた買いストラテジー（例として）
    // RSIの部分は実際のコードで置き換える必要があります
    /*
    AndEntryRule *maBuyAndRule = new AndEntryRule(ORDER_TYPE_BUY);
    maBuyAndRule.AddRule(new MABuyStrategy(MA_Period, MA_Shift));
    // 他の条件をここに追加（例：RSI）
    g_entryRuleManager.RegisterRule(maBuyAndRule, "MABuy_AND_RSI");
    */
    
    // シンプルなトレーリングストップルールを登録
    g_trailingRuleManager.RegisterRule(new SimpleTrailingRule(Trailing_Pips), "SimpleTrailing");
    
    return true;
}

//+------------------------------------------------------------------+ 