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

require 'fileutils'
require 'gst'

require 'object-extensions'

module FreeRec
  module Model
    class Recorder < Gst::Pipeline
      def self.output_dir= dir
        FileUtils.mkdir_p dir

        metaclass = class << self; self; end
        metaclass.send :define_method, :output_dir do dir end
      end

      def self.output_dir
        raise RuntimeError, "Call #{self}.output_dir = dir first"
      end

      def initialize
        super()

        src   = Gst::ElementFactory.make! 'autoaudiosrc'
        conv  = Gst::ElementFactory.make! 'audioconvert'
        resmp = Gst::ElementFactory.make! 'audioresample'
        tee   = Gst::ElementFactory.make! 'tee'

        @src = src

        caps = Gst::Caps.parse! 'audio/x-raw-int, channels=1'

        add src, conv, resmp, tee
        src >> conv
        conv.link_filtered! resmp, caps
        resmp >> tee

        spx_queue = Gst::ElementFactory.make! 'queue'
        spx_enc   = Gst::ElementFactory.make! 'speexenc'
        spx_mux   = Gst::ElementFactory.make! 'oggmux'
        spx_sink  = Gst::ElementFactory.make! 'filesink'

        @spx_sink = spx_sink

        spx_enc.quality = 0
        spx_enc.vbr = true
        spx_enc.vad = true
        spx_enc.dtx = true
        spx_enc.complexity = 10

        add spx_queue, spx_enc, spx_mux, spx_sink
        tee >> spx_queue >> spx_enc >> spx_mux >> spx_sink

        mp3_queue = Gst::ElementFactory.make! 'queue'
        mp3_enc   = Gst::ElementFactory.make! 'lame'
        mp3_sink  = Gst::ElementFactory.make! 'filesink'

        @mp3_sink = mp3_sink

        mp3_enc.bitrate = 64

        add mp3_queue, mp3_enc, mp3_sink
        tee >> mp3_queue >> mp3_enc >> mp3_sink

        vis_queue = Gst::ElementFactory.make! 'queue'
        vis_vis   = Gst::ElementFactory.make! 'libvisual_lv_analyzer'
        vis_crop  = Gst::ElementFactory.make! 'videocrop'
        vis_color = Gst::ElementFactory.make! 'ffmpegcolorspace'
        vis_sink  = Gst::ElementFactory.make! 'xvimagesink'

        @vis_sink = vis_sink

        vis_caps = Gst::Caps.parse! 'video/x-raw-rgb, width=256, height=80'

        add vis_queue, vis_vis, vis_crop, vis_color, vis_sink
        tee >> vis_queue >> vis_vis
        vis_vis.link_filtered! vis_crop, vis_caps
        vis_crop >> vis_color >> vis_sink

        vis_crop.top = 40
        vis_sink.sync = false
        vis_sink.force_aspect_ratio = true
        vis_sink.handle_events = false
      end

      def window= xid
        @vis_sink.xwindow_id = xid
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

      def position
        # Override position; when stopped at, say, 1:23 and restarted, this
        # pipeline’s queried position often stays at 1:23 until the actual
        # recording time reaches 1:23, and only then proceeds forward.

        @src.clock.time rescue -1
      end

      def duration
        -1
      end

      private

      def create_files
        base = "%s/%s" % [
          self.class.output_dir,
          Time.now.strftime('%Y_%m_%d_%a')
        ]

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

