package HTML::Ballot::Trusting;
our $VERSION = 0.1;
use strict;
use warnings;
use Carp;
use HTML::Entities ();
# Later: CGI and use HTML::EasyTemplate 0.985;


our $CHAT = 1;


=head1 NAME

HTML::Ballot::Trusting - HTML-template-based insercure multiple-choice ballot

=head1 SYNOPSIS

See L</SETTING UP A POLL>.

=head1 DESCRIPTION

A simple module for inseucre web ballots.

=over 4

=item *

a HTML page of voting options and one of the results of votes so far is
generated from a single HTML template, and it is in these pages that ballot
status is maintained, so no additional file access is required.  This may
be extended to include a ballot `time out'.

=item *

HTML output into the template is minimal, but all unique entities are given
a C<class> attribute for easy CSS re-definitions.

=item *

simple bar charts of results are generated using HTML.  Options to have
graphs based on single-pixels, or using the C<GD> interface will arrive
some time in the future.

=item *

no test is made of who is voting, so users may vote any number of times, or may
even vote (and surely will) thousands of times using a C<LWP> hack.
A more secure version is being constructed, which uses simple e-mail authentication
of users, sending ony one voting password to any e-mail address: this may appear
as C<HTML::Ballot::MoreCynical>.

=back

=head1 SYNOPSIS

There are three steps to creating a poll:

=over 4

=item 1.

Create an HTML template file containing the following element inserted where
the questions and answers are to be pasted:

	<TEMPLATEITEM name='QUESTIONS'></TEMPLATEITEM>

=item 2.

Construct a new HTML::Ballot::Trusting object, and call upon it the
C<create> method:

	use HTML::Ballot::Trusting;
	my $p = new HTML::Ballot::Trusting {
		RPATH 	  => 'E:/www/leegoddard_com/vote/results.html',
		SUBMITTO  => 'http://localhost/leegoddard_com/vote/vote.pl',
		TPATH	  => 'E:/www/leegoddard_com/vote/template.html',
		QPATH	  =>	'E:/www/leegoddard_com/vote/vote.html',
		QUESTIONS => [ 'Why?', 'Why not?', 'Why what?' ]
	};
	$p->create();
	exit;

See L</CONSTRUCTOR (new)> and L</METHOD create>.

=item 3.

Create a page to call the vote (the script may yet produce such an item):

	use HTML::Ballot::Trusting;
	use CGI;
	our $VOTING_PAGE = "http://localhost/leegoddard_com/vote/vote.html";
	our $cgi = new CGI;
	if ($cgi->param() and $cgi->param('question') and $cgi->param('rpath') ){
		$v = new HTML::Ballot::Trusting ( {RPATH=>$cgi->param('rpath')});
		$v->cast_vote($cgi->param('question'));
	} else { print "Location: $VOTING_PAGE\n\n" }
	exit;

=back

=cut

=head1 GLOBAL VARIABLES

=cut

#
# These defaults can be over-ridden by using their
# names as values in the hash passed to the constructor
#
our $ARTICLE_ROOT = 'E:/www/leegoddard_com';
our $URL_ROOT = 'http://localhost/leegoddard_com';
our $STARTGRAPHIC = "STARTGRAPHICHERE__";


=head1 CONSTRUCTOR (new)

Requires a reference to the class into which to bless, as well
as a hash (or reference to such) with the following key/value
content:

=over 4

=item ARTICLE_ROOT

can over-ride the global constant of the same name;

=item URL_ROOT

can over-ride the global constant of the same name;

=item QUESTIONS

an array of questions to use in the ballot

=item TPATH

Path the HTML template may be found at

=item QPATH

Path at which to save the HTML ballot page

=item RPATH

Path at which to save the HTML results page

=item SUBMITTO

Path to the script that processes submission of the CGI voting form

=back

=cut

sub new {
	my $class = shift or die "Called without class";
	my %args;
	my $self = {};
	bless $self,$class;

	# Default instance variables
	$self->{ARTICLE_ROOT} 	= $ARTICLE_ROOT;
	$self->{URL_ROOT} 		= $URL_ROOT;

	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }

	# Overwrite default instance variables with user's values
	foreach (keys %args) { $self->{uc $_} = $args{$_} }
	undef %args;

	# Calling-paramter error checking
	croak "Template path TPATH does not exist" if exists $self->{TPATH} and not -e $self->{TPATH};
	croak "No RPATH" if not exists $self->{RPATH} and not defined $self->{RPATH};

	return $self;
} # End sub new





=head2 METHOD create

Creates the HTML voting page.

Accepts: just the calling object: all properties used should be set
during construction (see L</CONSTRUCTOR (new)>).

Returns: the path to the saved HTML question document.

The template file used to generate the question and answer pages
should be an HTML page with the following markup inserted at the
point that the C<FORM> and radio-buttons should appear:

	<TEMPLATEITEM name='QUESTIONS'></TEMPLATEITEM>

=item QUESTION PAGE

The C<action> attribute of the C<FORM> element is set to the CGI
environment variable, C<SCRIPT_NAME> (that is, the location of this script).

Form elements are simply seperated by linebreaks (C<BR>): use CSS to control the layout:
the radio-button HTML elements are set to be class C<voteoption>; the C<SUBMIT> button
element is set to be class C<votesubmit>.

=item RESULTS PAGE

HTML is used to create bar charts, but this should be easy to replace with
a C<GD> image, or a stretched single-pixel.  Each question is given a C<TEMPLATEITEM>
element, and results will be placed within by the C<vote> method (see L</METHOD vote>).


CSS: C<voteresults> is the layer of the whole results section;
C<votequestion> is the question on the left; C<votescore> is the
number of votes recieved by the item; C<chart> is the chart....

=cut

sub create { my $self = shift;
	local *OUT;
	croak "No path to HTML template" if not exists $self->{TPATH} or not defined $self->{TPATH};
	croak "No path to save HTML at" if not exists $self->{QPATH} or not defined $self->{QPATH};
	croak "No questions" if not exists $self->{QUESTIONS} or not defined $self->{QUESTIONS};
	croak "No SUBMITTO value defined" if not exists $self->{SUBMITTO} or not defined $self->{SUBMITTO};
	use HTML::EasyTemplate 0.985;

	# Create question poll page QPATH #############################################
	#
	# Create radio button HTML from questions
	my $qhtml =	"<form name=\"".__PACKAGE__."\" method=\"post\" action=\"$self->{SUBMITTO}\">\n";
	foreach (@{$self->{QUESTIONS}}) {
		$_ = HTML::Entities::encode($_);
 		$qhtml .= "<input class=\"voteoption\" type=\"radio\" name=\"question\" value=\"$_\">$_</input><BR>\n";
	}
	$qhtml.="<INPUT type=\"HIDDEN\" name=\"rpath\" value=\"$self->{RPATH}\">\n";
	$qhtml.="<INPUT type=\"SUBMIT\" class=\"votesubmit\" value=\"Cast Vote\">\n</FORM>\n";
	my $TEMPLATE = new HTML::EasyTemplate(
		{	SOURCE_PATH => $self->{TPATH},
			ARTICLE_ROOT => $self->{ARTICLE_ROOT},
			URL_ROOT => $self->{URL_ROOT},
		});
	my %template_items;
	$template_items{QUESTIONS} 	= $qhtml;				# Make new values, for example:
	$TEMPLATE -> process('fill', \%template_items );	# Add them to the page
	$TEMPLATE -> save($self->{QPATH});

	# Create initial results page RPATH template ####################################
	#
	my $rhtml = "<DIV class=\"voteresults\">\n<TABLE width=\"100%\">\n";
	foreach (@{$self->{QUESTIONS}}) {
		$rhtml .= "<TR>\n<TD class=\"votequestion\" align=\"left\" nowrap width=\"25%\">$_</TD>\n\t";
		$rhtml .= "<TD class=\"votescore\"align=\"right\"><TEMPLATEITEM name=\"$_\">0</TEMPLATEITEM></TD>\n";
		$rhtml .= "<TD class=\"chart\" align=\"left\"><TEMPLATEITEM name=\"$STARTGRAPHIC$_\">No votes yet cast.</TEMPLATEITEM></TD>\n";
		$rhtml .= "</TR>\n";
	}
	$rhtml .= "</TABLE>\n</DIV>\n";

	$TEMPLATE = new HTML::EasyTemplate(
		{	ADD_TAGS => 1,
			SOURCE_PATH => $self->{TPATH},
			ARTICLE_ROOT => $self->{ARTICLE_ROOT},
			URL_ROOT => $self->{URL_ROOT},
		});

	$template_items{QUESTIONS} 	= $rhtml;				# Make new values, for example:
	$TEMPLATE -> process('fill', \%template_items );	# Add them to the page
	$TEMPLATE -> save($self->{RPATH});

	# Redirect
	print "Location: $TEMPLATE->{ARTICLE_PATH}\n\n";

	return $TEMPLATE->{ARTICLE_PATH};
}




=head2 METHOD cast_vote

Casts a vote and updates the results file.

Accepts: the question voted for, as defined in the HTML vote form's C<INPUT>/C<value>.

=cut

sub cast_vote { my ($self, $q_answered) = (shift,shift);
	croak "No object" if not defined $self;
	croak "No answer" if not defined $q_answered;
	croak "No RPATH" if not exists $self->{RPATH};
	croak "No RPATH path to save results at" if not exists $self->{RPATH};

	# Get existing results
	my $TEMPLATE = new HTML::EasyTemplate(
		{	ADD_TAGS => 1,
			SOURCE_PATH => $self->{RPATH},
			ARTICLE_ROOT => $self->{ARTICLE_ROOT},
			URL_ROOT => $self->{URL_ROOT},
		});
	$TEMPLATE -> process('collect');						# Collect the values
	my %template_items = %{$TEMPLATE->{TEMPLATEITEMS}};		# Do something with them
	my %scores;				# Keyed by question
	my $total_cast;
	# Aquire results from template
	foreach (keys %template_items){
		if ($_!~/^$STARTGRAPHIC/ and $_ ne 'QUESTIONS'){
			$template_items{$_}++ if $_ eq $q_answered;
			$scores{$_} = $template_items{$_};
			$total_cast += $scores{$_};
			warn "Total now $total_cast";
		}
	}
	# Create new results
	foreach (keys %scores){
		warn "$_...$template_items{$_}\n" if $CHAT;
		$template_items{$_} = $scores{$_};
		$template_items{"$STARTGRAPHIC$_"} = '<TABLE width="100%"><TR><TD width="';
		if ($scores{$_}==0){
			$template_items{"$STARTGRAPHIC$_"}.='0';
			$template_items{"$STARTGRAPHIC$_"}.= '%" bgcolor="white">';
		} else {
			warn ">>$_<< 2>>$_<<";
			$template_items{"$STARTGRAPHIC$_"} .= ((100 / $total_cast) * $template_items{$_} );
			$template_items{"$STARTGRAPHIC$_"}.= '%" bgcolor="red">&nbsp;';
		}
		$template_items{"$STARTGRAPHIC$_"}.= '</TD><TD></TD></TR></TABLE>'."\n";
	}
	$TEMPLATE -> process('fill', \%template_items );		# Add them to the page
	$TEMPLATE -> save($self->{RPATH});
	print "Location: $TEMPLATE->{ARTICLE_PATH}\n\n";
	return;
}

