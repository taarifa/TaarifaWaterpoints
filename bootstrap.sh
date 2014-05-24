if [[ -f $HOME/.profile ]]; then
  . $HOME/.profile
fi
mkvirtualenv TaarifaAPI
if [[ ! -d TaarifaAPI ]]; then
  git clone https://github.com/taarifa/TaarifaAPI
fi
(cd TaarifaAPI;
 python setup.py develop)
if [[ ! -d TaarifaWaterpoints ]]; then
  git clone https://github.com/taarifa/TaarifaWaterpoints
fi
(cd TaarifaWaterpoints;
 pip install -r requirements.txt
 npm install)
