from setuptools import setup

dep_links = ['git+https://github.com/taarifa/TaarifaAPI#egg=TaarifaAPI-dev']
setup(name='TaarifaWaterpoints',
      version='dev',
      description='Waterpoint management system for Tanzania',
      long_description=open('README.rst').read(),
      author='The Taarifa Organisation',
      author_email='taarifadev@gmail.com',
      url='http://taarifa.org',
      download_url='https://github.com/taarifa/TaarifaWaterpoints',
      classifiers=[
          'Development Status :: 3 - Alpha',
          'Intended Audience :: Developers',
          'Intended Audience :: Science/Research',
          'License :: OSI Approved :: BSD License',
          'Operating System :: OS Independent',
          'Programming Language :: Python :: 2',
          'Programming Language :: Python :: 2.6',
          'Programming Language :: Python :: 2.7',
      ],
      packages=['taarifa_waterpoints'],
      include_package_data=True,
      zip_safe=False,
      install_requires=['TaarifaAPI==dev', 'Flask-Script==2.0.3'],
      dependency_links=dep_links)
