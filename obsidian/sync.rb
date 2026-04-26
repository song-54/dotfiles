require 'json'
require 'fileutils'

def detect_os	
	case RUBY_PLATFORM
	when /mswin|mingw/
		# administrator check: for symlink
		# unless system('net session >nul 2>&1')
		# 	require 'win32ole'
		# 	shell = WIN32OLE.new('Shell.Application')
		# 	shell.ShellExecute('ruby.exe', __FILE__, '', 'runas', 1)
		# 	exit
		# end
		:windows
	when /darwin/
		:macos
	else
		raise "Unsupported OS: #{RUBY_PLATFORM}"
	end
end

def get_obsidian_vaults
	case $os
	when :windows
		path = File.join(ENV['APPDATA'], 'obsidian', 'obsidian.json')
	when :macos
		path = File.expand_path("~/Library/Application Support/obsidian/obsidian.json")
	end
	file = File.read(path)
	json = JSON.parse(file)
	json["vaults"].map {|_, v| v["path"] }
end

def get_sync_configs
	Dir.glob("**/*", base: __dir__)
		.select {|f| File.file?(File.join(__dir__, f)) and f != __FILE__ }
end

$os = detect_os
vaults = get_obsidian_vaults
configs = get_sync_configs

begin
	vaults.each do |vault|
		puts "[install] #{vault}"
		configs.each do |config|
			puts "- #{config}"
			dst = File.join(vault, ".obsidian", config)
			dir = File.dirname(dst)
			FileUtils.mkdir_p(dir) unless File.exist?(dir)
			FileUtils.install(config, dst)
		end
	end
rescue => e
	puts e.full_message
end

# STDIN.gets if $os == :windows
