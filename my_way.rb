require 'sinatra'

load './app/services/crebit_service.rb'

before do
  content_type :json
end

post '/clientes/:id/transacoes' do
  body = JSON.parse(request.body.read)

  customer_id = params[:id]&.to_i
  valor = body["valor"]&.to_i
  tipo = body["tipo"]
  descricao = body["descricao"]

  service = CrebitService.new
  response.body = service.create_transaction(customer_id, valor, tipo, descricao).to_json
  response.status = 200
rescue CrebitService::NotFound
  response.status = 404
rescue CrebitService::LimitError, CrebitService::InvalidDataSupplied
  response.status = 422
end

get '/clientes/:id/extrato' do
  customer_id = params[:id]&.to_i

  service = CrebitService.new

  response.body = service.extract(customer_id).to_json
  response.status = 200
rescue CrebitService::NotFound
  response.status = 404
end