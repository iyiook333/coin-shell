// pages/EarningsPage.ets
import promptAction from '@ohos.promptAction';
import HttpUtil from '../common/utils/HttpUtil';

interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T;
}

interface EarningsDetail {
  id: number;
  type: 'income' | 'expense';
  category: string;
  amount: number;
  desc: string;
  createTime: string;
}

interface ExchangeRequest {
  amount: number;
}

interface ExchangeResponse {
  newCash: number;
  newCoin: number;
}

interface CashExchangeParams {
  cashBalance: number;
}

@Component
export struct EarningsPage {
  @Consume('NavPathStack') navPathStack: NavPathStack;
  @State coinBalance: number = 0;
  @State cashBalance: number = 0;
  @State detailList: EarningsDetail[] = [];
  @State isLoading: boolean = true;
  @State isListLoading: boolean = false;  // 分离列表加载状态
  @State isExchanging: boolean = false;
  @State currentTab: 'coin' | 'cash' = 'coin';

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const coinRes = await HttpUtil.get<ApiResponse<number>>(getContext(), '/coin/balance');
      if (coinRes.code === 200) {
        this.coinBalance = coinRes.data || 0;
      }
      const cashRes = await HttpUtil.get<ApiResponse<number>>(getContext(), '/coin/cash');
      if (cashRes.code === 200) {
        this.cashBalance = cashRes.data || 0;
      }
      await this.fetchDetailList();
    } catch (e) {
      promptAction.showToast({ message: '加载收益数据失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async fetchDetailList() {
    this.isListLoading = true;  // ✅ 只控制列表区域
    try {
      const res = await HttpUtil.get<ApiResponse<EarningsDetail[]>>(
        getContext(),
        `/earnings/list?type=${this.currentTab}`
      );
      if (res.code === 200 && res.data) {
        this.detailList = res.data;
      }
    } catch (e) {
      promptAction.showToast({ message: '加载明细失败' });
    } finally {
      this.isListLoading = false;
    }
  }

  switchTab(tab: 'coin' | 'cash') {
    if (this.currentTab === tab) return;
    this.currentTab = tab;
    // ✅ 不再控制整个页面 loading，只刷新列表
    this.fetchDetailList();
  }

  async exchangeCoinToCash() {
    if (this.isExchanging) return;
    if (this.coinBalance < 100) {
      promptAction.showToast({ message: '金币不足100，无法兑换' });
      return;
    }
    this.isExchanging = true;
    try {
      const requestBody: ExchangeRequest = { amount: 1 };
      const res = await HttpUtil.post<ApiResponse<ExchangeResponse>>(
        getContext(),
        '/cash/exchange',
        requestBody
      );
      if (res.code === 200 && res.data) {
        this.coinBalance = res.data.newCoin;
        this.cashBalance = res.data.newCash;
        promptAction.showToast({ message: '兑换成功！获得 ¥1.00' });
        await this.loadData();
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
        // ===== 首次加载 =====
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40).color('#FF7A00')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: 12 }) {
              // ===== 双余额卡片 =====
              Row({ space: 12 }) {
                Column() {
                  Row() {
                    Column({ space: 2 }) {
                      Text('🪙 金币')
                        .fontSize(13)
                        .fontColor('#999')
                      Text(`${this.coinBalance}`)
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FF7A00')
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Button('换现金')
                      .fontSize(12)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#FF7A00')
                      .borderRadius(14)
                      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                      .onClick(() => {
                        this.exchangeCoinToCash();
                      })
                      .enabled(!this.isExchanging)
                  }
                  .width('100%')
                }
                .layoutWeight(1)
                .padding({ top: 14, bottom: 14, left: 14, right: 12 })
                .backgroundColor('#FFF8F0')
                .borderRadius(12)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Row() {
                    Column({ space: 2 }) {
                      Text('💰 现金')
                        .fontSize(13)
                        .fontColor('#999')
                      Text(`¥${this.cashBalance.toFixed(2)}`)
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#1976D2')
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Button('去兑换')
                      .fontSize(12)
                      .fontColor('#1976D2')
                      .backgroundColor('#E3F2FD')
                      .borderRadius(14)
                      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                      .onClick(() => {
                        const params: CashExchangeParams = { cashBalance: this.cashBalance };
                        this.navPathStack.pushPathByName('CashExchangePage', params);
                      })
                  }
                  .width('100%')
                }
                .layoutWeight(1)
                .padding({ top: 14, bottom: 14, left: 14, right: 12 })
                .backgroundColor('#F0F7FF')
                .borderRadius(12)
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .padding({ left: 16, right: 16 })
              .margin({ top: 16 })

              // ===== 明细卡片 =====
              Column({ space: 12 }) {
                // Tab 切换
                Row({ space: 0 }) {
                  this.TabItem('金币明细', 'coin')
                  this.TabItem('现金明细', 'cash')
                }
                .width('100%')
                .height(40)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .padding(4)

                // ===== 列表区域（带加载状态） =====
                if (this.isListLoading) {
                  // ✅ 列表加载中：显示 Loading 占位
                  Column() {
                    LoadingProgress().width(30).height(30).color('#FF7A00')
                    Text('加载中...')
                      .fontSize(12)
                      .fontColor('#999')
                      .margin({ top: 8 })
                  }
                  .width('100%')
                  .padding(30)
                  .alignItems(HorizontalAlign.Center)
                } else if (this.detailList.length === 0) {
                  Text('暂无记录')
                    .fontSize(14)
                    .fontColor('#999')
                    .padding(30)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                } else {
                  ForEach(this.detailList, (item: EarningsDetail) => {
                    Row() {
                      Column({ space: 2 }) {
                        Text(item.desc)
                          .fontSize(14)
                          .fontColor('#333')
                        Text(item.createTime)
                          .fontSize(11)
                          .fontColor('#999')
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Text(`${item.type === 'income' ? '+' : '-'}${item.amount.toFixed(2)}`)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(item.type === 'income' ? '#4CAF50' : '#EF5350')
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10, left: 14, right: 14 })
                    .backgroundColor('#FAFAFA')
                    .borderRadius(12)
                  }, (item: EarningsDetail) => item.id.toString())
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .margin({ left: 16, right: 16 })

              Blank().height(20)
            }
            .width('100%')
            .padding({ bottom: 10 })
          }
          .align(Alignment.TopStart)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .backgroundColor('#F8F6F0')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F6F0')
      .justifyContent(FlexAlign.Start)
    }
    .title('我的收益')
  }

  @Builder
  TabItem(title: string, tab: 'coin' | 'cash') {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(this.currentTab === tab ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTab === tab ? '#FFFFFF' : '#666666')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(6)
    .backgroundColor(this.currentTab === tab ? '#FF7A00' : 'transparent')
    .onClick(() => {
      this.switchTab(tab);
    })
  }
}