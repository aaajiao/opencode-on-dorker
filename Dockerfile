# ================================================
# 版本参数 (从 versions.lock 读取)
# ================================================
ARG BUN_VERSION=1.3.5
ARG PIP_REQUESTS=2.32.5
ARG PIP_PANDAS=2.2.3
ARG PIP_NUMPY=2.2.1
ARG PIP_MATPLOTLIB=3.10.0
ARG PIP_BEAUTIFULSOUP4=4.12.3
ARG PIP_PILLOW=11.1.0
ARG PIP_NOTEBOOKLM_PY=0.1.4
ARG OPENCODE_AI_VERSION=1.1.4

FROM oven/bun:${BUN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------------
# 第一步：安装系统基础依赖
# -------------------------------------------------------
RUN apt-get update && apt-get install -y \
    git curl wget ca-certificates gnupg unzip zip nano procps \
    python3-full python3-pip build-essential \
    xdg-utils jq tmux \
    libjpeg-dev zlib1g-dev libfreetype6-dev pkg-config libopenblas-dev gfortran \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------
# 第二步：安装 Node.js (用于 npx MCP 服务器)
# -------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# -------------------------------------------------------
# 第三步：安装 Playwright 浏览器依赖 (ARM64 兼容)
# -------------------------------------------------------
# 全局安装 playwright 确保浏览器下载到持久化路径 /root/.cache/ms-playwright/
# 同时创建 /opt/google/chrome/chrome symlink 供 @playwright/mcp 使用
RUN npm install -g playwright && \
    npx playwright install --with-deps chromium && \
    CHROME_BIN=$(find /root/.cache/ms-playwright/chromium-* -name "chrome" -type f -executable 2>/dev/null | head -1) && \
    if [ -n "$CHROME_BIN" ]; then \
        mkdir -p /opt/google/chrome && \
        ln -sf "$CHROME_BIN" /opt/google/chrome/chrome && \
        echo "✅ Chromium installed: $($CHROME_BIN --version 2>/dev/null || echo 'ready')"; \
    else \
        echo "⚠️ Chromium binary not found"; \
    fi

# -------------------------------------------------------
# 第四步：安装 uv (用于 uvx MCP 服务器)
# -------------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# -------------------------------------------------------
# 第五步：xdg-open 写入文件触发 Mac 打开
# -------------------------------------------------------
RUN echo '#!/bin/bash\n\
URL="$1"\n\
[[ -z "$URL" ]] && exit 0\n\
\n\
echo "$URL" > /root/.opencode/open_url\n\
echo "🔗 正在打开: $URL"\n\
' > /usr/local/bin/xdg-open-custom && \
    chmod +x /usr/local/bin/xdg-open-custom

# -------------------------------------------------------
# 第六步：覆盖系统 xdg-open
# -------------------------------------------------------
RUN if [ -f /usr/bin/xdg-open ]; then mv /usr/bin/xdg-open /usr/bin/xdg-open.bak; fi && \
    ln -sf /usr/local/bin/xdg-open-custom /usr/bin/xdg-open && \
    ln -sf /usr/local/bin/xdg-open-custom /bin/xdg-open || true

# -------------------------------------------------------
# 第七步：安装 GitHub CLI
# -------------------------------------------------------
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh

# -------------------------------------------------------
# 第八步：Python 虚拟环境
# -------------------------------------------------------
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 重新声明 ARG (FROM 后需要再次声明)
ARG PIP_REQUESTS
ARG PIP_PANDAS
ARG PIP_NUMPY
ARG PIP_MATPLOTLIB
ARG PIP_BEAUTIFULSOUP4
ARG PIP_PILLOW
ARG PIP_NOTEBOOKLM_PY

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    requests==${PIP_REQUESTS} \
    pandas==${PIP_PANDAS} \
    numpy==${PIP_NUMPY} \
    matplotlib==${PIP_MATPLOTLIB} \
    beautifulsoup4==${PIP_BEAUTIFULSOUP4} \
    pillow==${PIP_PILLOW} \
    notebooklm-py==${PIP_NOTEBOOKLM_PY}

# -------------------------------------------------------
# 第九步：安装 OpenCode
# -------------------------------------------------------
ARG OPENCODE_AI_VERSION
RUN bun add -g opencode-ai@${OPENCODE_AI_VERSION}

# -------------------------------------------------------
# 第十步：剪贴板桥接 - 伪 xclip 将内容写入文件供 Mac pbcopy
# -------------------------------------------------------
COPY scripts/fake-xclip.sh /usr/local/bin/xclip
RUN chmod +x /usr/local/bin/xclip && \
    ln -s /usr/local/bin/xclip /usr/local/bin/xsel

# -------------------------------------------------------
# 第十一步：通知系统 - 写入共享文件，宿主机监听并发送 macOS 通知
# -------------------------------------------------------
RUN echo '#!/bin/bash\n\
TITLE="${1:-OpenCode}"\n\
MSG="${2:-通知}"\n\
echo "${TITLE}|${MSG}" >> /root/.opencode/notifications\n\
' > /usr/local/bin/notify && \
    chmod +x /usr/local/bin/notify

RUN echo '#!/bin/bash\n\
if [[ "$*" == *"display notification"* ]]; then\n\
  MSG=$(echo "$*" | sed -n '"'"'s/.*display notification "\\([^"]*\\)".*/\\1/p'"'"')\n\
  TITLE=$(echo "$*" | sed -n '"'"'s/.*with title "\\([^"]*\\)".*/\\1/p'"'"')\n\
  [[ -z "$TITLE" ]] && TITLE="OpenCode"\n\
  [[ -n "$MSG" ]] && notify "$TITLE" "$MSG"\n\
fi\n\
' > /usr/local/bin/osascript && chmod +x /usr/local/bin/osascript

RUN echo '#!/bin/bash\n\
TITLE="${1:-通知}"\n\
MSG="${2:-}"\n\
[[ -n "$MSG" ]] && notify "$TITLE" "$MSG"\n\
' > /usr/local/bin/notify-send && chmod +x /usr/local/bin/notify-send

# -------------------------------------------------------
# 第十二步：Exa 健康检查脚本 - 检测内置 Exa 是否可用
# -------------------------------------------------------
RUN echo '#!/bin/bash\n\
# 检测 oh-my-opencode 内置 Exa 是否可用\n\
# 通过直接调用 Exa API 测试\n\
\n\
EXA_API_KEY="${EXA_API_KEY:-}"\n\
\n\
if [[ -z "$EXA_API_KEY" ]]; then\n\
    echo "no_key"\n\
    exit 0\n\
fi\n\
\n\
# 测试 Exa API 是否可用（简单的搜索请求）\n\
RESPONSE=$(curl -s -w "\\n%{http_code}" --max-time 5 \\\n\
    -X POST "https://api.exa.ai/search" \\\n\
    -H "Content-Type: application/json" \\\n\
    -H "x-api-key: $EXA_API_KEY" \\\n\
    -d '"'"'{"query":"test","numResults":1}'"'"' 2>/dev/null)\n\
\n\
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)\n\
\n\
if [[ "$HTTP_CODE" == "200" ]]; then\n\
    echo "ok"\n\
else\n\
    echo "failed"\n\
fi\n\
' > /usr/local/bin/check-exa && \
    chmod +x /usr/local/bin/check-exa

# -------------------------------------------------------
# 第十三步：预创建 .claude 挂载点目录
# 支持父目录只读挂载后的子目录覆盖挂载
# -------------------------------------------------------
RUN mkdir -p /root/.claude/todos \
             /root/.claude/transcripts \
             /root/.claude/commands \
             /root/.claude/skills \
             /root/.claude/agents \
             /root/.claude/rules

# -------------------------------------------------------
# 第十四步：收尾配置
# -------------------------------------------------------
WORKDIR /workspace

ENV PATH="/root/.local/bin:/opt/venv/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

RUN git config --global user.email "ai@opencode.orbstack" && \
    git config --global user.name "OpenCode Agent"

# -------------------------------------------------------
# 第十五步：Entrypoint 脚本 - 处理环境变量、GitHub 认证、Exa 检测、浏览器修复
# -------------------------------------------------------
RUN echo '#!/bin/bash\n\
\n\
# 调试函数\n\
ocd_debug() { [[ "$OCD_DEBUG" == "1" ]] && echo "[debug] $*" >&2 || true; }\n\
\n\
env | grep -E "^(GITHUB_TOKEN|ANTHROPIC_API_KEY|OPENAI_API_KEY|QUOTIO_|EXA_)=" >> /root/.bashrc\n\
\n\
# 确保缓存目录存在\n\
ocd_debug "检查容器内目录状态..."\n\
if [[ ! -d "/root/.cache/oh-my-opencode" ]]; then\n\
    ocd_debug "/root/.cache/oh-my-opencode 不存在，正在创建..."\n\
    mkdir -p /root/.cache/oh-my-opencode\n\
fi\n\
mkdir -p /root/.cache/oh-my-opencode/bin 2>/dev/null\n\
chmod 755 /root/.cache/oh-my-opencode /root/.cache/oh-my-opencode/bin 2>/dev/null || true\n\
ocd_debug "目录状态: $(ls -la /root/.cache/oh-my-opencode/ 2>&1)"\n\
\n\
# Playwright MCP: verify/fix Chrome symlink and clean stale locks\n\
rm -rf /root/.cache/ms-playwright/mcp-chrome 2>/dev/null\n\
if [ -d "/root/.cache/ms-playwright" ]; then\n\
    CHROME_PATH=$(find /root/.cache/ms-playwright/chromium-* -name "chrome" -type f -executable 2>/dev/null | head -1)\n\
    if [ -n "$CHROME_PATH" ] && [ -x "$CHROME_PATH" ]; then\n\
        mkdir -p /opt/google/chrome\n\
        ln -sf "$CHROME_PATH" /opt/google/chrome/chrome 2>/dev/null\n\
        CHROME_VER=$(/opt/google/chrome/chrome --version 2>/dev/null | head -1 || echo "ready")\n\
        echo "✅ Playwright Chromium: $CHROME_VER"\n\
    else\n\
        echo "⚠️  Playwright Chromium 未找到，浏览器功能可能不可用"\n\
    fi\n\
else\n\
    echo "⚠️  Playwright 未安装，浏览器功能不可用"\n\
fi\n\
\n\
if [[ -n "$GITHUB_TOKEN" ]]; then\n\
    if gh auth status &>/dev/null; then\n\
        echo "✅ GitHub 已认证 (使用 GITHUB_TOKEN)"\n\
    else\n\
        echo "⚠️  GITHUB_TOKEN 无效，请检查 token"\n\
    fi\n\
fi\n\
\n\
CONFIG_FILE="/root/.config/opencode/opencode.json"\n\
if [[ -f "$CONFIG_FILE" ]]; then\n\
    EXA_STATUS=$(check-exa)\n\
    if [[ "$EXA_STATUS" == "ok" ]]; then\n\
        echo "✅ Exa API 可用，使用内置 Exa"\n\
    elif [[ "$EXA_STATUS" == "no_key" ]]; then\n\
        echo "ℹ️  未配置 EXA_API_KEY，Exa 功能不可用"\n\
    else\n\
        echo "⚠️  内置 Exa 不可用，启用 fallback MCP"\n\
        if command -v jq &>/dev/null; then\n\
            jq '"'"'.mcp.exa.enabled = true'"'"' "$CONFIG_FILE" > /tmp/opencode.json && mv /tmp/opencode.json "$CONFIG_FILE"\n\
        else\n\
            sed -i '"'"'s/"exa":[[:space:]]*{[^}]*"enabled":[[:space:]]*false/"exa": {"enabled": true/'"'"' "$CONFIG_FILE" 2>/dev/null || true\n\
        fi\n\
    fi\n\
fi\n\
\n\
if [[ -n "$OCD_START_DIR" && -d "/workspace/$OCD_START_DIR" ]]; then\n\
    cd "/workspace/$OCD_START_DIR"\n\
fi\n\
\n\
# === NotebookLM Skill ===\n\
# 清理可能的断链\n\
[[ -L /root/.notebooklm && ! -e /root/.notebooklm ]] && rm -f /root/.notebooklm\n\
\n\
# 定位当前项目根目录\n\
PROJECT_ROOT="/workspace"\n\
if [[ -n "$OCD_START_DIR" ]]; then\n\
    check_dir="/workspace/$OCD_START_DIR"\n\
    while [[ "$check_dir" != "/workspace" && ! -d "$check_dir/.git" ]]; do\n\
        check_dir=$(dirname "$check_dir")\n\
    done\n\
    [[ -d "$check_dir/.git" ]] && PROJECT_ROOT="$check_dir"\n\
fi\n\
\n\
NOTEBOOKLM_SKILL="$PROJECT_ROOT/.opencode/skill/notebooklm-py"\n\
if [[ -d "$NOTEBOOKLM_SKILL" ]]; then\n\
    # data/ → ~/.notebooklm (认证数据)\n\
    if [[ -d "$NOTEBOOKLM_SKILL/data" ]]; then\n\
        rm -f /root/.notebooklm\n\
        ln -sf "$NOTEBOOKLM_SKILL/data" /root/.notebooklm\n\
        echo "✅ NotebookLM: 已链接认证数据"\n\
    fi\n\
\n\
    # .browsers/* → ~/.cache/ms-playwright/ (合并，不覆盖)\n\
    if [[ -d "$NOTEBOOKLM_SKILL/.browsers" && -n "$(ls -A "$NOTEBOOKLM_SKILL/.browsers" 2>/dev/null)" ]]; then\n\
        for browser_dir in "$NOTEBOOKLM_SKILL/.browsers"/*; do\n\
            [[ -d "$browser_dir" ]] || continue\n\
            browser_name=$(basename "$browser_dir")\n\
            target="/root/.cache/ms-playwright/$browser_name"\n\
            if [[ ! -e "$target" ]]; then\n\
                ln -sf "$browser_dir" "$target"\n\
                echo "✅ NotebookLM: 已链接 $browser_name"\n\
            fi\n\
        done\n\
    else\n\
        echo "ℹ️  NotebookLM: .browsers/ 为空，首次使用请运行:"\n\
        echo "   playwright install chromium"\n\
        echo "   cp -r ~/.cache/ms-playwright/chromium_headless_shell* $NOTEBOOKLM_SKILL/.browsers/"\n\
    fi\n\
fi\n\
# === End NotebookLM Skill ===\n\
\n\
# 始终传递当前工作目录给 opencode（使用 -c 选项明确指定）\n\
exec opencode -c . "$@"\n\
' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
