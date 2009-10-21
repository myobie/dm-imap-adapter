# Run me with:
#
#   $ watchr spec/watchr.rb

# --------------------------------------------------
# Convenience Methods
# --------------------------------------------------
def all_test_files
  Dir['spec/**/*_spec.rb']
end

def run(cmd)
  puts(cmd)
  system(cmd)
end

def run_all_tests
  cmd = "bacon '%w( #{all_test_files.join(' ')} ).each {|file| require file }'"
  run(cmd)
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------
watch( '^spec.*/.*_spec\.rb'   )   { |m| run( "bacon %s"                     % m[0] ) }
watch( '^lib/(.*)\.rb'         )   { |m| run( "bacon spec/%s_spec.rb" % m[1] ) }
watch( '^spec/spec_helper\.rb' )   { run_all_tests }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }