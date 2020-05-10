# 推荐一个最下安装版
FROM alpine:3

ARG CODE_URL
ARG CODE_RELEASE

# linux and softs
RUN echo "**** update linux ****" && \
    apk add --no-cache openssh sh bash vim curl jq tar git

# Code-Server
RUN echo "**** install code-server ****" && \
    if [ -z ${CODE_URL+x} ]; then \
        if [ -z ${CODE_RELEASE+x} ]; then \
            CODE_RELEASE=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/latest" \
            | awk '/tag_name/{print $4;exit}' FS='[""]'); \
        fi && \
        CODE_URL=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/tags/${CODE_RELEASE}" \
            | jq -r '.assets[] | select(.browser_download_url | contains("linux-x86_64")) | .browser_download_url'); \
    fi &&\
    curl -o /tmp/code.tar.gz -L "${CODE_URL}" && \
    mkdir -p /usr/lib/code-server &&\
    tar xzf /tmp/code.tar.gz -C /usr/lib/code-server/ --strip-components=1 && \
    ln -s /usr/lib/code-server/code-server /usr/bin/code-server &&\
    rm -rf /tmp/*

# install code server extension
ENV SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery \
    ITEM_URL=https://marketplace.visualstudio.com/items

RUN echo "**** install code-server extension ****" && \
    code-server --install-extension ms-ceintl.vscode-language-pack-zh-hans &&\
    code-server --install-extension mhutchie.git-graph &&\
    code-server --install-extension esbenp.prettier-vscode 

# config for user
COPY ["locale.json", "/root/.local/share/code-server/User/"]
ADD  "settings2.json", "/root/.local/share/code-server/User/settings.json"

COPY entrypoint.sh /usr/local/bin/

# worksapce
# 测试过程中发现，如果使用root账户，会导致程序部分插件没有访问User/文件夹的权限
RUN mkdir -p /home/project && \
    chmod +x /usr/local/bin/entrypoint.sh &&\
    mkdir -p /root/.local/share/code-server/User/globalStorage

WORKDIR  /home/project
#VOLUME [ "/home/project" ]

# code-server start
EXPOSE 7000
ENTRYPOINT ["entrypoint.sh"]
CMD [ "code-server", "--bind-addr", "0.0.0.0:7000", "--disable-telemetry", "--disable-updates", "/home/project"]


