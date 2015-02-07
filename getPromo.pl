#!/usr/bin/perl

use strict;
#use utf8 ;
use Data::Dumper;
use HTML::Entities ;
use RequestSignatureHelper;
use LWP::UserAgent;
use XML::Simple;
use URI::Escape;
use CGI;

use Config::Tiny ;
my $Config = Config::Tiny->new();
$Config = Config::Tiny->read( './AMZ2Yourls.ini' );
my $AWSId = $Config->{AMZ}->{AWSId};
my $AWSSecret = $Config->{AMZ}->{AWSSecret};
my $AWSAssociateTag = $Config->{AMZ}->{AWSAssociateTag};
my $AWSEndPoint = $Config->{AMZ}->{AWSEndPoint};
my $YourlsId = $Config->{YOURLS}->{YOURLSSignature};
my $YourlsEndPoint = $Config->{YOURLS}->{YOURLSEndPoint};

my $AMZItem ;
my $showLinks ;
my $cgi ;

$cgi = new CGI ;
print $cgi->header(-type => 'text/html', -charset => 'utf-8') ;
print $cgi->start_html(-title=>"Amazon Promo lister", -encoding=>"UTF-8") ;
my $keyword = $cgi->param('q') ;
my $categ = $cgi->param('categ') ;
my $reduc = $cgi->param('reduc') ;
#$reduc = 70 ;
if ($reduc !~ /[0-9]+/)
{
	$reduc = 70 ;
}
if ($categ !~ /./)
{
	$categ = "Electronics" ;
}
print '<form id="formsearch" class="appnitro"  method="post" action="getPromo.pl">
<div>
<label class="description" for="element_1">Mot Clef </label>
<input id="q" name="q" class="element text medium" type="text" maxlength="255" value="'.$keyword.'"/> 
		<label class="description" for="element_1">Category </label>
		<select class="element select medium" id="categ" name="categ">' ;
my $categories ;
$categories->{'Automobile'} = 'Automotive' ;
$categories->{'Bebe'} = 'Baby' ;
$categories->{'Beaute'} = 'Beauty' ;
$categories->{'Bijoux'} = 'Jewelry' ;
$categories->{'Bricolage'} = 'Tools' ;
$categories->{'Bureau'} = 'OfficeProducts' ;
$categories->{'Chaussures'} = 'Shoes' ;
$categories->{'Cuisine'} = 'Kitchen' ;
$categories->{'Electronics'} = 'Electronics' ;
$categories->{'DVD'} = 'DVD' ;
$categories->{'Exterieur'} = 'OutdoorLiving' ;
$categories->{'Instruments de Musique'} = 'MusicalInstruments' ;
$categories->{'Jardin'} = 'HomeGarden' ;
$categories->{'Jeux Video'} = 'VideoGames' ;
$categories->{'Jouets'} = 'Toys' ;
$categories->{'KindleStore'} = 'KindleStore' ;
$categories->{'Livres'} = 'Books' ;
$categories->{'Logiciel'} = 'Software' ;
$categories->{'Luminaires'} = 'Lighting' ;
$categories->{'Magazines'} = 'Magazines' ;
$categories->{'Marketplace'} = 'Marketplace' ;
$categories->{'Montres'} = 'Watches' ;
$categories->{'MP3Downloads'} = 'MP3Downloads' ;
$categories->{'Musique'} = 'Music' ;
$categories->{'PCHardware'} = 'PCHardware' ;
$categories->{'Photo'} = 'Photo' ;
$categories->{'Sport'} = 'SportingGoods' ;
$categories->{'Video'} = 'Video' ;
$categories->{'Vetements'} = 'Apparel' ;
$categories->{'VHS'} = 'VHS' ;

foreach my $scat (sort keys %$categories) 
{
	print "<option"; 
	if ($categories->{$scat} eq $categ) 
	{
		print " selected='selected' " ;
	}
	print " value='$categories->{$scat}'>$scat</option>\n" ;
}
print '		</select>
<label class="description" for="element_1">Reduction % </label>
<input id="reduc" name="reduc" class="element text medium" type="text" maxlength="10" value="'.$reduc.'"/> 
<input id="saveForm" class="button_text" type="submit" name="submit" value="Submit" />
</div> 
</form>' ;
print '<hr align=center width=80%/>' ;
if ($keyword !~ /.+/)
{
	print "<h3 color=red align=center>Il Manque des mots clef ...</h3>\n" ;
$keyword = "sd" ;
$categ = "Electronics" ;
	exit()
}
#my @categories = ("Electronics", "DVD", "Apparel", "Toys", "Jewelry", "PCHardware", "Tools", "Offers", "VideoGames") ;
#my @categories = ("Jewelry") ;
my $results ;
#foreach my $categ (@categories)
{
	my $cptPage = 0 ;
	while ($cptPage++ <=5)
	{
# Set up the helper
#$AWSEndPoint = "ecs.amazonaws.fr" ; 
		my $helper = new RequestSignatureHelper ( $AWSId, $AWSSecret, $AWSEndPoint);
		my $itemId = "" ;
# A simple ItemLookup request
		my $request = {
			Service => 'AWSECommerceService',
			SearchIndex => $categ,
			Operation => 'ItemSearch',
			Version => '2013-08-01',
#ItemId => $itemId,
			ResponseGroup => 'Large',
			Keywords => $keyword,
			MinPercentageOff => $reduc,
			AssociateTag => $AWSAssociateTag,
			ItemPage => $cptPage,
#			Sort => 'popularityrank',
		};

# Sign the request
		my $signedRequest = $helper->sign($request);

# We can use the helper's canonicalize() function to construct the query string too.
		my $queryString = $helper->canonicalize($signedRequest);
		my $url = "http://$AWSEndPoint/onca/xml?" . $queryString;
#print "Sending request to URL: $url \n";

		my $ua = new LWP::UserAgent();
		my $response = $ua->get($url);
		my $content = $response->content();
#print "Recieved Response: $content \n";

		my $xmlParser = new XML::Simple();
#print Dumper($content) ;
		my $xml = $xmlParser->XMLin($content);
#:print $xmlParser->XMLout($content) ;

#print "Parsed XML is: " . Dumper($xml) . "\n";
		my $signedurl ;
		my $title ;
		if ($response->is_success()) {
#print "\n\nXML : ".Dumper($xml->{Items}->{Item}) ;
			if(ref($xml->{Items}->{Item} ) eq 'ARRAY')
			{
				foreach my $item (@{$xml->{Items}->{Item}})
				{
#					print Dumper($item) ;
					my $Price = 0 ;
					my $Sale = 0 ;
					my $Reduc = $reduc ;
					my $reducval = $reduc ;
#Price Search
					if ($item->{ItemAttributes}->{ListPrice}->{Amount} =~ /[0-9]+/)
					{
						$Price = $item->{ItemAttributes}->{ListPrice}->{Amount} / 100 ;
					} elsif ($item->{Offers}->{TotalOfferPages} eq 1)
					{
						$Price = $item->{Offers}->{Offer}->{OfferListing}->{Price}->{Amount} /100 ;
					}

#Sale Search
					if ($Price > 0)
					{	
						if ($item->{Offers}->{TotalOfferPages} eq '1')
						{
							$Sale = $item->{Offers}->{Offer}->{OfferListing}->{Price}->{Amount} /100 ;
						} elsif ($item->{Offers}->{TotalOfferPages} eq '1')
						{
							$Sale = $item->{Offers}->{Offer}->{OfferListing}->{SalePrice}->{Amount} /100 ;
						}
					}

#Reduc Calculus
					if ($Sale > 0)
					{
						$reducval= sprintf "%.2f", 100 - ($Sale * 100 / $Price) ;
						$Reduc = "-$reducval%" ;
					} else {
						$Reduc = "Mini -$reduc%"
					}
					if ((($Price eq '0') || ($Sale eq '0'))&& (1 == 0))
					{
						print "-------------------------\n" ;
						print "-------------------------\n" ;
						print "Price : $Price, Sale : $Sale, Reduc : $Reduc\n" ;
						print Dumper($item) ;
						print "-------------------------\n" ;
						print "-------------------------\n" ;
					}
					if ($Reduc ne "-0.00%")
					{
						my $product->{img} = $item->{SmallImage}->{URL} ;
						$product->{url} = $item->{DetailPageURL} ;
						$product->{title} = $item->{ItemAttributes}->{Title} ;
						$product->{price} = $Price ;
						$product->{sale} = $Sale ;
						$product->{reduc} = $Reduc ;
						$product->{reducval} = $reducval ;
						push(@$results, $product) ;
#						print "<tr><td><img src='".$item->{SmallImage}->{URL}."'/></td><td><a href='".$item->{DetailPageURL}."' target='new'>".$item->{ItemAttributes}->{Title}."</a></td><td>$Price € > $Sale € ($Reduc)</td></tr>\n";
					}
				}

#	$signedurl = $xml->{Items}->{Item}->{DetailPageURL} ;
			}
		} else {
			my $error = findError($xml);
			if (defined $error) {
#print "Error: " . $error->{Code} . ": " . $error->{Message} . "\n";
			} else {
#print "Unknown Error!\n";
			}
			exit(1) ;
		}
	}

}
@$results = sort { $b->{reducval} <=> $a->{reducval} } @$results ;
print "<table>";
my $below = 0 ;
foreach my $item (@$results)
{
	if (($below == 0) && ($item->{reducval} < $reduc))
	{
		$below = 1 ;
		print "<tr bgcolor=black><td></td><td></td><td></td></tr>" ;
	}
	print "<tr><td align=right><img src='".$item->{img}."'/></td><td width=50%><a href='".$item->{url}."' target='new'>".$item->{title}."</a></td>" ;
	print "<td>";
	if ($item->{reduc} =~ /Mini/)
	{
		print "$item->{reduc}</td></tr>\n";
	} else {
		print "$item->{price} € > $item->{sale} € ($item->{reduc})</td></tr>\n";
	}
}
print "</table>" ;



sub findError {
	my $xml = shift;

	return undef unless ref($xml) eq 'HASH';

	if (exists $xml->{Error}) { return $xml->{Error}; };

	for (keys %$xml) {
		my $error = findError($xml->{$_});
		return $error if defined $error;
	}

	return undef;
}
