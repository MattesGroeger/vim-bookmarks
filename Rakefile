require 'rake/packagetask'

task :default => [:release]

desc "Create release archive"
task :release do
  tag = request_user_input("Which tag (0.1.0)?")
  `mkdir -p release`
  `zip -r release/vim-bookmarks-#{tag}.zip . -i "doc/*" -i "plugin/*" -i LICENSE.txt`
  if request_user_input("Create git tag and commit? (y/n)") == 'y'
    `git add .`
    `git commit -m "Release build #{tag}"`
    `git push --tags origin master`
  end
end

def request_user_input(message, fallback = "")
  STDOUT.puts message
  input = STDIN.gets.strip.to_s
  if input.empty?
    if fallback.empty?
      request_user_input(message) # try again
    else
      fallback.to_s
    end
  else
    input.to_s
  end
end
