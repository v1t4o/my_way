require 'pg'
require 'connection_pool'

class DatabaseConector
  POOL_SIZE = ENV['DB_POOL_SIZE'] || 5

  def self.connections
    @connections ||= ConnectionPool.new(size: POOL_SIZE, timeout: 300) do
      PG.connect(configuration)
    end
  end

  def self.configuration
    {
      host: 'postgres',
      dbname: 'postgres',
      user: 'frank',
      password: 'sinatra'
    }
  end
end