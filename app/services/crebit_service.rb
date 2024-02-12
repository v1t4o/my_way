load './app/database_conector.rb'
require 'pry'
class CrebitService
  class NotFound < StandardError; end
  class InvalidDataSupplied < StandardError; end
  class LimitError < StandardError; end

  def extract(customer_id)
    result = {}

    db.transaction do |conn|
      query = <<~SQL
        SELECT limite, saldo
        FROM customers
        WHERE id = $1
      SQL

      query_result = conn.exec_params(query, [customer_id]).first

      raise NotFound unless query_result

      result["saldo"] = {
        "total": query_result["saldo"].to_i,
        "data_extrato": DateTime.now.to_s,
        "limite": query_result["limite"].to_i
      }

      query = <<~SQL
        SELECT valor, tipo, descricao, realizada_em
        FROM transactions
        WHERE customer_id = $1
        ORDER BY realizada_em DESC
        LIMIT 10
      SQL

      query_result = conn.exec_params(query, [customer_id])

      result["ultimas_transacoes"] = query_result.to_a
    end

    result
  end

  def create_transaction(customer_id, valor, tipo, descricao)
    params = [customer_id, tipo, descricao]
    raise InvalidDataSupplied if params.select{|i| i&.empty?} && valor.nil?

    query = <<~SQL
      SELECT limite, saldo
      FROM customers
      WHERE id = $1
    SQL

    query_result = db.exec_params(query, [customer_id]).first

    raise NotFound unless query_result

    query = <<~SQL
      INSERT INTO transactions (customer_id, valor, tipo, descricao)
      VALUES ($1, $2, $3, $4)
    SQL

    verify_limit(query_result['saldo'], query_result['limite'], valor, tipo)

    db.exec_params(query, [customer_id, valor, tipo, descricao])

    raise InvalidDataSupplied unless ["d", "c"].include?(tipo)

    case tipo
    in 'd'
      query = <<~SQL
        UPDATE customers
        SET saldo = saldo - $2
        WHERE id = $1
      SQL
    in 'c'
      query = <<~SQL
        UPDATE customers
        SET saldo = saldo + $2
        WHERE id = $1
      SQL
    end

    db.exec_params(query, [customer_id, valor]).first

    query = <<~SQL
      SELECT limite, saldo
      FROM customers
      WHERE id = $1
    SQL

    query_result = db.exec_params(query, [customer_id]).first
  end

  private

  def db
    DatabaseConector.connections.checkout
  end

  def verify_limit(saldo, limite, valor, tipo)
    if tipo == 'd' && (saldo.to_i - valor.to_i) > limite.to_i
      raise LimitError 
    end
  end
end