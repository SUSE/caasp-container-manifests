#!/usr/bin/python
"""Setup module for caasp-setup-admin"""

import sys

try:
    import setuptools
except ImportError:
    sys.stderr.write('Python setuptools required, please install.')
    sys.exit(1)

if __name__ == '__main__':
    setuptools.setup(
        name='caasp-admin-setup',
        description=(
            'Script to set up a SUSE CaaSP admin node'),
        url='https://github.com/SUSE/pubcloud',
        license='MIT',
        author='SUSE Public Cloud Team',
        author_email='public-cloud-dev@susecloud.net',
        version='1.1.0',
        packages=setuptools.find_packages('lib'),
        package_dir={
            '': 'lib',
        },
        scripts=['caasp-admin-setup']
    )
