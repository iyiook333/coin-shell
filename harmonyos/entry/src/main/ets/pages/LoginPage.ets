// pages/LoginPage.ets
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import HttpUtil from '../common/utils/HttpUtil'; // 注意没有大括号
import { preferences } from '@kit.ArkData';

// 定义后端统一返回结构
interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T;
}
// 定义发送验证码请求参数接口
interface SendCodeRequest {
  phone: string;
}
// 用户信息结构
interface UserInfo {
  id: number;
  phone: string;
  username: string;
}

// 登录响应
interface LoginResponse {
  code: number;
  msg: string;
  data: string;
}
// 在顶部接口区域添加
interface LoginRequest {
  phone: string;
  code: string;
}
@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State code: string = '';
  @State agreed: boolean = false;
  @State codeText: string = '获取验证码';
  @State isCounting: boolean = false;
  private timer: number = -1;
  private countDown: number = 60;

  async sendCode() {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    if (this.isCounting) return;

    this.isCounting = true;
    this.codeText = '发送中...';

    try {
      const params: SendCodeRequest = { phone: this.phone };
      const res = await HttpUtil.post<ApiResponse<string>>(getContext(), '/user/code', params);;
      if (res.code === 200) {
        promptAction.showToast({ message: '验证码已发送' });
        this.countDown = 60;
        this.codeText = `${this.countDown}s`;
        this.timer = setInterval(() => {
          this.countDown--;
          if (this.countDown <= 0) {
            clearInterval(this.timer);
            this.isCounting = false;
            this.codeText = '获取验证码';
          } else {
            this.codeText = `${this.countDown}s`;
          }
        }, 1000);
      } else {
        promptAction.showToast({ message: res.msg || '发送失败' });
        this.isCounting = false;
        this.codeText = '获取验证码';
      }
    } catch (error) {
      console.error('发送验证码异常：' + JSON.stringify(error));
      promptAction.showToast({ message: '网络请求失败，请稍后重试' });
      this.isCounting = false;
      this.codeText = '获取验证码';
    }
  }

  async doLogin() {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    if (this.code.length !== 6) {
      promptAction.showToast({ message: '请输入6位验证码' });
      return;
    }
    if (!this.agreed) {
      promptAction.showToast({ message: '请先同意用户协议' });
      return;
    }

    try {
      const loginParams: LoginRequest = {
        phone: this.phone,
        code: this.code
      };
      const res = await HttpUtil.post<LoginResponse>(getContext(), '/user/login', loginParams);
      if (res.code === 200) {
        // 保存 token 到 Preferences
        const prefs = await preferences.getPreferences(getContext(), 'user_pref');
        await prefs.put('token', res.data);
        await prefs.flush();
        const savedToken = await prefs.get('token', '');
        console.info('保存的 Token：' + savedToken);
        promptAction.showToast({ message: '登录成功' });
        router.replaceUrl({ url: 'pages/MainPage' });
      } else {
        promptAction.showToast({ message: res.msg || '登录失败' });
      }
    } catch (error) {
      console.error('登录请求失败：' + JSON.stringify(error));
      promptAction.showToast({ message: '网络请求失败，请检查网络' });
    }
  }

  build() {
    Column({ space: 24 }) {
      Text('Coin Shell')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80 })
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 30 })

      // 手机号
      TextInput({ placeholder: '请输入手机号', text: this.phone })
        .width('90%')
        .textAlign(TextAlign.Start)
        .height(50)
        .borderRadius(12)
        .backgroundColor('#F5F5F5')
        .type(InputType.PhoneNumber)
        .maxLength(11)
        .onChange((value: string) => { this.phone = value; })

      // 验证码（框内包含获取按钮）
      Stack() {
        TextInput({ placeholder: '请输入验证码', text: this.code })
          .height(50)
          .backgroundColor('transparent')
          .type(InputType.Number)
          .maxLength(6)
          .onChange((value: string) => { this.code = value; })
        Text(this.codeText)
          .margin({left:200})
          .fontSize(14)
          .fontColor(this.isCounting ? '#999' : '#FF7A00')
          .onClick(() => {
            this.sendCode();
          })
      }
      .width('90%')
      .height(50)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)

      // 协议复选框
      Row({ space: 8 }) {
        Checkbox({ name: 'agreed' })
          .width(18)
          .height(18)
          .onChange((value: boolean) => {
            this.agreed = value;
          })
        Text('我已阅读并同意')
          .fontSize(13)
          .fontColor('#999')
        Text('《用户协议》')
          .fontSize(13)
          .fontColor('#FF7A00')
        Text('和')
          .fontSize(13)
          .fontColor('#999')
        Text('《隐私协议》')
          .fontSize(13)
          .fontColor('#FF7A00')
      }
      .width('90%')
      .justifyContent(FlexAlign.Center)

      Button('登录')
        .width('90%')
        .height(50)
        .fontSize(18)
        .fontColor(Color.White)
        .backgroundColor('#FF7A00')
        .borderRadius(25)
        .enabled(this.phone.length === 11 && this.code.length === 6 && this.agreed)
        .opacity(this.phone.length === 11 && this.code.length === 6 && this.agreed ? 1 : 0.6)
        .onClick(() => {
          console.info('当前验证码：' + this.code);
          this.doLogin();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }
}