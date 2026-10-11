// pages/SplashPage.ets
import router from '@ohos.router';
import preferences from '@ohos.data.preferences';

@Entry
@Component
struct SplashPage {
  @State currentIndex: number = 0;
  private swiperController: SwiperController = new SwiperController();

  async aboutToAppear() {
    // 获取 preference 实例
    const pp = await preferences.getPreferences(getContext(), 'you-pp');
    // 读取是否首次启动
    const isFirstLaunch = await pp.get('isFirstLaunch', true) as boolean;

    if (!isFirstLaunch) {
      // 非首次启动，检查 token
      const tokenPrefs = await preferences.getPreferences(getContext(), 'user_pref');
      const token = await tokenPrefs.get('token', '') as string;

      if (token) {
        // 已登录，直接进入主页（请根据实际路由名调整）
        router.replaceUrl({ url: 'pages/MainPage' });
      } else {
        // 未登录，去登录页
        router.replaceUrl({ url: 'pages/LoginPage' });
      }
    }
    // 首次启动时停留本页（引导页），不做任何跳转
  }

  async finishguide() {
    const pp = await preferences.getPreferences(getContext(), 'you-pp');
    await pp.put('isFirstLaunch', false);
    await pp.flush();
    // 引导完成后跳转登录页（首次使用肯定未登录）
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    Column() {
      Swiper(this.swiperController) {
        // 第1页
        Column() {
          Image($r('app.media.startIcon')).width('80%').height(200)
          Text('智能记账，让财富生长').fontSize(24).fontWeight(FontWeight.Bold).margin({ top: 30 })
          Text('AI语音记账，3秒完成').fontSize(16).fontColor('#999').margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 第2页
        Column() {
          Image($r('app.media.startIcon')).width('80%').height(200)
          Text('签到赚金币，记账有奖励').fontSize(24).fontWeight(FontWeight.Bold).margin({ top: 30 })
          Text('每日签到，连续翻倍').fontSize(16).fontColor('#999').margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 第3页
        Column() {
          Image($r('app.media.startIcon')).width('80%').height(200)
          Text('开始你的财富之旅').fontSize(24).fontWeight(FontWeight.Bold).margin({ top: 30 })
          Button('立即体验')
            .width('80%')
            .height(48)
            .fontSize(18)
            .backgroundColor('#FF7A00')
            .borderRadius(24)
            .margin({ top: 40 })
            .onClick(() => {
              this.finishguide()
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .loop(false)
      .indicator(true)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}