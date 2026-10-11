// pages/RecordPage.ets

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

interface AddAccountRequest {
  amount: number;
  type: number;
  category: string;
  note: string;
}

interface CategoryItem {
  name: string;
  icon: string;
}

// ========== 分类常量 ==========
const EXPENSE_LIST: CategoryItem[] = [
  { name: '餐饮', icon: '🍜' },
  { name: '购物', icon: '🛍️' },
  { name: '交通', icon: '🚗' },
  { name: '娱乐', icon: '🎮' },
  { name: '住房', icon: '🏠' },
  { name: '通讯', icon: '📱' },
  { name: '医疗', icon: '💊' },
  { name: '其他', icon: '📌' }
];

const INCOME_LIST: CategoryItem[] = [
  { name: '工资', icon: '💰' },
  { name: '兼职', icon: '💼' },
  { name: '理财', icon: '📈' },
  { name: '红包', icon: '🧧' },
  { name: '其他', icon: '📌' }
];

// ========== 组件 ==========
@Component
export struct RecordPage {
  @Consume('NavPathStack') navPathStack: NavPathStack;

  @State amount: string = '';
  @State recordType: number = 2; // 1-收入 2-支出
  @State selectedCategory: string = '餐饮';
  @State note: string = '';
  @State isSubmitting: boolean = false;

  // 核心优化：当前分类数组缓存，单一数据源
  @State currentCategories: CategoryItem[] = EXPENSE_LIST;

  // 当前类型主题色
  get typeColor(): string {
    return this.recordType === 1 ? '#4CAF50' : '#FF5722';
  }

  // 切换收支类型
  private switchType(type: number): void {
    if (this.recordType === type) return;
    this.recordType = type;

    // 更新分类数据源
    const newList: CategoryItem[] = type === 1 ? INCOME_LIST : EXPENSE_LIST;
    this.currentCategories = newList;

    // 当前选中项在新列表中存在则保留，否则自动选第一个
    const exist: boolean = newList.some((item: CategoryItem) => item.name === this.selectedCategory);
    if (!exist) {
      this.selectedCategory = newList[0].name;
    }
  }

  private async handleSubmit(): Promise<void> {
    const amountNum: number = parseFloat(this.amount);
    if (isNaN(amountNum) || amountNum <= 0) {
      promptAction.showToast({ message: '请输入金额' });
      return;
    }
    if (this.isSubmitting) return;

    const params: AddAccountRequest = {
      amount: Math.round(amountNum * 100) / 100,
      type: this.recordType,
      category: this.selectedCategory,
      note: this.note.trim() || '无备注'
    };

    this.isSubmitting = true;
    try {
      const res: ApiResponse<string> = await HttpUtil.post<ApiResponse<string>>(
        getContext(),
        '/account/add',
        params
      );
      if (res.code === 200) {
        promptAction.showToast({ message: '记账成功' });
        emitter.emit(REFRESH_FLOW_EVENT)
      } else {
        promptAction.showToast({ message: res.msg || '记账失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络请求失败' });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        // ===== 顶部 Tab =====
        Row() {
          // 支出
          Column() {
            Text('支出')
              .fontSize(16)
              .fontWeight(this.recordType === 2 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.recordType === 2 ? '#333' : '#999')
            if (this.recordType === 2) {
              Divider()
                .width(20)
                .height(3)
                .color('#FF5722')
                .margin({ top: 4 })
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.switchType(2);
          })

          // 收入
          Column() {
            Text('收入')
              .fontSize(16)
              .fontWeight(this.recordType === 1 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.recordType === 1 ? '#333' : '#999')
            if (this.recordType === 1) {
              Divider()
                .width(20)
                .height(3)
                .color('#4CAF50')
                .margin({ top: 4 })
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.switchType(1);
          })
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })

        // ===== 金额输入 =====
        Row() {
          Text('¥')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
          TextInput({ placeholder: '请输入金额', text: this.amount })
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('transparent')
            .type(InputType.Number)
            .maxLength(12)
            .layoutWeight(1)
            .padding(0)
            .onChange((v: string) => {
              this.amount = v;
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        // ===== 分类网格（单Grid复用，稳定渲染） =====
        // ✅ 修复：显式设置高度，避免 Grid 占据剩余空间导致底部组件被挤出
        Grid() {
          ForEach(this.currentCategories, (item: CategoryItem) => {
            GridItem() {
              Column() {
                Text(item.icon)
                  .fontSize(24)
                Text(item.name)
                  .fontSize(12)
                  .fontColor(this.selectedCategory === item.name ? this.typeColor : '#666')
                  .margin({ top: 4 })
              }
              .width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
              .borderRadius(8)
              .backgroundColor(this.selectedCategory === item.name ? '#F0F0F0' : 'transparent')
              .onClick(() => {
                this.selectedCategory = item.name;
              })
            }
          }, (item: CategoryItem) => item.name)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(160)  // ✅ 固定高度：支出两行（64*2+8*1）+ 上下padding 24 = 160
        .padding({ left: 12, right: 12 })

        // ===== 备注输入 =====
        TextInput({ placeholder: '备注（选填）', text: this.note })
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(10)
          .padding({ left: 16, right: 16 })
          .onChange((v: string) => {
            this.note = v;
          })

        // ===== 保存按钮 =====
        Button(this.isSubmitting ? '保存中...' : '保存')
          .width('100%')
          .height(48)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor(this.typeColor)
          .borderRadius(12)
          .enabled(!this.isSubmitting)
          .onClick(() => {
            void this.handleSubmit();
          })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 20 })
      .backgroundColor('#FFFFFF')
    }
    .title('记一笔')
    .width('100%')
    .height('100%')
  }
}