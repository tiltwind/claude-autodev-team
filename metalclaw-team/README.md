# MetalClaw Team

MetalClaw 多智能体开发流水线技能集，用于 Claude Code。通过协调多个子智能体（analyst、designer、improver、developer、reviewer、tester、documenter）将需求转化为经过测试的代码，并同步更新产品设计文档（PRD）。

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
│   ├── improver.md              # 技术专家
│   ├── developer.md             # 开发工程师
│   ├── reviewer.md              # 代码审查员
│   ├── tester.md                # 测试工程师
│   └── documenter.md            # 产品设计文档编写者
├── skills/                      # 技能集
│   ├── metalclaw-product-design/  # 产品设计（无代码）
│   ├── metalclaw-req-prepare/     # 需求粗粒度分析与拆分
│   ├── metalclaw-dev-full/        # 完整开发流水线（固定全部阶段）
│   ├── metalclaw-dev-auto/         # 自动按复杂度选择阶段
│   ├── metalclaw-dev-step/        # 人工分步确认流水线
│   ├── metalclaw-dev-general/     # 通用开发流水线
│   └── metalclaw-dev-lite/        # 精简开发流水线
├── scripts/
│   └── install.sh               # 技能安装脚本
└── README.md
```

## 技能说明

### metalclaw-product-design

产品设计技能，专注于系统角色、模型、状态、流程、规则、应用和页面的设计，不涉及代码。

### metalclaw-req-prepare

需求准备技能。结合项目架构文档（`doc/prd/`）对需求做**粗粒度**的影响范围分析，判断需求是否需要拆分：

- 默认**不拆分**；小需求、中等复杂度需求都保持为一个
- 仅当需求引入 2+ 个相对独立的能力或跨 3+ 模块且有清晰架构切缝时，才建议拆分
- 拆分建议需经用户**显式确认**，确认后按依赖顺序创建多个 `<dev-session-dir>`，并写入 `requirement-raw.md`
- 只从模块/架构层面思考，不读代码、不深入到函数/文件层面
- 拆分出的需求相对独立，可以有顺序依赖（通过目录序号 `<NNN>` 体现）

适合作为大型需求进入后续开发流水线（`metalclaw-dev-auto`、`metalclaw-dev-step`、`metalclaw-dev-full` 等）之前的第一步。

### metalclaw-dev-full

完整开发流水线，包含全部 7 个子智能体：

```
analyst -> designer -> improver -> developer -> reviewer -> tester -> documenter
                                    ^                        |
                                    |   (if tests fail)      |
                                    +------------------------+
```

测试失败时自动循环修复（最多3次迭代）。documenter 在最后同步更新 PRD。

### metalclaw-dev-auto

自动按复杂度选择阶段的流水线。`analyst`、`designer`、`developer`、`documenter` 始终执行；在 `designer` 完成后进行**复杂度评估**，自动决定是否启用 `improver`、`reviewer`、`tester`：

```
analyst -> designer -> [improver?] -> developer -> [reviewer?] -> [tester?] -> documenter
```

评估依据包括影响模块数、是否引入新的架构/API/数据模型、是否涉及并发/安全/性能、diff 规模、是否可集成测试等。评估结果写入 `<dev-session-dir>/auto-plan.md`，断点续跑时会沿用已有决策。不确定时倾向**保留**阶段。

### metalclaw-dev-step

人工分步确认流水线。继承 `metalclaw-dev-auto` 的条件阶段选择，并在**除 `documenter` 之外**的每个阶段结束后加入用户确认环节：

- 每个子智能体完成后写入 `<dev-session-dir>/confirmations-<phase>-<NN>.md`（`Status: pending | none`）
- 若有待确认项，流水线将问题呈现给用户，收集答复后**重新启动同一个子智能体**（全新实例），让其应用确认结果更新产出
- 每个阶段最多 3 轮确认，与测试修复循环独立计数
- 断点续跑时，若存在 `pending` 轮次，直接从确认环节恢复

适合需要人工把关关键决策的场景。

### metalclaw-dev-general

通用开发流水线，包含 4 个子智能体：

```
analyst -> designer -> developer -> reviewer
```

适用于需要代码审查但不需要专家评审和集成测试的场景。

### metalclaw-dev-lite

精简开发流水线，包含 4 个子智能体：

```
analyst -> designer -> developer -> documenter
```

适用于快速从需求到代码并同步 PRD 的开发场景。


## 使用方式

安装后，在 Claude Code 中通过斜杠命令调用：

```
/metalclaw-product-design 设计订单管理模块
/metalclaw-req-prepare 重构用户中心，支持企业账户与多租户
/metalclaw-dev-full 实现用户登录功能
/metalclaw-dev-auto 添加数据导出接口
/metalclaw-dev-step 改造支付回调流程
/metalclaw-dev-general 添加数据导出接口
/metalclaw-dev-lite 修复分页查询 bug
```

## 推荐组合

- **大型/跨模块需求**：先跑 `/metalclaw-req-prepare` 做拆分，再对每个拆出的 `<dev-session-dir>` 按依赖顺序运行 `/metalclaw-dev-auto` 或 `/metalclaw-dev-step`。
- **一般业务需求**：直接 `/metalclaw-dev-auto`，让流水线自行判断是否需要 improver / reviewer / tester。
- **关键/高风险改动**：用 `/metalclaw-dev-step`，每阶段人工确认。
- **小 bug / 文案调整**：`/metalclaw-dev-lite`。
