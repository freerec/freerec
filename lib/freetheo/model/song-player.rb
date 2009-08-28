require 'gst'

module FreeTheo
  module Model
    class SongPlayer < Gst::Pipeline
      SONGS_PATH = File.dirname(__FILE__)+'/../../../songs'

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
      end

      private

      def path_for_song number
        filename = '%03u.mp3' % number
        File.join SONGS_PATH, filename
      end
    end
  end
end

