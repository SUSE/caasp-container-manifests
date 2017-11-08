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

def get_salt_cloud_profile_config(image, root_volume_size):
    config = {
        "worker":  {
            "provider": "ec2",
            "image": image,
            "size": "SIZE",
            "script": "/etc/salt/cloud-configure-minion.sh",
            "block_device_mappings": [{
                "DeviceName": "/dev/sda1",
                "Ebs.VolumeSize": root_volume_size
            }],
            "network_interfaces": [{
                "DeviceIndex": 0,
                "AssociatePublicIpAddress": False,
                "SubnetId": "SUBNETID",
                "SecurityGroupId": "SECURITYGROUPID",
            }]
        }
    }
    return config

def get_salt_cloud_provider_config(key_name, private_key_file):
    config = {
        "ec2": {
            "driver": "ec2",
            "keyname": key_name,
            "ssh_interface": "private_ips",
            "ssh_user": "ec2-user",
            "private_key": private_key_file,
            "id": "use-instance-role-credentials",
            "key": "use-instance-role-credentials",
            "location": "LOCATION",
            "minion": {
                "master": get_local_ipv4()
            }
        }
    }
    return config
