namespace :backend do
  desc 'Restart the backend'
  task :restart do
    execute :sudo, "/usr/sbin/service", "shadowcraft-backend-all", "restart"
  end

  desc 'Update the backend from git'
  task :update do
    within fetch(:engine_path) do
      execute :git, "pull"
    end
  end
end

after "backend:update", "backend:restart"