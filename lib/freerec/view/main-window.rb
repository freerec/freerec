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

require 'delegate'
require 'gtk2'

require 'freerec/view/builder'

module FreeRec
  module View
    class MainWindow < DelegateClass(Gtk::Window)
      def initialize
        builder = Builder.instance
        super builder['main-window']

        @recorder_record_button = builder['recorder-record-button']
        @recorder_pause_button  = builder['recorder-pause-button']
        @recorder_stop_button   = builder['recorder-stop-button']
        @recorder_dir_button    = builder['recorder-open-directory-button']

        @songs_play_button  = builder['songs-play-button']
        @songs_pause_button = builder['songs-pause-button']
        @songs_stop_button  = builder['songs-stop-button']

        @recorder_progressbar = builder['recorder-progressbar']
        @songs_progressbar    = builder['songs-progressbar']

        @recorder_visualization = builder['recorder-visualization-drawingarea']
        @recorder_visualization.app_paintable = true
        @recorder_visualization.double_buffered = false

        @songs_iconview = builder['songs-iconview']

        store = Gtk::ListStore.new Integer, String, Gdk::Pixbuf
        @songs_iconview.model = store
        @songs_iconview.text_column   = 1
        @songs_iconview.pixbuf_column = 2

        @songs_icon = Gtk::IconTheme.default.load_icon 'audio-x-generic', 16,
          Gtk::IconTheme::LOOKUP_USE_BUILTIN

        show_all

        self.recorder_state = :stopped
        self.songs_state    = :stopped
      end

      def visualization_xid
        @recorder_visualization.window.xid
      end

      def visualization_on_expose
        @recorder_visualization.signal_connect 'expose-event' do
          yield
        end
      end

      def recorder_state= state
        unless [:recording, :paused, :stopped].include? state
          raise ArgumentError, "Invalid state #{state.inspect}", caller
        end

        @recorder_record_button.sensitive = [:paused, :stopped].include? state
        @recorder_pause_button.sensitive  = :recording == state
        @recorder_stop_button.sensitive   = [:recording, :paused].include? state

        @recorder_record_button.visible = @recorder_record_button.sensitive?
        @recorder_pause_button.visible  = @recorder_pause_button.sensitive?

        case state
        when :recording
          @recorder_progressbar.fraction = 1.0
        when :paused, :stopped
          @recorder_progressbar.fraction = 0.0
        end
      end

      def recorder_text= text
        @recorder_progressbar.text = text
      end

      def on_recorder_record &block
        @recorder_record_button.signal_connect 'clicked', &block
      end

      def on_recorder_pause &block
        @recorder_pause_button.signal_connect 'clicked', &block
      end

      def on_recorder_stop &block
        @recorder_stop_button.signal_connect 'clicked', &block
      end

      def on_recorder_open_directory &block
        @recorder_dir_button.signal_connect 'clicked', &block
      end

      def songs_state= state
        unless [:playing, :paused, :stopped].include? state
          raise ArgumentError, "Invalid state #{state.inspect}", caller
        end

        @songs_play_button.sensitive  = [:paused, :stopped].include? state
        @songs_pause_button.sensitive = :playing == state
        @songs_stop_button.sensitive  = [:playing, :paused].include? state

        @songs_play_button.visible  = @songs_play_button.sensitive?
        @songs_pause_button.visible = @songs_pause_button.sensitive?

        case state
        when :playing, :paused
          @songs_progressbar.fraction = 1.0
        when :stopped
          @songs_progressbar.fraction = 0.0
        end
      end

      def songs_text= text
        @songs_progressbar.text = text
      end

      def on_songs_play &block
        @songs_play_button.signal_connect 'clicked', &block
      end

      def on_songs_pause &block
        @songs_pause_button.signal_connect 'clicked', &block
      end

      def on_songs_stop &block
        @songs_stop_button.signal_connect 'clicked', &block
      end

      def on_destroy &block
        signal_connect 'destroy', &block
      end

      def songs_add number
        iter = @songs_iconview.model.append
        iter[0] = number
        iter[1] = number.to_s
        iter[2] = @songs_icon
      end

      def on_songs_select
        @songs_iconview.signal_connect 'selection-changed' do |iconview|
          path = *iconview.selected_items
          if path and iter = iconview.model.get_iter(path)
            yield iter.get_value(0)
          end
        end
      end

      def songs_select number
        # XXX Not very efficient. :-P
        @songs_iconview.model.each do |model, path, iter|
          if iter.get_value(0) == number
            @songs_iconview.select_path path
            break
          end
        end
      end
    end
  end
end

