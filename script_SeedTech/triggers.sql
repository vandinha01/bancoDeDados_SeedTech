-- #################################################
-- SCRIPT DE CRIAÇÃO DE TRIGGERS
-- #################################################

USE seed_tech;

-- Define o delimitador
DELIMITER $$

-- =====================================================================
-- TRIGGERS DE INSERÇÃO (5 Triggers)
-- =====================================================================

-- 1. TRIGGER: TR_Armazem_Before_Insert
-- Garante que a capacidade de um armazém seja sempre positiva.
CREATE TRIGGER TR_Armazem_Before_Insert
BEFORE INSERT ON armazens
FOR EACH ROW
BEGIN
    IF NEW.capacidade_kg <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A capacidade do armazém deve ser um valor positivo.';
    END IF;
END $$

-- 2. TRIGGER: TR_ESP32_Nome_Upper_Insert
-- Garante que o nome do dispositivo ESP32 seja armazenado em letras maiúsculas.
CREATE TRIGGER TR_ESP32_Nome_Upper_Insert
BEFORE INSERT ON esp32_dispositivos
FOR EACH ROW
BEGIN
    SET NEW.nome = UPPER(NEW.nome);
END $$

-- 3. TRIGGER: TR_DHT22_Validar_Dados_Insert
-- Valida que a temperatura e umidade estejam dentro de um intervalo razoável (ex: Temp 0-50°C, Umid 0-100%).
CREATE TRIGGER TR_DHT22_Validar_Dados_Insert
BEFORE INSERT ON dht22_dados
FOR EACH ROW
BEGIN
    IF NEW.temperatura < 0.00 OR NEW.temperatura > 50.00 THEN
        SIGNAL SQLSTATE '45001'
        SET MESSAGE_TEXT = 'Temperatura fora do intervalo de 0°C a 50°C.';
    END IF;
    IF NEW.umidade < 0.00 OR NEW.umidade > 100.00 THEN
        SIGNAL SQLSTATE '45002'
        SET MESSAGE_TEXT = 'Umidade fora do intervalo de 0% a 100%.';
    END IF;
END $$

-- 4. TRIGGER: TR_LDR_Timestamp_Not_Future
-- Garante que a leitura não esteja no futuro (erro de relógio do dispositivo).
CREATE TRIGGER TR_LDR_Timestamp_Not_Future
BEFORE INSERT ON ldr_dados
FOR EACH ROW
BEGIN
    IF NEW.timestamp > NOW() THEN
        SET NEW.timestamp = NOW(); -- Corrige o timestamp para o momento atual do BD
    END IF;
END $$

-- 5. TRIGGER: TR_Ultrassonico_Set_Impacto
-- Garante que o campo 'impacto' seja setado corretamente antes de inserir, caso a SP não o faça.
CREATE TRIGGER TR_Ultrassonico_Set_Impacto
BEFORE INSERT ON ultrassonico_dados
FOR EACH ROW
BEGIN
    -- Lógica de impacto: se a distância for muito pequena (ex: 5 cm)
    IF NEW.distancia IS NOT NULL AND NEW.distancia <= 5.00 THEN
        SET NEW.impacto = TRUE;
    ELSE
        SET NEW.impacto = FALSE;
    END IF;
END $$

-- =====================================================================
-- TRIGGERS DE ATUALIZAÇÃO (4 Triggers)
-- =====================================================================

-- 6. TRIGGER: TR_Armazem_Before_Update
-- Previne a atualização do ID do armazém.
CREATE TRIGGER TR_Armazem_Before_Update
BEFORE UPDATE ON armazens
FOR EACH ROW
BEGIN
    IF OLD.id <> NEW.id THEN
        SIGNAL SQLSTATE '45003'
        SET MESSAGE_TEXT = 'Atualização do ID do armazém não é permitida.';
    END IF;
END $$

-- 7. TRIGGER: TR_DHT22_Validar_Dados_Update
-- Valida temperatura e umidade também em operações de UPDATE.
CREATE TRIGGER TR_DHT22_Validar_Dados_Update
BEFORE UPDATE ON dht22_dados
FOR EACH ROW
BEGIN
    IF NEW.temperatura < 0.00 OR NEW.temperatura > 50.00 THEN
        SIGNAL SQLSTATE '45004'
        SET MESSAGE_TEXT = 'Temperatura fora do intervalo de 0°C a 50°C em UPDATE.';
    END IF;
    IF NEW.umidade < 0.00 OR NEW.umidade > 100.00 THEN
        SIGNAL SQLSTATE '45005'
        SET MESSAGE_TEXT = 'Umidade fora do intervalo de 0% a 100% em UPDATE.';
    END IF;
END $$

-- 8. TRIGGER: TR_ESP32_Status_Log_Update
-- Loga (em uma tabela de log que precisaria ser criada) a mudança de status de um dispositivo.
CREATE TRIGGER TR_ESP32_Status_Log_Update
AFTER UPDATE ON esp32_dispositivos
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        -- Exemplo de inserção em uma tabela de log (Log_Status_Dispositivos)
        /* INSERT INTO Log_Status_Dispositivos (dispositivo_id, status_antigo, status_novo, data_mudanca)
        VALUES (OLD.id, OLD.status, NEW.status, NOW()); 
        */
        -- Para este exercício, apenas uma nota:
        -- DO SLEEP(0); -- Operação dummy para simular a ação (MySQL não permite SELECT AFTER TRIGGER)
        DO SLEEP(0); 
    END IF;
END $$

-- 9. TRIGGER: TR_LDR_Prevenir_Alteracao_Timestamp
-- Impede que o timestamp de uma leitura LDR seja alterado após o registro inicial.
CREATE TRIGGER TR_LDR_Prevenir_Alteracao_Timestamp
BEFORE UPDATE ON ldr_dados
FOR EACH ROW
BEGIN
    IF OLD.timestamp <> NEW.timestamp THEN
        SIGNAL SQLSTATE '45006'
        SET MESSAGE_TEXT = 'O timestamp de leitura não pode ser alterado.';
    END IF;
END $$

-- =====================================================================
-- TRIGGERS DE EXCLUSÃO (3 Triggers)
-- =====================================================================

-- 10. TRIGGER: TR_Prevenir_Delete_DHT22_Sensor
-- Previne a exclusão de um sensor DHT22 se ele tiver dados registrados no último mês.
CREATE TRIGGER TR_Prevenir_Delete_DHT22_Sensor
BEFORE DELETE ON dht22_sensores
FOR EACH ROW
BEGIN
    DECLARE tem_dados_recentes INT;
    
    SELECT COUNT(*) INTO tem_dados_recentes
    FROM dht22_dados
    WHERE dht22_sensor_id = OLD.id
      AND timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY);
      
    IF tem_dados_recentes > 0 THEN
        SIGNAL SQLSTATE '45007'
        SET MESSAGE_TEXT = 'Não é possível excluir o sensor DHT22: possui leituras recentes (últimos 30 dias).';
    END IF;
END $$

-- 11. TRIGGER: TR_Limpeza_LDR_Dados
-- Executa a limpeza de dados antigos após a exclusão de um registro LDR (simula um procedimento de manutenção).
CREATE TRIGGER TR_Limpeza_LDR_Dados
AFTER DELETE ON ldr_dados
FOR EACH ROW
BEGIN
    -- Exclui leituras LDR com mais de 1 ano
    DELETE FROM ldr_dados
    WHERE timestamp < DATE_SUB(NOW(), INTERVAL 1 YEAR);
    
    DO SLEEP(0); -- Operação dummy
END $$

-- 12. TRIGGER: TR_Desativar_ESP32_On_Armazem_Delete
-- Garante que, antes de um armazém ser deletado, todos os seus dispositivos ESP32 sejam marcados como 'desativado' (se não houver ON DELETE CASCADE).
CREATE TRIGGER TR_Desativar_ESP32_On_Armazem_Delete
BEFORE DELETE ON armazens
FOR EACH ROW
BEGIN
    UPDATE esp32_dispositivos
    SET status = 'desativado'
    WHERE armazem_id = OLD.id;
END $$

-- Restaura o delimitador padrão
DELIMITER ;