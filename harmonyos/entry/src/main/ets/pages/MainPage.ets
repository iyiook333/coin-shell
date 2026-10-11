// pages/MainPage.ets

import { FlowPage } from './FlowPage';
import { ReportPage } from './ReportPage';
import { EarnPage } from './EarnPage';
import { ProfilePage } from './ProfilePage';
import { RecordPage } from './RecordPage';
import { AIAssistantPage } from './AIAssistantPage';
import {CashExchangePage} from  './CashExchangePage';
import {EarningsPage} from './EarningsPage'
@Entry
@Component
struct MainPage {
  @Provide('NavPathStack') navPathStack: NavPathStack = new NavPathStack();
  @State currentTab: number = 0;
  private tabsController: TabsController = new TabsController(); // 控制器

  private isPushing: boolean = false;

  @Builder
  PageMap(name: string, _param: object) {
    if (name === 'AIAssistantPage') {
      AIAssistantPage()
    } else if (name === 'RecordPage') {
      RecordPage()
    } else if (name === 'EarningsPage') {
      EarningsPage()
    } else if (name === 'CashExchangePage') {
      CashExchangePage()
    }
  }

  @Builder
  TabBarItem(index: number, icon: Resource, text: string) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentTab === index ? '#FF7A00' : '#999999')
      Text(text)
        .fontSize(12)
        .fontColor(this.currentTab === index ? '#FF7A00' : '#999999')
    }
    .width('100%')
  }

  @Builder
  CenterButton() {
    Column() {
      Row() {
        Text('+')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width(40)
      .height(35)
      .border({ width: 2, color: '#333333', radius: 6 })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)
      .onClick(() => {
        if (this.isPushing) return;
        this.isPushing = true;

        try {
          console.info('跳转到 RecordPage');
          this.navPathStack.pushPathByName('RecordPage', null);
        } catch (e) {
          console.error('跳转失败：' + JSON.stringify(e));
        } finally {
          setTimeout(() => {
            this.isPushing = false;
          }, 500);
        }
      })

      Text('')
        .fontSize(11)
        .height(8)
    }
    .width('100%')
  }

  build() {
    Navigation(this.navPathStack) {
      Tabs({ index: this.currentTab, barPosition: BarPosition.End, controller: this.tabsController }) {
        TabContent() { FlowPage() }
        .tabBar(this.TabBarItem(0, $r('app.media.zijinliushuimingxibian'), '流水'))
        TabContent() { ReportPage() }
        .tabBar(this.TabBarItem(1, $r('app.media.baobiaozhongxin'), '报表'))
        TabContent() { Column().width(0).height(0) }
        .tabBar(this.CenterButton())
        TabContent() { EarnPage() }
        .tabBar(this.TabBarItem(3, $r('app.media.jinbiduihuan'), '赚钱'))
        TabContent() { ProfilePage() }
        .tabBar(this.TabBarItem(4, $r('app.media.wode'), '我的'))
      }
      .barPosition(BarPosition.End)
      .width('100%')
      .height('100%')
      .barMode(BarMode.Fixed)
      .scrollable(false)                     // 禁止滑动
      .onChange((index: number) => {
        if (index !== 2) {
          this.currentTab = index;
        } else {
          // 点击中间加号时，立即回退到之前的有效 Tab，避免空白
          this.tabsController.changeIndex(this.currentTab);
        }
      })
    }
    .navDestination(this.PageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
  }
}