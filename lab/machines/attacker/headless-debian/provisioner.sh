#!/bin/bash

sudo apt update -y && sudo apt upgrade -y && \
sudo apt install -y wget gnupg2 curl ca-certificates apt-transport-https software-properties-common lsb-release postgresql && \
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && \
  chmod 755 msfinstall && \
  ./msfinstall && \
printf '#!/bin/bash\nmsfconsole -n' > start_the_fun.sh && \
chmod +x start_the_fun.sh
