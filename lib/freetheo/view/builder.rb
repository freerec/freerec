require 'gtk2'
require 'singleton'

module FreeTheo
  module View
    class Builder < Gtk::Builder
      include Singleton

      def initialize
        super()

        self << File.dirname(__FILE__)+'/../../../ui/freetheo.ui'
      end
    end
  end
end

