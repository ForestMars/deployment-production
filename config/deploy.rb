puts "You must provide the app name and type as environment variables when running this script" if ENV['LOCATION'].nil? or ENV['TYPE'].nil?
puts "You must choose to deploy either the syn or agg" if ENV['TYPE'] != "agg" or ENV['TYPE'] != "syn"

set :application, "#{ENV['LOCATION']}_#{ENV['TYPE']}"
if ENV['TYPE'] == "syn"
  set :repository,  "https://github.com/Localvox/LocalVox.git"
elsif ENV['TYPE'] == "agg"
  set :repository, "https://github.com/Localvox/LocalVox---Aggregator.git"
end

set :scm, :git
set :user, File.exists?(".CAPUSER") ? File.open(".CAPUSER").read.chomp() : "ubuntu"
set :deploy_to, "/var/www/#{ENV['LOCATION']}/#{ENV['TYPE']}"
set :gfs_location, "/mnt/gfs"
ssh_options[:forward_agent] = true


role :web, "www1.site.com"
role :web, "www2.site.com"

after "deploy", "deploy:symlink_files_dir"
after "deploy", "deploy:cut_tag"

namespace :deploy do
  task :symlink_files_dir do
    run("ln -s #{gfs_location} #{deploy_to}/current/sites/default/files")
  end

  task :finalize_update do
  end

  task :restart do
  end

  task :cut_tag do
    time = Time.now.strftime('%y-%m-%d_%H%M')
    system("rm -rf repo") if File.exist?("repo")
    system("git clone #{repository} repo && cd repo && git tag deploy_#{time}_#{ENV['APPLICATION']}_#{ENV['TYPE']} && git push --tags")
  end
end

namespace :gluster do
  task :setup do
    created_location = "#{gfs_location}/#{ENV['LOCATION']}/#{ENV['TYPE']}"
    run("sudo mkdir -p #{created_location}/files")
    run("sudo touch #{created_location}/settings.php.inc")
    puts "The files directory and include settings file has been created at #{created_location}."
  end
end
