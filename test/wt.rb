require "minitest/autorun"
require "fileutils"
require "open3"
require "tmpdir"

describe "WorktreeTest" do
	before do
		dotfiles_home = File.expand_path("..", __dir__)
		@wt_sh = "#{dotfiles_home}/shrc/wt.sh"
		@work_forest = File.expand_path("~/.worktree")

		@primary = Dir.mktmpdir("wt-test-")
		@worktrees = [
			Dir.mktmpdir("wt-worktree-feature-"), 			# general worktree
			File.join(@work_forest, "#{File.basename(@primary)}-test"), # forest worktree
		]

		# prepare dummy git repository with worktrees
		git "init", "--initial-branch=main"
		git "config", "user.name", "Worktree Test"
		git "config", "user.email", "worktree-test@example.invalid"
		File.write(File.join(@primary, "README.md"), "# worktree test repository\n")
		File.write(File.join(@primary, ".gitignore"), "link.txt\ncopy.txt\n.wtconfig\n")
		File.write(File.join(@primary, ".wtconfig"), "[link]\nlink.txt\n[copy]\ncopy.txt\n")
		File.write(File.join(@primary, "link.txt"), "This is a symlinked file.\n")
		File.write(File.join(@primary, "copy.txt"), "This is a copied file.\n")

		git "add", "README.md", ".gitignore"
		git "commit", "-m", "Initial commit"

		git "worktree", "add", "--detach", @worktrees[0]
		git "worktree", "add", "--detach", @worktrees[1]
	end

	after do
		if @primary && File.exist?(File.join(@primary, ".git"))
			@worktrees&.each do |worktree_dir|
				git "worktree", "remove", "--force", worktree_dir
			end
			FileUtils.remove_entry(@primary)
		end
	end

	# execute worktree function
	def wt(*args, chdir: @primary)
		command = "source #{@wt_sh} && #{args.join(" ")}"
		output, status = Open3.popen2("bash", "-c", command,
			chdir: chdir, err: File::NULL) do |input, output, wait_thread|
			yield input if block_given?
			input.close
			[output.read, wait_thread.value]
		end
		raise "wt command failed:\n#{output}" unless status.success?
		output.chomp
	end

	def git(*args)
		output, status = Open3.capture2e("git", *args, chdir: @primary)
		raise "git #{args.join(" ")} failed:\n#{output}" unless status.success?
		output
	end

	it "knows primary repo and name from any worktree" do
		name = File.basename(@primary)
		dirs = [@primary] + @worktrees
		dirs.each do |dir|
			Dir.chdir(dir) do
				_(wt "wt_primary_dir").must_equal(@primary)
				_(wt "wt_primary_name").must_equal(name)
			end
		end
	end

	it "changes directory to the primary worktree or a named worktree" do
		_(wt("wt cd; pwd")).must_equal(@primary)
		_(wt("wt cd worktree-feature; pwd")).must_equal(@worktrees[0])
		_(wt("wt cd test; pwd")).must_equal(@worktrees[1])
	end

	it "add & delete worktree" do
		branch = "adddel"
		target = File.join(@work_forest, "#{File.basename(@primary)}-#{branch}")

		wt "wt add #{branch}"
		_(File.exist?(target)).must_equal true
		# test symlink and copy files
		_(File.symlink?(File.join(target, "link.txt"))).must_equal true
		_(File.read(File.join(target, "copy.txt"))).must_equal "This is a copied file.\n"

		wt("wt del #{branch}") { |input| input.puts "f" }
		_(File.exist?(target)).must_equal false
	end
end
