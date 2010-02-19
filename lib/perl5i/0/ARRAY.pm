# vi: set ts=4 sw=4 ht=4 et :
package perl5i::0::ARRAY;
use 5.010;

use strict;
use warnings;
use Carp;

sub ARRAY::grep {
    my ( $array, $filter ) = @_;

    return [ CORE::grep { $_ ~~ $filter } @$array ];
}

sub ARRAY::all {
    require List::MoreUtils;
    return List::MoreUtils::all($_[1], @{$_[0]});
}

sub ARRAY::any {
    require List::MoreUtils;
    return List::MoreUtils::any($_[1], @{$_[0]});
}

sub ARRAY::none {
    require List::MoreUtils;
    return List::MoreUtils::none($_[1], @{$_[0]});
}

sub ARRAY::true {
    require List::MoreUtils;
    return List::MoreUtils::true($_[1], @{$_[0]});
}

sub ARRAY::false {
    require List::MoreUtils;
    return List::MoreUtils::false($_[1], @{$_[0]});
}

sub ARRAY::uniq {
    require List::MoreUtils;
    return [ List::MoreUtils::uniq(@{$_[0]}) ];
}

sub ARRAY::minmax {
    require List::MoreUtils;
    return [ List::MoreUtils::minmax(@{$_[0]}) ];
}

sub ARRAY::mesh {
    require List::MoreUtils;
    return [ List::MoreUtils::zip(@_) ];
}

sub ARRAY::diff {
    my ($c, @rest) = @_;
    return $c unless (@rest);

    croak "Arguments must be array references" if grep { ! ref $_ eq 'ARRAY' } @rest;

    foreach my $array (@rest) {
        $c = _diff_two($c, $array);
    }

    return $c;
}

sub _diff_two {
    my ($c, $d) = @_;

    # Split both arrays into shallow elements (nonrefs) and nested data
    # structures (references);
    my ( %nonrefs, %refs );
    $refs{c} = [ grep { ref } @$c ];
    $refs{d} = [ grep { ref } @$d ];
    $nonrefs{c} = [ grep { ! ref } @$c ];
    $nonrefs{d} = [ grep { ! ref } @$d ];

    my $diff;

    # Calculate the diff of the shallow elements, populating $diff;
    if ( not defined $nonrefs{d} ) { $diff = $nonrefs{c} }
    else {
        require Array::Diff;
        $diff = Array::Diff->diff($nonrefs{c}, $nonrefs{d})->deleted;
    }

    return $diff if not defined $refs{c};
    return [ @$diff, @{$refs{c}} ] if not defined $refs{d};

    # Now both $c and $d contained deep structures. Try to find for each
    # element of $c if it is equal to any of the elements of $d. If not,
    # it's unique, and has to be pushed into $diff;

    require List::MoreUtils;
    foreach my $item (@{$refs{c}}) {
        unless (
            # for some reason, any { foo() } @bar complains
            List::MoreUtils::any( sub { _are_equal( $item, $_ ) }, @{$refs{d}} )
        )
        { push @$diff, $item; }
    }

    return $diff;
}

sub _are_equal {
    my ($r1, $r2) = @_;

    # given two scalars, decide whether they are identical or not,
    # recursing over deep data structures. Since it uses recursion,
    # traversal is done depth-first.

    return unless ( defined $r1 and defined $r2 and ( ref $r1 eq ref $r2 ) );

    given (ref $r1) {
        when ("") {
            return "$r1" eq "$r2";
        }
        when ('ARRAY') {
            return unless @$r1 == @$r2;
            foreach my $i (0 .. @$r1 - 1) {
                return unless _are_equal($r1->[$i], $r2->[$i]);
            }
            return 1;
        }
        when ("SCALAR") {
            return "$$r1" eq "$$r2";
        }
        when ("HASH") {
            return unless _are_equal( [ keys %$r1   ], [ keys %$r2   ] );
            return unless _are_equal( [ values %$r1 ], [ values %$r2 ] );
            return 1;
        }
        default {
            return "$r1" eq "$r2";
        }

    }

}

1;

