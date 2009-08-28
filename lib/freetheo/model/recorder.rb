require 'fileutils'
require 'gst'

module FreeTheo
  module Model
    class Recorder < Gst::Pipeline
      OUTPUT_DIR = File.dirname(__FILE__)+'/../../../recordings'

      FileUtils.mkdir_p OUTPUT_DIR

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

        @spx_sink = spx_sink

        spx_enc.quality = 0
        spx_enc.vbr = true
        spx_enc.vad = true

        add spx_queue, spx_conv, spx_resmp, spx_enc, spx_mux, spx_sink
        tee >>
          spx_queue >> spx_conv >> spx_resmp >> spx_enc >> spx_mux >> spx_sink

        mp3_queue = Gst::ElementFactory.make 'queue'
        mp3_conv  = Gst::ElementFactory.make 'audioconvert'
        mp3_resmp = Gst::ElementFactory.make 'audioresample'
        mp3_enc   = Gst::ElementFactory.make 'lame'
        mp3_sink  = Gst::ElementFactory.make 'filesink'

        @mp3_sink = mp3_sink

        mp3_enc.bitrate = 64
        mp3_enc.mode = 'mono'

        add mp3_queue, mp3_conv, mp3_resmp, mp3_enc, mp3_sink
        tee >> mp3_queue >> mp3_conv >> mp3_resmp >> mp3_enc >> mp3_sink
      end

      def play
        old_state = get_state(Gst::ClockTime::NONE)[1]
        unless [Gst::State::PLAYING, Gst::State::PAUSED].include? old_state
          spx_name, mp3_name = create_files

          @spx_sink.location = spx_name
          @mp3_sink.location = mp3_name
        end

        super()
      end

      private

      def create_files
        base = "%s/%s" % [OUTPUT_DIR, Time.now.strftime('%Y_%m_%d')]

        100.times do |i|
          spx_name = "%s_%02u.ogg" % [base, i]
          mp3_name = "%s_%02u.mp3" % [base, i]

          if not File.exists? spx_name and
             not File.exists? mp3_name
            # Make sure there is no race condition: exclusively create empty
            # files.
            File.open spx_name, File::RDWR|File::CREAT|File::EXCL do end
            File.open mp3_name, File::RDWR|File::CREAT|File::EXCL do end

            return [spx_name, mp3_name]
          end
        end

        raise RuntimeError, "Failed to create unique filenames"
      end
    end
  end
end

