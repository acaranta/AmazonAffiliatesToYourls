#!/usr/bin/perl

use strict;
use utf8 ;
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

if (@ARGV > 0)
{
	$AMZItem = shift @ARGV ;
} else {
	$cgi = new CGI ;
	print $cgi->header('Content-type: text/html; charset=utf-8') ;
	print $cgi->start_html(-title=>"Amazon Affiliates Link Generator for yourls", -encoding=>"UTF-8") ;
	$AMZItem = $cgi->param('url') ;
	$showLinks = $cgi->param('showlinks') ;
}

my $itemId ;

if ($AMZItem =~ /^[0-9A-Z]{10}$/)
{
	$itemId = $AMZItem ;
} elsif ($AMZItem =~ /[0-9A-Z]{10}/)
{
	$AMZItem =~ m/amazon\.([a-zA-Z]+)\// ;
	my $tld = $1 ;
	#print "TLD = $tld\n" ;
	$AWSEndPoint = "ecs.amazonaws.$tld" ; 
	$AMZItem =~ /([0-9A-Z]{10})/ ;
	$itemId = $1 ;
	print 'You can drag the bookmarlet to get : <ul><li>-your links directly from an amazon Page : <a href="javascript:(function(){window.open(\''.$cgi->url().'?showlinks=1&url=\'+document.URL);})();">AMZ Aff Link</a></li><li>-directly redirected to the Affiliated link:  <a href="javascript:(function(){window.open(\''.$cgi->url().'?showlinks=0&url=\'+document.URL,\'_self\');})();">AMZ Aff Direct</a></li></ul><hr><br/><br/>' ;
} else {
	print 'You can drag the bookmarlet to get : <ul><li>-your links directly from an amazon Page : <a href="javascript:(function(){window.open(\''.$cgi->url().'?showlinks=1&url=\'+document.URL);})();">AMZ Aff Link</a></li><li>-directly redirected to the Affiliated link:  <a href="javascript:(function(){window.open(\''.$cgi->url().'?showlinks=0&url=\'+document.URL,\'_self\');})();">AMZ Aff Direct</a></li></ul><hr><br/><br/>' ;
	print "No ASIN Found !!\n" ;
	exit(2) ;
}
# Set up the helper
my $helper = new RequestSignatureHelper ( $AWSId, $AWSSecret, $AWSEndPoint);

# A simple ItemLookup request
my $request = {
    Service => 'AWSECommerceService',
    Operation => 'ItemLookup',
    Version => '2009-03-31',
    ItemId => $itemId,
    ResponseGroup => 'Small',
	AssociateTag => $AWSAssociateTag,
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

#print "Parsed XML is: " . Dumper($xml) . "\n";
my $signedurl ;
my $title ;
if ($response->is_success()) {
    $title = $xml->{Items}->{Item}->{ItemAttributes}->{Title};
    $signedurl = $xml->{Items}->{Item}->{DetailPageURL} ;
} else {
    my $error = findError($xml);
    if (defined $error) {
		#print "Error: " . $error->{Code} . ": " . $error->{Message} . "\n";
    } else {
		#print "Unknown Error!\n";
    }
	exit(1) ;
}

my $shorturl ;

if ($YourlsId =~ /[a-aA-Z0-9]+/)
{
	my $request = {
		action=> 'shorturl',
		url =>  $signedurl,
		output => 'xml',
	};

#url =>  uri_unescape($signedurl),
	my $url = $YourlsEndPoint."/yourls-api.php?action=".$request->{'action'}."&url=".$request->{url}."&output=".$request->{output}."&signature=".$YourlsId;

	my $ua = new LWP::UserAgent();
	my $response = $ua->get($url);
	my $content = $response->content();
##print $content ;
	$content =~ s/&(uml|cent|acirc|atilde|reg);//gi ;	
	my $xmlParser = new XML::Simple();
	my $xml = $xmlParser->XMLin($content);


	if ($response->is_success()) {
		$shorturl = $xml->{shorturl} ;
	}
}
if (@ARGV > 0)
{
	print "Item $itemId is titled \"$title\"\n";
#print "Signed URL : ".uri_unescape($signedurl)."\n" ;
	print "Signed URL : $signedurl\n" ;
	print "Short URL : $shorturl\n" ;
} else {
	if ($showLinks ne '0')
	{
		print "Item is : '$title'<br/>" ;
#print "<br/>Amazon Link : ".uri_unescape($signedurl)." <a href='".uri_unescape($signedurl)."'>Link</a><br/>" ;
		print "<br/>Amazon Link : ".uri_unescape($signedurl)." <a href='".$signedurl."'>Link</a><br/>" ;
		print "Shortened URL : $shorturl and <a href='$shorturl'>Link</a><br/>" ;
		my $curtime = time() ;
		my $titleshare = $title ;
		$titleshare =~ s/'/&#39;/g ;
		$titleshare =~ s/"/&#34;/g ;
		print "<br/><br/>Share link :<ul>
			<li><a target='_blank' href='http://twitter.com/share?_=$curtime&text=$titleshare&url=$shorturl'><img src='img/tweetshare.png'/></a></li>
			<li><a target='_blank' href='http://www.facebook.com/sharer.php?u=$shorturl'><img src='img/fbshare.png' border=0/></a></li>
			</ul>" ;
	} else {
		print "\n<h3>Links Generated ...</h3><br/><h1> Redirecting ...</h1>" ;
		print '<script type="text/javascript">window.location = "';
		print $signedurl ;
		print '"</script>' ;
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




