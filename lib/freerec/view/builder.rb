require 'gtk2'
require 'singleton'

module FreeRec
  module View
    class Builder < Gtk::Builder
      include Singleton

      def initialize
        super()

        self << File.dirname(__FILE__)+'/../../../ui/freerec.ui'
      end
    end
  end
end

