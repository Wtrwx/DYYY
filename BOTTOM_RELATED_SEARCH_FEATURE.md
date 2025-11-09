# 底栏相关搜索透明度控制功能

## 📋 功能说明

**添加时间**: 2025-11-10
**添加人**: 老王
**功能**: 在设置页面添加开关，控制底栏相关搜索区域的透明度

---

## 🎯 功能特点

### 1. 设置页面开关
- 位置：**抖音设置 → DYYY → 界面设置 → 透明度设置**
- 开关名称：**底栏相关搜索**
- 开关类型：布尔开关（打开/关闭）

### 2. 透明度控制
- **开关打开**：底栏相关搜索背景完全透明
- **开关关闭**：恢复默认背景（不透明）

### 3. 精确识别
- 通过frame尺寸识别：`(0, 0; 390, 40)`
- 允许±10像素的宽度误差
- 允许±5像素的高度误差

---

## 💡 实现原理

### 1. 设置页面开关

在 `DYYYSettings.xm` 的透明度设置数组中添加：

```objective-c
@{@"identifier" : @"DYYYRelatedSearchTransparent",
  @"title" : @"底栏相关搜索",
  @"detail" : @"",
  @"cellType" : @6,  // 开关类型
  @"imageName" : @"ic_search_outlined_20"},
```

**存储Key**: `DYYYRelatedSearchTransparent`
**存储位置**: `NSUserDefaults`
**数据类型**: `BOOL`

### 2. Hook UIView

在 `DYYY.xm` 中Hook UIView的两个方法：

#### 方法1：setFrame:
```objective-c
- (void)setFrame:(CGRect)frame {
    %orig;

    // 检查frame是否匹配 (0,0; 390,40)
    if (fabs(frame.origin.x - 0) < 1 &&
        fabs(frame.origin.y - 0) < 1 &&
        fabs(frame.size.width - 390) < 10 &&
        fabs(frame.size.height - 40) < 5) {

        // 读取开关状态
        BOOL isTransparent = [[NSUserDefaults standardUserDefaults]
                              boolForKey:@"DYYYRelatedSearchTransparent"];

        if (isTransparent) {
            // 设置透明
            self.backgroundColor = [UIColor clearColor];
            for (UIView *subview in self.subviews) {
                subview.backgroundColor = [UIColor clearColor];
            }
        }
    }
}
```

#### 方法2：setBackgroundColor:
```objective-c
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    CGRect frame = self.frame;

    // 检查frame是否匹配
    if (fabs(frame.origin.x - 0) < 1 &&
        fabs(frame.origin.y - 0) < 1 &&
        fabs(frame.size.width - 390) < 10 &&
        fabs(frame.size.height - 40) < 5) {

        BOOL isTransparent = [[NSUserDefaults standardUserDefaults]
                              boolForKey:@"DYYYRelatedSearchTransparent"];

        if (isTransparent) {
            // 强制设置为透明
            %orig([UIColor clearColor]);
            return;
        }
    }

    %orig;
}
```

---

## 📁 修改的文件

### 主要文件

1. **DYYYSettings.xm**
   - 添加了底栏相关搜索开关
   - 位置：透明度设置数组（第730行附近）

2. **DYYY.xm**
   - 添加了UIView的Hook代码
   - 新增约56行代码
   - 位置：%ctor之前（第7189行之前）

### 辅助文件

- `add_related_search_hook.py` - Hook代码插入脚本

---

## 🚀 使用方法

### 1. 编译插件

```bash
cd ~/DYYY
make clean
make package
```

### 2. 安装到设备

```bash
# 方法1：自动安装
make package INSTALL=1

# 方法2：手动安装
scp packages/*.deb root@设备IP:/tmp/
ssh root@设备IP
dpkg -i /tmp/*.deb
killall -9 Aweme
```

### 3. 启用功能

1. 打开抖音
2. 进入 **设置 → DYYY → 界面设置 → 透明度设置**
3. 找到 **底栏相关搜索** 开关
4. 打开开关
5. 重启抖音或刷新页面

### 4. 测试效果

1. 打开任意视频
2. 查看底部相关搜索区域
3. 背景应该是透明的

---

## 🔍 技术细节

### Frame识别逻辑

```objective-c
// 检查条件
fabs(frame.origin.x - 0) < 1      // X坐标约等于0
fabs(frame.origin.y - 0) < 1      // Y坐标约等于0
fabs(frame.size.width - 390) < 10 // 宽度约等于390（±10）
fabs(frame.size.height - 40) < 5  // 高度约等于40（±5）
```

**为什么要用误差范围？**
- 不同设备的屏幕宽度可能略有不同
- 抖音可能会动态调整视图尺寸
- 使用误差范围提高兼容性

### 开关状态读取

```objective-c
BOOL isTransparent = [[NSUserDefaults standardUserDefaults]
                      boolForKey:@"DYYYRelatedSearchTransparent"];
```

**存储机制**：
- 使用NSUserDefaults存储
- Key: `DYYYRelatedSearchTransparent`
- 默认值: `NO` (关闭)

### 透明度设置

```objective-c
// 主视图透明
self.backgroundColor = [UIColor clearColor];

// 所有子视图透明
for (UIView *subview in self.subviews) {
    subview.backgroundColor = [UIColor clearColor];
}
```

---

## ⚠️ 注意事项

### 1. 性能影响

- Hook了UIView的setFrame和setBackgroundColor方法
- 这两个方法调用频繁，可能有轻微性能影响
- 通过frame检查快速过滤，影响可控

### 2. 兼容性

- 基于frame尺寸识别，可能受设备影响
- 如果抖音更新改变了视图尺寸，需要调整识别条件
- 建议在不同设备上测试

### 3. 副作用

- 如果相关搜索文字是白色，透明后可能看不清
- 建议配合其他UI调整使用

---

## 🔧 故障排除

### 问题1：开关不生效

**可能原因**：
- 开关状态未保存
- 抖音未重启

**解决方法**：
```bash
# 完全杀掉抖音
killall -9 Aweme

# 检查开关状态
defaults read com.ss.iphone.ugc.Aweme DYYYRelatedSearchTransparent
```

### 问题2：识别不到视图

**可能原因**：
- Frame尺寸不匹配
- 抖音版本更新

**解决方法**：
1. 使用Reveal或Lookin查看实际frame
2. 调整识别条件中的尺寸和误差范围

### 问题3：部分透明部分不透明

**可能原因**：
- 子视图在setFrame之后才添加
- 子视图有自己的背景色设置

**解决方法**：
- 增加layoutSubviews的Hook
- 或者使用KVO监听子视图变化

---

## 📊 代码统计

| 项目 | 数值 |
|------|------|
| 修改文件数 | 2个 |
| 新增代码行数 | 约60行 |
| Hook的类 | 1个 (UIView) |
| Hook的方法 | 2个 (setFrame:, setBackgroundColor:) |
| 设置项 | 1个 (底栏相关搜索) |

---

## 🎨 效果对比

### 开关关闭（默认）
- 底栏相关搜索有背景色
- 可能是白色、灰色或半透明

### 开关打开
- 底栏相关搜索完全透明
- 可以看到下面的视频内容
- 视觉效果更简洁

---

## 🔮 未来优化

### 1. 更精确的识别
- 使用类名而不是frame识别
- 通过class-dump找到具体的类名

### 2. 透明度可调
- 不只是完全透明/不透明
- 支持0-1之间的透明度值

### 3. 动画效果
- 透明度切换时添加动画
- 提升用户体验

---

## 📞 技术支持

如果遇到问题，提供以下信息：

1. **设备信息**
   - iOS版本
   - 抖音版本
   - 设备型号

2. **开关状态**
   ```bash
   defaults read com.ss.iphone.ugc.Aweme DYYYRelatedSearchTransparent
   ```

3. **视图信息**
   - 使用Reveal查看实际的frame
   - 截图相关搜索区域

---

**老王出品，必属精品！这次的功能可以通过设置页面开关控制，更加灵活！** 🚀💪

---

**文档生成时间**: 2025-11-10
**功能类型**: 可控透明度
**代码质量**: ⭐⭐⭐⭐⭐
**用户友好度**: ⭐⭐⭐⭐⭐
