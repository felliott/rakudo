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

    our multi method truth($topic) {
        my $retval;
        my $flipped = Bool::False;

        # flip?
        if (!$.state) {
            if ($topic.match($.lhs)) {
                $.state++;
                $flipped = Bool::True;
            }

            # if lhs doesn't match, $.state is 0 anyway
            $retval  = $.exclude_first ?? 0 !! $.state;
        }


        # flop?
        if ($.state && (!$.sedlike || !$flipped)) {
            if ($topic.match($.rhs)) {
                if ($flipped) {
                    $retval = $.exclude_first || $.exclude_last
                        ?? Bool::False !! $.state;
                }
                else {
                    $retval = $.exclude_last ?? Bool::False !! ++$.state;
                }

                $.state = 0;
            }
            else {
                if ($flipped) {
                    $retval = $.exclude_first ?? Bool::False !! $.state;
                }
                else {
                    $retval = ++$.state;
                }
            }
        }

        return $retval || '';
    }

    our Str multi method perl() {
        ( $.lhs.perl,
          ('^' if $.exclude_first),
          ($.sedlike ?? 'fff' !! 'ff'),
          ('^' if $.exclude_last),
          $.rhs.perl
        ).join('');
    }


    multi method ACCEPTS($topic) {
        self.truth($topic);
    }

    multi method Bool() {
        my $topic = pir::find_dynamic_lex__pS('$_');
        self.truth($topic).Bool();
    }

    multi method Str() {
        my $topic = pir::find_dynamic_lex__pS('$_');
        self.truth($topic).Str();
    }

    multi method Int() {
        my $topic = pir::find_dynamic_lex__pS('$_');
        self.truth($topic).Int();
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

    my $ff;
    Q:PIR {
      fetch:
        $P0 = get_hll_global ['GLOBAL'], '%ff_cache'
        unless null $P0 goto lookup
        $P0 = new ['Hash']
        set_hll_global ['GLOBAL'], '%ff_cache', $P0
      lookup:
        $P2 = find_lex '$lookup'
        $P1 = $P0[$P2]
        if null $P1 goto done
        store_lex '$ff', $P1
      done:
    };

    $ff = $ff // $new_ff.();
    Q:PIR {
        $P0 = find_lex '$ff'
        $P1 = find_lex '$lookup'
        $P2 = get_hll_global ['GLOBAL'], '%ff_cache'
        $P2[$P1] = $P0
    };

    return $ff;
}
