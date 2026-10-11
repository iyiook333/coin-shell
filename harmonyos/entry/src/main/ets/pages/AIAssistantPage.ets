// pages/AIAssistantPage.ets

import promptAction from '@ohos.promptAction';
import HttpUtil from '../common/utils/HttpUtil';
import { emitter } from '@kit.BasicServicesKit';
import { REFRESH_FLOW_EVENT } from '../common/constants/EventConstants';
import { preferences } from '@kit.ArkData';
import util from '@ohos.util';
// ========== 接口定义 ==========
interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T;
}

interface VoiceRequest {
  text: string;
  sessionId: string;
  userId: number;
}
// 在接口定义区域添加
interface HistoryMessage {
  role: string;   // 'user' | 'assistant'
  content: string;
}

// ========== 消息模型 ==========
interface ChatMessage {
  id: number;
  text: string;
  isUser: boolean;
  isLoading?: boolean;
}
interface UserInfo {
  id: number;
  phone: string;
  username: string;
}
// ========== 组件 ==========
@Component
export struct AIAssistantPage {
  @Consume('NavPathStack') navPathStack: NavPathStack;
  @State userId: number = 0;
  @State inputText: string = '';
  @State messages: ChatMessage[] = [];
  @State isSending: boolean = false;
  @State sessionId: string = '';
  private msgIdCounter: number = 0;
  private scroller: Scroller = new Scroller();
  private quickExamples: string[] = ['打车花了35', '午餐28元', '工资到账5000'];
  async aboutToAppear() {
    this.getUIContext().setKeyboardAvoidMode(1);

    await this.initSessionId();
    await this.loadHistory();
  }
  //loadHistory 方法
  async loadHistory() {
    if (!this.sessionId) return;
    try {
      // 通过 Spring Boot 代理，返回的数据结构是 ApiResponse 包装
      const res = await HttpUtil.get<ApiResponse<HistoryMessage[]>>(
        getContext(),
        `/account/history/${this.sessionId}`
      );
      if (res.code === 200 && res.data) {
        const historyMessages: ChatMessage[] = res.data.map((item: HistoryMessage, index: number) => {
          return {
            id: index + 1,
            text: item.content,
            isUser: item.role === 'user'
          } as ChatMessage;
        });
        this.messages = historyMessages;
        this.msgIdCounter = historyMessages.length;
        setTimeout(() => {
          this.scroller.scrollEdge(Edge.Bottom);
        }, 100);
      }
    } catch (e) {
      console.error('加载历史失败:', JSON.stringify(e));
    }
  }

  async initSessionId() {
    // 1. 先获取当前用户 ID
    try {
      const userRes = await HttpUtil.get<ApiResponse<UserInfo>>(getContext(), '/user/me');
      if (userRes.code === 200 && userRes.data) {
        this.userId = userRes.data.id;
      } else {
        // 未登录或获取失败，无法初始化
        console.warn('无法获取用户信息，sessionId 初始化失败');
        return;
      }
    } catch (e) {
      console.error('获取用户信息失败:', JSON.stringify(e));
      return;
    }

    // 2. 用 userId 作为 Key 的一部分，每个用户独立存储
    try {
      const pref = await preferences.getPreferences(getContext(this), 'ai_session_pref');
      const key = `session_${this.userId}`;   // 例如: session_1
      let sid = await pref.get(key, '') as string;
      if (!sid) {
        sid = util.generateRandomUUID();
        await pref.put(key, sid);
        await pref.flush();
      }
      this.sessionId = sid;
      console.info(`会话 ID 初始化成功: userId=${this.userId}, sessionId=${this.sessionId}`);
    } catch (e) {
      console.error('初始化 sessionId 失败:', JSON.stringify(e));
    }
  }
  private async sendMessage(text: string): Promise<void> {
    const trimmed = text.trim();
    if (!trimmed) {
      promptAction.showToast({ message: '请输入内容' });
      return;
    }
    if (this.isSending) return;

    const userMsg: ChatMessage = { id: ++this.msgIdCounter, text: trimmed, isUser: true };
    this.messages.push(userMsg);
    this.inputText = '';
    this.isSending = true;

    const placeholder: ChatMessage = { id: ++this.msgIdCounter, text: '', isUser: false, isLoading: true };
    this.messages.push(placeholder);
    const placeholderIndex = this.messages.length - 1;
    this.messages = [...this.messages];
    this.scroller.scrollEdge(Edge.Bottom);

    const params: VoiceRequest = { text: trimmed,sessionId: this.sessionId ,userId: this.userId};
    try {
      const res = await HttpUtil.post<ApiResponse<string>>(
        getContext(),
        '/account/voice',
        params
      );

      if (res.code === 200) {
        const finalText = res.data || res.msg || '记账成功！';
        this.messages.splice(placeholderIndex, 1, {
          id: ++this.msgIdCounter,
          text: finalText,
          isUser: false,
          isLoading: false
        });
        this.messages = [...this.messages];
        emitter.emit(REFRESH_FLOW_EVENT);
      } else {
        this.messages.splice(placeholderIndex, 1, {
          id: ++this.msgIdCounter,
          text: res.msg || '记账失败，请重试',
          isUser: false,
          isLoading: false
        });
        this.messages = [...this.messages];
      }
    } catch (e) {
      const errorMsg = JSON.stringify(e);
      console.info('AI 记账异常：' + errorMsg);

      // 区分超时和普通错误
      let displayText = '未识别到可记账内容，请重试或手动记账';
      if (errorMsg.includes('Timeout') || errorMsg.includes('timeout')) {
        displayText = '响应超时，请稍后重试';
      }

      this.messages.splice(placeholderIndex, 1, {
        id: ++this.msgIdCounter,
        text: displayText,
        isUser: false,
        isLoading: false
      });
      this.messages = [...this.messages];
      promptAction.showToast({ message: 'AI 响应超时，请稍后重试' });
    } finally {
      this.isSending = false;
      this.messages = [...this.messages];
      this.scroller.scrollEdge(Edge.Bottom);
    }
  }

  private onQuickExample(text: string): void {
    this.sendMessage(text);
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('‹')
            .padding({bottom:5})
            .fontSize(28)
            .fontColor('#333333')
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.navPathStack.pop();
            })
          Text('AI 智能助手')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }
        .height(56)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .padding({ left: 16 ,right:16})

        Scroll(this.scroller) {
          Column({ space: 12 }) {
            if (this.messages.length === 0) {
              Column() {
                Text('👋')
                  .fontSize(48)
                  .margin({ top: 60 })
                Text('你好！我是你的智能记账助手')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')
                  .margin({ top: 12 })
                Text('你可以说：')
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ top: 8 })
                Text('"打车花了35" 或 "午餐28元"')
                  .fontSize(14)
                  .fontColor('#999999')
                Row({ space: 8 }) {
                  ForEach(this.quickExamples, (item: string) => {
                    Button(item)
                      .fontSize(13)
                      .fontColor('#FF7A00')
                      .backgroundColor('#FFF0E6')
                      .borderRadius(20)
                      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                      .onClick(() => {
                        this.onQuickExample(item);
                      })
                  }, (item: string) => item)
                }
                .margin({ top: 16 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.messages, (msg: ChatMessage) => {
                Row() {
                  if (msg.isUser) {
                    Column() {
                      Text(msg.text)
                        .fontSize(15)
                        .fontColor('#FFFFFF')
                        .padding(12)
                        .backgroundColor('#FF7A00')
                        .borderRadius(12)
                        .maxLines(10)
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.End)
                  } else {
                    Column() {
                      if (msg.isLoading) {
                        Row({ space: 4 }) {
                          LoadingProgress()
                            .width(20)
                            .height(20)
                            .color('#FF7A00')
                          Text('正在思考...')
                            .fontSize(14)
                            .fontColor('#999999')
                        }
                        .padding(12)
                        .backgroundColor('#F5F5F5')
                        .borderRadius(12)
                      } else {
                        Text(msg.text)
                          .fontSize(15)
                          .fontColor('#333333')
                          .padding(12)
                          .backgroundColor('#F5F5F5')
                          .borderRadius(12)
                          .maxLines(10)
                      }
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start)
                  }
                }
                .width('100%')
                .padding({ left: 16, right: 16 })
              }, (msg: ChatMessage) => `msg_${msg.id}`)
            }

            Blank().height(80)
          }
          .width('100%')
          .padding({ top: 12 })
        }
        .clip(true)
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#F8F6F0')

        Row() {
          TextInput({ placeholder: '说句话或输入...', text: this.inputText })
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#F5F5F5')
            .borderRadius(22)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.inputText = value;
            })
            .onSubmit(() => {
              this.sendMessage(this.inputText);
            })

          Button(this.isSending ? '发送中' : '发送')
            .height(44)
            .fontSize(16)
            .backgroundColor(this.isSending ? '#CCCCCC' : '#FF7A00')
            .borderRadius(22)
            .padding({ left: 20, right: 20 })
            .margin({ left: 8 })
            .enabled(!this.isSending)
            .onClick(() => {
              this.sendMessage(this.inputText);
            })
        }
        .width('100%')
        .height(64)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
        .borderRadius({ topLeft: 16, topRight: 16 })
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: -2 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
    .title('')
    .hideTitleBar(true)
    .backgroundColor('#FFFFFF')
    .width('100%')
    .height('100%')
  }
}