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
$Config = Config::Tiny->read( './getPromos.ini' );
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
print $cgi->start_html(-title=>"Amazon Promo lister", 
		-encoding=>"UTF-8",
		-script =>[
		{-type=>"text/javascript",-src=>"//code.jquery.com/jquery-1.11.2.min.js"},
		{-type=>"text/javascript",-src=>"//code.jquery.com/jquery-migrate-1.2.1.min.js"},
		],
		) ;
my $keyword = $cgi->param('q') ;
my $categ = $cgi->param('categ') ;
my $reduc = $cgi->param('reduc') ;
my $getdata = $cgi->param('getdata') ;
if ($getdata ne "true")
{
#$reduc = 70 ;
        print '<script type="text/javascript">
function getData(){
    $("#content").hide();  
    $("#error").hide(); 
    $("#loading").show();  // show the loading message.
    $.ajax({
        url: "getPromo.pl?q="+ $("#q").val() + "&categ=" + $("#categ").val() + "&getdata=true&reduc=" + $("#reduc").val(),
        type: "GET",
        cache: false,
        success : function(html){
            $("#content").html(html);
            $("#content").show();
            $("#loading").hide(); // hide the loading message
        }
    });
}
</script>';
	if ($reduc !~ /[0-9]+/)
	{
		$reduc = 70 ;
	}
	if ($categ !~ /./)
	{
		$categ = "Electronics" ;
	}
	#print '<form id="formsearch" method="post" action="getPromo.pl">
	print '<form id="formsearch" >
		<div>
		<label class="description" for="element_1">Mot Clef </label>
		<input id="q" name="q" class="textbox" type="text" maxlength="255" value="'.$keyword.'"/> 
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
		#<input id="saveForm" class="button_text" type="submit" name="submit" value="Submit" />
	print '		</select>
		<label class="description" for="element_1">Reduction % </label>
		<input id="reduc" name="reduc" class="textbox" type="text" maxlength="10" value="'.$reduc.'"/>';
	print '	<a href="#" onclick="javascript:getData()">Go</a>' ;
	print '	</div> 
		</form>' ;
	print '<hr align=center width=80%/>' ;

	print "<div id='loading' style='display:none' width='100%' align=center> <img align=center src='loading.gif'/> <h3 align=center>En cours ...</h3> </div>" ;
	print "<div id='content' width='100%'></div>" ;
	print '<script>
$(".textbox").bind("enterKey",function(e) {
getData() ;
});
$(".textbox").keyup(function(e){
    if(e.keyCode == 13)
    {
        $(this).trigger("enterKey");
    }
});
</script>' ;
} else {
	if ($keyword !~ /.+/)
	{
		print "<div id='error'><h3 color=red align=center>Il Manque des mots clef ...</h3></div>\n" ;
#$keyword = "sd" ;
#$categ = "Electronics" ;
		exit()
	}
	if ($reduc >100)
	{
		print "<div id='error'><h3 color=red align=center>Reduction invalide : (0-100)\n<h3/></div>" ;
		exit() ;
	}
	my $results ;
	{
		my $cptPage = 0 ;
		while ($cptPage++ <=5)
		{
# Set up the helper
			my $helper = new RequestSignatureHelper ( $AWSId, $AWSSecret, $AWSEndPoint);
			my $itemId = "" ;
# A simple ItemLookup request
			my $request = {
				Service => 'AWSECommerceService',
				SearchIndex => $categ,
				Operation => 'ItemSearch',
				Version => '2013-08-01',
				ResponseGroup => 'Large',
				Keywords => $keyword,
				MinPercentageOff => $reduc,
				AssociateTag => $AWSAssociateTag,
				ItemPage => $cptPage,
			};

# Sign the request
			my $signedRequest = $helper->sign($request);

# We can use the helper's canonicalize() function to construct the query string too.
			my $queryString = $helper->canonicalize($signedRequest);
			my $url = "http://$AWSEndPoint/onca/xml?" . $queryString;

			my $ua = new LWP::UserAgent();
			my $response = $ua->get($url);
			my $content = $response->content();

			my $xmlParser = new XML::Simple();
			my $xml = $xmlParser->XMLin($content);

			my $signedurl ;
			my $title ;
			if ($response->is_success()) {
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
							$product->{asin} = $item->{ASIN} ;
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
	if (defined (@$results) )
	{
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
				print "$item->{reduc}</td>";
			} else {
				print "$item->{price} € > $item->{sale} € ($item->{reduc})</td>";
			}
			print "<td width='10px'><input type='checkbox' value='$item->{asin}'><p style='color:#F0F5FF; font-size:8px'>$item->{asin}</p</td></tr>\n";
		}
		print "</table>" ;

		print "<br/><div align=center id='asins'></div>" ;
		print '<script>
			$("input[type=checkbox]").on("change", function () {
					var str = "";
					$("input[type=checkbox]:checked").each(function () {
						str += $(this).val() + ", ";
						});
					$("#asins").html(str);
					});
		</script>';
	} else 
	{
		print "<h3 align=center>Rien par ici ...</h3>" ;
	}
}

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
