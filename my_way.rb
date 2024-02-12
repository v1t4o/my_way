require 'sinatra'

load './app/services/crebit_service.rb'

before do
  content_type :json
end

post '/clientes/:id/transacoes' do
  body = JSON.parse(request.body.read)

  customer_id = params[:id]
  valor = body["valor"]
  tipo = body["tipo"]
  descricao = body["descricao"]

  service = CrebitService.new
  service.create_transaction(customer_id, valor, tipo, descricao).to_json
rescue CrebitService::LimitError, CrebitService::InvalidDataSupplied
  response.status = 422
end

get '/clientes/:id/extrato' do
  customer_id = params[:id]

  service = CrebitService.new

  response.body = service.extract(customer_id).to_json
  response.status = 200
rescue CrebitService::NotFound
  response.status = 404
end