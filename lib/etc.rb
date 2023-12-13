# frozen-string-literal: true

require 'etc.so'
require 'shellwords'

module Etc
  #
  # Parses the +os-release+ file to return a hash like
  # <code>{ :NAME => "Fedora Linux", ... }</code>.
  #
  # Parsing is done according to the Bourne shell word rules, but no
  # shell expansion of any kind is performed and variables with empty
  # values are discarded.
  #
  # With no arguments, looks for the +os-release+ file in +/etc+ (and
  # a couple of other places). With arguments, goes through each one
  # of them until the first successful parse.
  #
  # If the host OS is Linux _and_ keys +:NAME+, +:ID+, or
  # +:PRETTY_NAME+ are undefined in the file, sets them to the default
  # standard values according to the Freedesktop specification.
  #
  # Raises a +RuntimeError+ if no file is successfully parsed or
  # an error from +Shellwords+ module in case of syntax problems.
  #
  def self.freedesktop_os_release *src
    defvars = RUBY_PLATFORM =~ /linux/i ? Freedesktop::LINUX_DEFAULS : {}

    (src.length == 0 ? Freedesktop::FILES : src).each do |file|
      text = File.read(file) rescue nil
      if text
        begin
          return defvars.merge Freedesktop.os_release_parse_str(text)
        rescue
          fail "Parsing `#{file}` failed"
        end
      end
    end

    fail "No suitable sources"
  end

  class Freedesktop # :nodoc:
    FILES = ['/etc/os-release', '/usr/lib/os-release', '/etc/initrd-release']
    LINUX_DEFAULS = {
      :NAME => "Linux",
      :ID => "linux",
      :PRETTY_NAME => "Linux",
    }

    def self.os_release_parse_str s
      valid_name = /^(?![0-9])[a-zA-Z0-9_]+$/
      s.split($/)
        .map { |line| Shellwords.split(line).first&.split('=') }
        .filter { |v| v && v.length > 1 && v.first =~ valid_name }
        .map { |v| [v.first.upcase.to_sym, v[1..-1].join('=')] }
        .to_h
    end
  end

end
