// pages/FlowPage.ets

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

interface AccountItem {
  id: number;
  amount: number;
  type: number;
  category: string;
  note: string;
  accountTime: string;
}

interface PageResult {
  records: AccountItem[];
  total: number;
  size: number;
  current: number;
  pages: number;
}

// ========== 组件 ==========
@Component
export struct FlowPage {
  @Consume('NavPathStack') navPathStack: NavPathStack;

  @State flowList: AccountItem[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear(): Promise<void> {
    await this.loadData();
    emitter.on(REFRESH_FLOW_EVENT, () => {
      this.loadData();
    });
  }
  aboutToDisappear(): void {
    emitter.off(REFRESH_FLOW_EVENT);
  }
  private showDeleteDialog(item: AccountItem): void {
    promptAction.showDialog({
      title: '确认删除',
      message: `确定要删除这条 ${item.category} 记录吗？`,
      buttons: [
        {
          text: '取消',
          color: '#999999'
        },
        {
          text: '删除',
          color: '#FF4D4F'
        }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.deleteAccount(item);
      }
    });
  }

  private async deleteAccount(item: AccountItem): Promise<void> {
    try {
      const res = await HttpUtil.delete<ApiResponse<string>>(
        getContext(),
        `/account/delete/${item.id}`
      );

      if (res.code === 200) {
        promptAction.showToast({ message: '已删除' });
        emitter.emit(REFRESH_FLOW_EVENT)
        // 删除成功后刷新列表（重新加载）
        await this.loadData();
      } else {
        promptAction.showToast({ message: res.msg || '删除失败' });
      }
    } catch (e) {
      console.error('删除异常：' + JSON.stringify(e));
      promptAction.showToast({ message: '删除失败，请重试' });
    }
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const res: ApiResponse<PageResult> = await HttpUtil.get<ApiResponse<PageResult>>(
        getContext(),
        '/account/page?page=1&size=20'
      );
      if (res.code === 200 && res.data) {
        this.flowList = res.data.records;
      } else {
        promptAction.showToast({ message: res.msg || '加载失败' });
      }
    } catch (e) {
      console.error('加载流水异常：' + JSON.stringify(e));
      promptAction.showToast({ message: '网络请求失败' });
    } finally {
      this.isLoading = false;

    }
  }

  build() {
    Column() {
      // ===== 顶部标题栏 =====
      Row() {
        Row({ space: 8 }) {
          Image($r('app.media.startIcon'))
            .width(28)
            .height(28)
            .fillColor('#FF7A00')
          Text('AI助手')
            .fontSize(16)
            .fontColor('#FF7A00')
            .fontWeight(FontWeight.Medium)
        }
        .onClick(() => {
          this.navPathStack.pushPathByName('AIAssistantPage', null);
        })
        Blank()
          .width(76)
        Text('流水')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // ===== 内容区域 =====
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#FF7A00')
          Text('加载中...').fontSize(14).fontColor('#999999').margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.flowList.length === 0) {
        Column() {
          Text('📭').fontSize(48)
          Text('暂无记录').fontSize(16).fontColor('#999999').margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.flowList, (item: AccountItem) => {
              Row() {
                Stack() {
                  Circle()
                    .width(40)
                    .height(40)
                    .fill('#F0F0F0')
                  Text(item.category.charAt(0))
                    .fontSize(18)
                    .fontColor('#666')
                }

                Column({ space: 2 }) {
                  Text(item.category)
                    .fontSize(15)
                    .fontColor('#333333')
                  Text(item.note || '无备注')
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 })

                Text(`${item.type === 1 ? '+' : '-'}¥${item.amount.toFixed(2)}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(item.type === 1 ? '#4CAF50' : '#FF4D4F')
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 8 })
              .onClick(() => {
                this.showDeleteDialog(item);
              })
            }, (item: AccountItem) => item.id.toString())
          }
          .width('100%')
          .padding({ left: 16, right: 16 ,top:10})
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .backgroundColor('#F8F6F0')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F6F0')
  }
}