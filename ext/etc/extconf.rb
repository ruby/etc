# frozen_string_literal: true
require 'mkmf'

headers = []
%w[sys/utsname.h].each {|h|
  if have_header(h, headers)
    headers << h
  end
}
have_library("sun", "getpwnam")	# NIS (== YP) interface for IRIX 4
have_func("uname((struct utsname *)NULL)", headers)
have_func("getlogin")
have_func("getpwent")
have_func("getgrent")
if (sysconfdir = RbConfig::CONFIG["sysconfdir"] and
    !RbConfig.expand(sysconfdir.dup, "prefix"=>"", "DESTDIR"=>"").empty?)
  $defs.push("-DSYSCONFDIR=#{Shellwords.escape(sysconfdir.dump)}")
end

have_func("sysconf")
have_func("confstr")
have_func("fpathconf")

# for https://github.com/ruby/etc
srcdir = __dir__
constdefs = "#{srcdir}/constdefs.h"
if !File.exist?(constdefs)
  ruby = RbConfig.ruby
  if File.file?(ruby)
    ruby = [ruby]
  else
    require "shellwords"
    ruby = Shellwords.split(ruby)
  end
  system(*ruby, "#{srcdir}/mkconstants.rb", "-o", constdefs)
end

# TODO: remove when dropping 2.7 support, as exported since 3.0
have_func('rb_deprecate_constant(Qnil, "None")')

have_func("rb_io_descriptor")

$distcleanfiles << "constdefs.h"

create_makefile("etc")
