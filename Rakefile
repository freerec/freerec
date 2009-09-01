require 'rake/clean'
require 'set'
require 'yaml'

task :default => :build

task :build => [:'intltool-merge', :mo]

# {{{ Globals

PACKAGE = 'freerec'

INTLTOOL_SOURCES   = Rake::FileList.new '**/*.desktop.in', '**/*.ui.in'
INTLTOOL_LIST_FILE = 'po/POTFILES.in'
INTLTOOL_POT_FILE  = "po/#{PACKAGE}-intltool.pot"

RGETTEXT_SOURCES   = Rake::FileList.new 'freerec', '**/*.rb'
RGETTEXT_LIST_FILE = "po/#{PACKAGE}-rgettext.list"
RGETTEXT_POT_FILE  = "po/#{PACKAGE}-rgettext.pot"

POT_FILE = "po/#{PACKAGE}.pot"

PO_FILES = Rake::FileList.new 'po/*.po'

# }}}

# {{{ ListFileTask

class ListFileTask < Rake::Task
  def initialize *args
    super

    enhance do
      write_list
    end
  end

  def needed?
    read_list.to_set != prerequisites.to_set
  end

  def timestamp
    n = name.to_s
    if File.exist? n
      File.mtime n
    else
      Time.now
    end
  end

  def read_list
    begin
      YAML.load_file name
    rescue Errno::ENOENT
      []
    end
  end

  def write_list
    rake_output_message "Update #{name}" if verbose

    open name, 'w' do |io|
      YAML.dump prerequisites, io
    end
  end
end

# }}}

# {{{ intltool: po/POTFILES.in

class IntltoolPotfilesTask < ListFileTask
  def read_list
    [].tap do |list|
      begin
        open name do |io|
          io.each do |line|
            line.gsub! /\[[^\]]*\]/, ''
            line.sub! /#.*/, ''
              line.strip!
            list << line unless line.empty?
          end
        end
      rescue Errno::ENOENT
        # Ignore.
      end
    end
  end

  def write_list
    rake_output_message "Update #{name}" if verbose

    open name, 'w' do |io|
      io.puts '[encoding: UTF-8]'
      prerequisites.sort.each do |file|
        line = file.dup
        line.insert 0, '[type: gettext/glade] ' if file =~ /\.ui\.in$/
        io.puts line
      end
    end
  end
end

IntltoolPotfilesTask.define_task INTLTOOL_LIST_FILE => INTLTOOL_SOURCES
CLEAN << INTLTOOL_LIST_FILE

# }}}

# {{{ intltool-update: PACKAGE-intltool.pot

file INTLTOOL_POT_FILE => [INTLTOOL_LIST_FILE, 'po/Makevars']
file INTLTOOL_POT_FILE => INTLTOOL_SOURCES

file INTLTOOL_POT_FILE do |t|
  Dir.chdir 'po' do
    sh *%W{
      intltool-update --pot
      --gettext-package=#{t.name.pathmap('%f').pathmap('%n')}
    }
  end
end

CLEAN << INTLTOOL_POT_FILE

# }}}

# {{{ rgettext: PACKAGE-rgettext.pot

ListFileTask.define_task RGETTEXT_LIST_FILE => RGETTEXT_SOURCES
CLEAN << RGETTEXT_LIST_FILE

file RGETTEXT_POT_FILE => RGETTEXT_LIST_FILE
file RGETTEXT_POT_FILE => RGETTEXT_SOURCES

ta = file RGETTEXT_POT_FILE do |t|
  rm_f t.name
  cmd = %W{rgettext} + RGETTEXT_SOURCES + %W{-o #{t.name}}
  sh *cmd
end

CLEAN << RGETTEXT_POT_FILE

# }}}

# {{{ msgcat: PACKAGE.pot

file POT_FILE => [INTLTOOL_POT_FILE, RGETTEXT_POT_FILE] do |t|
  cmd = %W{msgcat --sort-by-file} + t.prerequisites + %W{-o #{t.name}}
  sh *cmd
end

CLEAN << POT_FILE

# }}}

# {{{ msgmerge

task :msgmerge => POT_FILE do
  PO_FILES.each do |dst|
    sh *%W{msgmerge --update --backup=off --sort-by-file #{dst} #{POT_FILE}}
  end
end

# }}}

# {{{ intltool-merge

INTLTOOL_MERGE_CACHE = 'po/.intltool-merge-cache'
CLEAN << INTLTOOL_MERGE_CACHE

INTLTOOL_SOURCES.each do |src|
  dst = src.pathmap('%X')
  unless src == "#{dst}.in"
    raise RuntimeError, "Got #{src.inspect}, expected (...).in"
  end

  ext = dst.pathmap('%x')

  arg = case ext
  when '.desktop'
    '--desktop-style'
  when '.ui'
    '--xml-style'
  else
    raise RuntimeError, "Extension #{ext.inspect} not recognized"
  end

  file dst => PO_FILES

  file dst => src do
    sh *%W{
      intltool-merge #{arg} --utf8 --cache #{INTLTOOL_MERGE_CACHE}
      po #{src} #{dst}
    }
  end

  CLOBBER << dst

  task :'intltool-merge' => dst
end

# }}}

# {{{ locale/**/*.mo (msgfmt)

PO_FILES.each do |src|
  if match = src.match(%r{\Apo/(.+)\.po\z})
    lang = match[1]
    dst  = "locale/#{lang}/LC_MESSAGES/#{PACKAGE}.mo"

    file dst => src do
      mkdir_p dst.pathmap '%d'
      sh *%W{msgfmt --check -o #{dst} #{src}}
    end

    CLOBBER << dst

    task :clobber do
      cmd = %W{
        find locale -depth -type d -exec rmdir --ignore-fail-on-non-empty {} +
      }
      sh *cmd do |ok, res|
        ok or $stderr.puts "…but that’s okay."
      end
    end

    task :mo => dst

  else
    raise RuntimeError, "Failed to parse language from #{src.inspect}"
  end
end

# }}}

# vim:set foldmethod=marker:
