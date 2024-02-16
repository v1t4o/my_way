instal.ando:
	@docker-compose run api1 bundle

dev.ando:
	@docker-compose up -d nginx

produz.indo:
	@docker-compose -f docker-compose-prod.yml up -d nginx

estress.ando:
	@sh load-test/run-test.sh

docker.build:
	@docker build -t v1t4o/my_way .

docker.push:
	@docker push v1t4o/my_way