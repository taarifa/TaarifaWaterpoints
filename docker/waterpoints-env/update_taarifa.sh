if [[ ! -d TaarifaAPI ]]; then
  git clone https://github.com/taarifa/TaarifaAPI
fi
(cd TaarifaAPI
 git pull
 python setup.py develop --user)
if [[ ! -d TaarifaWaterpoints ]]; then
  git clone https://github.com/taarifa/TaarifaWaterpoints
fi
(cd TaarifaWaterpoints
 git pull
 pip install --user -r requirements/dev.txt
 npm install
 bower install)
