import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';
import { promptAction, router } from '@kit.ArkUI';

class HttpUtil {
  private static instance: HttpUtil;
  private httpRequest: http.HttpRequest | null = null;
  private baseURL: string = 'http://10.0.2.2:8080';

  public static getInstance(): HttpUtil {
    if (!HttpUtil.instance) {
      HttpUtil.instance = new HttpUtil();
    }
    return HttpUtil.instance;
  }

  private getRequest(): http.HttpRequest {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }
    return this.httpRequest;
  }
//获取token
  private async getToken(context: Context): Promise<string> {
    try {
      const prefs = await preferences.getPreferences(context, 'user_pref');
      const token = await prefs.get('token', '') as string;
      return token;
    } catch (e) {
      console.error('读取 Token 失败：' + JSON.stringify(e));
      return '';
    }
  }

  // ===== POST 请求 =====
  async post<T>(context: Context, url: string, data: object): Promise<T> {
    const token = await this.getToken(context);
    const httpRequest = this.getRequest();
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : ''
      },
      extraData: JSON.stringify(data),
      readTimeout: 30000,
      connectTimeout: 15000
    };

    return new Promise((resolve, reject) => {
      httpRequest.request(this.baseURL + url, options, async (err, response) => {
        if (err) { reject(err); return; }
        if (!response) { reject(new Error('服务器无响应')); return; }

        //  专门处理 401
        if (response.responseCode === 401) {
          try {
            promptAction.showToast({ message: '登录已过期，请重新登录' });
            const prefs = await preferences.getPreferences(context, 'user_pref');
            await prefs.delete('token');
            await prefs.flush();
            router.replaceUrl({ url: 'pages/LoginPage' });
          } catch (e) {
            console.error('清理 Token 失败：' + JSON.stringify(e));
          }
          reject(new Error('UNAUTHORIZED'));
          return;
        }
        // 专门处理 200
        if (response.responseCode !== 200) {
          reject(new Error(`HTTP ${response.responseCode}`));
          return;
        }

        try {
          resolve(JSON.parse(response.result as string));
        } catch (e) {
          reject(e);
        }
      });
    });
  }

  // ===== GET 请求 =====
  async get<T>(context: Context, url: string): Promise<T> {
    const token = await this.getToken(context);
    const httpRequest = this.getRequest();
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : ''
      },
      readTimeout: 15000,
      connectTimeout: 15000
    };

    return new Promise((resolve, reject) => {
      httpRequest.request(this.baseURL + url, options, async (err, response) => {
        if (err) {
          console.error('请求发生错误：' + JSON.stringify(err));
          reject(err);
          return;
        }
        if (!response) {
          reject(new Error('服务器无响应'));
          return;
        }
        // 专门处理 401
        if (response.responseCode === 401) {
          try {
            promptAction.showToast({ message: '登录已过期，请重新登录' });
            const prefs = await preferences.getPreferences(context, 'user_pref');
            await prefs.delete('token');
            await prefs.flush();
            router.replaceUrl({ url: 'pages/LoginPage' });
          } catch (e) {
            console.error('清理 Token 失败：' + JSON.stringify(e));
          }
          reject(new Error('UNAUTHORIZED'));
          return;
        }
        // 专门处理 200
        if (response.responseCode !== 200) {
          reject(new Error(`HTTP ${response.responseCode}`));
          return;
        }
        try {
          resolve(JSON.parse(response.result as string));
        } catch (e) {
          reject(e);
        }
      });
    });
  }

  // ===== DELETE 请求 =====
  async delete<T>(context: Context, url: string): Promise<T> {
    const token = await this.getToken(context);
    const httpRequest = this.getRequest();
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.DELETE,
      header: {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : ''
      },
      readTimeout: 15000,
      connectTimeout: 15000
    };

    return new Promise((resolve, reject) => {
      httpRequest.request(this.baseURL + url, options, async (err, response) => {
        if (err) {
          reject(err);
          return;
        }
        if (!response) {
          reject(new Error('服务器无响应'));
          return;
        }
        // 专门处理 401
        if (response.responseCode === 401) {
          try {
            promptAction.showToast({ message: '登录已过期，请重新登录' });
            const prefs = await preferences.getPreferences(context, 'user_pref');
            await prefs.delete('token');
            await prefs.flush();
            router.replaceUrl({ url: 'pages/LoginPage' });
          } catch (e) {
            console.error('清理 Token 失败：' + JSON.stringify(e));
          }
          reject(new Error('UNAUTHORIZED'));
          return;
        }
        // 专门处理 200
        if (response.responseCode !== 200) {
          reject(new Error(`HTTP ${response.responseCode}`));
          return;
        }
        try {
          resolve(JSON.parse(response.result as string));
        } catch (e) {
          reject(e);
        }
      });
    });
  }
  // HttpUtil.ets 中新增以下方法

  // ===== GET 请求（专用于 FastAPI，baseURL 固定为 8000 端口） =====
  async getFastApi<T>(context: Context, url: string): Promise<T> {
    const token = await this.getToken(context);
    const httpRequest = this.getRequest();
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: {
        'Content-Type': 'application/json',
         'Authorization': token ? `Bearer ${token}` : ''
      },
      readTimeout: 15000,
      connectTimeout: 15000
    };

    // 注意：直接使用 8000 端口，不拼接 baseURL
    const fastApiBaseUrl = 'http://10.0.2.2:8000';

    return new Promise((resolve, reject) => {
      httpRequest.request(fastApiBaseUrl + url, options, async (err, response) => {
        if (err) { reject(err); return; }
        if (!response) { reject(new Error('FastAPI 无响应')); return; }
        if (response.responseCode !== 200) {
          reject(new Error(`FastAPI HTTP ${response.responseCode}`));
          return;
        }
        try {
          resolve(JSON.parse(response.result as string));
        } catch (e) {
          reject(e);
        }
      });
    });
  }
}



export default HttpUtil.getInstance();