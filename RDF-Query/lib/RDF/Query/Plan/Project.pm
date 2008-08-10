# RDF::Query::Plan::Project
# -----------------------------------------------------------------------------

=head1 NAME

RDF::Query::Plan::Project - Executable query plan for Projects.

=head1 METHODS

=over 4

=cut

package RDF::Query::Plan::Project;

use strict;
use warnings;
use base qw(RDF::Query::Plan);

=item C<< new ( $plan, \@keys ) >>

=cut

sub new {
	my $class	= shift;
	my $plan	= shift;
	my $keys	= shift;
	my (@vars, @exprs);
	foreach my $k (@$keys) {
		push(@exprs, $k) if ($k->isa('RDF::Query::Expression'));
		push(@vars, $k->name) if ($k->isa('RDF::Query::Node::Variable'));
		push(@vars, $k) if (not(ref($k)));
	}
	my $self	= $class->SUPER::new( $plan, \@vars, \@exprs );
	return $self;
}

=item C<< execute ( $execution_context ) >>

=cut

sub execute ($) {
	my $self	= shift;
	my $context	= shift;
	if ($self->state == $self->OPEN) {
		throw RDF::Query::Error::ExecutionError -text => "PROJECT plan can't be executed while already open";
	}
	my $plan	= $self->[1];
	$plan->execute( $context );
	
	if ($plan->state == $self->OPEN) {
		$self->[0]{context}	= $context;
		$self->state( $self->OPEN );
	} else {
		warn "could not execute plan in PROJECT";
	}
	$self;
}

=item C<< next >>

=cut

sub next {
	my $self	= shift;
	unless ($self->state == $self->OPEN) {
		throw RDF::Query::Error::ExecutionError -text => "next() cannot be called on an un-open PROJECT";
	}
	my $plan	= $self->[1];
	my $row		= $plan->next;
	return undef unless ($row);
	
	my $keys	= $self->[2];
	my $exprs	= $self->[3];
	my $query	= $self->[0]{context}->query;
	my $bridge	= $self->[0]{context}->model;
	
	my $proj	= $row->project( @{ $keys } );
	foreach my $e (@$exprs) {
		my $name;
		if ($e->isa('RDF::Query::Expression::Alias')) {
			$name	= $e->name;
			$e		= $e->expression;
		} else {
			$name	= $e->sse;
		}
		$proj->{ $name }	= $query->var_or_expr_value( $bridge, $row, $e );
	}
	
	return $proj;
}

=item C<< close >>

=cut

sub close {
	my $self	= shift;
	unless ($self->state == $self->OPEN) {
		throw RDF::Query::Error::ExecutionError -text => "close() cannot be called on an un-open PROJECT";
	}
	delete $self->[0]{context};
	$self->[1]->close();
	$self->SUPER::close();
}

=item C<< pattern >>

Returns the query plan that will be used to produce the data to be projected.

=cut

sub pattern {
	my $self	= shift;
	return $self->[1];
}

=item C<< distinct >>

Returns true if the pattern is guaranteed to return distinct results.

=cut

sub distinct {
	my $self	= shift;
	return $self->pattern->distinct;
}

=item C<< ordered >>

Returns true if the pattern is guaranteed to return ordered results.

=cut

sub ordered {
	my $self	= shift;
	return $self->pattern->ordered;
}


1;

__END__

=back

=head1 AUTHOR

 Gregory Todd Williams <gwilliams@cpan.org>

=cut