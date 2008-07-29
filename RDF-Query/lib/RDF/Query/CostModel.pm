# RDF::Query::CostModel
# -----------------------------------------------------------------------------

=head1 NAME

RDF::Query::CostModel::Naive - Execution cost estimator

=head1 METHODS

=over 4

=cut

package RDF::Query::CostModel;

our ($VERSION);
BEGIN {
	$VERSION	= '2.002';
}

use strict;
use warnings;
no warnings 'redefine';

use Set::Scalar;
use Data::Dumper;
use Scalar::Util qw(blessed);

our $TRIPLE_SIZE	= 1_000_000;
our $MAX_COST		= 9_999_999;

=item C<< new () >>

Return a new cost model object.

=cut

sub new {
	my $class	= shift;
	my %args	= @_;
	
	my $size	= $args{ size } || $TRIPLE_SIZE;
	my $max		= $args{ max } || $MAX_COST;
	my $self	= bless( {
					kSize	=> $size,
					kMax	=> $max,
				}, $class );
	return $self;
}

=item C<< cost ( $pattern ) >>

Returns the cost (based on the expected time of execution) of the supplied
SPARQL algebra pattern.

=cut

sub cost {
	my $self	= shift;
	my $pattern	= shift;
	my $type	= $pattern->type;
	my $method	= "_cost_" . lc($type);
	my $l		= Log::Log4perl->get_logger("rdf.query.costmodel");
	$l->trace("computing cost of $type pattern");
	return $self->$method( $pattern );
}


sub _local_join_cost {
	my $self	= shift;
	my $lhs		= shift;
	my $rhs		= shift;
	my $lhsc	= $self->_cardinality( $lhs );
	my $rhsc	= $self->_cardinality( $rhs );
	return $lhsc * $rhsc;
}

sub _size {
	my $self	= shift;
	return $self->{ kSize };
}

sub _max {
	my $self	= shift;
	return $self->{ kMax };
}

sub _cardinality {
	my $self	= shift;
	my $pattern	= shift;
	my $type	= $pattern->type;
	my $method	= "_cardinality_" . lc($type);
	my $l		= Log::Log4perl->get_logger("rdf.query.costmodel");
	$l->trace("computing cardinality of $type pattern");
	return $self->$method( $pattern );
}


1;

__END__

=back

=head1 AUTHOR

 Gregory Todd Williams <gwilliams@cpan.org>

=cut
