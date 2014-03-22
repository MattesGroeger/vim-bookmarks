guard :shell do
  watch(/(autoload|plugin|t)\/.+\.vim$/) do |m|
    cmd = "rake test"
    puts "Executing #{cmd}"
    puts `#{cmd}`
    puts '...done.'
  end
end
