# config valid only for current version of Capistrano
lock '3.4.1'

set :application, 'shadowcraft'
set :repo_url, 'https://github.com/cheald/shadowcraft-ui'
set :deploy_to, '/home/web/shadowcraft'
set :linked_files, fetch(:linked_files, []).push('config/auth_key.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
set :log_level, :info

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, 'master'

# namespace :deploy do
#   after :restart, :clear_cache do
#     on roles(:web), in: :groups, limit: 3, wait: 10 do
#       within release_path do
#         execute :touch, 'tmp/restart.txt'
#       end
#     end
#   end
# end
