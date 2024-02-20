require_relative '../adapters/database_conector'

class CrebitService
  class NotFound < StandardError; end
  class InvalidDataSupplied < StandardError; end
  class LimitError < StandardError; end

  def extract(customer_id)
    result = {}

    pool.with do |db|
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

        result["ultimas_transacoes"] = query_result.map do |transaction|
          {
            "valor": transaction["valor"].to_i,
            "tipo": transaction["tipo"],
            "descricao": transaction["descricao"],
            "realizada_em": transaction["realizada_em"],
          }
        end
      end
    end

    result
  end

  def create_transaction(customer_id, valor, tipo, descricao)
    result = {}

    raise InvalidDataSupplied unless customer_id && valor && tipo && descricao
    raise InvalidDataSupplied if descricao && descricao.empty? || descricao.length > 10
    raise InvalidDataSupplied if valor && !valor.kind_of?(Integer) || valor.negative?
    raise InvalidDataSupplied unless ["d","c"].include?(tipo)

    pool.with do |db|
      db.transaction do |conn|
        query = <<~SQL
          SELECT limite, saldo
          FROM customers
          WHERE id = $1
          FOR UPDATE
        SQL

        query_result = conn.exec_params(query, [customer_id]).first

        raise NotFound unless query_result

        saldo = query_result['saldo'].to_i
        limite = query_result['limite'].to_i
        valor = valor.to_i

        if tipo == 'd' && verify_limit(saldo, limite, valor)
          raise LimitError
        end

        query = <<~SQL
          INSERT INTO transactions (customer_id, valor, tipo, descricao)
          VALUES ($1, $2, $3, $4)
        SQL

        conn.exec_params(query, [customer_id, valor, tipo, descricao])

        case tipo
        in 'd'
          query = <<~SQL
            UPDATE customers
            SET saldo = saldo - $1
            WHERE id = $2
          SQL
        in 'c'
          query = <<~SQL
            UPDATE customers
            SET saldo = saldo + $1
            WHERE id = $2
          SQL
        end

        conn.exec_params(query, [valor, customer_id])

        query = <<~SQL
          SELECT limite, saldo
          FROM customers
          WHERE id = $1
          FOR UPDATE
        SQL

        query_result = conn.exec_params(query, [customer_id]).first

        result = {
          "limite": query_result["limite"].to_i,
          "saldo": query_result["saldo"].to_i,
        }
      end
    end

    result
  end

  private

  def pool
    DatabaseConector.connections
  end

  def verify_limit(saldo, limite, valor)
    return false if (saldo - valor) > limite
    (saldo - valor).abs > limite
  end
end