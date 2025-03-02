# MQL5におけるクリーンアーキテクチャの実装ガイド

## 1. はじめに

このドキュメントでは、MQL5におけるクリーンアーキテクチャの実装方法について詳細に解説します。実装例を通じて理解を深め、実際のプロジェクトに適用するための指針を提供します。

## 2. プロジェクト構造

MetaTrader 5の標準的なディレクトリ構造に合わせたクリーンアーキテクチャの実装構造は以下の通りです：

```
MQL5/
├── Experts/
│   └── MyCleanEA/
│       └── MyCleanEA.mq5   # 依存性の注入とエントリーポイントのみ
│
├── Include/
│   └── MyCleanArchitecture/
│       ├── Core/
│       │   ├── Entities/   # ビジネスエンティティ
│       │   │   ├── Order.mqh
│       │   │   ├── Position.mqh
│       │   │   ├── Trade.mqh
│       │   │   └── ...
│       │   │
│       │   ├── ValueObjects/ # 値オブジェクト
│       │   │   ├── Price.mqh
│       │   │   ├── RiskParameters.mqh
│       │   │   └── ...
│       │   │
│       │   └── UseCases/    # ビジネスロジック
│       │       ├── Interfaces/  # ポートとインターフェース
│       │       │   ├── IOrderRepository.mqh
│       │       │   ├── IMarketDataProvider.mqh
│       │       │   └── ...
│       │       │
│       │       ├── EntryRules/   # エントリーロジック
│       │       │   ├── IEntryRule.mqh
│       │       │   ├── MACrossEntryRule.mqh
│       │       │   └── ...
│       │       │
│       │       ├── ExitRules/    # 決済ロジック
│       │       │   ├── IExitRule.mqh
│       │       │   ├── TrailingStopExitRule.mqh
│       │       │   └── ...
│       │       │
│       │       └── Services/     # ユースケースサービス
│       │           ├── TradeExecutionService.mqh
│       │           ├── RiskManagementService.mqh
│       │           └── ...
│       │
│       ├── Adapters/             # インターフェースアダプター
│       │   ├── Repositories/     # データアクセス
│       │   │   ├── MT5OrderRepository.mqh
│       │   │   ├── SQLiteTradeHistoryRepository.mqh
│       │   │   └── ...
│       │   │
│       │   ├── Presenters/       # 表示ロジック
│       │   │   ├── DashboardPresenter.mqh
│       │   │   ├── AlertPresenter.mqh
│       │   │   └── ...
│       │   │
│       │   └── Controllers/      # コントローラー
│       │       ├── TradeController.mqh
│       │       ├── BacktestController.mqh
│       │       └── ...
│       │
│       ├── Infrastructure/       # 外部システム連携
│       │   ├── MT5/              # MT5 API連携
│       │   │   ├── MT5OrderExecutor.mqh
│       │   │   ├── MT5MarketDataProvider.mqh
│       │   │   └── ...
│       │   │
│       │   ├── Database/         # データベース連携
│       │   │   ├── SQLiteHandler.mqh
│       │   │   └── ...
│       │   │
│       │   ├── Messaging/        # 外部通信
│       │   │   ├── EmailNotifier.mqh
│       │   │   ├── TelegramNotifier.mqh
│       │   │   └── ...
│       │   │
│       │   └── Configuration/    # 設定管理
│       │       ├── JsonConfigReader.mqh
│       │       └── ...
│       │
│       └── Utils/                # ユーティリティ
│           ├── DateTime/         # 日時処理
│           ├── Math/            # 数学関数
│           ├── String/          # 文字列処理
│           └── Logging/         # ロギング
│
├── Scripts/
│   └── MyCleanEA/
│       ├── Tests/              # テスト
│       │   ├── UnitTests/      # ユニットテスト
│       │   └── IntegrationTests/ # 統合テスト
│       │
│       └── Tools/              # ツール
│           ├── ConfigGenerator.mq5  # 設定ファイル生成
│           ├── DatabaseMigration.mq5 # DB移行
│           └── ...
│
└── Files/
    └── MyCleanEA/
        ├── Config/             # 設定ファイル
        │   ├── default_config.json
        │   └── ...
        │
        ├── Logs/               # ログファイル
        │
        └── Database/           # SQLiteデータベース
```

## 3. 各レイヤーの実装例

### 3.1 Core層 - エンティティの実装

エンティティは、アプリケーションのコアとなるビジネスロジックとデータモデルを表します。

```mql5
// Include/MyCleanArchitecture/Core/Entities/Position.mqh
class Position
{
private:
    int m_ticket;
    string m_symbol;
    ENUM_POSITION_TYPE m_type;
    double m_volume;
    double m_openPrice;
    double m_stopLoss;
    double m_takeProfit;
    datetime m_openTime;
    
public:
    // コンストラクタ
    Position(int ticket, string symbol, ENUM_POSITION_TYPE type, double volume,
             double openPrice, double stopLoss, double takeProfit, datetime openTime)
        : m_ticket(ticket), m_symbol(symbol), m_type(type), m_volume(volume),
          m_openPrice(openPrice), m_stopLoss(stopLoss), m_takeProfit(takeProfit),
          m_openTime(openTime) {}
    
    // ゲッターメソッド
    int Ticket() const { return m_ticket; }
    string Symbol() const { return m_symbol; }
    ENUM_POSITION_TYPE Type() const { return m_type; }
    double Volume() const { return m_volume; }
    double OpenPrice() const { return m_openPrice; }
    double StopLoss() const { return m_stopLoss; }
    double TakeProfit() const { return m_takeProfit; }
    datetime OpenTime() const { return m_openTime; }
    
    // ビジネスロジックメソッド
    double CalculateProfit(double currentPrice) const
    {
        if(m_type == POSITION_TYPE_BUY)
            return (currentPrice - m_openPrice) * m_volume;
        else
            return (m_openPrice - currentPrice) * m_volume;
    }
    
    bool IsProfit(double currentPrice) const
    {
        return CalculateProfit(currentPrice) > 0;
    }
};
```

### 3.2 Core層 - 値オブジェクトの実装

値オブジェクトは、不変の値を表現するオブジェクトです。

```mql5
// Include/MyCleanArchitecture/Core/ValueObjects/RiskParameters.mqh
class RiskParameters
{
private:
    double m_riskPercent;
    double m_maxDrawdownPercent;
    int m_maxOpenPositions;
    bool m_isValid;

public:
    // コンストラクタ
    RiskParameters(double riskPercent, double maxDrawdownPercent, int maxOpenPositions)
    {
        // バリデーション
        m_isValid = (riskPercent > 0 && riskPercent <= 100) &&
                   (maxDrawdownPercent > 0 && maxDrawdownPercent <= 100) &&
                   (maxOpenPositions > 0);
                   
        m_riskPercent = riskPercent;
        m_maxDrawdownPercent = maxDrawdownPercent;
        m_maxOpenPositions = maxOpenPositions;
    }
    
    // ゲッターメソッド
    double RiskPercent() const { return m_riskPercent; }
    double MaxDrawdownPercent() const { return m_maxDrawdownPercent; }
    int MaxOpenPositions() const { return m_maxOpenPositions; }
    bool IsValid() const { return m_isValid; }
    
    // 値オブジェクトは不変なので、変更時は新しいインスタンスを作成
    RiskParameters WithRiskPercent(double newRiskPercent) const
    {
        return RiskParameters(newRiskPercent, m_maxDrawdownPercent, m_maxOpenPositions);
    }
};
```

### 3.3 Core層 - インターフェースの実装

インターフェースは、外部レイヤーとのやり取りに使われるポートを定義します。

```mql5
// Include/MyCleanArchitecture/Core/UseCases/Interfaces/IMarketDataProvider.mqh
// 市場データプロバイダーのインターフェース
interface IMarketDataProvider
{
public:
    // 現在価格の取得
    virtual double GetCurrentPrice(string symbol, ENUM_APPLIED_PRICE priceType) = 0;
    
    // インジケーター値の取得
    virtual double GetIndicatorValue(string indicatorName, string symbol, ENUM_TIMEFRAMES timeframe, int shift) = 0;
    
    // オールージのデータを取得
    virtual void GetOHLCData(string symbol, ENUM_TIMEFRAMES timeframe, int count, datetime &time[], double &open[], 
                            double &high[], double &low[], double &close[], long &volume[]) = 0;
};
```

### 3.4 Core層 - ユースケースサービスの実装

ユースケースサービスは、アプリケーション固有のビジネスロジックを実装します。

```mql5
// Include/MyCleanArchitecture/Core/UseCases/Services/TradeExecutionService.mqh
#include "../../Core/Entities/Position.mqh"
#include "../../Core/ValueObjects/RiskParameters.mqh"
#include "../Interfaces/IOrderRepository.mqh"
#include "../Interfaces/IMarketDataProvider.mqh"

// トレード実行サービス
class TradeExecutionService
{
private:
    IOrderRepository *m_orderRepo;
    IMarketDataProvider *m_marketData;
    RiskParameters m_riskParams;
    
public:
    // コンストラクタでインターフェースを注入
    TradeExecutionService(IOrderRepository *orderRepo, IMarketDataProvider *marketData, const RiskParameters &riskParams)
        : m_orderRepo(orderRepo), m_marketData(marketData), m_riskParams(riskParams) {}
    
    // 新規ポジションのオープン
    bool OpenPosition(string symbol, ENUM_POSITION_TYPE type, double volume, double stopLoss, double takeProfit)
    {
        // リスク管理チェック
        if(!ValidateRiskParameters(symbol, type, volume, stopLoss))
            return false;
            
        // ポジション作成をリポジトリに依頼
        int ticket = m_orderRepo.CreatePosition(symbol, type, volume, stopLoss, takeProfit);
        return ticket > 0;
    }
    
    // リスク管理パラメーターのバリデーション
    bool ValidateRiskParameters(string symbol, ENUM_POSITION_TYPE type, double volume, double stopLoss)
    {
        // 現在の価格を取得
        double currentPrice = m_marketData.GetCurrentPrice(symbol, PRICE_CLOSE);
        
        // 既存ポジション数のチェック
        int openPositions = m_orderRepo.CountOpenPositions();
        if(openPositions >= m_riskParams.MaxOpenPositions())
            return false;
            
        // リスクパーセンテージの計算とチェック
        double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double potentialLoss = 0;
        
        if(type == POSITION_TYPE_BUY)
            potentialLoss = (currentPrice - stopLoss) * volume;
        else
            potentialLoss = (stopLoss - currentPrice) * volume;
            
        double riskPercent = (potentialLoss / accountBalance) * 100;
        
        return riskPercent <= m_riskParams.RiskPercent();
    }
};
```

### 3.5 Adapters層 - リポジトリの実装

リポジトリは、データアクセスの抽象化を提供します。

```mql5
// Include/MyCleanArchitecture/Adapters/Repositories/MT5OrderRepository.mqh
#include "../../Core/UseCases/Interfaces/IOrderRepository.mqh"
#include "../../Core/Entities/Position.mqh"

// MT5 APIを使用したポジション管理リポジトリ
class MT5OrderRepository : public IOrderRepository
{
private:
    int m_magicNumber;
    
public:
    MT5OrderRepository(int magicNumber) : m_magicNumber(magicNumber) {}
    
    // 新規ポジションの作成
    virtual int CreatePosition(string symbol, ENUM_POSITION_TYPE type, double volume, double stopLoss, double takeProfit) override
    {
        // MT5 APIを使って実際に注文を実行
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = symbol;
        request.volume = volume;
        request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        request.price = SymbolInfoDouble(symbol, (type == POSITION_TYPE_BUY) ? SYMBOL_ASK : SYMBOL_BID);
        request.sl = stopLoss;
        request.tp = takeProfit;
        request.magic = m_magicNumber;
        
        // フィリングモードの設定
        request.type_filling = ORDER_FILLING_IOC;
        
        if(!OrderSend(request, result))
        {
            // エラーハンドリング
            Print("OrderSend error: ", GetLastError());
            return 0;
        }
        
        return (int)result.order;
    }
    
    // オープンポジションの数を取得
    virtual int CountOpenPositions() override
    {
        int count = 0;
        
        for(int i = 0; i < PositionsTotal(); i++)
        {
            if(PositionSelectByTicket(PositionGetTicket(i)))
            {
                // 指定したマジックナンバーのポジションのみカウント
                if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
                {
                    count++;
                }
            }
        }
        
        return count;
    }
    
    // その他のメソッド実装...
};
```

### 3.6 Infrastructure層 - 外部連携の実装

インフラストラクチャ層は、外部システムとの連携を担当します。

```mql5
// Include/MyCleanArchitecture/Infrastructure/MT5/MT5MarketDataProvider.mqh
#include "../../Core/UseCases/Interfaces/IMarketDataProvider.mqh"

// MT5から市場データを提供するクラス
class MT5MarketDataProvider : public IMarketDataProvider
{
public:
    // 現在価格の取得
    virtual double GetCurrentPrice(string symbol, ENUM_APPLIED_PRICE priceType) override
    {
        if(priceType == PRICE_CLOSE)
            return SymbolInfoDouble(symbol, SYMBOL_LAST);
        else if(priceType == PRICE_ASK)
            return SymbolInfoDouble(symbol, SYMBOL_ASK);
        else if(priceType == PRICE_BID)
            return SymbolInfoDouble(symbol, SYMBOL_BID);
            
        // デフォルトはBID価格
        return SymbolInfoDouble(symbol, SYMBOL_BID);
    }
    
    // インジケーター値の取得
    virtual double GetIndicatorValue(string indicatorName, string symbol, ENUM_TIMEFRAMES timeframe, int shift) override
    {
        // ここでは単純化のために、MAを例としています
        if(indicatorName == "MA")
        {
            int maHandle = iMA(symbol, timeframe, 14, 0, MODE_SMA, PRICE_CLOSE);
            if(maHandle == INVALID_HANDLE)
                return 0;
                
            double maValue[];
            ArraySetAsSeries(maValue, true);
            
            if(CopyBuffer(maHandle, 0, shift, 1, maValue) > 0)
                return maValue[0];
        }
        
        return 0;
    }
    
    // OHLCデータの取得
    virtual void GetOHLCData(string symbol, ENUM_TIMEFRAMES timeframe, int count, datetime &time[], double &open[], 
                            double &high[], double &low[], double &close[], long &volume[]) override
    {
        ArraySetAsSeries(time, true);
        ArraySetAsSeries(open, true);
        ArraySetAsSeries(high, true);
        ArraySetAsSeries(low, true);
        ArraySetAsSeries(close, true);
        ArraySetAsSeries(volume, true);
        
        CopyTime(symbol, timeframe, 0, count, time);
        CopyOpen(symbol, timeframe, 0, count, open);
        CopyHigh(symbol, timeframe, 0, count, high);
        CopyLow(symbol, timeframe, 0, count, low);
        CopyClose(symbol, timeframe, 0, count, close);
        CopyTickVolume(symbol, timeframe, 0, count, volume);
    }
};
```

### 3.7 コントローラーの実装

コントローラーは、アプリケーションのエントリーポイントとなり、ユーザーとのやり取りを管理します。

```mql5
// Include/MyCleanArchitecture/Adapters/Controllers/TradeController.mqh
#include "../../Core/UseCases/Services/TradeExecutionService.mqh"
#include "../../Core/UseCases/EntryRules/IEntryRule.mqh"
#include "../../Core/UseCases/ExitRules/IExitRule.mqh"

// トレードコントローラー
class TradeController
{
private:
    TradeExecutionService *m_tradeService;
    IEntryRule *m_entryRule;
    IExitRule *m_exitRule;
    
public:
    // コンストラクタでサービスとルールを注入
    TradeController(TradeExecutionService *tradeService, IEntryRule *entryRule, IExitRule *exitRule)
        : m_tradeService(tradeService), m_entryRule(entryRule), m_exitRule(exitRule) {}
    
    // ティック更新時の処理
    void OnTick(string symbol)
    {
        // エントリールールのチェック
        if(m_entryRule.ShouldEnter(symbol))
        {
            // エントリールールから詳細を取得
            ENUM_POSITION_TYPE type = m_entryRule.GetEntryType();
            double volume = m_entryRule.GetVolume();
            double stopLoss = m_entryRule.GetStopLoss();
            double takeProfit = m_entryRule.GetTakeProfit();
            
            // ポジションをオープン
            m_tradeService.OpenPosition(symbol, type, volume, stopLoss, takeProfit);
        }
        
        // 決済ルールのチェック
        if(m_exitRule.ShouldExit(symbol))
        {
            // 決済処理は別途実装
        }
    }
};
```

### 3.8 メインEAファイルの実装

最後に、すべてを組み合わせたEAのエントリーポイントを実装します。

```mql5
// Experts/MyCleanEA/MyCleanEA.mq5
#include <MyCleanArchitecture/Core/ValueObjects/RiskParameters.mqh>
#include <MyCleanArchitecture/Core/UseCases/Services/TradeExecutionService.mqh>
#include <MyCleanArchitecture/Core/UseCases/EntryRules/MACrossEntryRule.mqh>
#include <MyCleanArchitecture/Core/UseCases/ExitRules/TrailingStopExitRule.mqh>
#include <MyCleanArchitecture/Adapters/Repositories/MT5OrderRepository.mqh>
#include <MyCleanArchitecture/Adapters/Controllers/TradeController.mqh>
#include <MyCleanArchitecture/Infrastructure/MT5/MT5MarketDataProvider.mqh>

// 入力パラメーター
input int MagicNumber = 123456;
input double RiskPercent = 2.0;
input double MaxDrawdownPercent = 20.0;
input int MaxOpenPositions = 5;
input int FastMA = 12;
input int SlowMA = 26;

// グローバル変数
TradeController *controller = NULL;

// 初期化関数
int OnInit()
{
    // 値オブジェクトの作成
    RiskParameters *riskParams = new RiskParameters(RiskPercent, MaxDrawdownPercent, MaxOpenPositions);
    
    // インフラストラクチャ層のオブジェクト作成
    MT5MarketDataProvider *marketData = new MT5MarketDataProvider();
    MT5OrderRepository *orderRepo = new MT5OrderRepository(MagicNumber);
    
    // ユースケース層のサービス作成
    TradeExecutionService *tradeService = new TradeExecutionService(orderRepo, marketData, riskParams);
    
    // エントリールールとエグジットルールの作成
    MACrossEntryRule *entryRule = new MACrossEntryRule(marketData, FastMA, SlowMA);
    TrailingStopExitRule *exitRule = new TrailingStopExitRule(marketData, 20); // 20ポイントのトレーリングストップ
    
    // コントローラーの作成
    controller = new TradeController(tradeService, entryRule, exitRule);
    
    return INIT_SUCCEEDED;
}

// ティック関数
void OnTick()
{
    if(controller != NULL)
    {
        controller.OnTick(_Symbol);
    }
}

// 終了関数
void OnDeinit(const int reason)
{
    // メモリ解放（逆順）
    if(controller != NULL)
    {
        delete controller;
        controller = NULL;
    }
}
```

## 4. メリットと注意点

### 4.1 クリーンアーキテクチャのメリット

1. **テスト容易性**
   - ビジネスロジックを外部依存から分離することで、単体テストが容易になります。
   - モックオブジェクトを使用して、MT5 APIなどの外部依存を置き換えることができます。

2. **保守性の向上**
   - 関心の分離により、コード変更の影響範囲が限定されます。
   - 各コンポーネントが明確な責任を持つため、コードが理解しやすくなります。

3. **拡張性**
   - 新しい戦略や機能を追加する際に、既存のコードを変更する必要が最小限になります。
   - インターフェースを実装することで、簡単に新しいコンポーネントを追加できます。

### 4.2 MQL5での実装における注意点

1. **パフォーマンス**
   - クリーンアーキテクチャは抽象化レイヤーを追加するため、オーバーヘッドが生じる可能性があります。
   - 特にOnTick関数内の処理など、パフォーマンスクリティカルな部分では注意が必要です。

2. **メモリ管理**
   - MQL5ではガベージコレクションがないため、動的に割り当てたオブジェクトは明示的に解放する必要があります。
   - OnDeinit関数での適切なメモリ解放が重要です。

3. **依存関係の注入**
   - MQL5には依存関係注入フレームワークがないため、手動で実装する必要があります。
   - コンストラクタインジェクションが最も簡単なアプローチです。

## 5. まとめ

クリーンアーキテクチャはMQL5開発において、保守性、テスト容易性、拡張性を大幅に向上させることができます。コードの構造化と依存関係の明確化により、長期的なプロジェクト管理が容易になります。初期の学習コストと実装の複雑さはありますが、中長期的には大きなメリットをもたらすでしょう。

特に複雑なEAや長期間メンテナンスする必要があるプロジェクトでは、クリーンアーキテクチャの採用を検討する価値があります。 