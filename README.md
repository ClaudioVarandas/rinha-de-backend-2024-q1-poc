# Rinha de Backend - 2024/Q1

### Introdução

Este é o meu projecto de implementação, para a participação da rinha de backend 2024Q1. 

Após assistir aos mais diversos conteudos criados para a primeira rinha do lado de fora, 
desta vez resolvi meter mão a obra e fazer qq coisa, tentar pelo menos participar.

Sendo eu um programador web PHP / Js de profissão , queria sair fora da caixa e aproveitar 
a oportunidade para aprender uma nova tecnologia, pensei em RUST (ando ao tempo para experimentar),
mas depois ao passar os olhos pelas participações vi a do [dowingows](https://github.com/zanfranceschi/rinha-de-backend-2024-q1/tree/main/participantes/dowingows-phalcon-php) 
(peço desculpa se n é esse o nome), e tem uma participação com phalconPHP que eu usei na primeiras versões, 
sei lá tem prai mais de 15 anos não faço ideia. 

Então como vou enfrentar varios desafios , resolvi alocar o pouco tempo aos desafios da rinha e menos tempo a linguagem
e optei por PhalconPHP, para quem não sabe é uma framework PHP escrita em c , ou seja funciona como uma extensão c e é 
integrada no PHP com o objectivo de melhorar a performance.

### Stack tecnologico

- Nginx - como load balancer 
- Postgres - para base de dados
- Phalcon PHP - Framework PHP para a API
- PHP- Linguagem da API


### Como correr o projecto

É necesario docker e docker compose instalado.

Subir o stack

`docker compose up -d --build`

Destruir o stack

`docker compose down -v`

#### Notas

Build e run php image

```bash
#build image
docker build --tag cvarandas/rinha-2024q1-phalcon-php:1.0 .
#run the image
docker run --rm -p 8088:80 cvarandas/rinha-2024q1-phalcon-php:1.0 sh -c "echo '<?php phpinfo();' > index.php; php -S [::]:80 -t ."
```
  
### Autor

Cláudio Varandas de Portugal , Lisboa.

#### Creditos 

Inspiração para configurações docker / imagem php :

https://github.com/zanfranceschi/rinha-de-backend-2024-q1-poc

https://github.com/Dowingows/rinha-backend-2024-q1-phalcon-php/blob/main/Dockerfile

https://github.com/joseluisq/alpine-php-fpm/tree/master

