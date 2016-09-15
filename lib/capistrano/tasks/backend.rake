namespace :backend do
  desc 'Restart the backend'
  task :restart do
    on roles(:backend) do
      execute "/usr/bin/sudo /usr/sbin/service shadowcraft-engine-all restart"
    end
  end

  desc 'Update the backend from git'
  task :update do
    on roles(:backend) do
      within fetch(:engine_path) do
        execute :git, "pull"
      end
    end
  end
end

namespace :nginx do
  desc "Restart nginx"
  task :restart do
    on roles(:web) do
      execute :sudo, "/usr/sbin/service", "nginx", "restart"
    end
  end
end

after "backend:update", "backend:restart"