package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"time"

	fdk "github.com/fnproject/fdk-go"
	"github.com/oracle/oci-go-sdk/common/auth"
	"github.com/oracle/oci-go-sdk/core"
	"github.com/oracle/oci-go-sdk/dns"
)

// EventsInput structure will match the OCI events format
type EventsInput struct {
	CloudEventsVersion string      `json:"cloudEventsVersion"`
	EventID            string      `json:"eventID"`
	EventType          string      `json:"eventType"`
	Source             string      `json:"source"`
	EventTypeVersion   string      `json:"eventTypeVersion"`
	EventTime          time.Time   `json:"eventTime"`
	SchemaURL          interface{} `json:"schemaURL"`
	ContentType        string      `json:"contentType"`
	Extensions         struct {
		CompartmentID string `json:"compartmentId"`
	} `json:"extensions"`
	Data struct {
		CompartmentID      string `json:"compartmentId"`
		CompartmentName    string `json:"compartmentName"`
		ResourceName       string `json:"resourceName"`
		ResourceID         string `json:"resourceId"`
		AvailabilityDomain string `json:"availabilityDomain"`
		FreeFormTags       struct {
		} `json:"freeFormTags"`
		DefinedTags struct {
			Automation struct {
				DNSHostname string `json:"DNSHostname"`
				DNSZone     string `json:"DNSZone"`
			} `json:"Automation"`
		} `json:"definedTags"`
		AdditionalDetails struct {
			Namespace        string `json:"namespace"`
			PublicAccessType string `json:"publicAccessType"`
			ETag             string `json:"eTag"`
		} `json:"additionalDetails"`
	} `json:"data"`
}

func main() {
	fdk.Handle(fdk.HandlerFunc(updateDNSHandler))
}

func updateDNSHandler(ctx context.Context, in io.Reader, out io.Writer) {

	event := &EventsInput{}
	json.NewDecoder(in).Decode(event)

	tagNamespace := os.Getenv("OCI_DNS_TAG_NAMESPACE")
	if tagNamespace == "" {
		tagNamespace = "Automation"
	}
	tagDNSZone := os.Getenv("OCI_DNS_TAG_ZONE")
	if tagDNSZone == "" {
		tagDNSZone = "DNSZone"
	}
	tagHostname := os.Getenv("OCI_DNS_TAG_HOSTNAME")
	if tagHostname == "" {
		tagHostname = "DNSHostname"
	}

	primaryDnszone := event.Data.DefinedTags.Automation.DNSZone
	primaryDnshostname := event.Data.DefinedTags.Automation.DNSHostname

	recOperation := "ADD"
	// remove records for instances that are terminated
	if event.EventType == "com.oraclecloud.computeapi.terminateinstance.begin" {
		recOperation = "REMOVE"
	}

	// exit if no DNSZone found
	if primaryDnszone == "" {
		log.Println("Not matching tag found, skipping DNS record creating for ", event.Data.ResourceID)
		return
	}

	// if no tag present, use the machine hostname
	if primaryDnshostname == "" {
		primaryDnshostname = event.Data.ResourceName
	}

	// exit function if any of the client initializations fail
	provider, err := auth.ResourcePrincipalConfigurationProvider()
	if err != nil {
		log.Fatalln("Error: ", err)
	}
	computeClient, err := core.NewComputeClientWithConfigurationProvider(provider)
	if err != nil {
		log.Fatalln("Error: ", err)
	}
	vnicattachments, err := computeClient.ListVnicAttachments(ctx, core.ListVnicAttachmentsRequest{CompartmentId: &event.Data.CompartmentID, InstanceId: &event.Data.ResourceID})
	if err != nil {
		log.Fatalln("Error: ", err)
	}
	vncClient, err := core.NewVirtualNetworkClientWithConfigurationProvider(provider)
	if err != nil {
		log.Fatalln("Error: ", err)
	}
	dnsClient, err := dns.NewDnsClientWithConfigurationProvider(provider)
	if err != nil {
		log.Fatalln("Error: ", err)
	}

	for _, vnicattachment := range vnicattachments.Items {

		vnic, err := vncClient.GetVnic(ctx, core.GetVnicRequest{VnicId: vnicattachment.VnicId})
		if err != nil {
			log.Println("Error: ", err)
			continue
		}
		ips, err := vncClient.ListPrivateIps(ctx, core.ListPrivateIpsRequest{VnicId: vnicattachment.VnicId})
		if err != nil {
			log.Println("Error: ", err)
			continue
		}

		for _, ip := range ips.Items {

			dnshostname := primaryDnshostname
			dnszone := primaryDnszone

			if *vnic.IsPrimary == true && *ip.IsPrimary == true {
				// for primary IP use default values taken from tags and/or hostname
			} else if ip.DefinedTags[tagNamespace][tagHostname] != nil {
				dnshostname = fmt.Sprintf("%s", ip.DefinedTags[tagNamespace][tagHostname])

				if ip.DefinedTags[tagNamespace][tagDNSZone] != nil {
					dnszone = fmt.Sprintf("%s", ip.DefinedTags[tagNamespace][tagDNSZone])
				}
			} else {
				// skip ip address if neither primary ip nor specific dns hostname defined in tag
				continue
			}

			recRtype := "A"
			recTTL := 30
			recDomain := fmt.Sprintf("%s.%s", dnshostname, dnszone)

			if recOperation == "REMOVE" {
				recDomain = ""
			}

			_, err := dnsClient.PatchZoneRecords(ctx, dns.PatchZoneRecordsRequest{
				ZoneNameOrId: &primaryDnszone,
				PatchZoneRecordsDetails: dns.PatchZoneRecordsDetails{
					Items: []dns.RecordOperation{{
						Domain:    &recDomain,
						Rtype:     &recRtype,
						Rdata:     ip.IpAddress,
						Ttl:       &recTTL,
						Operation: dns.RecordOperationOperationEnum(recOperation),
					}},
				},
			})
			if err != nil {
				log.Println("Error when trying to update DNS Zone: ", err)
			}
			log.Printf("%s operation for DNS record A %s %s completed successfully.\n", recOperation, recDomain, *ip.IpAddress)
		}
	}

}
