require "yaml"
require "erb"

TARGETS = {
	codex: {
		template: ERB.new(File.read(File.join(__dir__, "codex.template"))),
		target: [File.expand_path("~/.codex/agents"), "toml"],
	},
	claude: {
		template: ERB.new(File.read(File.join(__dir__, "claude.template"))),
		target: [File.expand_path("~/.claude"), "md"],
	}
}

def config
	@config ||= Dir.glob(File.join(__dir__, "*.yaml")).to_h do |file|
		key = File.basename(file, ".yaml")
		yaml = YAML.load_file(file)
		values = {}
		overrides = {}
		yaml.each do |key, value|
			if key.start_with?(".")
				overrides[key] = value
			else
				values[key] = value
			end
		end
		[key, { values: values, overrides: overrides }]
	end
end

command = ARGV.shift
case command
when "apply"
	config.each do |persona, conf|
		TARGETS.each do |tkey, tconf|
			v = conf[:values].merge(conf[:overrides][".#{tkey}"] || {})
			rendered = tconf[:template].result_with_hash(v)
			agent_file = File.join(tconf[:target][0], "#{persona}.#{tconf[:target][1]}")
			puts "#{persona} -> #{agent_file}"
			File.write(agent_file, rendered)
		end
	end
when "list"
	puts "key\tmodel\teffort"
	config.each do |key, conf|
		TARGETS.keys.map do |target|
			conf[:values].merge(conf[:overrides][".#{target}"] || {}).values_at("model", "effort")
		end.uniq.each do |model, effort|
			puts [key, model, effort].join("\t")
			key = nil
		end
	end
else
    puts "Usage: #{$0} [apply|list]"
end
