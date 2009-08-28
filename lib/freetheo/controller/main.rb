require 'freetheo/model/song-player'
require 'freetheo/view/main-window'

module FreeTheo
  module Controller
    class Main
      def initialize
        @window = View::MainWindow.new

        @player = Model::SongPlayer.new

        selected_song = 0

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

        build_songs_treeview

        selection = @window.songs_treeview.selection
        selection.signal_connect 'changed' do |treesel|
          selected = treesel.selected
          selected_song = selected.get_value(0) if selected
        end
        selection.select_iter @window.songs_treeview.model.iter_first

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

      def update_player_state
        state = @player.get_state(Gst::ClockTime::NONE)[1]
        case state
        when Gst::State::PLAYING
          @window.songs_state = :playing
        when Gst::State::PAUSED
          @window.songs_state = :paused
        else
          @window.songs_state = :stopped
        end
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
    end
  end
end

