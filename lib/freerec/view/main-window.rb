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

        @recorder_scale = builder['recorder-scale']
        @recorder_scale.sensitive = false
        @recorder_scale.update_policy = Gtk::UPDATE_DISCONTINUOUS
        @recorder_scale.set_range 0, 1
        @recorder_scale.signal_connect 'format-value' do |scale, position|
          format_ns position
        end

        @songs_play_button  = builder['songs-play-button']
        @songs_pause_button = builder['songs-pause-button']
        @songs_stop_button  = builder['songs-stop-button']

        @songs_scale = builder['songs-scale']
        @songs_scale.sensitive = false
        @songs_scale.update_policy = Gtk::UPDATE_DISCONTINUOUS
        @songs_scale.set_range 0, 1
        @songs_scale.set_increments 5_000_000_000, 5_000_000_000
        @songs_scale.signal_connect 'format-value' do |scale, position|
          duration = scale.adjustment.upper
          "%s / %s" % [format_ns(position), format_ns(duration)]
        end

        @songs_scale_handlers = []

        @songs_scale_dragging = false
        @songs_scale.signal_connect 'button-press-event' do
          @songs_scale_dragging = true
          false
        end
        @songs_scale.signal_connect 'button-release-event' do
          @songs_scale_dragging = false
          false
        end

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
      end

      def recorder_position position
        @recorder_scale.set_range 0, [1, position].max
        @recorder_scale.value = [0, position].max
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
      end

      def songs_position position, duration
        return if @songs_scale_dragging

        @songs_scale_handlers.each do |h|
          @songs_scale.signal_handler_block h
        end

        duration = if duration < 0 then position else duration end

        @songs_scale.sensitive = position >= 0

        @songs_scale.set_range 0, [1, duration].max
        @songs_scale.set_value [0, position].max

        @songs_scale_handlers.each do |h|
          @songs_scale.signal_handler_unblock h
        end
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

      def on_songs_seek
        h = @songs_scale.signal_connect 'value-changed' do
          yield @songs_scale.value
        end
        @songs_scale_handlers << h
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

      private

      def format_ns time
        s = 1_000_000_000
        h_m_s_ns = [60*60*s, 60*s, s].inject([time]) do |list, div|
          list[0..-2] + list[-1].divmod(div)
        end

        if h_m_s_ns[0] > 0
          '%u:%02u:%02u' % h_m_s_ns[0..2]
        else
          '%u:%02u' % h_m_s_ns[1..2]
        end
      end
    end
  end
end

