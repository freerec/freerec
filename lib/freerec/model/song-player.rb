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

require 'gst'

module FreeRec
  module Model
    class SongPlayer < Gst::Pipeline
      SONGS_PATH = File.dirname(__FILE__)+'/../../../../songs'

      def initialize
        super()

        src   = Gst::ElementFactory.make 'filesrc'
        dec   = Gst::ElementFactory.make 'decodebin'
        conv  = Gst::ElementFactory.make 'audioconvert'
        resmp = Gst::ElementFactory.make 'audioresample'
        sink  = Gst::ElementFactory.make 'autoaudiosink'

        @src = src

        add src, dec, conv, resmp, sink
        src >> dec
        conv >> resmp >> sink

        dec.signal_connect 'new-decoded-pad' do |elem, pad|
          pad.link conv['sink']
        end
      end

      def song= number
        @src.location = path_for_song number
      end

      def each_song
        return enum_for :each_song unless block_given?

        n = 1
        loop do
          path = path_for_song n
          if File.exists? path
            yield n, path
          else
            break
          end
          n += 1
        end

        nil
      end

      private

      def path_for_song number
        filename = '%03u.mp3' % number
        File.join SONGS_PATH, filename
      end
    end
  end
end
