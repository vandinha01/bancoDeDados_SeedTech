-- #################################################
-- SCRIPT DE CRIAÇÃO DE PROCEDURES E FUNÇÕES
-- #################################################

USE seed_tech;

-- Define o delimitador para permitir o uso de ';' dentro dos blocos CREATE PROCEDURE/FUNCTION
DELIMITER $$

-- =====================================================================
-- FUNÇÕES (6 Funções Escalares)
-- =====================================================================

-- 1. FUNÇÃO: Obter_Ultima_Temperatura (Escalar)
-- Retorna a última temperatura registrada para um sensor DHT22 específico.
CREATE FUNCTION Obter_Ultima_Temperatura(p_dht22_sensor_id INT)
RETURNS DECIMAL(5, 2)
READS SQL DATA
BEGIN
    DECLARE ultima_temp DECIMAL(5, 2);
    
    SELECT temperatura INTO ultima_temp
    FROM dht22_dados
    WHERE dht22_sensor_id = p_dht22_sensor_id
    ORDER BY timestamp DESC
    LIMIT 1;
    
    RETURN ultima_temp;
END $$

-- 2. FUNÇÃO: Obter_Media_Umidade_Armazem (Escalar)
-- Retorna a umidade média das últimas 24 horas para todos os sensores DHT22 de um armazém.
CREATE FUNCTION Obter_Media_Umidade_Armazem(p_armazem_id INT)
RETURNS DECIMAL(5, 2)
READS SQL DATA
BEGIN
    DECLARE media_umidade DECIMAL(5, 2);
    
    SELECT AVG(D.umidade) INTO media_umidade
    FROM dht22_dados D
    JOIN dht22_sensores S ON D.dht22_sensor_id = S.id
    JOIN esp32_dispositivos E ON S.esp32_dispositivo_id = E.id
    WHERE E.armazem_id = p_armazem_id
      AND D.timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR);
      
    RETURN IFNULL(media_umidade, 0.00);
END $$

-- 3. FUNÇÃO: Contar_Sensores_Ativos_Armazem (Escalar)
-- Retorna o número de sensores ativos em um determinado armazém.
CREATE FUNCTION Contar_Sensores_Ativos_Armazem(p_armazem_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE total_ativos INT;
    
    SELECT COUNT(*) INTO total_ativos
    FROM esp32_dispositivos
    WHERE armazem_id = p_armazem_id
      AND status = 'ativo';
      
    RETURN total_ativos;
END $$

-- 4. FUNÇÃO: Obter_Nivel_Luz_Medio_Ultima_Hora (Escalar)
-- Retorna a luminosidade média registrada na última hora para um sensor LDR.
CREATE FUNCTION Obter_Nivel_Luz_Medio_Ultima_Hora(p_ldr_sensor_id INT)
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE media_lux DECIMAL(10, 2);
    
    SELECT AVG(luminosidade) INTO media_lux
    FROM ldr_dados
    WHERE ldr_sensor_id = p_ldr_sensor_id
      AND timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR);
      
    RETURN IFNULL(media_lux, 0.00);
END $$

-- 5. FUNÇÃO: Calcular_Taxa_Impacto_Armazem (Escalar)
-- Retorna a porcentagem de leituras que indicaram impacto nas últimas 48 horas em um armazém.
CREATE FUNCTION Calcular_Taxa_Impacto_Armazem(p_armazem_id INT)
RETURNS DECIMAL(5, 2)
READS SQL DATA
BEGIN
    DECLARE total_leituras INT;
    DECLARE total_impactos INT;
    DECLARE taxa_impacto DECIMAL(5, 2);

    SELECT COUNT(*) INTO total_leituras
    FROM ultrassonico_dados D
    JOIN ultrassonico_sensores S ON D.ultrassonico_sensor_id = S.id
    JOIN esp32_dispositivos E ON S.esp32_dispositivo_id = E.id
    WHERE E.armazem_id = p_armazem_id
      AND D.timestamp >= DATE_SUB(NOW(), INTERVAL 48 HOUR);

    SELECT COUNT(*) INTO total_impactos
    FROM ultrassonico_dados D
    JOIN ultrassonico_sensores S ON D.ultrassonico_sensor_id = S.id
    JOIN esp32_dispositivos E ON S.esp32_dispositivo_id = E.id
    WHERE E.armazem_id = p_armazem_id
      AND D.timestamp >= DATE_SUB(NOW(), INTERVAL 48 HOUR)
      AND D.impacto = TRUE;

    IF total_leituras > 0 THEN
        SET taxa_impacto = (total_impactos / total_leituras) * 100;
    ELSE
        SET taxa_impacto = 0.00;
    END IF;
    
    RETURN taxa_impacto;
END $$

-- 6. FUNÇÃO: Obter_Distancia_Minima_Recente (Escalar)
-- Retorna a menor distância registrada (indicando maior proximidade/nível) nas últimas 6 horas para um sensor ultrassônico.
CREATE FUNCTION Obter_Distancia_Minima_Recente(p_ultrassonico_sensor_id INT)
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE dist_min DECIMAL(10, 2);
    
    SELECT MIN(distancia) INTO dist_min
    FROM ultrassonico_dados
    WHERE ultrassonico_sensor_id = p_ultrassonico_sensor_id
      AND timestamp >= DATE_SUB(NOW(), INTERVAL 6 HOUR);
      
    RETURN IFNULL(dist_min, 9999.99); -- Retorna um valor alto se não houver dados
END $$

-- =====================================================================
-- PROCEDURES (8 Procedures, Total de 14 Objetos)
-- =====================================================================

-- 7. PROCEDURE: SP_Listar_Dados_DHT22_Armazem (Tabela)
-- Retorna os últimos 100 registros de temperatura/umidade de um armazém.
-- (Substitui a função TABLE anterior que causava erro)
CREATE PROCEDURE SP_Listar_Dados_DHT22_Armazem (
    IN p_armazem_id INT
)
BEGIN
    SELECT 
        D.id AS registro_id,
        D.temperatura,
        D.umidade,
        D.timestamp AS timestamp_leitura,
        S.localizacao_detalhada AS sensor_detalhe
    FROM dht22_dados D
    JOIN dht22_sensores S ON D.dht22_sensor_id = S.id
    JOIN esp32_dispositivos E ON S.esp32_dispositivo_id = E.id
    WHERE E.armazem_id = p_armazem_id
    ORDER BY D.timestamp DESC
    LIMIT 100;
END $$


-- 8. PROCEDURE: SP_Inserir_Leitura_DHT22 (INSERT)
-- Procedure principal para a API inserir dados de Temperatura e Umidade.
CREATE PROCEDURE SP_Inserir_Leitura_DHT22 (
    IN p_dht22_sensor_id INT,
    IN p_temperatura DECIMAL(5, 2),
    IN p_umidade DECIMAL(5, 2)
)
BEGIN
    INSERT INTO dht22_dados (dht22_sensor_id, temperatura, umidade)
    VALUES (p_dht22_sensor_id, p_temperatura, p_umidade);
END $$

-- 9. PROCEDURE: SP_Inserir_Leitura_LDR (INSERT)
-- Procedure principal para a API inserir dados de Luminosidade.
CREATE PROCEDURE SP_Inserir_Leitura_LDR (
    IN p_ldr_sensor_id INT,
    IN p_luminosidade DECIMAL(10, 2)
)
BEGIN
    INSERT INTO ldr_dados (ldr_sensor_id, luminosidade)
    VALUES (p_ldr_sensor_id, p_luminosidade);
END $$

-- 10. PROCEDURE: SP_Inserir_Leitura_Ultrassonico (INSERT)
-- Procedure principal para a API inserir dados de Distância/Impacto.
CREATE PROCEDURE SP_Inserir_Leitura_Ultrassonico (
    IN p_ultrassonico_sensor_id INT,
    IN p_distancia DECIMAL(10, 2)
)
BEGIN
    -- Lógica simples: Se a distância for muito curta (ex: < 10 cm), marca como impacto
    DECLARE v_impacto BOOLEAN;
    SET v_impacto = IF(p_distancia <= 10.00, TRUE, FALSE);

    INSERT INTO ultrassonico_dados (ultrassonico_sensor_id, distancia, impacto)
    VALUES (p_ultrassonico_sensor_id, p_distancia, v_impacto);
END $$

-- 11. PROCEDURE: SP_Atualizar_Status_Dispositivo (UPDATE)
-- Atualiza o status do dispositivo (ex: de 'ativo' para 'manutencao').
CREATE PROCEDURE SP_Atualizar_Status_Dispositivo (
    IN p_dispositivo_id INT,
    IN p_novo_status VARCHAR(50)
)
BEGIN
    UPDATE esp32_dispositivos
    SET status = p_novo_status
    WHERE id = p_dispositivo_id;
END $$

-- 12. PROCEDURE: SP_Remover_Armazem (DELETE)
-- Remove um armazém e seus dispositivos/sensores associados.
CREATE PROCEDURE SP_Remover_Armazem (
    IN p_armazem_id INT
)
BEGIN
    -- Nota: As FKs em cascata garantem a remoção dos registros filhos. 
    -- Se não houver ON DELETE CASCADE, esta SP precisará remover manualmente:
    -- DELETE FROM dht22_dados ...; DELETE FROM ldr_dados ...; etc.
    DELETE FROM armazens
    WHERE id = p_armazem_id;
END $$

-- 13. PROCEDURE: SP_Obter_Ultimas_10_Leituras_Dispositivo (SELECT)
-- Retorna as 10 últimas leituras de todos os tipos para um dispositivo específico.
CREATE PROCEDURE SP_Obter_Ultimas_10_Leituras_Dispositivo (
    IN p_dispositivo_id INT
)
BEGIN
    -- Tabela de dados DHT22
    SELECT 'DHT22' AS Tipo, D.timestamp, D.temperatura, D.umidade
    FROM dht22_dados D
    JOIN dht22_sensores S ON D.dht22_sensor_id = S.id
    WHERE S.esp32_dispositivo_id = p_dispositivo_id
    ORDER BY D.timestamp DESC
    LIMIT 10;
    
    -- Tabela de dados LDR
    SELECT 'LDR' AS Tipo, D.timestamp, D.luminosidade
    FROM ldr_dados D
    JOIN ldr_sensores S ON D.ldr_sensor_id = S.id
    WHERE S.esp32_dispositivo_id = p_dispositivo_id
    ORDER BY D.timestamp DESC
    LIMIT 10;

    -- Tabela de dados Ultrassônico
    SELECT 'Ultrassonico' AS Tipo, D.timestamp, D.distancia, D.impacto
    FROM ultrassonico_dados D
    JOIN ultrassonico_sensores S ON D.ultrassonico_sensor_id = S.id
    WHERE S.esp32_dispositivo_id = p_dispositivo_id
    ORDER BY D.timestamp DESC
    LIMIT 10;
END $$

-- 14. PROCEDURE: SP_Registrar_Novo_Sensor_LDR (INSERT)
-- Cria um novo sensor LDR e o associa a um dispositivo ESP32 existente.
CREATE PROCEDURE SP_Registrar_Novo_Sensor_LDR (
    IN p_esp32_dispositivo_id INT,
    IN p_localizacao_detalhada VARCHAR(255)
)
BEGIN
    INSERT INTO ldr_sensores (esp32_dispositivo_id, localizacao_detalhada)
    VALUES (p_esp32_dispositivo_id, p_localizacao_detalhada);
END $$

-- Restaura o delimitador padrão
DELIMITER ;