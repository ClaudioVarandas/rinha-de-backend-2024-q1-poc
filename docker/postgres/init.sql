CREATE TABLE IF NOT EXISTS clientes (
	id SERIAL PRIMARY KEY,
	nome VARCHAR(50) NOT NULL,
	limite INTEGER NOT NULL,
    saldo INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS transacoes (
	id SERIAL PRIMARY KEY,
	cliente_id INTEGER NOT NULL,
	valor INTEGER NOT NULL,
	tipo CHAR(1) NOT NULL,
	descricao VARCHAR(10) NOT NULL,
	realizada_em TIMESTAMPTZ DEFAULT NOW(),
	CONSTRAINT fk_clientes_transacoes_id
		FOREIGN KEY (cliente_id) REFERENCES clientes(id)
);

DO $$
BEGIN
    INSERT INTO clientes (id, nome, limite, saldo)
    VALUES
        (1 ,'o barato sai caro', 1000 * 100, 0),
        (2 ,'zan corp ltda', 800 * 100, 0),
        (3 ,'les cruders', 10000 * 100, 0),
        (4 ,'padaria joia de cocaia', 100000 * 100, 0),
        (5 ,'kid mais', 5000 * 100, 0);
END;
$$;