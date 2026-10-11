// pages/CashExchangePage.ets
import promptAction from '@ohos.promptAction';
import HttpUtil from '../common/utils/HttpUtil';

interface ApiResponse<T> { code: number; msg: string; data: T; }

interface CashExchangeParams {
  cashBalance?: number;
}

interface ExchangeResponse {
  newCash: number;
}

interface ExchangeRequest {
  amount: number;
}

@Component
export struct CashExchangePage {
  @Consume('NavPathStack') navPathStack: NavPathStack;
  @State cashBalance: number = 0;
  @State selectedAmount: number = 0;
  @State isExchanging: boolean = false;

  async aboutToAppear() {
    const cashRes = await HttpUtil.get<ApiResponse<number>>(getContext(), '/coin/cash');
    if (cashRes.code === 200) {
      this.cashBalance = cashRes.data || 0;
    }
  }

  async exchange(amount: number) {
    if (this.isExchanging) return;
    if (this.cashBalance < amount) {
      promptAction.showToast({ message: '余额不足，请先赚取更多金币' });
      return;
    }
    this.isExchanging = true;
    try {
      const requestBody: ExchangeRequest = { amount };
      const res = await HttpUtil.post<ApiResponse<ExchangeResponse>>(
        getContext(),
        '/cash/exchange',
        requestBody
      );
      if (res.code === 200 && res.data) {
        const newCashRes = await HttpUtil.get<ApiResponse<number>>(getContext(), '/coin/cash');
        if (newCashRes.code === 200) {
          this.cashBalance = newCashRes.data || 0;
        }
        promptAction.showToast({ message: `兑换成功！获得 ¥${amount}` });
      } else {
        promptAction.showToast({ message: res.msg || '兑换失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络异常，请重试' });
    } finally {
      this.isExchanging = false;
    }
  }

  build() {
    NavDestination() {
      Column() {

        Scroll() {
          Column({ space: 20 }) {
            // ===== 可兑换余额 =====
            Column({ space: 4 }) {
              Text('可兑换现金')
                .fontSize(14)
                .fontColor('#999')
              Text(`¥${this.cashBalance.toFixed(2)}`)
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF7A00')
            }
            .width('100%')
            .padding(24)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ left: 16, right: 16, top: 16 })

            // ===== 兑换额度 =====
            Column({ space: 12 }) {
              Text('选择兑换金额')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333')
                .width('100%')
                .padding({ left: 4 })

              Row({ space: 12 }) {
                this.ExchangeButton(1)
                this.ExchangeButton(15)
                this.ExchangeButton(30)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceEvenly)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ left: 16, right: 16 })

            // ===== 提示 =====
            Text('100金币 = 1元 · 每日限兑30元')
              .fontSize(12)
              .fontColor('#999')
              .width('100%')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 30 })
        }
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .backgroundColor('#F8F6F0')
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F6F0')
    }
    .title('现金兑换')
  }

  @Builder
  ExchangeButton(amount: number) {
    Button(`¥${amount}`)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.selectedAmount === amount ? '#FFFFFF' : '#FF7A00')
      .backgroundColor(this.selectedAmount === amount ? '#FF7A00' : '#FFF0E6')
      .borderRadius(12)
      .padding({ left: 28, right: 28, top: 14, bottom: 14 })
      .onClick(() => {
        if (this.isExchanging) return;
        this.selectedAmount = amount;
        this.exchange(amount);
      })
      .enabled(!this.isExchanging && this.cashBalance >= amount)
      .opacity(this.cashBalance < amount ? 0.4 : 1)
  }
}