class FlipFlop {
    has $.lhs;
    has $.rhs;

    has $.exclude_first = Bool::False;
    has $.exclude_last  = Bool::False;
    has $.sedlike       = Bool::False;

    has $.state is rw   = 0;

    multi method new($lhs, $rhs,
                     Bool :$exclude_first = Bool::False,
                     Bool :$exclude_last  = Bool::False,
                     Bool :$sedlike       = Bool::False) {
        # say "    ...building new FlipFlop";
        self.bless(*, :$lhs, :$rhs, :$exclude_first, :$exclude_last, :$sedlike);
    }

    # multi method ACCEPTS($topic) {
    #     my $match = $topic.match(self);
    #     pir::store_dynamic_lex__vSP('$/', $match);
    #     $match
    # }

    our Bool multi method truth($topic) {
        my $retval;
        my $flipped = Bool::False;

        # flip?
        if (!$.state) {
            if ($topic.match($.lhs)) {
                $.state  = $.state + 1;
                $flipped = Bool::True;
                $retval  = $.exclude_first ?? Bool::False !! $.state;
            }
            else {
                $retval = Bool::False;
            }
        }

        # flop?
        if ($.state && (!$.sedlike || !$flipped)) {
            if ($topic.match($.rhs)) {
                $retval = ($flipped && $.exclude_first) || $.exclude_last
                    ?? Bool::False !! ($flipped ?? $.state !! $.state + 1);
                $.state = 0;
            }
            else {
                $.state = $.state + 1 if (!$flipped);
                $retval = ($flipped && $.exclude_first) ?? Bool::False !! $.state;
            }
        }

        return $retval || '';
    }

    multi method Bool() {
        my $topic = pir::find_dynamic_lex__pS('$_');
        self.truth($topic).Bool();
    }
}



our multi sub infix:<ff>($lhs, $rhs) {
    return __check_ff_cache(sub {
        return FlipFlop.new($lhs, $rhs);
    });
}

our multi sub infix:<^ff>($lhs, $rhs) {
    return __check_ff_cache(sub {
        return FlipFlop.new($lhs, $rhs, :exclude_first(Bool::True));
    });
}

our multi sub infix:<ff^>($lhs, $rhs) {
    return __check_ff_cache(sub {
        return FlipFlop.new($lhs, $rhs, :exclude_last(Bool::True));
    });
}

our multi sub infix:<^ff^>($lhs, $rhs) {
    return __check_ff_cache(sub {
        return FlipFlop.new($lhs, $rhs,
            :exclude_first(Bool::True), :exclude_last(Bool::True));
    });
}


our multi sub infix:<fff>($lhs, $rhs) {
    return __check_ff_cache(sub {
        return FlipFlop.new($lhs, $rhs, :sedlike(Bool::True));
    });
}

our multi sub infix:<^fff>($lhs, $rhs) {
    return __check_ff_cache(sub {
        return FlipFlop.new($lhs, $rhs,
            :exclude_first(Bool::True), :sedlike(Bool::True));
    });
}

our multi sub infix:<fff^>($lhs, $rhs) {
    return __check_ff_cache(sub {
        return FlipFlop.new($lhs, $rhs,
            :exclude_last(Bool::True), :sedlike(Bool::True));
    });
}

our multi sub infix:<^fff^>($lhs, $rhs) {
    return __check_ff_cache(sub {
        return FlipFlop.new($lhs, $rhs,
            :exclude_first(Bool::True), :exclude_last(Bool::True),
            :sedlike(Bool::True));
    });
}



sub __check_ff_cache($new_ff) {

    my $lookup = callframe(2).file ~ ':' ~ callframe(2).line;

    # print "  Checking ff_cache for $lookup... ";
    my $ff;
    my $found = Q:PIR {
      fetch:
        $P0 = get_hll_global ['GLOBAL'], '%ff_cache'
        unless null $P0 goto lookup
        $P0 = new ['Hash']
        set_hll_global ['GLOBAL'], '%ff_cache', $P0
        goto fetch
      lookup:
        $P2 = find_lex '$lookup'
        $P1 = $P0[$P2]
        if null $P1 goto nope
        store_lex '$ff', $P1
        $I0 = 1
        goto done
      nope:
        $I0 = 0
      done:
        $P3 = new ['Int']
        $P3 = $I0
        %r = $P3
    };

    # say $found ?? " Found it!" !! "  not found.";

    $ff = $ff // $new_ff.();
    Q:PIR {
        $P0 = find_lex '$ff'
        $P1 = find_lex '$lookup'
        $P2 = get_hll_global ['GLOBAL'], '%ff_cache'
        $P2[$P1] = $P0
    };

    return $ff;
}
