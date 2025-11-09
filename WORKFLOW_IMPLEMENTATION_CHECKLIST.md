# GitHub Actions 工作流优化实施清单

本清单帮助你逐步实施工作流审查报告中的建议。

---

## 📋 实施前准备

- [ ] 阅读完整审查报告 (`WORKFLOW_AUDIT_REPORT.md`)
- [ ] 阅读审查总结 (`WORKFLOW_AUDIT_SUMMARY.md`)
- [ ] 备份当前工作流文件
  ```bash
  cp .github/workflows/build.yml .github/workflows/build.yml.backup
  ```
- [ ] 确认当前工作流可以正常运行
- [ ] 检查是否有正在运行的构建任务

---

## 🔴 高优先级修改（建议立即实施）

### 1. 固定 macOS Runner 版本
**预计时间**: 1 分钟  
**风险**: 低

**当前配置** (第 9 行):
```yaml
runs-on: macos-latest
```

**修改为**:
```yaml
runs-on: macos-13
```

**验证方法**:
- [ ] 保存文件
- [ ] 提交并推送
- [ ] 检查新构建是否成功
- [ ] 查看构建日志确认使用 macOS 13

---

### 2. 添加分支过滤
**预计时间**: 3 分钟  
**风险**: 低

**当前配置** (第 3-5 行):
```yaml
on: 
  push:
  pull_request:
```

**修改为**:
```yaml
on: 
  push:
    branches:
      - main          # 或 master，根据你的主分支
      - develop       # 如果有开发分支
      - 'release/**'  # 发布分支（可选）
    paths-ignore:
      - '**.md'
      - 'docs/**'
      - 'LICENSE'
      - '.gitignore'
  pull_request:
    branches:
      - main        # 或 master
      - develop
  workflow_dispatch:  # 允许手动触发
```

**验证方法**:
- [ ] 保存文件
- [ ] 提交到非主分支（如 test-branch）并推送
- [ ] 确认构建**没有**触发（符合预期）
- [ ] 在 GitHub Actions 页面测试手动触发
- [ ] 提交 .md 文件并推送到主分支
- [ ] 确认构建**没有**触发（符合预期）

---

### 3. 添加构建验证
**预计时间**: 2 分钟  
**风险**: 低

**在第 37 行之后添加**:
```yaml
      - name: Verify build output
        run: |
          if [ ! -f packages/*.deb ]; then
            echo "❌ Error: No .deb package generated!"
            exit 1
          fi
          echo "✅ Build successful:"
          ls -lh packages/*.deb
```

**验证方法**:
- [ ] 保存文件
- [ ] 提交并推送
- [ ] 检查构建日志中出现验证步骤
- [ ] 确认显示包大小和文件名

---

## 🟡 中优先级修改（建议两周内实施）

### 4. 改进产物命名
**预计时间**: 1 分钟  
**风险**: 无

**当前配置** (第 42 行):
```yaml
          name: DYYY-SDK16.5-rootless
```

**修改为**:
```yaml
          name: DYYY-SDK16.5-rootless-build${{ github.run_number }}
```

**或者更详细的**:
```yaml
          name: DYYY-SDK16.5-rootless-${{ github.sha }}-${{ github.run_number }}
```

**验证方法**:
- [ ] 保存文件
- [ ] 提交并推送
- [ ] 在 Actions 页面检查产物名称是否包含构建编号

---

### 5. 添加产物保留策略
**预计时间**: 1 分钟  
**风险**: 无

**在产物上传步骤添加** (第 43 行之后):
```yaml
          retention-days: 30
```

**完整示例**:
```yaml
      - name: Upload SDK 16.5 rootless Deb package
        uses: actions/upload-artifact@v4.6.0
        with:
          name: DYYY-SDK16.5-rootless-build${{ github.run_number }}
          path: ${{ github.workspace }}/packages/*.deb
          retention-days: 30
```

**验证方法**:
- [ ] 保存文件
- [ ] 提交并推送
- [ ] 构建完成后，在产物页面确认保留期为 30 天

---

### 6. 添加构建超时保护
**预计时间**: 2 分钟  
**风险**: 无

**在构建步骤添加** (第 34 行之后):
```yaml
      - name: Build package (SDK 16.5 rootless)
        run: |
          rm -f packages/*
          make package THEOS_PACKAGE_SCHEME=rootless TARGET=iphone:clang:16.5:11.0 FINALPACKAGE=1 -j$(sysctl -n hw.ncpu)
        timeout-minutes: 10
```

**验证方法**:
- [ ] 保存文件
- [ ] 查看工作流定义确认超时设置

---

### 7. 联系 Theos Action 维护者
**预计时间**: 15 分钟  
**风险**: 无

**当前配置** (第 28 行):
```yaml
      - name: Prepare Theos
        uses: huami1314/theos-action@main
```

**待办事项**:
- [ ] 访问 https://github.com/huami1314/theos-action
- [ ] 检查是否有 releases 或 tags
- [ ] 如果有版本标签，修改为：
  ```yaml
  uses: huami1314/theos-action@v1.0.0  # 使用实际版本号
  ```
- [ ] 如果没有版本标签：
  - [ ] 开 Issue 请求创建版本标签
  - [ ] 或考虑 fork 仓库并自行打标签
  
**验证方法**:
- [ ] 如果更改了版本，提交并推送
- [ ] 检查构建是否成功

---

## 🟢 低优先级修改（可选）

### 8. 添加构建摘要
**预计时间**: 5 分钟  
**风险**: 无

**在工作流末尾添加**:
```yaml
      - name: Generate build summary
        if: always()
        run: |
          echo "### 🏗️ Build Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          if [ -f packages/*.deb ]; then
            echo "✅ **Build Status**: Success" >> $GITHUB_STEP_SUMMARY
            echo "- Package: $(ls packages/*.deb | xargs basename)" >> $GITHUB_STEP_SUMMARY
            echo "- Size: $(ls -lh packages/*.deb | awk '{print $5}')" >> $GITHUB_STEP_SUMMARY
            echo "- Commit: \`${{ github.sha }}\`" >> $GITHUB_STEP_SUMMARY
          else
            echo "❌ **Build Status**: Failed" >> $GITHUB_STEP_SUMMARY
          fi
```

**验证方法**:
- [ ] 保存文件
- [ ] 提交并推送
- [ ] 在 GitHub Actions 页面查看构建摘要

---

### 9. 添加依赖验证
**预计时间**: 3 分钟  
**风险**: 无

**在构建步骤之前添加**:
```yaml
      - name: Verify dependencies
        run: |
          echo "Verifying libwebp.a..."
          if [ -f libs/libwebp.a ]; then
            lipo -info libs/libwebp.a
            echo "Size: $(ls -lh libs/libwebp.a | awk '{print $5}')"
          else
            echo "⚠️ Warning: libwebp.a not found"
          fi
```

**验证方法**:
- [ ] 保存文件
- [ ] 提交并推送
- [ ] 检查构建日志显示 libwebp.a 架构信息

---

### 10. 添加 GitHub Actions 徽章到 README
**预计时间**: 2 分钟  
**风险**: 无

**在 README.md 顶部添加**:
```markdown
[![Build Status](https://github.com/huami1314/DYYY/workflows/Build%20DYYY/badge.svg)](https://github.com/huami1314/DYYY/actions)
```

**注意**: 
- 将工作流名称 URL 编码（空格 = `%20`）
- 使用实际的仓库路径

**验证方法**:
- [ ] 保存 README.md
- [ ] 提交并推送
- [ ] 查看 GitHub 仓库页面，确认徽章显示正确

---

### 11. 添加构建矩阵（可选，高级）
**预计时间**: 10 分钟  
**风险**: 中（会增加构建时间和资源使用）

**完全重构工作流以支持多版本**:
```yaml
jobs:
  build:
    runs-on: macos-13
    
    strategy:
      matrix:
        sdk: ["16.5"]
        scheme: ["rootless", "roothide"]
    
    steps:
      # ... 其他步骤保持不变
      
      - name: Build package
        run: |
          rm -f packages/*
          make package \
            THEOS_PACKAGE_SCHEME=${{ matrix.scheme }} \
            TARGET=iphone:clang:${{ matrix.sdk }}:11.0 \
            FINALPACKAGE=1 \
            -j$(sysctl -n hw.ncpu)
```

**验证方法**:
- [ ] 保存文件
- [ ] 提交并推送
- [ ] 确认启动了多个构建任务
- [ ] 检查每个任务生成对应的产物

---

## 🚀 实施步骤建议

### 第1天：基础稳定性（必须）
1. ✅ 固定 macOS runner 版本
2. ✅ 添加分支过滤
3. ✅ 添加构建验证

**检查点**: 
- [ ] 所有修改已提交
- [ ] 至少一次成功的构建
- [ ] 验证步骤在日志中可见

---

### 第2天：产物管理（推荐）
4. ✅ 改进产物命名
5. ✅ 添加保留策略
6. ✅ 添加超时保护

**检查点**:
- [ ] 产物名称包含构建号
- [ ] 保留期设置正确
- [ ] 工作流配置完整

---

### 第1周：完善细节（可选）
7. ✅ 联系 theos-action 维护者
8. ✅ 添加构建摘要
9. ✅ 添加依赖验证

**检查点**:
- [ ] 构建日志信息丰富
- [ ] GitHub Actions 界面清晰
- [ ] 依赖状态可见

---

### 第2周：锦上添花（可选）
10. ✅ 添加状态徽章
11. ✅ 考虑构建矩阵（如果需要）

**检查点**:
- [ ] README 展示构建状态
- [ ] 多版本构建（如果实施）

---

## ✅ 最终验证清单

完成所有修改后，进行全面测试：

### 功能测试
- [ ] 推送到主分支触发构建
- [ ] 推送到其他分支**不**触发构建
- [ ] 只修改 .md 文件**不**触发构建
- [ ] PR 到主分支触发构建
- [ ] 手动触发工作流成功

### 构建质量
- [ ] 构建成功完成
- [ ] .deb 文件正确生成
- [ ] 产物可以下载
- [ ] 产物命名符合预期
- [ ] 构建日志清晰易读

### 性能检查
- [ ] 构建时间合理（2-5分钟）
- [ ] 缓存工作正常
- [ ] 没有不必要的构建

### 文档更新
- [ ] README 包含构建徽章（如果添加）
- [ ] 工作流文件有清晰的注释
- [ ] 团队成员了解新的配置

---

## 🆘 故障排除

### 问题 1: 分支过滤后没有构建触发

**可能原因**: 分支名称不匹配

**解决方案**:
```bash
# 检查当前分支名
git branch --show-current

# 确保工作流中的分支名与实际匹配
# 例如：main vs master
```

---

### 问题 2: 手动触发按钮不显示

**可能原因**: 工作流文件有语法错误

**解决方案**:
```bash
# 验证 YAML 语法
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yml'))"

# 或使用在线 YAML 验证器
```

---

### 问题 3: 构建失败，提示找不到 .deb

**可能原因**: 实际构建失败了，但错误被忽略

**解决方案**:
- 检查 "Build package" 步骤的完整日志
- 查看 make 命令的输出
- 确认 Theos 正确安装

---

### 问题 4: 缓存不工作

**可能原因**: 缓存键计算失败

**解决方案**:
```yaml
# 添加错误处理
- name: Check cache key
  run: |
    git ls-remote https://github.com/roothide/theos | head -n 1 | cut -f 1 || echo "fallback-key"
```

---

## 📞 获取帮助

如果遇到问题：

1. 查看完整审查报告中的"常见问题"部分
2. 检查 GitHub Actions 文档：https://docs.github.com/en/actions
3. 查看构建日志的详细错误信息
4. 在项目中开 Issue 讨论

---

## 📊 进度跟踪

| 阶段 | 任务数 | 完成数 | 进度 |
|------|--------|--------|------|
| 高优先级 | 3 | 0 | ⬜⬜⬜ 0% |
| 中优先级 | 4 | 0 | ⬜⬜⬜⬜ 0% |
| 低优先级 | 4 | 0 | ⬜⬜⬜⬜ 0% |
| **总计** | **11** | **0** | **0%** |

在实施过程中更新此表格，跟踪进度。

---

**创建日期**: 2024-11-09  
**最后更新**: 2024-11-09  
**状态**: 待实施
