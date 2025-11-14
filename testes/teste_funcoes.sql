-- #################################################
-- SCRIPT DE TESTE DE PROCEDURES E FUNÇÕES
-- #################################################

USE seed_tech;

-- Define o delimitador para a procedure
DELIMITER $$

-- =====================================================================
-- INSERÇÃO DE DADOS INICIAIS PARA TESTE
-- =====================================================================

-- Armazéns
INSERT INTO armazens (nome, localizacao, capacidade_kg) VALUES ('Silo Principal A', 'Fazenda 1, Setor Leste', 50000.00); -- ID 1
INSERT INTO armazens (nome, localizacao, capacidade_kg) VALUES ('Silo Secundário B', 'Fazenda 1, Setor Oeste', 25000.00); -- ID 2

-- Dispositivos ESP32
INSERT INTO esp32_dispositivos (nome, armazem_id) VALUES ('Gateway Central A', 1); -- ID 1
INSERT INTO esp32_dispositivos (nome, armazem_id, status) VALUES ('Módulo Umidade B1', 2, 'manutencao'); -- ID 2
INSERT INTO esp32_dispositivos (nome, armazem_id) VALUES ('Monitor Impacto A2', 1); -- ID 3

-- Sensores DHT22
INSERT INTO dht22_sensores (esp32_dispositivo_id, localizacao_detalhada) VALUES (1, 'Superior, Centro'); -- ID 1 (temp/umid)
INSERT INTO dht22_sensores (esp32_dispositivo_id, localizacao_detalhada) VALUES (2, 'Medio, Parede Sul'); -- ID 2 (temp/umid)

-- Sensores LDR
INSERT INTO ldr_sensores (esp32_dispositivo_id, localizacao_detalhada) VALUES (1, 'Base, Janela Principal'); -- ID 1 (ldr)

-- Sensores Ultrassônicos
INSERT INTO ultrassonico_sensores (esp32_dispositivo_id, localizacao_detalhada) VALUES (3, 'Lateral Norte'); -- ID 1 (ultrassonico)

-- =====================================================================
-- TESTE DAS PROCEDURES (INSERT/UPDATE)
-- =====================================================================

-- 1. SP_Inserir_Leitura_DHT22 (ID 8)
CALL SP_Inserir_Leitura_DHT22(1, 25.5, 60.0)$$ -- Leitura 1
CALL SP_Inserir_Leitura_DHT22(1, 26.1, 59.5)$$ -- Leitura 2
CALL SP_Inserir_Leitura_DHT22(2, 28.0, 75.0)$$ -- Leitura 3
SELECT '>>> DHT22 Dados Inseridos' AS Teste_8;
SELECT * FROM dht22_dados ORDER BY id DESC LIMIT 3;

-- 2. SP_Inserir_Leitura_LDR (ID 9)
CALL SP_Inserir_Leitura_LDR(1, 450.75)$$
CALL SP_Inserir_Leitura_LDR(1, 1000.00)$$ -- Mais luz
SELECT '>>> LDR Dados Inseridos' AS Teste_9;
SELECT * FROM ldr_dados ORDER BY id DESC LIMIT 2;

-- 3. SP_Inserir_Leitura_Ultrassonico (ID 10)
CALL SP_Inserir_Leitura_Ultrassonico(1, 50.00)$$ -- Sem impacto
CALL SP_Inserir_Leitura_Ultrassonico(1, 5.50)$$  -- Com impacto (distância < 10)
SELECT '>>> Ultrassonico Dados Inseridos' AS Teste_10;
SELECT * FROM ultrassonico_dados ORDER BY id DESC LIMIT 2;

-- 4. SP_Atualizar_Status_Dispositivo (ID 11)
CALL SP_Atualizar_Status_Dispositivo(2, 'ativo')$$ -- Módulo Umidade B1 volta a ser ativo
SELECT '>>> Status do Dispositivo 2 Atualizado' AS Teste_11;
SELECT id, nome, status FROM esp32_dispositivos WHERE id = 2;

-- 5. SP_Registrar_Novo_Sensor_LDR (ID 14)
CALL SP_Registrar_Novo_Sensor_LDR(3, 'Teto, Monitor Impacto')$$ -- Adiciona um sensor LDR ao dispositivo 3
SELECT '>>> Novo Sensor LDR Registrado' AS Teste_14;
SELECT * FROM ldr_sensores WHERE esp32_dispositivo_id = 3;

-- 6. SP_Obter_Ultimas_10_Leituras_Dispositivo (ID 13)
SELECT '>>> Últimas 10 Leituras do Dispositivo 1' AS Teste_13;
CALL SP_Obter_Ultimas_10_Leituras_Dispositivo(1)$$

-- =====================================================================
-- TESTE DAS FUNÇÕES (SELECT)
-- =====================================================================

-- 7. Obter_Ultima_Temperatura (ID 1)
SELECT '>>> Última Temperatura Sensor DHT22 ID 1:' AS Teste_1, Obter_Ultima_Temperatura(1) AS Ultima_Temp;

-- 8. Obter_Media_Umidade_Armazem (ID 2)
SELECT '>>> Umidade Média Armazém 1 (24h):' AS Teste_2, Obter_Media_Umidade_Armazem(1) AS Media_Umidade;

-- 9. Contar_Sensores_Ativos_Armazem (ID 3)
SELECT '>>> Sensores Ativos Armazém 1:' AS Teste_3, Contar_Sensores_Ativos_Armazem(1) AS Ativos_Armazem_1;
SELECT '>>> Sensores Ativos Armazém 2 (agora é 1):' AS Teste_3_2, Contar_Sensores_Ativos_Armazem(2) AS Ativos_Armazem_2;

-- 10. Obter_Nivel_Luz_Medio_Ultima_Hora (ID 4)
SELECT '>>> Luz Média Última Hora Sensor LDR ID 1:' AS Teste_4, Obter_Nivel_Luz_Medio_Ultima_Hora(1) AS Media_Lux;

-- 11. Calcular_Taxa_Impacto_Armazem (ID 5)
SELECT '>>> Taxa de Impacto Armazém 1 (48h):' AS Teste_5, Calcular_Taxa_Impacto_Armazem(1) AS Taxa_Impacto;

-- 12. Obter_Distancia_Minima_Recente (ID 6)
SELECT '>>> Distância Mínima Recente Ultrassonico 1:' AS Teste_6, Obter_Distancia_Minima_Recente(1) AS Distancia_Min;

-- 13. SP_Listar_Dados_DHT22_Armazem (ID 7 - Procedure)
SELECT '>>> Últimos Dados DHT22 do Armazém 1 (via SP)' AS Teste_7;
CALL SP_Listar_Dados_DHT22_Armazem(1)$$

-- 14. SP_Remover_Armazem (ID 12)
-- ATENÇÃO: Descomente para executar o DELETE:
/*
CALL SP_Remover_Armazem(2)$$ 
SELECT '>>> Armazém 2 Removido' AS Teste_12;
SELECT * FROM armazens;
SELECT * FROM esp32_dispositivos;
*/

-- Restaura o delimitador padrão
DELIMITER ;