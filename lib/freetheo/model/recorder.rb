require 'gst'

module FreeTheo
  module Model
    class Recorder < Gst::Pipeline
      def initialize
        super()

        src = Gst::ElementFactory.make 'autoaudiosrc'
        tee = Gst::ElementFactory.make 'tee'

        add src, tee
        src >> tee

        spx_queue = Gst::ElementFactory.make 'queue'
        spx_conv  = Gst::ElementFactory.make 'audioconvert'
        spx_resmp = Gst::ElementFactory.make 'audioresample'
        spx_enc   = Gst::ElementFactory.make 'speexenc'
        spx_mux   = Gst::ElementFactory.make 'oggmux'
        spx_sink  = Gst::ElementFactory.make 'filesink'

        spx_enc.quality = 0
        spx_enc.vbr = true
        spx_enc.vad = true
        spx_sink.location = 'out.ogg'

        add spx_queue, spx_conv, spx_resmp, spx_enc, spx_mux, spx_sink
        tee >>
          spx_queue >> spx_conv >> spx_resmp >> spx_enc >> spx_mux >> spx_sink

        mp3_queue = Gst::ElementFactory.make 'queue'
        mp3_conv  = Gst::ElementFactory.make 'audioconvert'
        mp3_resmp = Gst::ElementFactory.make 'audioresample'
        mp3_enc   = Gst::ElementFactory.make 'lame'
        mp3_sink  = Gst::ElementFactory.make 'filesink'

        mp3_enc.bitrate = 64
        mp3_enc.mode = 'mono'
        mp3_sink.location = 'out.mp3'

        add mp3_queue, mp3_conv, mp3_resmp, mp3_enc, mp3_sink
        tee >> mp3_queue >> mp3_conv >> mp3_resmp >> mp3_enc >> mp3_sink
      end
    end
  end
end

