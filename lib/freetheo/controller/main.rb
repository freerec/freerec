require 'freetheo/model/song-player'
require 'freetheo/view/main-window'

module FreeTheo
  module Controller
    class Main
      def initialize
        @window = View::MainWindow.new

        @player = Model::SongPlayer.new
        @player.song = 1

        @window.songs_play_button.signal_connect 'clicked' do
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
    end
  end
end

