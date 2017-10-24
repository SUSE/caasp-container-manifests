import boto3
import ec2metadata

def _get_from_metadata(key):
    return ec2metadata.EC2Metadata().get(key)

def _get_instance_region():
    return _get_from_metadata('availability-zone')[:-1]

def get_local_ipv4():
    return _get_from_metadata('local-ipv4')

def get_instance_id():
    return _get_from_metadata('instance-id')

def create_public_key(key_name, public_key_data):
    client = boto3.client(service_name='ec2', region_name=_get_instance_region())
    client.import_key_pair(
        KeyName = key_name,
        PublicKeyMaterial = public_key_data
    )

def generate_salt_cloud_config(
        config_dir,
        key_name,
        private_key_file,
        image,
        root_volume_size
    ):
    providers_conf = """\
ec2:
  driver: ec2
  keyname: {}
  ssh_interface: private_ips
  ssh_user: ec2-user
  private_key: {}
  id: use-instance-role-credentials
  key: use-instance-role-credentials
  location: LOCATION
  minion:
    master: {}
""".format(key_name, private_key_file, get_local_ipv4())
    providers_conf_file = open('{}/cloud.providers'.format(config_dir), 'w')
    providers_conf_file.write(providers_conf)
    providers_conf_file.close()

    profiles_conf = """\
worker:
  provider: ec2
  size: SIZE
  image: {}
  script: /etc/salt/cloud-configure-minion.sh
  block_device_mappings:
    - DeviceName: /dev/sda1
      Ebs.VolumeSize: {}
  network_interfaces:
    - DeviceIndex: 0
      AssociatePublicIpAddress: False
      SubnetId: SUBNETID
      SecurityGroupId: SECURITYGROUPID
""".format(image, root_volume_size)
    profiles_conf_file = open('{}/cloud.profiles'.format(config_dir), 'w')
    profiles_conf_file.write(profiles_conf)
    profiles_conf_file.close()

