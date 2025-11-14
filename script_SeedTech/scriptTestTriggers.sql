-- #################################################
-- SCRIPT DE TESTE DE TRIGGERS
-- #################################################

USE seed_tech;

-- Define o delimitador
DELIMITER $$

-- Exclui e recria dados para garantir que os IDs estejam corretos após o teste de SPs
DELETE FROM dht22_dados;
DELETE FROM dht22_sensores;
DELETE FROM ldr_dados;
DELETE FROM ldr_sensores;
DELETE FROM ultrassonico_dados;
DELETE FROM ultrassonico_sensores;
DELETE FROM esp32_dispositivos;
DELETE FROM armazens;
ALTER TABLE armazens AUTO_INCREMENT = 1;
ALTER TABLE esp32_dispositivos AUTO_INCREMENT = 1;

-- Inserção de dados iniciais de referência
INSERT INTO armazens (nome, localizacao, capacidade_kg) VALUES ('Armazem A', 'Local X', 1000.00); -- Armazem ID 1
INSERT INTO esp32_dispositivos (nome, armazem_id, status) VALUES ('MODULO TESTE A1', 1, 'ativo'); -- Dispositivo ID 1
INSERT INTO dht22_sensores (esp32_dispositivo_id, localizacao_detalhada) VALUES (1, 'Posicao Central'); -- DHT22 Sensor ID 1
INSERT INTO ldr_sensores (esp32_dispositivo_id, localizacao_detalhada) VALUES (1, 'LDR Exemplo'); -- LDR Sensor ID 1
INSERT INTO ultrassonico_sensores (esp32_dispositivo_id, localizacao_detalhada) VALUES (1, 'Ultra Exemplo'); -- Ultra Sensor ID 1

SELECT '>>> DADOS INICIAIS RECRIADOS' AS PASSO;

-- Restaura o delimitador padrão (necessário para comandos fora de SPs/Functions/Triggers)
DELIMITER ;

-- =====================================================================
-- TESTE DOS TRIGGERS DE INSERT (1, 2, 3, 4, 5)
-- =====================================================================

-- TESTE 1: TR_Armazem_Before_Insert (Erro esperado: Capacidade Zero)
SELECT '--- TESTE 1: Capacidade Zero (Erro esperado) ---' AS TESTE;
-- Tenta inserir armazém com capacidade <= 0
-- Se o SGBD parar no erro, os testes subsequentes não rodarão.
-- INSERT INTO armazens (nome, localizacao, capacidade_kg) VALUES ('Erro Capacidade', 'Erro Local', 0.00); 

-- TESTE 2: TR_ESP32_Nome_Upper_Insert (Sucesso: Nome Upper)
SELECT '--- TESTE 2: Nome Upper (Sucesso) ---' AS TESTE;
INSERT INTO esp32_dispositivos (nome, armazem_id) VALUES ('nome minusculo', 1); -- ID 2
SELECT nome FROM esp32_dispositivos WHERE id = 2; -- Deve retornar 'NOME MINUSCULO'

-- TESTE 3: TR_DHT22_Validar_Dados_Insert (Erro esperado: Temperatura Inválida)
SELECT '--- TESTE 3: Temperatura Invalida (Erro esperado) ---' AS TESTE;
-- Tenta inserir temperatura alta (acima de 50.00)
-- INSERT INTO dht22_dados (dht22_sensor_id, temperatura, umidade) VALUES (1, 50.01, 50.00); 

-- TESTE 4: TR_LDR_Timestamp_Not_Future (Sucesso: Correção Automática)
SELECT '--- TESTE 4: Timestamp Futuro (Sucesso - Correção) ---' AS TESTE;
-- Define o delimitador para executar o bloco de código
DELIMITER $$
-- Simula um timestamp 10 minutos no futuro
SET @future_time = DATE_ADD(NOW(), INTERVAL 10 MINUTE)$$
INSERT INTO ldr_dados (ldr_sensor_id, luminosidade, timestamp) VALUES (1, 500.00, @future_time)$$
-- Restaura o delimitador
DELIMITER ;
SELECT IF(timestamp <= NOW(), 'CORRIGIDO', 'FALHOU') AS Resultado FROM ldr_dados ORDER BY id DESC LIMIT 1;

-- TESTE 5: TR_Ultrassonico_Set_Impacto (Sucesso: Lógica de Impacto)
SELECT '--- TESTE 5: Impacto (Sucesso - Lógica) ---' AS TESTE;
INSERT INTO ultrassonico_dados (ultrassonico_sensor_id, distancia) VALUES (1, 4.99); -- Distancia <= 5.00
SELECT distancia, impacto FROM ultrassonico_dados ORDER BY id DESC LIMIT 1; -- Deve retornar impacto = 1 (TRUE)


-- =====================================================================
-- TESTE DOS TRIGGERS DE UPDATE (6, 7, 8, 9)
-- =====================================================================

-- TESTE 6: TR_Armazem_Before_Update (Erro esperado: Mudar ID Armazém)
SELECT '--- TESTE 6: Tentativa de Mudar ID Armazém (Erro esperado) ---' AS TESTE;
-- UPDATE armazens SET id = 10 WHERE id = 1; 

-- TESTE 7: TR_DHT22_Validar_Dados_Update (Erro esperado: Umidade Inválida em Update)
SELECT '--- TESTE 7: Umidade Invalida em Update (Erro esperado) ---' AS TESTE;
-- Insere um dado válido primeiro
INSERT INTO dht22_dados (dht22_sensor_id, temperatura, umidade) VALUES (1, 25.00, 50.00); 
-- Tenta atualizar com umidade inválida
-- UPDATE dht22_dados SET umidade = 100.01 WHERE id = (SELECT MAX(id) FROM dht22_dados); 

-- TESTE 8: TR_ESP32_Status_Log_Update (Sucesso: Loga a Mudança)
SELECT '--- TESTE 8: Mudança de Status (Sucesso) ---' AS TESTE;
UPDATE esp32_dispositivos SET status = 'manutencao' WHERE id = 1; -- Log deve ser gerado (internamente no BD)
SELECT id, status FROM esp32_dispositivos WHERE id = 1;

-- TESTE 9: TR_LDR_Prevenir_Alteracao_Timestamp (Erro esperado: Mudar Timestamp LDR)
SELECT '--- TESTE 9: Mudar Timestamp LDR (Erro esperado) ---' AS TESTE;
-- UPDATE ldr_dados SET timestamp = DATE_SUB(NOW(), INTERVAL 1 DAY) WHERE id = (SELECT MAX(id) FROM ldr_dados); 

-- =====================================================================
-- TESTE DOS TRIGGERS DE DELETE (10, 11, 12)
-- =====================================================================

-- TESTE 10: TR_Prevenir_Delete_DHT22_Sensor (Erro esperado: Dados Recentes)
SELECT '--- TESTE 10: Deletar Sensor com Dados Recentes (Erro esperado) ---' AS TESTE;
-- O sensor 1 tem dados recém-inseridos.
-- DELETE FROM dht22_sensores WHERE id = 1;

-- TESTE 11: TR_Limpeza_LDR_Dados (Sucesso: Limpeza em Lote)
SELECT '--- TESTE 11: Deletar um dado e fazer Limpeza (Sucesso) ---' AS TESTE;
-- Adiciona um dado LDR bem antigo para ser limpo (mais de 2 anos)
INSERT INTO ldr_dados (ldr_sensor_id, luminosidade, timestamp) VALUES (1, 100.00, DATE_SUB(NOW(), INTERVAL 2 YEAR));
SELECT COUNT(*) AS Antes_Limpeza FROM ldr_dados; -- Deve ser 2 (1 recente + 1 antigo)
DELETE FROM ldr_dados WHERE id = (SELECT MAX(id) FROM ldr_dados); -- Deleta o dado RECENTE (o trigger roda e remove o antigo)
SELECT COUNT(*) AS Depois_Limpeza FROM ldr_dados; -- Deve ser 0 (o DELETE removeu o recente, o AFTER DELETE removeu o antigo)

-- TESTE 12: TR_Desativar_ESP32_On_Armazem_Delete (Sucesso: Desativação)
SELECT '--- TESTE 12: Desativar ESP32 ao Deletar Armazém (Sucesso) ---' AS TESTE;
-- O ESP32 ID 1 está 'manutencao'. O trigger o mudará para 'desativado'
DELETE FROM armazens WHERE id = 1; 
SELECT id, status FROM esp32_dispositivos; -- O dispositivo 1 deve ter status 'desativado'