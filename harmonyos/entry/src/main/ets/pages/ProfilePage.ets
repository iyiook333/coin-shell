// pages/ProfilePage.ets

import { preferences } from "@kit.ArkData";
import { router } from "@kit.ArkUI";
import HttpUtil from "../common/utils/HttpUtil";

interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T;
}

interface MenuItem {
  name: string;
  url:Resource
}
interface UserInfo {
  id: number;
  phone: string;
  username: string;
}

interface UserStats {
  totalEarnings: number;      // 累计收益（元）
  completedTasks: number;     // 完成任务数
  consecutiveSignIns: number; // 连续签到天数
}

interface EmptyRequest {}

@Component
export struct ProfilePage {
  @State userInfo: UserInfo = { id: 0, phone: '', username: '' };
  @State totalEarnings: number = 0;
  @State completedTasks: number = 0;
  @State consecutiveSignIns: number = 0;
  @State isLoading: boolean = true;

  private menuList: MenuItem[] = [
    { name: '账户安全' ,url:$r('app.media.hnksanquan')},
    { name: '消息通知' ,url:$r('app.media.yonghuzhongxinxiaoxitongzhi')},
    { name: '帮助反馈' ,url:$r('app.media.tubiaoyibangzhufankuix')},
    { name: '关于我们',url:$r('app.media.weibiaoti') },
    { name: '设置' ,url:$r('app.media.ashezhishucaidanshezhi')}
  ];

  aboutToAppear() {
    this.loadAllData();
  }

  async loadAllData() {
    this.isLoading = true;
    try {
      await Promise.all([
        this.loadUserInfo(),
        this.loadUserStats()
      ]);
    } catch (e) {
      console.error('加载个人数据失败', e);
    } finally {
      this.isLoading = false;
    }
  }

  async loadUserInfo() {
    try {
      const res = await HttpUtil.get<ApiResponse<UserInfo>>(getContext(), '/user/me');
      if (res.code === 200 && res.data) {
        this.userInfo = res.data;
        console.info('用户信息加载成功:', this.userInfo);
      }
    } catch (e) {
      console.error('加载用户信息失败', e);
    }
  }

  async loadUserStats() {
    try {
      const res = await HttpUtil.get<ApiResponse<UserStats>>(getContext(), '/user/stats');
      if (res.code === 200 && res.data) {
        this.totalEarnings = res.data.totalEarnings || 0;
        this.completedTasks = res.data.completedTasks || 0;
        this.consecutiveSignIns = res.data.consecutiveSignIns || 0;
        console.info('用户统计加载成功:', res.data);
      }
    } catch (e) {
      console.error('加载用户统计失败', e);
    }
  }

  async QuitLogin() {
    try {
      await HttpUtil.post<ApiResponse<string>>(getContext(), '/user/logout', {} as EmptyRequest);
    } catch (e) {
      console.error('退出接口调用失败，但继续清除本地Token');
    }
    const pp = await preferences.getPreferences(getContext(), 'user_pref');
    await pp.delete('token');
    await pp.flush();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('👤 我的')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
          .width('100%')
          .textAlign(TextAlign.Start)
          .padding({ left: 20, right: 20 })

        // 用户信息卡片
        Row() {
          Image($r('app.media.zuoxitouxiang'))
            .width(56)
            .height(56)
            .borderRadius(28)
            .margin({ right: 16 })
            .objectFit(ImageFit.Cover)

          Column({ space: 6 }) {
            Text(this.userInfo.username || '未设置昵称')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Text(this.userInfo.phone || '未绑定手机')
              .fontSize(13)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Image($r('app.media.zuoxitouxiang'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .opacity(0.5)
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .margin({ left: 20, right: 20 })

        // 统计三连卡片
        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text('累计收益')
              .fontSize(12)
              .fontColor('#999999')
            Text(`¥${this.totalEarnings.toFixed(2)}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFB800')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Divider()
            .width(1)
            .height(32)
            .color('#EEEEEE')

          Column({ space: 4 }) {
            Text('完成任务')
              .fontSize(12)
              .fontColor('#999999')
            Text(`${this.completedTasks}个`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#66BB6A')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Divider()
            .width(1)
            .height(32)
            .color('#EEEEEE')

          Column({ space: 4 }) {
            Text('连续签到')
              .fontSize(12)
              .fontColor('#999999')
            Text(`${this.consecutiveSignIns}天`)
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
        .margin({ left: 20, right: 20 })

        // 功能菜单列表
        Column() {
          ForEach(this.menuList, (item: MenuItem) => {
            Row() {
              Image(item.url)
                .width(20)
                .height(20)
                .margin({ right: 16 })
                .objectFit(ImageFit.Contain)

              Text(item.name)
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)

            }
            .width('100%')
            .height(52)
          }, (item: MenuItem) => item.name)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .margin({ left: 20, right: 20 })

        Button('退出登录')
          .onClick(() => { void this.QuitLogin() })
          .width('80%')
          .height(44)
          .fontSize(15)
          .backgroundColor('#FFEBEE')
          .fontColor('#E53935')
          .borderRadius(22)
          .margin({ top: 20 })
      }
      .width('100%')
      .padding({ bottom: 100 })
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F6F0')
  }
}
