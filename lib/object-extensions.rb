# FreeRec
# Copyright © 2009 FreeRec author <freerec1@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

class Object
  def method_missing meth, *args, &block
    meth_s = meth.to_s
    return super unless meth_s[-1..-1] == '!'
    meth = meth_s.chop.to_sym

    return super unless respond_to? meth

    kaller = caller(0)

    send(meth, *args, &block).tap do |val|
      if val.nil?
        raise ArgumentError, "%s.%s(%s) returned nil" % [
          self, meth, args.map(&:inspect).join(', ')
        ], kaller
      end
    end
  end
end

class Gst::Element
  def position
    query_obj = Gst::QueryPosition.new Gst::Format::TIME
    query query_obj
    query_obj.parse[1]
  end

  def duration
    query_obj = Gst::QueryDuration.new Gst::Format::TIME
    query query_obj
    query_obj.parse[1]
  end
end

