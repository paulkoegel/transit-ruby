# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Transit
  module WriteHandlers
    class NilHandler
      def tag(_) "_" end
      def rep(_) nil end
      def string_rep(n) nil end
    end

    class KeywordHandler
      def tag(_) ":" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class StringHandler
      def tag(_) "s" end
      def rep(s) s end
      def string_rep(s) s end
    end

    class TrueHandler
      def tag(_) "?" end
      def rep(_) true end
      def string_rep(_) "t" end
    end

    class FalseHandler
      def tag(_) "?" end
      def rep(_) false end
      def string_rep(_) "f" end
    end

    class IntHandler
      def tag(i) i > MAX_INT || i < MIN_INT ? "n" : "i" end
      def rep(i) i > MAX_INT || i < MIN_INT ? i.to_s : i end
      def string_rep(i) i.to_s end
    end

    class FloatHandler
      def tag(_) "d" end
      def rep(f) f end
      def string_rep(f) f.to_s end
    end

    class BigDecimalHandler
      def tag(_) "f" end
      def rep(f) f.to_s("f") end
      def string_rep(f) rep(f) end
    end

    # TimeHandler, DateTimeHandler, and DateHandler all have different
    # implementations of string_rep. Here is the rationale:
    #
    # For all three, want to write out the same format
    # e.g. 2014-04-18T18:51:29.478Z, and we want the milliseconds to truncate
    # rather than round, eg 29.4786 seconds should be 29.478, not 29.479.
    # - "sss is the number of complete milliseconds since the start of the
    #    second as three decimal digits."
    # - http://www.ecma-international.org/ecma-262/5.1/#sec-15.9.1.15
    #
    # Some data points (see benchmarks/encoding_time.rb)
    # - Time and DateTime each offer iso8601 methods, but strftime is faster.
    # - DateTime's strftime (and iso8601) round millis
    # - Time's strftime (and iso8601) truncate millis
    # - we don't care about truncate v round for dates (which have 000 ms)
    # - date.to_datetime.strftime(...) is considerably faster than date.to_time.strftime(...)
    class TimeHandler
      def tag(_) "m" end
      def rep(t) DateTimeUtil.to_millis(t) end
      def string_rep(t) rep(t).to_s end
      def verbose_handler() VerboseTimeHandler end
    end

    class DateTimeHandler < TimeHandler
      def verbose_handler() VerboseDateTimeHandler end
    end

    class DateHandler     < TimeHandler
      def verbose_handler() VerboseDateHandler end
    end

    class VerboseTimeHandler
      def tag(_) "t" end
      def rep(t)
        # .getutc because we don't want to modify t
        t.getutc.strftime(Transit::TIME_FORMAT)
      end
      def string_rep(t) rep(t) end
    end

    class VerboseDateTimeHandler < VerboseTimeHandler
      def rep(t)
        # .utc because to_time already creates a new object
        t.to_time.utc.strftime(Transit::TIME_FORMAT)
      end
    end

    class VerboseDateHandler < VerboseTimeHandler
      def rep(d)
        # to_datetime because DateTime's strftime is faster
        # thank Time's, and millis are 000 so it doesn't matter
        # if we truncate or round.
        d.to_datetime.strftime(Transit::TIME_FORMAT)
      end
    end

    class UuidHandler
      def tag(_) "u" end
      def rep(u) [u.most_significant_bits, u.least_significant_bits] end
      def string_rep(u) u.to_s end
    end

    class LinkHandler
      def tag(_) "link" end
      def rep(l) l.to_h end
      def string_rep(_) nil end
    end

    class UriHandler
      def tag(_) "r" end
      def rep(u) u.to_s end
      def string_rep(u) rep(u) end
    end

    class AddressableUriHandler
      def tag(_) "r" end
      def rep(u) u.to_s end
      def string_rep(u) rep(u) end
    end

    class ByteArrayHandler
      def tag(_) "b" end
      def rep(b) b.to_base64 end
      def string_rep(b) rep(b) end
    end

    class TransitSymbolHandler
      def tag(_) "$" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class ArrayHandler
      def tag(_) "array" end
      def rep(a) a end
      def string_rep(_) nil end
    end

    class MapHandler
      def handlers=(handlers)
        @handlers = handlers
      end

      def stringable_keys?(m)
        m.keys.all? {|k| (@handlers[k.class].tag(k).length == 1) }
      end

      def tag(m)
        stringable_keys?(m) ? "map" : "cmap"
      end

      def rep(m)
        stringable_keys?(m) ? m : m.reduce([]) {|a, kv| a.concat(kv)}
      end

      def string_rep(_) nil end
    end

    class SetHandler
      def tag(_) "set" end
      def rep(s) s.to_a end
      def string_rep(_) nil end
    end

    class TaggedValueHandler
      def tag(tv) tv.tag end
      def rep(tv) tv.rep end
      def string_rep(_) nil end
    end

    DEFAULT_WRITE_HANDLERS = {
      NilClass         => NilHandler.new,
      ::Symbol         => KeywordHandler.new,
      String           => StringHandler.new,
      TrueClass        => TrueHandler.new,
      FalseClass       => FalseHandler.new,
      Fixnum           => IntHandler.new,
      Bignum           => IntHandler.new,
      Float            => FloatHandler.new,
      BigDecimal       => BigDecimalHandler.new,
      Time             => TimeHandler.new,
      DateTime         => DateTimeHandler.new,
      Date             => DateHandler.new,
      UUID             => UuidHandler.new,
      Link             => LinkHandler.new,
      URI              => UriHandler.new,
      Addressable::URI => AddressableUriHandler.new,
      ByteArray        => ByteArrayHandler.new,
      Transit::Symbol  => TransitSymbolHandler.new,
      Array            => ArrayHandler.new,
      Hash             => MapHandler.new,
      Set              => SetHandler.new,
      TaggedValue      => TaggedValueHandler.new
    }.freeze
  end
end