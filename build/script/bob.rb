#!/usr/bin/env ruby

# copyright:      Copyright (c) 2009 Tango. All rights reserved
# license:        BSD style: $(LICENSE)
# version:        Oct 2009: Initial release
# author:         larsivi, sleets, kris, Jacob Carlborg 
# port to ruby:   Jacob Carlborg

require "optparse"
require "stringio"

COMPILERS = %w[dmd gdc ldc]
RUNTIMES = COMPILERS
FILTERS = %w[osx freebsd linux haiku solaris windows]

OSX = RUBY_PLATFORM =~ /darwin/ ? true : false
FREEBSD = RUBY_PLATFORM =~ /freebsd/ ? true : false
LINUX = RUBY_PLATFORM =~ /linux/ ? true : false
HAIKU = RUBY_PLATFORM =~ /haiku/ ? true : false
SOLARIS = RUBY_PLATFORM =~ /solaris/ ? true : false
WINDOWS = RUBY_PLATFORM =~ /windows/ ? true : false

class Functor
	def initialize (symbol, object)
		@symbol = symbol
		@object = object
	end
	
	def call (*args)
		@symbol.to_proc.call(@object, *args)
	end
end

class Symbol	
	def to_proc
 		proc { |obj, *args| obj.send(self, *args) }
 	end
end

class Hash
	def contains_key? (regexp)
		self.each_key do |key|
			return true if regexp =~ Regexp.new(key)
		end
		
		return false
	end	
end

class String
	def each_char
		if block_given?
			scan(/./m) do |x|
				yield x
			end
		else
			scan(/./m)
		end
	end	
end

def main (arg)
	help_msg = "Use the `-h' flag or for help."	
	banner = "Usage: #{File.basename(__FILE__)} path-to-tango-root\n" + 
			 "Example: ./build/script/bob.rb -q -r dmd -c dmd ."
	
	begin 
		args = Args.new
		
		populate(arg, args, help_msg, banner)
		
		File.delete(args.lib) if File.exists?(args.lib)
		Dir.mkdir(args.objs) unless File.exists?(args.objs)

		linux_dmd = "dmd -c -I#{args.root}/tango/core -I#{args.root} -I#{args.root}/tango/core/vendor #{args.flags} -of#{args.objs}/"
		linux_ldc = "ldc -c -I#{args.root}/tango/core -I#{args.root}/tango/core/rt/compiler/ldc -I#{args.root} -I#{args.root}/tango/core/vendor #{args.flags} -of#{args.objs}/"
		linux_gdc = "gdc -c -I#{args.root}/tango/core -I#{args.root} -I#{args.root}/tango/core/vendor #{args.flags} -of#{args.objs}/"
		
		osx_dmd = linux_dmd[0 ... 4] + "-version=darwin -version=osx " + linux_dmd[4 .. -1]
		osx_ldc = linux_ldc
		osx_gdc = linux_gdc
		
		freebsd_dmd = linux_dmd[0 ... 4] + "-version=freebsd " + linux_dmd[4 .. -1]
		freebsd_ldc = linux_ldc
		freebsd_gdc = linux_gdc
		
		solaris_dmd = linux_dmd
		solaris_ldc = linux_ldc
		solaris_gdc = linux_gdc		
				
		Posix.new(args, "osx", osx_dmd, osx_ldc, osx_gdc)
		Posix.new(args, "linux", linux_dmd, linux_ldc, linux_gdc)
		Posix.new(args, "freebsd", freebsd_dmd, freebsd_ldc, freebsd_gdc)
		Posix.new(args, "solaris", solaris_dmd, solaris_ldc, solaris_gdc)
		Windows.new(args)
		
		puts FileFilter.builder(args.os, args.compiler).call.to_s + " files"
	rescue => e
		msg = e.message
		msg = "Internal error" if msg.empty?
		
		die msg, banner, help_msg
	end
end

class FileFilter
	VERSION = 1.2
	@@builders = {}
	
	def initialize (args)
		@libs = StringIO.new
		@args = args
		@count = 0
		@suffix = ""
		@excluded = {}		
		
		excluded("tango/core") unless @args.core

		exclude("tango/net/cluster");
		exclude("tango/io/protocol");

		exclude("tango/sys/win32");
		exclude("tango/sys/darwin");
		exclude("tango/sys/freebsd");
		exclude("tango/sys/linux");
		exclude("tango/sys/solaris");

		exclude("tango/core/rt/gc/stub");
		exclude("tango/core/rt/compiler/dmd");
		exclude("tango/core/rt/compiler/gdc");
		exclude("tango/core/rt/compiler/ldc");
		exclude("tango/core/vendor")
		
		include("tango/core/rt/compiler/" + args.target)
		include("tango/core/vendor/" + args.target)
	end
	
	def self.register (platform, compiler, symbol, object)
		@@builders[platform + compiler] = Functor.new(symbol, object)
	end

	def self.builder (platform, compiler)
		s = platform + compiler
		return @@builders[s] if @@builders.has_key?(s)
		
		raise "Unsupported combination of " + platform + " and " + compiler
	end
	
	def scan (suffix, &block)
		@suffix = suffix
		
		pwd = Dir.pwd
		
		Dir.chdir(File.join(@args.root, "tango"))		
		pattern = File.join("**", "*" + suffix)
		
		Dir[pattern].each do |file|
			f = File.join(@args.root, "tango", file)
			
			unless @excluded.contains_key?(f)
				@count += 1
				block.call(f)
			end
		end
		
		Dir.chdir(pwd)
	end	
	
	def exclude (path)
		@excluded[path] = true
	end
	
	def include (path)
		@excluded.delete(path)
	end
	
	def objname (file, ext = ".obj")		
		folder = File.dirname(file)
		name = File.basename(file, File.extname(file))

		tmp = folder[@args.root.length + 1 .. -1] + name + @args.flags
		return tmp.gsub(/[.\/= "]/, "-") + ext
	end
	
	def isOverdue (file, objfile)
		newObjFile = File.join(@args.objs, objfile)
		
		return true unless File.exists?(newObjFile)
		
		src = File.mtime(file)
		obj = File.mtime(newObjFile)
		
		return src >= obj
	end
	
	def addToLib (obj)
		eol = "\r\n" if WINDOWS
		eol = " " unless WINDOWS
		
		file = File.join(@args.objs, obj)
		
		@libs << file << eol if File.exists?(file)
	end
	
	def makeLib (use32bit = false)
		if @libs.length > 0
			if @args.dynamic
				gcc = use32bit ? "gcc -m32" : "gcc"				
				options = "-dynamiclib -install_name @rpath/#{File.basename(@args.lib)} -Xlinker -headerpad_max_install_names" if DARWIN

				exec("#{gcc} #{options} -o #{@args.lib} #{@libs.string} -lz -lbz2")
			else
				exec("ar -r #{@args.lib} #{@libs.string}")
			end
		end
	end
	
	def exec (cmd)
		exec2(cmd, nil, nil)
	end
	
	def exec2 (cmd, env, work_dir)		
		puts cmd if @args.verbose
		
		unless @args.inhibit
			Dir.chdir(work_dir) unless work_dir.nil? || work_dir.empty?		
			result = `#{cmd}`
			check_command(nil, cmd)
		end
	end
	
	def check_command (cmd, line)
		if $?.to_i != 0
			raise "#{cmd} returned #{$?.to_int/256} exit status\nline was: #{line}"
		end
	end
end

class Windows < FileFilter
	def initialize (args)
		super(args)
		exclude("tango/stdc/posix")
		include("tango/sys/win32")
		FileFilter.register("windows", "dmd", :dmd, self)
	end
	
	def dmd
		def compile (cmd, file)
			temp = objname(file)
			
			if !@args.quick || isOverdue(file, temp)
				exec(cmd + tmp + " " + file)
			end
			
			addToLib(temp)
		end

		dmd = "dmd -c -I#{@args.root}/tango/core -I#{@args.root} -I#{@args.root}/tango/core/vendor #{@args.flags} -of#{@args.objs}/";
		libs("-c -n -p256\n" + @args.lib)
		
		exclude("tango/core/rt/compiler/dmd/posix")
		exclude("tango/core/rt/compiler/dmd/darwin")
		
		scan(".d") do |file|
			compile(dmd, file)
		end
		
		scan(".c") do |file|
			compile("dmc -c -mn -6 -r -o", file)
		end
		
		addToLib(@args.root + "/tango/core/rt/compiler/dmd/minit.obj") if @args.core
		
		File.open("tango.lsp", "w+") do |file|
			file.puts(@libs.string)
		end		
		
		exec("lib @tango.lsp")
		#exec("cmd /q /c del tango.lsp *.obj")
		exec("cmd /q /c del tango.lsp")
		
		return @count
	end	
end

class Posix < FileFilter
	def initialize (args, os, dmd, ldc, gdc)
		super(args)
		include("tango/sys/darwin") if os == "osx"
		include("tango/sys/#{os}") unless os == "osx"
		FileFilter.register(os, "dmd", :dmd, self)
		FileFilter.register(os, "ldc", :ldc, self)
		FileFilter.register(os, "gdc", :gdc, self)
		
		@gcc = "gcc -c -o #{@args.objs}/"
		@gcc32 = "gcc -c -m32 -o #{@args.objs}/"
		@dmd = dmd
		@ldc = ldc
		@gdc = gdc
		@os = os
	end
	
	def compile (file, cmd)
		temp = objname(file, ".o")
		
		if !@args.quick || isOverdue(file, temp)
			exec2(cmd + temp + " " + file, $Environment, nil)
		end
		
		return temp
	end
	
	def dmd ()		
		exclude("tango/core/rt/compiler/dmd/darwin") unless @os == "darwin"		
		exclude("tango/core/rt/compiler/dmd/windows")
		
		scan(".d") do |file|
			obj = compile(file, @dmd)
			addToLib(obj)
		end
		
		if @args.core
			scan(".c") do |file|
				obj = compile(file, @gcc32)
				addToLib(obj)
			end
			
			scan(".S") do |file|
				obj = compile(file, @gcc32)
				addToLib(obj)
			end
		end
		
		makeLib(true)
				
		return @count		
	end
	
	def ldc ()		
		scan(".d") do |file|
			obj = compile(file, @ldc)
			addToLib(obj)
		end
		
		if @args.core
			scan(".c") do |file|
				obj = compile(file, @gcc)
				addToLib(obj)
			end

			scan(".S") do |file|
				obj = compile(file, @gcc)
				addToLib(obj)
			end
		end
		
		
		makeLib()
		
		return @count
	end	
	
	def gdc ()		
		scan(".d") do |file|
			obj = compile(file, @gdc)
			addToLib(obj)
		end
		
		if @args.core
			scan(".c") do |file|
				obj = compile(file, @gcc)
				addToLib(obj)
			end
			
			scan(".S") do |file|
				obj = compile(file, @gcc)
				addToLib(obj)
			end
		end
		
		makeLib()
		
		return @count
	end	
end

Args = Struct.new(:verbose, :inhibit, :include, :target, :compiler, 
				  :flags, :lib, :os, :core, :root, :filter, :quick,
				  :objs, :dynamic) do
					
	def initialize
		self.verbose = false
		self.inhibit = false
		self.include = false
		self.target = COMPILERS[0]
		self.compiler = RUNTIMES[0]
		self.flags = "-release"
		
		self.lib = "tango" if WINDOWS
		self.lib = "libtango" unless WINDOWS
		
		self.core = true
		self.root = ""
		self.filter = false
		self.quick = false
		self.objs = File.expand_path("objs")
		self.dynamic = false
		
		self.os = ""
		self.os = "osx" if OSX
		self.os = "freebsd" if FREEBSD
		self.os = "linux" if LINUX
		self.os = "haiku" if HAIKU
		self.os = "solaris" if SOLARIS
		self.os = "windows" if WINDOWS
	end	
end

def populate (args, options, help_msg, banner)	
	OptionParser.new do |opts|
		opts.banner = banner
		opts.separator ""
		opts.separator "Options:"
		
		opts.on("-v", "--verbose", "Verbose output.") do |opt|
			options.verbose = true
		end
		
		opts.on("-q", "--quick", "Quick execution") do |opt|
			options.quick = true
		end
		
		opts.on("-i", "--inhibit", "Inhibit execution") do |opt|
			options.inhibit = true
		end
		
		opts.on("-u", "--include", "Include user modules.") do |opt|
			options.include = true
		end
		
		runtime_list = RUNTIMES.join(",")
		
		opts.on("-r", "--runtime RUNTIME", RUNTIMES, "Include a runtime target", "\t(#{runtime_list}).") do |opt|
			options.target = opt
			options.core = true
		end
		
		compiler_list = COMPILERS.join(",")
		
		opts.on("-c", "--compiler COMPILER", COMPILERS, "Specify a compiler to use", "\t(#{compiler_list}).") do |opt|
			options.compiler = opt
		end
		
		opts.on("-d", "--dynamic", "Build Tango as a dynamic/shared library") do |opt|
			if DARWIN
				options.dynamic = true
			else
				die "Building Tango as a dynamic/shared library is currently not supported on this platform."
			end
		end
		
		opts.on("-o", "--options OPTIONS", "Specify D compiler options") do |opt|
			options.flags = opt
		end
		
		opts.on("-l", "--library NAME", "Specify library name (sans .ext)") do |opt|
			options.lib = opt
		end
		
		opts.on(nil, "--objs PATH", "Specify the path where to place temporary object files (defaults to ./objs)") do |opt|
			options.objs = File.expand_path(opt)
		end
		
		filter_list = FILTERS.join(",")
		
		opts.on("-p", "--filter FILTER", FILTERS, "Determines package filtering", "\t(#{filter_list}).") do |opt|
			options.os = opt
			options.filter = true
		end
		
		opts.on("-h", "--help", "Show this message and exit.") do
			puts opts, help_msg
			exit
		end
		
		opts.on(nil, '--version', 'Show version and exit.') do
			puts "bob.rb version " + FileFilter::VERSION.to_s
			exit
		end
		
		opts.separator ""
		
		if args.empty?
			die opts.banner
		else
			opts.parse!(args)

			die "No path to Tango given" if args.empty?
			
			unless OSX || FREEBSD || LINUX || HAIKU || SOLARIS || WINDOWS
				die "No package filter given" unless options.filter
			end
			
			if options.dynamic
				if DARWIN
					options.lib += ".dylib"
				elsif WINDOWS
					options.lib += ".dll"
				else
					options.lib += ".so"
				end
			else
				options.lib += ".lib" if WINDOWS
				options.lib += ".a" unless WINDOWS
			end
			
			options.root = File.expand_path(args[0])
		end
	end
end

def die (*msg)
	$stderr.puts msg
	exit 1
end

if __FILE__ == $0
	main(ARGV)
	$Environment = ENV.dup
end