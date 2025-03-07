FROM debian:11

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>"

ENV VNC_SCREEN_SIZE=1024x768

COPY copyables /

# Update packages, install essential dependencies, and clean up
RUN sed -i s/deb.debian.org/mirrors.ustc.edu.cn/g /etc/apt/sources.list &&\
    sed -i s/security.debian.org/mirrors.ustc.edu.cn/g /etc/apt/sources.list &&\
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    gnupg2 \
    fonts-noto-cjk \
    pulseaudio \
    supervisor \
    x11vnc \
    fluxbox \
    eterm \
    jq \
    unzip \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    rm -rf /var/cache/* /var/log/apt/* /tmp/*

# Install Latest Google Chrome and Chrome Remote Desktop
RUN wget --no-check-certificate -O /tmp/google-chrome-stable.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    wget --no-check-certificate -O /tmp/chrome-remote-desktop.deb https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends /tmp/google-chrome-stable.deb /tmp/chrome-remote-desktop.deb && \
    chrome_version=$(dpkg -l | grep google-chrome | awk '{print $3}' | cut -d'-' -f1) &&\
    chromedriver_url=$(wget --no-check-certificate -qO- https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json | jq -r ".versions[] | select(.version == \"$chrome_version\") | .downloads.chromedriver[] | select(.platform == \"linux64\").url") &&\
    wget --no-check-certificate -O /tmp/chromedriver.zip $chromedriver_url &&\
    unzip -jo /tmp/chromedriver.zip 'chromedriver-linux64/chromedriver' -d /bin &&\
    rm /tmp/google-chrome-stable.deb /tmp/chrome-remote-desktop.deb /tmp/chromedriver.zip

# Configure the environment
RUN useradd -m -G chrome-remote-desktop,pulse-access chrome && \
    usermod -s /bin/bash chrome && \
    ln -s /crdonly /usr/local/sbin/crdonly && \
    ln -s /update /usr/local/sbin/update && \
    mkdir -p /home/chrome/.config/chrome-remote-desktop /home/chrome/.fluxbox && \
    echo ' \n\
       session.screen0.toolbar.visible:        false\n\
       session.screen0.fullMaximization:       true\n\
       session.screen0.maxDisableResize:       true\n\
       session.screen0.maxDisableMove: true\n\
       session.screen0.defaultDeco:    NONE\n\
    ' >> /home/chrome/.fluxbox/init && \
    chown -R chrome:chrome /home/chrome/.config /home/chrome/.fluxbox

USER chrome

VOLUME ["/home/chrome"]

WORKDIR /home/chrome

EXPOSE 5900 9000

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]