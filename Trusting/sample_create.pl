# Create the poll

use HTML::Ballot::Trusting;
my $p = new HTML::Ballot::Trusting {
	RPATH 	 => 'E:/www/leegoddard_com/vote/results.html',
	SUBMITTO => 'http://localhost/leegoddard_com/vote/vote.pl',
	TPATH	 => 'E:/www/leegoddard_com/vote/template.html',
	QPATH	 =>	'E:/www/leegoddard_com/vote/vote.html',
	QUESTIONS => [
		'Why?',
		'Why not?',
		'Only for £300.'
	]
};

$p->create();
