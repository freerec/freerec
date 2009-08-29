require 'freerec/model/recorder'
require 'freerec/model/song-player'
require 'freerec/view/main-window'

module FreeRec
  module Controller
    class Main
      def initialize
        @window = View::MainWindow.new

        @recorder = Model::Recorder.new
        @player = Model::SongPlayer.new

        @recorder_state = :stopped
        @player_state   = :stopped

        selected_song = 0

        @window.recorder_record_button.signal_connect 'clicked' do
          @recorder.play
          update_recorder_state
        end

        @window.recorder_pause_button.signal_connect 'clicked' do
          @recorder.pause
          update_recorder_state
        end

        @window.recorder_stop_button.signal_connect 'clicked' do
          @recorder.stop
          update_recorder_state
        end

        @window.recorder_dir_button.signal_connect 'clicked' do
          system 'xdg-open', Model::Recorder::OUTPUT_DIR
        end

        @window.songs_play_button.signal_connect 'clicked' do
          @player.song = selected_song
          @player.play
          update_player_state
        end

        @window.songs_pause_button.signal_connect 'clicked' do
          @player.pause
          update_player_state
        end

        @window.songs_stop_button.signal_connect 'clicked' do
          @player.stop
          update_player_state
        end

        @window.signal_connect 'destroy' do
          Gtk.main_quit
        end

        @recorder.bus.add_watch do |bus, message|
          case message.type
          when Gst::Message::EOS
            @recorder.stop
            update_recorder_state
          end
          true
        end

        @player.bus.add_watch do |bus, message|
          case message.type
          when Gst::Message::EOS
            @player.stop
            update_player_state
          end
          true
        end

        build_songs_treeview

        selection = @window.songs_treeview.selection
        selection.signal_connect 'changed' do |treesel|
          selected = treesel.selected
          selected_song = selected.get_value(0) if selected
        end
        selection.select_iter @window.songs_treeview.model.iter_first

        update_recorder_progressbar
        update_songs_progressbar

        GLib::Timeout.add_seconds 1 do
          update_recorder_progressbar
          update_songs_progressbar
        end

        if block_given?
          begin
            yield self
          ensure
            stop
          end
        end
      end

      def stop
        @player.stop if @player
      end

      private

      def update_recorder_state
        state = @recorder.get_state(Gst::ClockTime::NONE)[1]
        case state
        when Gst::State::PLAYING
          @recorder_state = :recording
        when Gst::State::PAUSED
          @recorder_state = :paused
        else
          @recorder_state = :stopped
        end

        @window.recorder_state = @recorder_state

        update_recorder_progressbar
      end

      def update_player_state
        state = @player.get_state(Gst::ClockTime::NONE)[1]
        case state
        when Gst::State::PLAYING
          @player_state = :playing
        when Gst::State::PAUSED
          @player_state = :paused
        else
          @player_state = :stopped
        end

        @window.songs_state = @player_state

        update_songs_progressbar
      end

      def build_songs_treeview
        store = Gtk::ListStore.new Integer
        @player.each_song do |n, path|
          iter = store.append
          iter[0] = n
        end
        @window.songs_treeview.model = store

        renderer = Gtk::CellRendererText.new

        column = Gtk::TreeViewColumn.new 'Number', renderer, 'text' => 0
        @window.songs_treeview.append_column column

        nil
      end

      def update_recorder_progressbar
        bar = @window.recorder_progressbar

        seconds = @recorder.clock.time/1000000000.0 rescue 0
        time = format_time seconds

        case @recorder_state
        when :recording
          bar.text = time
          bar.fraction = 1.0
        when :paused
          bar.text = time
          bar.fraction = 0.0
        when :stopped
          bar.text = ''
          bar.fraction = 0.0
        end

        true
      end

      def update_songs_progressbar
        bar = @window.songs_progressbar

        seconds = @player.clock.time/1000000000.0 rescue 0
        time = format_time seconds

        case @player_state
        when :playing
          bar.text = time
          bar.fraction = 1.0
        when :paused
          bar.text = time
          bar.fraction = 1.0
        when :stopped
          bar.text = ''
          bar.fraction = 0.0
        end

        true
      end

      def format_time seconds
        hms = [60*60, 60].inject([seconds]) do |list, div|
          list[0..-2] + list[-1].divmod(div)
        end

        '%u:%02u:%02u' % hms
      end
    end
  end
end

