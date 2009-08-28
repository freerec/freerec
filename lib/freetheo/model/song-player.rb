module FreeTheo
  module Model
    class SongPlayer < Gst::Pipeline
      def initialize song_number
        super()

        src   = Gst::ElementFactory.make 'filesrc'
        dec   = Gst::ElementFactory.make 'decodebin'
        conv  = Gst::ElementFactory.make 'audioconvert'
        resmp = Gst::ElementFactory.make 'audioresample'
        sink  = Gst::ElementFactory.make 'autoaudiosink'

        src.location = "songs/%03u.mp3" % song_number

        add src, dec, conv, resmp, sink
        src >> dec
        conv >> resmp >> sink

        dec.signal_connect 'new-decoded-pad' do |elem, pad|
          pad.link conv['sink']
        end
      end
    end
  end
end

