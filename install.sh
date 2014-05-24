sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install -y git python-pip python-setuptools mongodb nodejs
sudo pip install virtualenv virtualenvwrapper
sudo npm install -g grunt-cli

if ! grep -q WORKON_HOME $HOME/.profile; then
  echo "export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME
source /usr/local/bin/virtualenvwrapper.sh" >> $HOME/.profile
fi
