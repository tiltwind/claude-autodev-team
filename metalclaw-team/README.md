# MetalClaw Team

MetalClaw 多智能体开发流水线技能集，用于 Claude Code。通过协调多个子智能体（analyst、designer、expert、developer、reviewer、tester）将需求转化为经过测试的代码。

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/tiltwind/claude-autodev-team/main/metalclaw-team/scripts/install.sh | bash
```


## 目录结构

```
metalclaw-team/
├── metalclaw-sub-agents/        # 共享子智能体定义
│   ├── analyst.md               # 需求分析师
│   ├── designer.md              # 技术设计师
│   ├── expert.md                # 技术专家
│   ├── developer.md             # 开发工程师
│   ├── reviewer.md              # 代码审查员
│   └── tester.md                # 测试工程师
├── skills/                      # 技能集
│   ├── metalclaw-product-design/  # 产品设计（无代码）
│   ├── metalclaw-dev-full/        # 完整开发流水线
│   ├── metalclaw-dev-general/     # 通用开发流水线
│   └── metalclaw-dev-lite/        # 精简开发流水线
├── scripts/
│   └── install.sh               # 技能安装脚本
└── README.md
```

## 技能说明

### metalclaw-product-design

产品设计技能，专注于系统角色、模型、状态、流程、规则、应用和页面的设计，不涉及代码。

### metalclaw-dev-full

完整开发流水线，包含全部6个子智能体：

```
analyst -> designer -> expert -> developer -> reviewer -> tester
                                    ^                        |
                                    |   (if tests fail)      |
                                    +------------------------+
```

测试失败时自动循环修复（最多3次迭代）。

### metalclaw-dev-general

通用开发流水线，包含4个子智能体：

```
analyst -> designer -> developer -> reviewer
```

适用于需要代码审查但不需要专家评审和集成测试的场景。

### metalclaw-dev-lite

精简开发流水线，包含3个子智能体：

```
analyst -> designer -> developer
```

适用于快速从需求到代码的开发场景。


## 使用方式

安装后，在 Claude Code 中通过斜杠命令调用：

```
/metalclaw-dev-full 实现用户登录功能
/metalclaw-dev-general 添加数据导出接口
/metalclaw-dev-lite 修复分页查询 bug
/metalclaw-product-design 设计订单管理模块
```
