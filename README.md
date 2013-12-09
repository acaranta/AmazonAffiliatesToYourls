AmazonAffiliatesToYourls
=========================

Allows you to easily generate your own Amazon affiliate link and shorten them with your Yourls URL shortener.
This is done by using the well documented Amazon Product Advertising API.

## Prerequisites :
Required Perl modules :
- LWP::UserAgent, 
- XML::Simple, 
- URI::Escape, 
- CGI, 
- Config::Tiny , 
- Data::Dumper, 
- Digest, 
- Digest::SHA

Amazon Account(s) :
- An Amazon Affiliates (Partenaires) account [https://affiliate-program.amazon.com/]
- An Amazon Affiliates (Partenaires) API (AWS) And ID/Secret pair [http://aws.amazon.com]
- .. More info on how to get your access to Amazon Affiliates Program [http://docs.aws.amazon.com/AWSECommerceService/2011-08-01/GSG/GettingSetUp.html]
- A Working YOURLS installation (with API enabled) [http://yourls.org]

## Installation :
- Get the files (the way you want (git or tarball)
- Copy them to a web accessible path
- Copy *AMZ2Yourls.ini.sample* to *AMZ2Yourls.ini*
- Edit *AMZ2Yourls.ini* and fill the (I hope) explicit fields ;)
- **Make Sure you configure you webserver to deny access to *AMZ2Yourls.ini* ! THIS IS HIGHLY IMPORTANT !!**
- Browse to AMZAff2Yourls.pl and you're done !

## How to use :
### First time use :
- Browse to AMZAff2Yourls.pl 
- You should see the bookmarlet for your installation.
- Drag this to your broswer bookmarks

### Using it on amazon :
When browsing a product page on Amazon, click on the bookmarlet which will open a new window. In this window the Amazon link will be parsed to find the Amazon product id (ASIN), the country specific Amazon store and both parameters will be used to create your Affiliate link.
Then the signed link to your affiliate code will be displayed along with the shortened version (for easier sharing).

Enjoy !

## TODO :
- [] Make the web pages less ugly !!
- [] Enhance the bookmarlet
- [] Add other type of sponsored Amazon requests (product search, etc)

## Like it ?
OK, if you liked this two ways to thank me :
-Bitcoin donation to 13MNuF4dCJNh2vs2TS9ms2cKPSpWG3hUGj
-Or just buy product on amazon via link generated through my Affiliate links ;) : [http://api.minixer.com/AMZ2YOURLS/AMZAff2Yourls.pl](Link)

## License
The initial core code to sign the Amazon request (perl module) was released under Apache 2.0 Licensed but quite thoroughly rewritten for useability ;) ([http://aws.amazon.com/code/Product-Advertising-API/2482](Link))
