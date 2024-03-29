#!/usr/bin/perl -w

use strict;
use XML::LibXML;

my $xmlns="http://schemas.dmtf.org/ovf/envelope/1";
my $xmlns_vmw="http://www.vmware.com/schema/ovf";
my $xmlns_vssd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData";
my $xmlns_rasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData";
my $file = $ARGV[0];

my $parser = XML::LibXML->new;
open my $fh, "$file" or die "Failed to open $file: $!";
my $string = join('', <$fh>);
my $xml;
eval {
    $xml = $parser->parse_string($string, { no_blanks => 1 });
};
if ($@) {
    my $err = $@;
    die "Failed to parse file $file: $@";
};
close $fh;

#print $xml->toString;

my $root = $xml->documentElement;
$root->setNamespace($xmlns_vmw, 'vmw', 0);

foreach my $oss ($root->getElementsByTagNameNS($xmlns, 'OperatingSystemSection')) {
    # add attributes  ovf:version="11" vmw:osType="debian11_64Guest"
    # to /Envelope/VirtualSystem/OperatingSystemSection
    $oss->setAttributeNS($xmlns, 'version', '11');
    $oss->setAttributeNS($xmlns_vmw, 'osType', 'otherLinux64Guest');

    # Add name for vmware. Yes it neededs to have Info element as first.
    my $virtualSystem = $oss->parentNode;
    my $name = $virtualSystem->getAttributeNS($xmlns, 'id');
    my $nameNode = XML::LibXML::Element->new("Name");
    my $nameNodeText = XML::LibXML::Text->new($name);
    my $newLine = XML::LibXML::Text->new("\n");
    $nameNode->addChild($nameNodeText);
    $virtualSystem->insertAfter($nameNode,$virtualSystem->firstChild->nextNonBlankSibling);
    $virtualSystem->insertBefore($newLine,$nameNode);

    # remove all subelements from /Envelope/VirtualSystem/OperatingSystemSection except Info
    foreach my $child ($oss->childNodes()) {
	next if ($child->nodeName eq 'Info');
#	next if (($child->nodeName eq '#text') and $child->parentNode->nodeName);
	$oss->removeChild($child);
    }
};

# change text value of /Envelope/VirtualSystem/VirtualHardwareSection from virtualbox-2.2 to vmx-10
foreach my $vhs ($root->getElementsByTagNameNS($xmlns_vssd, 'VirtualSystemType')) {
    my $value = $vhs->textContent;
    die "Node ".$vhs->nodePath."/".$vhs->nodeName.
	" have different value than expected virtualbox-2.2. Terminating" if ($value ne 'virtualbox-2.2');

    $vhs->removeChildNodes;
    # https://kb.vmware.com/s/article/1003746
    # vmx-13 means ESXi 6.5 which is expired 15 Oct 2022
    # https://endoflife.date/esxi
    $vhs->appendText('vmx-13');
};

# locate section with AHCI SATA controller and alter it to plase VMWare Sphere Client
foreach my $res_subtype ($root->getElementsByTagNameNS($xmlns_rasd, "ResourceSubType")) {
    if ($res_subtype->textContent eq 'AHCI') {
	# replace AHCI with vmware.sata.ahci
	$res_subtype->removeChildNodes;
	$res_subtype->appendText('vmware.sata.ahci');
	# add <vmw:CoresPerSocket ovf:required="false">1</vmw:CoresPerSocket>
	my $coresPerSocket = XML::LibXML::Element->new('CoresPerSocket');
	$coresPerSocket->setNamespace($xmlns_vmw, 'vmw', 1);
	$coresPerSocket->setAttribute('ovf:required', 'false');
	$coresPerSocket->appendText('1');
	$res_subtype->parentNode->appendText("\t");
	$res_subtype->parentNode->appendChild($coresPerSocket);
	$res_subtype->parentNode->appendText("\n");
    };
}

print $xml->toString;
