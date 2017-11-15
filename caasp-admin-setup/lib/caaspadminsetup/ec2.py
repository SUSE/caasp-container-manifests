import boto3
import ec2metadata
import netifaces
import urllib

_meta_data_base_url = "http://169.254.169.254/2016-09-02/meta-data/"
_cluster_security_group_id = None

def _get_from_metadata(key):
    return ec2metadata.EC2Metadata().get(key)

def _get_instance_region():
    return _get_from_metadata('availability-zone')[:-1]

def _get_instance_mac():
    return netifaces.ifaddresses("eth0")[netifaces.AF_LINK][0]["addr"]

def _get_instance_vpc_id():
    url = "{}/network/interfaces/macs/{}/vpc-id".format(
                                                     _meta_data_base_url,
                                                     _get_instance_mac()
                                                 )
    val = urllib.urlopen(url).read()
    return val

def get_local_ipv4():
    return _get_from_metadata('local-ipv4')

def get_instance_id():
    return _get_from_metadata('instance-id')

def get_instance_subnet_id():
    url = "{}/network/interfaces/macs/{}/subnet-id".format(
                                                        _meta_data_base_url,
                                                        _get_instance_mac()
                                                    )
    val = urllib.urlopen(url).read()
    return val

def get_cluster_security_group_id():
    return _cluster_security_group_id

def create_public_key(key_name, public_key_data):
    client = boto3.client(service_name='ec2', region_name=_get_instance_region())
    client.import_key_pair(
        KeyName = key_name,
        PublicKeyMaterial = public_key_data
    )

def create_security_group(security_group_name):
    global _cluster_security_group_id
    client = boto3.client(service_name='ec2', region_name=_get_instance_region())
    response = client.create_security_group(
                   Description="Autocreated by SUSE CaaSP",
                   GroupName=security_group_name,
                   VpcId=_get_instance_vpc_id()
               )
    group_id = response["GroupId"]
    res = boto3.resource(service_name='ec2', region_name=_get_instance_region())
    sec_group = res.SecurityGroup(group_id)
    sec_group.authorize_ingress(
        IpPermissions=
        [{
            "IpProtocol": "-1",
            "UserIdGroupPairs":
            [{
                'GroupId': sec_group.group_id
            }]
        }]
    )
    sec_group.authorize_ingress(
        IpProtocol="-1",
        CidrIp="{}/32".format(get_local_ipv4())
    )
    _cluster_security_group_id = sec_group.group_id

def get_salt_cloud_profile_config(profile_name, image, root_volume_size):
    config = {
        "worker":  {
            "provider": "ec2",
            "image": image,
            "script": "/usr/share/caasp-cloud-config/cloud-configure-minion.sh",
            "block_device_mappings": [{
                "DeviceName": "/dev/sda1",
                "Ebs.VolumeSize": root_volume_size
            }],
            "network_interfaces": [{
                "DeviceIndex": 0,
                "AssociatePublicIpAddress": False,
                "SecurityGroupId": _cluster_security_group_id,
                "SubnetId": get_instance_subnet_id()
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
            "location": _get_instance_region(),
            "minion": {
                "master": get_local_ipv4()
            }
        }
    }
    return config
