#/usr/bin/python

"""
This script walks the user through the Admin node SSL certificate setup
for CaaSP in the Public Cloud. It is framework independent
"""

print "Welcome to the SSL configuration for SUSE Caas Platform in the Public Cloud"
print
print "The following few questions will let you configure SSL for the Administrative node for SUSE CaaS Platform and it should take you only a couple of minutes to get started"
print
own_cert = raw_input("Would you like to use your own certificate from a known (public or self signed) Certificate Authority [Y/n]: ")

has_owncert = None
if own_cert in ['Y','y','yes', 'Yes']:
   # Make the directory
   copy_complete = raw_input("Please copy you certificate and the key to /tmp/caasp_cert, press enter when th eupload is complete ")
   # Copy the cert
   has_owncert = True

# run activate.sh

if not has_owncert:
   print "The fingerprint of the generated certificate is: ...."
