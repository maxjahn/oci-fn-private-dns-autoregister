# Automation of DNS Zone Management in Oracle Cloud via Cloud Events & Serverless Functions

This approach uses events to trigger a serverless function to update DNS records. The first element in the implementation is the use of defined tags. The tags will be used for configuring the DNS records to be associated with a virtual machine. Then there are cloud events and rules that will trigger a serverless function. This function then will query some metadata and update DNS records in the private DNS zone.

A detailed description of this implementation can be found in my blog post at https://blog.maxjahn.at/2020/10/cloud-automation-autoregistering-virtual-machines-with-private-dns-zones-in-oracle-oci-using-serverless-functions/.
