// pages/EarnPage.ets

import promptAction from '@ohos.promptAction';
import HttpUtil from '../common/utils/HttpUtil';

// ========== 接口定义 ==========
interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T;
}
interface CashExchangeParams {
  cashBalance: number;
}
interface SignInfo {
  month: string;        // 当前月份，如 "2026-08"
  monthDays: number;    // 本月已签到天数
  todaySigned: boolean; // 今日是否已签到
  coin: number;         // 今日签到可获得金币数（随机1-10）
}
interface EarningsParams {
  type: 'coin' | 'cash';
}
interface FlashInfo {
  grabbed: boolean;       // 今日是否已抢到
  remaining: number;      // 剩余名额
  isActive: boolean;      // 是否在活动时间段内
  startTime: string;      // 活动开始时间
  endTime: string;        // 活动结束时间
}
interface TaskItem {
  icon: string;
  name: string;
  desc: string;
  btnText: string;
  isSignTask?: boolean;  // 标记是否为签到任务
}

interface EmptyRequest {}

// ========== 组件 ==========
@Component
export struct EarnPage {
  @Consume('NavPathStack') navPathStack: NavPathStack;
  @State cashBalance: number = 0
  @State coinBalance: number = 0;
  @State signInfo: SignInfo = {
    month: '2026-08',
    monthDays: 0,
    todaySigned: false,
    coin: 0
  };
  @State isLoading: boolean = true;
  @State flashInfo: FlashInfo = {
    grabbed: false,
    remaining: 500,
    isActive: false,
    startTime: '10:00',
    endTime: '11:00'
  };
  @State isGrabbing: boolean = false;
  //  签到任务放在任务列表第一位
  @State taskList: TaskItem[] = [
    {
      icon: '📆',
      name: '签到得金币',
      desc: '第 1/14 天 · 今日随机 1-10 金币',
      btnText: '去签到',
      isSignTask: true
    },
    {
      icon: '⚡',
      name: '限时领金币',
      desc: '每日10:00后领金币，前200名立得大额金币',
      btnText: '立马领'
    },
    { icon: '📺', name: '看广告', desc: '看 30s 广告领金币', btnText: '赚金币' },
    { icon: '📝', name: '今日首次记账', desc: '记一笔账得金币', btnText: '赚金币' },
    { icon: '🍱', name: '饭店领饭补', desc: '填写工作餐信息', btnText: '赚金币' },
    { icon: '👥', name: '邀请好友', desc: '邀请新用户注册', btnText: '赚金币' },
    { icon: '📰', name: '浏览资讯', desc: '浏览 3 条资讯', btnText: '赚金币' },
  { icon: '📤', name: '每日分享', desc: '分享给好友或朋友圈', btnText: '赚金币' },
{ icon: '📖', name: '阅读文章', desc: '阅读 1 篇精选内容', btnText: '赚金币' },
{ icon: '📋', name: '完成问卷', desc: '参与用户调研问卷', btnText: '赚金币' }
  ];

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const res = await HttpUtil.get<ApiResponse<SignInfo>>(
        getContext(),
        '/sign/info'
      );
      if (res.code === 200 && res.data) {
        this.signInfo = res.data;
      }
      else {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        this.signInfo = {
          month: `${year}-${month}`,
          monthDays: 0,
          todaySigned: false,
          coin: 0
        };
      }
      this.updateSignTask();
      const coinRes = await HttpUtil.get<ApiResponse<number>>(
        getContext(),
        '/coin/balance'
      );
      if (coinRes.code === 200) {
        this.coinBalance = coinRes.data || 0;
      }
      const flashRes = await HttpUtil.get<ApiResponse<FlashInfo>>(
        getContext(),
        '/flash/status'
      );
      const cashRes = await HttpUtil.get<ApiResponse<number>>(getContext(), '/coin/cash');
      if (cashRes.code === 200) {
        // 注意：现金余额以元为单位，可能是小数，后端返回 BigDecimal 转为 number
        this.cashBalance = cashRes.data || 0;
      }
      if (flashRes.code === 200 && flashRes.data) {
        this.flashInfo = flashRes.data;
      }
      else {
        // 兜底默认值
        this.flashInfo = {
          grabbed: false,
          remaining: 200,
          isActive: false,
          startTime: '10:00',
          endTime: '11:00'
        };
      }
      this.updateFlashTask();
    } catch (e) {
      console.error('加载数据失败', e);
    } finally {
      this.isLoading = false;
    }
  }
  // 更新限时领任务的状态
  private updateFlashTask() {
    const flashTask = this.taskList.find(t => t.name === '限时领金币');
    if (!flashTask) return;

    if (!this.flashInfo.isActive) {
      flashTask.desc = `⏳ 每日 ${this.flashInfo.startTime} 开放领取`;
      flashTask.btnText = '未开始';
    } else if (this.flashInfo.grabbed) {
      flashTask.desc = `✅ 已领取！大额金币已到账 🎉`;
      flashTask.btnText = '已领';
    } else if (this.flashInfo.remaining <= 0) {
      flashTask.desc = `😅 今日名额已领完，明天早点来`;
      flashTask.btnText = '已领完';
    } else {
      flashTask.desc = `🔥 剩余 ${this.flashInfo.remaining} 个名额，手慢无！`;
      flashTask.btnText = '立马领';
    }
    this.taskList = [...this.taskList];
  }
  // 处理限时领
  async handleFlashGrab() {
    if (this.isGrabbing) return;
    if (this.flashInfo.grabbed) {
      promptAction.showToast({ message: '今日已领取，明天再来吧' });
      return;
    }
    if (!this.flashInfo.isActive) {
      promptAction.showToast({ message: `活动未开始，请于 ${this.flashInfo.startTime} 后参与` });
      return;
    }
    if (this.flashInfo.remaining <= 0) {
      promptAction.showToast({ message: '名额已领完，明天再来吧' });
      return;
    }

    this.isGrabbing = true;
    try {
      const res = await HttpUtil.post<ApiResponse<FlashInfo>>(
        getContext(),
        '/flash/grab',
        {} as EmptyRequest
      );
      if (res.code === 200 && res.data) {
        this.flashInfo = res.data;
        this.updateFlashTask();
        // 刷新金币余额
        const coinRes = await HttpUtil.get<ApiResponse<number>>(
          getContext(),
          '/coin/balance'
        );
        if (coinRes.code === 200) {
          this.coinBalance = coinRes.data || 0;
        }
        promptAction.showToast({ message: `🎉 领取成功！剩余 ${res.data.remaining} 个名额` });
      } else {
        promptAction.showToast({ message: res.msg || '领取失败，请重试' });
      }
    } catch (e) {
      console.error('限时领异常', e);
      promptAction.showToast({ message: '领取失败，请重试' });
    } finally {
      this.isGrabbing = false;
    }
  }
  private updateSignTask() {
    const signTask = this.taskList.find(t => t.isSignTask === true);
    if (signTask) {
      if (this.signInfo.todaySigned) {
        signTask.desc = `本月已签到 ${this.signInfo.monthDays} 天 🎉`;
        signTask.btnText = '已签到';
      } else {
        const parts = this.signInfo.month.split('-');
        const year = parts[0];
        const month = parts[1];
        signTask.desc = `${year}年${parseInt(month)}月 · 已签到 ${this.signInfo.monthDays} 天`;
        signTask.btnText = '签到';
      }
    }
  }
  async handleSignIn() {
    if (this.signInfo.todaySigned) {
      promptAction.showToast({ message: '今日已签到' });
      return;
    }
    try {
      const res = await HttpUtil.post<ApiResponse<SignInfo>>(
        getContext(),
        '/sign/in',
        {} as EmptyRequest
      );
      if (res.code === 200 && res.data) {
        this.signInfo = res.data;
        this.updateSignTask();
        this.taskList = [...this.taskList];
        const coinRes = await HttpUtil.get<ApiResponse<number>>(
          getContext(),
          '/coin/balance'
        );
        if (coinRes.code === 200) {
          this.coinBalance = coinRes.data || 0;
        }
        promptAction.showToast({ message: `签到成功！获得 ${res.data.coin} 金币` });
      } else {
        promptAction.showToast({ message: res.msg || '签到失败' });
      }
    } catch (e) {
      console.error('签到异常', e);
      promptAction.showToast({ message: '签到失败，请重试' });
    }
  }

  private handleTaskClick(task: TaskItem) {
    if (task.isSignTask) {
      this.handleSignIn();
      return;
    }
    if (task.name === '限时领金币') {
      this.handleFlashGrab();
      return;
    }
    promptAction.showToast({ message: `${task.name} 功能开发中` });
  }

  // ===== 构建 =====
  build() {
    NavDestination() {
      Column() {
        // ===== 标题栏（固定，不滚动） =====
        Row() {
          Blank()
            .width("40%")
          Text('任务中心')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Blank()

          Text('规则')
            .fontSize(14)
            .fontColor('#FF7A00')
            .onClick(() => {
              promptAction.showToast({ message: '签到规则：自然月内每天可签到一次，每月1日重置签到天数' });
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .borderRadius({ bottomLeft: 12, bottomRight: 12 })

        // ===== 滚动区域 =====
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40).color('#FF7A00')
            Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: 12 }) {
              // ===== 1. 金币卡片 =====
              this.CoinCard()

              // ===== 2. 每日任务（含签到） =====
              this.DailyTasks()

            }
            .margin({top:15})
            .width('100%')
            .padding({left:10,right:10})
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
    .title('')
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }

  // ===== 金币卡片 =====
  @Builder
  CoinCard() {
    Row() {
      Column({ space: 2 }) {
        Text('🪙')
          .fontSize(22)
        Text(`${this.coinBalance}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text('金币')
          .fontSize(11)
          .fontColor('#999')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        const params: EarningsParams = { type: 'coin' };
        this.navPathStack.pushPathByName('EarningsPage', params);
      })
      Column({ space: 2 }) {
        Text('💰')
          .fontSize(22)
        Text(`${this.cashBalance.toFixed(2)}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text('现金 (元)')
          .fontSize(11)
          .fontColor('#999')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        const params: EarningsParams = { type: 'cash' };
        this.navPathStack.pushPathByName('EarningsPage',params);
      })
      Column() {
        Button('换现金')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF7A00')
          .borderRadius(18)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .onClick(() => {
            const params: CashExchangeParams = { cashBalance: this.coinBalance / 100 };
            this.navPathStack.pushPathByName('CashExchangePage', params);
          })
      }
      .layoutWeight(0.8)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16, left: 20, right: 20 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16 })
  }

  // ===== 每日任务（含签到） =====
  @Builder
  DailyTasks() {
    Column() {
      Text('📋 每日任务')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333')
        .width('100%')
        .padding({ left: 4, bottom: 8 })

      ForEach(this.taskList, (task: TaskItem) => {
        Row() {
          Text(task.icon)
            .fontSize(20)
            .margin({ right: 10 })

          Column({ space: 2 }) {
            Text(task.name)
              .fontSize(14)
              .fontColor('#333')
            Text(task.desc)
              .fontSize(12)
              .fontColor('#999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 统一按钮样式（签到和赚金币风格一致）
          Button(task.btnText)
            .fontSize(12)
            .fontColor(task.isSignTask && this.signInfo.todaySigned ? '#999999' : '#FF7A00')
            .backgroundColor(task.isSignTask && this.signInfo.todaySigned ? '#F5F5F5' : '#FFF0E6')
            .borderRadius(14)
            .padding({ left: 14, right: 14, top: 4, bottom: 4 })
            .enabled(!(task.isSignTask && this.signInfo.todaySigned))
            .onClick(() => {
              this.handleTaskClick(task);
            })
        }
        .width('100%')
        .padding({ top: 10, bottom: 10, left: 14, right: 14 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ bottom: 6 })
      }, (task: TaskItem) => task.name)
    }
    .width('100%')
    .padding(16)
    .margin({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}