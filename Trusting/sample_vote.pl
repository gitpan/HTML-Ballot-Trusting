use HTML::Ballot::Trusting;
use CGI;
# Path to the HTML file that is the voting page
# I suppose it may not always the same as $ENV{HTTP_REFERER},
# though that is the intention:
our $VOTING_PAGE = "http://localhost/leegoddard_com/vote/vote.html";
our $cgi = new CGI;
if ($cgi->param() and $cgi->param('question') and $cgi->param('rpath') ){
	$v = new HTML::Ballot::Trusting ( {RPATH=>$cgi->param('rpath')});
	$v->cast_vote( $cgi->param('question') );
} else {	# If no vote is cast, will redirect.
	print "Location: $VOTING_PAGE\n\n";
}
