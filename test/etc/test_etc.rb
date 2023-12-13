# frozen_string_literal: true
require "test/unit"
require "etc"
require "tempfile"

class TestEtc < Test::Unit::TestCase
  def test_getlogin
    s = Etc.getlogin
    return if s == nil
    assert(s.is_a?(String), "getlogin must return a String or nil")
    assert_predicate(s, :valid_encoding?, "login name should be a valid string")
  end

  def test_passwd
    Etc.passwd do |s|
      assert_instance_of(String, s.name)
      assert_instance_of(String, s.passwd) if s.respond_to?(:passwd)
      assert_kind_of(Integer, s.uid)
      assert_kind_of(Integer, s.gid)
      assert_instance_of(String, s.gecos) if s.respond_to?(:gecos)
      assert_instance_of(String, s.dir)
      assert_instance_of(String, s.shell)
      assert_kind_of(Integer, s.change) if s.respond_to?(:change)
      assert_kind_of(Integer, s.quota) if s.respond_to?(:quota)
      assert(s.age.is_a?(Integer) || s.age.is_a?(String)) if s.respond_to?(:age)
      assert_instance_of(String, s.uclass) if s.respond_to?(:uclass)
      assert_instance_of(String, s.comment) if s.respond_to?(:comment)
      assert_kind_of(Integer, s.expire) if s.respond_to?(:expire)
    end

    Etc.passwd { assert_raise(RuntimeError) { Etc.passwd { } }; break }
  end

  def test_getpwuid
    # password database is not unique on UID, and which entry will be
    # returned by getpwuid() is not specified.
    passwd = Hash.new {[]}
    # on MacOSX, same entries are returned from /etc/passwd and Open
    # Directory.
    Etc.passwd {|s| passwd[s.uid] |= [s]}
    passwd.each_pair do |uid, s|
      assert_include(s, Etc.getpwuid(uid))
    end
    s = passwd[Process.euid]
    unless s.empty?
      assert_include(s, Etc.getpwuid)
    end
  end unless RUBY_PLATFORM.include?("android")

  def test_getpwnam
    passwd = {}
    Etc.passwd do |s|
      passwd[s.name] ||= s unless /\A\+/ =~ s.name
    end
    passwd.each_value do |s|
      assert_equal(s, Etc.getpwnam(s.name))
    end
  end unless RUBY_PLATFORM.include?("android")

  def test_passwd_with_low_level_api
    a = []
    Etc.passwd {|s| a << s }
    b = []
    Etc.setpwent
    while s = Etc.getpwent
      b << s
    end
    Etc.endpwent
    assert_equal(a, b)
  end

  def test_group
    Etc.group do |s|
      assert_instance_of(String, s.name)
      assert_instance_of(String, s.passwd) if s.respond_to?(:passwd)
      assert_kind_of(Integer, s.gid)
    end

    Etc.group { assert_raise(RuntimeError) { Etc.group { } }; break }
  end

  def test_getgrgid
    # group database is not unique on GID, and which entry will be
    # returned by getgrgid() is not specified.
    groups = Hash.new {[]}
    # on MacOSX, same entries are returned from /etc/group and Open
    # Directory.
    Etc.group {|s| groups[s.gid] |= [[s.name, s.gid]]}
    groups.each_pair do |gid, s|
      g = Etc.getgrgid(gid)
      assert_include(s, [g.name, g.gid])
    end
    s = groups[Process.egid]
    unless s.empty?
      g = Etc.getgrgid
      assert_include(s, [g.name, g.gid])
    end
  end

  def test_getgrnam
    groups = Hash.new {[]}
    Etc.group do |s|
      groups[s.name] |= [s.gid] unless /\A\+/ =~ s.name
    end
    groups.each_pair do |n, s|
      assert_include(s, Etc.getgrnam(n).gid)
    end
  end

  def test_group_with_low_level_api
    a = []
    Etc.group {|s| a << s }
    b = []
    Etc.setgrent
    while s = Etc.getgrent
      b << s
    end
    Etc.endgrent
    assert_equal(a, b)
  end

  def test_uname
    begin
      uname = Etc.uname
    rescue NotImplementedError
      return
    end
    assert_kind_of(Hash, uname)
    [:sysname, :nodename, :release, :version, :machine].each {|sym|
      assert_operator(uname, :has_key?, sym)
      assert_kind_of(String, uname[sym])
    }
  end

  def test_sysconf
    begin
      Etc.sysconf
    rescue NotImplementedError
      return
    rescue ArgumentError
    end
    assert_kind_of(Integer, Etc.sysconf(Etc::SC_CLK_TCK))
  end if defined?(Etc::SC_CLK_TCK)

  def test_confstr
    begin
      Etc.confstr
    rescue NotImplementedError
      return
    rescue ArgumentError
    end
    assert_kind_of(String, Etc.confstr(Etc::CS_PATH))
  end if defined?(Etc::CS_PATH)

  def test_pathconf
    begin
      Etc.confstr
    rescue NotImplementedError
      return
    rescue ArgumentError
    end
    IO.pipe {|r, w|
      val = w.pathconf(Etc::PC_PIPE_BUF)
      assert(val.nil? || val.kind_of?(Integer))
    }
  end if defined?(Etc::PC_PIPE_BUF)

  def test_nprocessors
    n = Etc.nprocessors
    assert_operator(1, :<=, n)
  end

  def test_ractor
    return unless Etc.passwd # => skip test if no platform support
    Etc.endpwent

    assert_ractor(<<~RUBY, require: 'etc')
      ractor = Ractor.new do
        Etc.passwd do |s|
          Ractor.yield :sync
          Ractor.yield s.name
          break :done
        end
      end
      ractor.take # => :sync
      assert_raise RuntimeError, /parallel/ do
        Etc.passwd {}
      end
      name = ractor.take # => first name
      ractor.take # => :done
      name2 = Etc.passwd do |s|
        break s.name
      end
      assert_equal(name2, name)
    RUBY
  end

  def test_freedesktop_os_release
      e = assert_raise(RuntimeError) { Etc.freedesktop_os_release '/not/found' }
      assert_equal 'No suitable sources', e.message

      Tempfile.create do |file|
        file.puts "ID=test"
        file.flush
        if RUBY_PLATFORM =~ /linux/i
          assert_equal({:ID=>"test", :NAME=>"Linux", :PRETTY_NAME=>"Linux"},
                       Etc.freedesktop_os_release(file.path))
        else
          assert_equal({:ID=>"test"}, Etc.freedesktop_os_release(file.path))
        end
      end

      Tempfile.create do |file|
        file.puts "foo='1"
        file.flush
        e = assert_raise(RuntimeError) {
          Etc.freedesktop_os_release file.path
        }
        assert_equal("Parsing `#{file.path}` failed", e.message)
      end
  end

  def test_freedesktop_os_release_parse_str
      assert_equal({}, Etc::Freedesktop.os_release_parse_str(""))
      assert_equal({}, Etc::Freedesktop.os_release_parse_str("\n"))
      assert_equal({ :BAR=>"$USER=foo `bar`" },
                   Etc::Freedesktop.os_release_parse_str("\n\
not an assigment, ignored
IGNORED_FOR_THE_VALUE_CONTAINS_AN_EMPTY_STRING_1=\n\
IGNORED_FOR_THE_VALUE_CONTAINS_AN_EMPTY_STRING_2=''\n\
INVALID FOR THE NAME HAS SPACES='123'\n\
0_INVALID_FOR_THE_NAME_STARTS_WITH_A_DIGIT='123'\n\
bar=\"$USER=foo `bar`\"\n\
 # all comments
# are ignored"))

      e = assert_raise(ArgumentError) {
        Etc::Freedesktop.os_release_parse_str("foo=\"1")
      }
      assert_match(/Unmatched quote/, e.message)
  end

end
