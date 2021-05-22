cd /chia-blockchain

. ./activate
chia init

if [[ ${ca} == "new" ]]; then
  echo "### to use your own ca pass the ca folder -v /path/to/ca:/path/in/container and -e ca=\"/path/in/container\""
else
  echo "### Starting chia init with own ca: ${ca}"
  chia init -c ${ca}
fi

if [[ ${keys} == "generate" ]]; then
  echo "### to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  chia keys generate
elif [[ ${keys} == "false" ]]; then
  echo "### Not adding keys"
else
  echo "### Adding keys"
  chia keys add -f ${keys}
fi

for p in ${plots_dir//:/ }; do
    mkdir -p ${p}
    if [[ ! "$(ls -A $p)" ]]; then
        echo "### Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    chia plots add -d ${p}
done

sed -i 's/localhost/127.0.0.1/g' ~/.chia/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  echo "### Starting farmer-only"
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} ]]; then
    echo "A farmer peer address and port are required."
    exit
  else
    echo "### configure farmer"
    chia configure --set-farmer-peer ${farmer_address}:${farmer_port}
    echo "### Starting harvester"
    chia start harvester -r
  fi
else
  echo "### Starting farmer"
  chia start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    chia configure --set-fullnode-port 58444
  else
    chia configure --set-fullnode-port ${var.full_node_port}
  fi
fi

if [[ ! -z ${chiadash_api_token} ]]; then
  wget https://github.com/felixbrucker/chia-dashboard-satellite/releases/download/1.9.0/chia-dashboard-satellite-1.9.0-linux.zip
  unzip chia-dashboard-satellite-1.9.0-linux.zip
  sed -i "s/<chiadash_api_token>/${chiadash_api_token}/g" /root/.config/chia-dashboard-satellite/config.yaml
  ./chia-dashboard-satellite-1.9.0/chia-dashboard-satellite &
fi

if [[ ${chiadog} == "true" ]]; then
  cd /chiadog
  chia configure -log-level=INFO
  sed -i "s/<pushover_api_token>/${chiadog_pushover_api_token}/g" ./config.yaml
  sed -i "s/<pushover_user_key>/${chiadog_pushover_user_key}/g" ./config.yaml
  . ./venv/bin/activate
  nohup python3 -u main.py --config config.yaml > chiadog.log
fi


while true; do sleep 30; done;
