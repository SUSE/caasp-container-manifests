import json
import logging
import re
import susepubliccloudinfoclient.infoserverrequests as ifsrequest
import yaml

RELEASE_DATE = re.compile('^.*-v(\d{8})-.*')


def get_caasp_release_version():
    """Return the version from os-release"""
    os_release = open('/etc/os-release', 'r').readlines()
    for entry in os_release:
        if entry.startswith('VERSION_ID'):
            version_id = entry.split('=')[-1].strip()
            # We assume that os-release will always have '"' as
            # version delimiters
            version = version_id.strip('"\'')
            logging.info('Release version: "%s"' % version)
            return version


def get_cloud_config_path():
    """Return the path for the cloud configuration file"""
    return '/etc/salt/pillar/cloud.sls'


def get_from_config(config_option):
    """Get the value for the given config option"""
    # Expected low usage of this method, re-read the file on an as needed
    # basis. If this turns out to be an issue cache the content
    config_path = get_cloud_config_path()
    with open(config_path) as config_file:
            config = yaml.load(config_file.read())
    settings = config.get('cloud')
    if not settings:
        return
    return settings.get(config_option)


def get_cluster_image_identifier(framework, region):
    """Return the identifier for the latest cluster node image"""
    cluster_image = get_from_config('cluster_image')
    if cluster_image:
        # The data returned in this code path has built in knowledge
        # about the information consumed by the client from the
        # full pint data
        image_data = {}
        image_data['id'] = cluster_image
        image_data['name'] = cluster_image
        msg = 'Using cluster image from configuration. '
        msg += 'Image data for cluster node image: "%s"'
        logging.info(msg % image_data)
        return image_data
    name_filter = 'name~caasp,name~cluster'
    flavor = get_from_config('procurement_flavor')
    if flavor == 'byos':
        name_filter += ',name~byos'
    else:
        name_filter += ',name!byos'
    version = get_caasp_release_version()
    name_filter += ',name~' + version.replace('.', '-')
    # The cluster image we choose depends on the admin node version,
    # thus we cannot just query for active images. We need to get all
    # images an dthen process accordingly.
    try:
        image_info = ifsrequest.get_image_data(
            framework,
            None,
            'json',
            region,
            name_filter
        )
    except Exception as e:
        logging.error('Pint server access failed: "%s"' % e.message)
        # This message will bubble up through salt
        return 'See /var/log/caasp_cloud_setup.log'
    try:
        image_data = json.loads(image_info)
        available_images = image_data.get('images', [])
        target_image_date = 0
        for image in available_images:
            image_name = image.get('name')
            try:
                date = int(RELEASE_DATE.match(image_name).group(1))
                if date > target_image_date:
                    # If we have multiple images with the same date that
                    # match our filter criteria we have a serious data problem
                    # we cannot really recover, the first one wins
                    target_image = image
            except Exception:
                # Image name with no date stamp skip it
                continue
    except Exception as e:
        logging.error('Could not load json data from pint: "%s"' % e.message)
        # This message will bubble up through salt
        return 'See /var/log/caasp_cloud_setup.log'

    logging.info('Image data for cluster node image: "%s"' % target_image)
    return target_image


def load_platform_module(platform_name):
    mod = __import__('caaspadminsetup.%s' % platform_name, fromlist=[''])
    return mod
