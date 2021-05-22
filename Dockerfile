FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

ENV ca="new"
ENV keys="false"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV full_node_port="null"
ENV branch="1.1.6"

RUN DEBIAN_FRONTEND=noninteractive apt update \
&& apt install -y ca-certificates openssl sudo python3.8-venv python3.8-distutils python3.8-dev git lsb-release wget unzip

RUN echo "cloning ${branch}"
RUN git clone --branch ${branch} https://github.com/Chia-Network/chia-blockchain.git \
&& cd chia-blockchain \
&& git submodule update --init mozilla-ca \
&& chmod +x install.sh \
&& /usr/bin/sh ./install.sh \
&& cd ..

RUN git clone https://github.com/martomi/chiadog.git \
&& cd chiadog \
&& ./install.sh

ADD ./chiadog-config.yaml chiadog/config.yaml
ADD ./chia-dash-config.yaml /root/.config/chia-dashboard-satellite/config.yaml

WORKDIR /chia-blockchain
ADD ./entrypoint.sh entrypoint.sh

ENTRYPOINT ["bash", "./entrypoint.sh"]
