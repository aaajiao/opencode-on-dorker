FROM oven/bun:latest

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
# 第三步：安装 Playwright 浏览器依赖
# -------------------------------------------------------
RUN npx playwright install --with-deps chromium

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
echo "$URL" >> /root/.opencode/open_url\n\
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

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    requests pandas numpy matplotlib beautifulsoup4 pillow

# -------------------------------------------------------
# 第九步：安装 OpenCode
# -------------------------------------------------------
RUN bun add -g opencode-ai

# -------------------------------------------------------
# 第十步：通知脚本 - 写入共享文件，宿主机监听并发送 macOS 通知
# -------------------------------------------------------
RUN echo '#!/bin/bash\n\
TITLE="${1:-OpenCode}"\n\
MSG="${2:-通知}"\n\
echo "${TITLE}|${MSG}" >> /root/.opencode/notifications\n\
' > /usr/local/bin/notify && \
    chmod +x /usr/local/bin/notify

# -------------------------------------------------------
# 第十一步：收尾配置
# -------------------------------------------------------
WORKDIR /workspace

ENV PATH="/root/.local/bin:/opt/venv/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

RUN git config --global user.email "ai@opencode.orbstack" && \
    git config --global user.name "OpenCode Agent"

# -------------------------------------------------------
# 第十二步：Entrypoint 脚本 - 处理环境变量和 GitHub 认证
# -------------------------------------------------------
RUN echo '#!/bin/bash\n\
\n\
# 把环境变量写入 bashrc 供子 shell 使用\n\
env | grep -E "^(GITHUB_TOKEN|ANTHROPIC_API_KEY|OPENAI_API_KEY|QUOTIO_)=" >> /root/.bashrc\n\
\n\
# 检查 GitHub 认证状态（GITHUB_TOKEN 环境变量会被 gh 自动使用）\n\
if [[ -n "$GITHUB_TOKEN" ]]; then\n\
    if gh auth status &>/dev/null; then\n\
        echo "✅ GitHub 已认证 (使用 GITHUB_TOKEN)"\n\
    else\n\
        echo "⚠️  GITHUB_TOKEN 无效，请检查 token"\n\
    fi\n\
fi\n\
\n\
# 启动 opencode\n\
exec opencode "$@"\n\
' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
