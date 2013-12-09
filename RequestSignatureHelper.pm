####
#This Module is based on code example as provided by Amazon 
#
###
package RequestSignatureHelper;

use strict;
use warnings;
use utf8;

use Data::Dumper;

use Digest;
use Digest::SHA qw(hmac_sha256_base64);
use URI::Escape qw(uri_escape_utf8);

# set this to 1 if you want to see debugging output, 0 otherwise.
my $DEBUG = 0;

use base 'Exporter';

our $kAWSAccessKeyId = 'AWSAccessKeyId';
our $kAWSSecretKey   = 'AWSSecretKey';
our $kEndPoint       = 'EndPoint';
our $kRequestMethod  = 'RequestMethod';
our $kRequestUri     = 'RequestUri';

our $kTimestampParam		= 'Timestamp';
our $kSignatureParam		= 'Signature';
our $kSignatureVersionParam	= 'SignatureVersion';
our $kSignatureVersionValue	= '2';
our $kSignatureMethodParam	= 'SignatureMethod';
our $kSignatureMethodValue	= 'HmacSHA256';

use constant kUriEscapeRegex => '^A-Za-z0-9\-_.~';

sub new {
    my ($class, $AWSAccessId, $AWSSecret, $AWSEndPoint) = @_;
    
    my $self = {};
    
	$kAWSAccessKeyId = $AWSAccessId ;
	$kAWSSecretKey = $AWSSecret ;
    $kEndPoint	= lc($AWSEndPoint);
    $kRequestMethod	= 'GET' ;
    $kRequestUri	= '/onca/xml' ;

    bless $self, $class;

    return $self;
}

sub sign {
    my ($self, $params) = @_;
    
    $params->{AWSAccessKeyId} = $kAWSAccessKeyId;
    $params->{Timestamp} = $self->generateTimestamp() ;
    my $canonical = $self->canonicalize($params);
    my $stringToSign = 
	$kRequestMethod    . "\n" . 
	$kEndPoint	    . "\n" . 
	$kRequestUri	    . "\n" . 
	$canonical;
    
    # calculate the signature value and add it to the request.
    my $signature = $self->digest($stringToSign);
    $params->{Signature} = $signature;

    debug ("signature: \"$signature\"\n");
    debug ("final signed request: " . Dumper($params));
    
    return $params;
}

sub generateTimestamp {
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.000Z",
       sub {    ($_[5]+1900,
                 $_[4]+1,
                 $_[3],
                 $_[2],
                 $_[1],
                 $_[0])
           }->(gmtime(time)));
}

sub escape {
    my ($self, $x) = @_;
    return uri_escape_utf8($x, +kUriEscapeRegex);
}

sub digest {
    my ($self, $x) = @_;
    my $digest = hmac_sha256_base64 ($x, $kAWSSecretKey);

    return $digest . "=";
}

sub canonicalize {
    my ($self, $params) = @_;
    
    my @parts = ();
    while (my ($k, $v) = each %$params) {
	my $x = $self->escape($k) . "=" . $self->escape($v);
	push @parts, $x;
    }

    my $out = join ("&", sort @parts);
    return $out;
}

sub debug {
    if ($DEBUG) { print STDERR shift }
}

1;

