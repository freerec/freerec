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

        @window.on_recorder_record do
          @recorder.play
          update_recorder_state
        end

        @window.on_recorder_pause do
          @recorder.pause
          update_recorder_state
        end

        @window.on_recorder_stop do
          @recorder.stop
          update_recorder_state
        end

        @window.on_recorder_open_directory do
          system 'xdg-open', Model::Recorder::OUTPUT_DIR
        end

        @window.on_songs_play do
          @player.song = selected_song
          @player.play
          update_player_state
        end

        @window.on_songs_pause do
          @player.pause
          update_player_state
        end

        @window.on_songs_stop do
          @player.stop
          update_player_state
        end

        @window.on_destroy do
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

        @player.each_song do |n, path|
          @window.songs_add n
        end

        @window.on_songs_select do |number|
          selected_song = number
        end
        @window.songs_select 1

        update_recorder_text
        update_songs_text

        GLib::Timeout.add_seconds 1 do
          update_recorder_text
          update_songs_text
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

        update_recorder_text
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

        update_songs_text
      end

      def update_recorder_text
        seconds = @recorder.clock.time/1000000000.0 rescue 0
        time = format_time seconds

        @window.recorder_text = time

        true
      end

      def update_songs_text
        seconds = @player.clock.time/1000000000.0 rescue 0
        time = format_time seconds

        @window.songs_text = time

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

