use HTML::Ballot::Trusting;
use CGI;
our $VOTING_PAGE = "http://localhost/leegoddard_com/vote/vote.html";
our $cgi = new CGI;
if ($cgi->param() and $cgi->param('question') and $cgi->param('rpath') ){
	$v = new HTML::Ballot::Trusting ( {RPATH=>$cgi->param('rpath')});
	$v->cast_vote( $cgi->param('question') );
} else {print "Location: $VOTING_PAGE\n\n";}
