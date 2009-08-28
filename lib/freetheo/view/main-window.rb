require 'delegate'
require 'gtk2'

require 'freetheo/view/builder'

module FreeTheo
  module View
    class MainWindow < DelegateClass(Gtk::Window)
      attr_reader :recorder_record_button,
                  :recorder_pause_button,
                  :recorder_stop_button,
                  :recorder_dir_button,
                  :songs_play_button,
                  :songs_pause_button,
                  :songs_stop_button

      attr_reader :songs_treeview

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

        @songs_treeview = builder['songs-treeview']

        show_all

        self.recorder_state = :stopped
        self.songs_state    = :stopped
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
    end
  end
end

