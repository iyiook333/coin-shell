// pages/ReportPage.ets

import promptAction from '@ohos.promptAction';
import HttpUtil from '../common/utils/HttpUtil';
import emitter from '@ohos.events.emitter';
import { REFRESH_FLOW_EVENT } from '../common/constants/EventConstants';
// ========== 接口定义 ==========
interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T;
}

interface OverviewData {
  totalIncome: number;
  totalExpense: number;
  balance: number;
}

interface CategoryStat {
  category: string;
  amount: number;
  percent: number;
}

interface TrendData {
  date: string;
  income: number;
  expense: number;
}

// ========== 颜色映射 ==========
const CATEGORY_COLORS: Record<string, string> = {
  '餐饮': '#FF6B6B',
  '交通': '#FFB800',
  '购物': '#66BB6A',
  '娱乐': '#AB47BC',
  '住房': '#1976D2',
  '通讯': '#26C6DA',
  '医疗': '#EF5350',
  '教育': '#42A5F5',
  '工资': '#4CAF50',
  '兼职': '#8D6E63',
  '理财': '#FFA726',
  '红包': '#EC407A',
  '其他': '#90A4AE'
};

// ========== 组件 ==========
@Component
export struct ReportPage {
  @State isLoading: boolean = true;
  @State totalIncome: number = 0;
  @State totalExpense: number = 0;
  @State balance: number = 0;
  @State categoryList: CategoryStat[] = [];
  @State trendList: TrendData[] = [];
  @State currentMonth: string = '';

  aboutToAppear() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    this.currentMonth = `${year}-${month}`;
    this.loadData();
    emitter.on(REFRESH_FLOW_EVENT, () => {
      this.loadData();
    });
  }
  aboutToDisappear(): void {
    emitter.off(REFRESH_FLOW_EVENT);
  }
  async loadData() {
    this.isLoading = true;
    try {
      const overviewRes = await HttpUtil.get<ApiResponse<OverviewData>>(
        getContext(),
        `/account/statistics/overview?month=${this.currentMonth}`
      );
      const categoryRes = await HttpUtil.get<ApiResponse<CategoryStat[]>>(
        getContext(),
        `/account/statistics/category?month=${this.currentMonth}`
      );
      const trendRes = await HttpUtil.get<ApiResponse<TrendData[]>>(
        getContext(),
        '/account/statistics/trend'
      );

      if (overviewRes.code === 200 && overviewRes.data) {
        this.totalIncome = overviewRes.data.totalIncome || 0;
        this.totalExpense = overviewRes.data.totalExpense || 0;
        this.balance = overviewRes.data.balance || 0;
      }
      if (categoryRes.code === 200 && categoryRes.data) {
        this.categoryList = categoryRes.data;
      }
      if (trendRes.code === 200 && trendRes.data) {
        this.trendList = trendRes.data;
      }
    } catch (e) {
      console.error('加载报表数据异常：' + JSON.stringify(e));
      promptAction.showToast({ message: '加载报表失败' });
    } finally {
      this.isLoading = false;
    }
  }

  private getCategoryColor(category: string): string {
    return CATEGORY_COLORS[category] || '#90A4AE';
  }

  private getMaxVal(): number {
    let max = 0;
    for (let i = 0; i < this.trendList.length; i++) {
      const item = this.trendList[i];
      const val = item.income > item.expense ? item.income : item.expense;
      if (val > max) max = val;
    }
    return max || 1;
  }

  private getBarHeight(value: number): number {
    const max = this.getMaxVal();
    if (max === 0) return 0;
    return Math.round((value / max) * 100);
  }

  // ========== 仅修改 build 中的布局结构，保留所有逻辑不变 ==========
  build() {
    Column() {
      // ===== 固定标题栏（与 EarnPage 风格一致） =====
      Row() {
        Blank()   // 左侧留空，保持标题居中
          .width('45%')
        Text('报表')   // 去掉 emoji
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()   // 右侧留空，但放置月份显示（仅文本，无交互）
        Text(this.currentMonth)
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ bottomLeft: 12, bottomRight: 12 })

      // ===== 滚动内容区域 =====
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#FF7A00')
          Text('加载中...').fontSize(14).fontColor('#999999').margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            // ===== 1. 收支概览（合并为一个卡片，内部三列） =====
            Row() {
              Column({ space: 2 }) {
                Text('总收入')
                  .fontSize(12)
                  .fontColor('#999999')
                Text(`¥${this.totalIncome.toFixed(2)}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#66BB6A')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              Column({ space: 2 }) {
                Text('总支出')
                  .fontSize(12)
                  .fontColor('#999999')
                Text(`¥${this.totalExpense.toFixed(2)}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#EF5350')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              Column({ space: 2 }) {
                Text('结余')
                  .fontSize(12)
                  .fontColor('#999999')
                Text(`¥${this.balance.toFixed(2)}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1976D2')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            // 父容器已有左右 padding，无需额外 margin

            // ===== 2. 分类支出占比 =====
            Column({ space: 12 }) {
              Text('分类支出占比')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .width('100%')
                .padding({ left: 4 })

              if (this.categoryList.length === 0) {
                Text('暂无支出数据')
                  .fontSize(14)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 20, bottom: 20 })
              } else {
                ForEach(this.categoryList, (item: CategoryStat) => {
                  Column({ space: 6 }) {
                    Row() {
                      Row({ space: 8 }) {
                        Circle()
                          .width(10)
                          .height(10)
                          .fill(this.getCategoryColor(item.category))
                        Text(item.category)
                          .fontSize(13)
                          .fontColor('#666666')
                      }
                      .layoutWeight(1)

                      Text(`¥${item.amount.toFixed(2)}  ${item.percent}%`)
                        .fontSize(13)
                        .fontColor('#333333')
                    }
                    .width('100%')

                    Stack({ alignContent: Alignment.Start }) {
                      Row()
                        .width('100%')
                        .height(8)
                        .backgroundColor('#F0F0F0')
                        .borderRadius(4)

                      Row()
                        .width(`${item.percent}%`)
                        .height(8)
                        .backgroundColor(this.getCategoryColor(item.category))
                        .borderRadius(4)
                    }
                    .width('100%')
                  }
                  .width('100%')
                }, (item: CategoryStat) => item.category)
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            // ===== 3. 近7天收入趋势 =====
            Column({ space: 8 }) {
              Text('近7天收入趋势')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .width('100%')
                .padding({ left: 4 })

              if (this.trendList.length === 0 || this.trendList.every(item => item.income === 0)) {
                Text('暂无收入数据')
                  .fontSize(14)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 20, bottom: 20 })
              } else {
                Row({ space: 6 }) {
                  ForEach(this.trendList, (item: TrendData) => {
                    Column() {
                      Column() {
                        Row()
                          .width(20)
                          .height(this.getBarHeight(item.income))
                          .backgroundColor('#66BB6A')
                          .borderRadius({ topLeft: 3, topRight: 3 })
                      }
                      .justifyContent(FlexAlign.End)
                      .height(120)
                      .width(20)
                      .backgroundColor('#F5F5F5')
                      .borderRadius(3)

                      Text(item.date)
                        .fontSize(10)
                        .fontColor('#999999')
                        .margin({ top: 6 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                  }, (item: TrendData) => item.date)
                }
                .width('100%')
                .padding({ top: 8 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            // ===== 4. 近7天支出趋势 =====
            Column({ space: 8 }) {
              Text('近7天支出趋势')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .width('100%')
                .padding({ left: 4 })

              if (this.trendList.length === 0 || this.trendList.every(item => item.expense === 0)) {
                Text('暂无支出数据')
                  .fontSize(14)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 20, bottom: 20 })
              } else {
                Row({ space: 6 }) {
                  ForEach(this.trendList, (item: TrendData) => {
                    Column() {
                      Column() {
                        Row()
                          .width(20)
                          .height(this.getBarHeight(item.expense))
                          .backgroundColor('#EF5350')
                          .borderRadius({ topLeft: 3, topRight: 3 })
                      }
                      .justifyContent(FlexAlign.End)
                      .height(120)
                      .width(20)
                      .backgroundColor('#F5F5F5')
                      .borderRadius(3)

                      Text(item.date)
                        .fontSize(10)
                        .fontColor('#999999')
                        .margin({ top: 6 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                  }, (item: TrendData) => item.date)
                }
                .width('100%')
                .padding({ top: 8 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            Blank().height(8)   // 底部留白
          }
          .margin({top:15})
          .width('100%')
          .padding({ left: 10, right: 10 })   // 统一左右边距
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .backgroundColor('#F8F6F0')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F6F0')
    // 移除原外部 padding(5)，由内部控制
  }
}