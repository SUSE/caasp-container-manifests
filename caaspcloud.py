# COPYRIGHT 2017 SUSE Linux GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
import yaml
import json
import sys
import os.path
import logging
import copy

_PROVIDERS_DIR="/etc/salt/cloud.providers.d"
_PROFILES_DIR="/etc/salt/cloud.profiles.d"

log=logging.getLogger(__name__)

def dict_merge(a, b):
    if not isinstance(b, dict):
        return b
    result = copy.deepcopy(a)
    for k, v in b.iteritems():
        if k in result and isinstance(result[k], dict):
            result[k] = dict_merge(result[k], v)
        else:
            result[k] = copy.deepcopy(v)
    return result

def _update_yaml(cfg_file, config_new):
    if os.path.isfile(cfg_file):
        config_old = yaml.load(open(cfg_file, 'r').read())
        # This file should have only one key
        if len(config_old.keys()) != 1:
            log.error("File {} has unexpected format.".format(cfg_file))
            return False
        config = dict_merge(config_old, config_new)
    else:
	log.debug("File {} does not exist, will be created.".format(cfg_file))
	config = config_new
    with open(cfg_file, 'w') as outfile:
        yaml.safe_dump(config, outfile, default_flow_style=False)
    return True

def _update_config(cfg_path, config):
    if config is None:
        log.error('Parameter "config" is missing')
        return False
    success = True
    # update each section individually (individual files)
    for section_name in config.keys():
        if not section_name:
            log.error('Empty section name')
            return False
        log.debug("Updating {} configuration in {}".format(section_name, cfg_path))
        success = success and _update_yaml("{}/{}.conf".format(cfg_path, section_name),
                                           { section_name: config[section_name] })
    return success


# Update a salt-cloud provider configuration.
#
def update_providers(*args, **kwargs):
    return _update_config(_PROVIDERS_DIR, kwargs.get('config'))


# Update a salt-cloud profile configuration.
#
def update_profiles(*arg, **kwargs):
    return _update_config(_PROFILES_DIR, kwargs.get('config'))

