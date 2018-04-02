import caaspadminsetup.utils as utils
import json
import logging
import re
import susepubliccloudinfoclient.infoserverrequests as ifsrequest
import yaml

RELEASE_DATE = re.compile('^.*-v(\d{8})-.*')


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
    name_filter = 'name~caasp,name~cluster'
    flavor = utils.get_from_config('procurement_flavor')
    if flavor == 'byos':
        name_filter += ',name~byos'
    else:
        name_filter += ',name!byos'
    image_info = ifsrequest.get_image_data(
        framework,
        'active',
        'json',
        region,
        name_filter
    )
    # We expect only one image but need to handle data inconsistencies
    # Sort by date and use the latest
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
    except Exception:
        # We did not find an image
        # Let the deployment fail somewhere else
        return

    logging.info('Image data for cluster node image: "%s"' % target_image)
    return target_image


def load_platform_module(platform_name):
    mod = __import__('caaspadminsetup.%s' % platform_name, fromlist=[''])
    return mod
