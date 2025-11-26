USE seed_tech;

-- 1. View para identificar Armazéns Grandes (Capacidade >= 500k)
SELECT * FROM vw_grandes_armazens;
CREATE VIEW vw_grandes_armazens as
SELECT Nome, capacidade_kg
FROM armazens
WHERE capacidade_kg >= 500000;

-- 2. View para localizar Dispositivos Ativos
SELECT * FROM vw_dispositivos_ativos_local;
CREATE VIEW vw_dispositivos_ativos_local as
SELECT 
	esp32_dispositivos.nome as NomeDispositivo,
	armazens.nome as NomeArmazem
FROM esp32_dispositivos
JOIN armazens on esp32_dispositivos.armazem_id = armazens.id
WHERE esp32_dispositivos.status = 'ativo';

-- 3. View para Alerta de Temperatura (Acima de 27°C)
SELECT * FROM vw_alerta_temperatura;
CREATE VIEW vw_alerta_temperatura as
SELECT dht22_sensores.localizacao_detalhada, dht22_dados.temperatura
FROM dht22_dados
JOIN dht22_sensores on dht22_dados.dht22_sensor_id = dht22_sensores.id
WHERE dht22_dados.temperatura >= 27;

-- 4. View para Histórico de Impactos (Ultrassônico)
SELECT * FROM vw_historico_impactos;
CREATE VIEW vw_historico_impactos as
SELECT ultrassonico_sensores.localizacao_detalhada, ultrassonico_dados.timestamp
FROM ultrassonico_sensores
JOIN ultrassonico_dados on ultrassonico_dados.ultrassonico_sensor_id = ultrassonico_sensores.id
WHERE ultrassonico_dados.impacto = 1;

-- 5. View para Locais Escuros (Luminosidade < 100)
SELECT * FROM vw_locais_escuros;
CREATE VIEW vw_locais_escuros as
SELECT ldr_sensores.localizacao_detalhada, ldr_dados.luminosidade
FROM ldr_sensores
JOIN ldr_dados on ldr_dados.ldr_sensor_id = ldr_sensores.id
WHERE ldr_dados.luminosidade < 100;

-- 6. Qual é a quantidade total de dispositivos esp32 cadastrados no sistema?
SELECT * FROM total_disp;
CREATE VIEW total_disp as
SELECT COUNT(esp.id) "Dispositivo"
FROM esp32_dispositivos esp;

-- 7. Quantos dispositivos ESP32 existem por armazém? 
SELECT * FROM disp_total_armazem;
CREATE VIEW disp_total_armazem as
SELECT arm.nome "Armazen",
arm.localizacao "Localização",
CONCAT(arm.capacidade_kg, ' kg') "Capacidade",
COUNT(esp.id) "Dispositivo"
FROM armazens arm
INNER JOIN esp32_dispositivos esp on arm.id = esp.armazem_id
GROUP BY arm.nome, arm.localizacao, arm.capacidade_kg
ORDER BY COUNT(esp.id) DESC;

-- 8. Liste todos os armazéns com seus dispositivos ESP32 e o sensor DHTT22, incluindo armazéns que não possuem dispositivos ou sensores.
SELECT * FROM armazens_total;
CREATE VIEW armazens_total as
SELECT arm.nome "Armazem",
arm.localizacao "Localização",
esp.nome "Dispositivo",
UPPER(esp.status) "Status do Dispositivo",
dhts.id "DHTT22"
FROM armazens arm
LEFT JOIN esp32_dispositivos esp on arm.id = esp.armazem_id
LEFT JOIN dht22_sensores dhts on esp.id = dhts.esp32_dispositivo_id
GROUP BY arm.nome, arm.localizacao, esp.nome, esp.status, dhts.id;

-- 9. Verificar se tem algum dispositivo que não esta conectado a nenhum sensor.
SELECT * FROM disp_desconectado;
CREATE VIEW disp_desconectado as
SELECT esp.nome "Dispositivo",
UPPER(esp.status) "Status do Dispositivo",
dhts.id "DHTT22",
CONCAT('LDR ', ldrs.id) "LDR",
ult.id "Ultrassonico"
FROM esp32_dispositivos esp
LEFT JOIN dht22_sensores dhts on esp.id = dhts.esp32_dispositivo_id
LEFT JOIN ldr_sensores ldrs on esp.id = ldrs.esp32_dispositivo_id
LEFT JOIN ultrassonico_sensores ult on esp.id = ult.esp32_dispositivo_id
WHERE dhts.id and ldrs.id and ult.id IS NULL
GROUP BY esp.nome, UPPER(esp.status), dhts.id, ldrs.id, ult.id;


-- 10. Liste todos os dispositivos cadastrados, mostrando também a última leitura registrada para cada sensor. 
SELECT * FROM vw_leituras_ldr ORDER BY Dispositivo;
CREATE OR REPLACE VIEW vw_leituras_ldr as
SELECT 
esp.nome as "Dispositivo",
UPPER(esp.status) "Status do Dispositivo",
CONCAT('LDR ', ldrs.id) "Sensor LDR",
CONCAT(MAX(ldrd.luminosidade), ' lx') "Luminosidade_Max",
MAX(ldrd.timestamp) "Momento do Registro LDR"
FROM esp32_dispositivos esp 
INNER JOIN ldr_sensores ldrs on esp.id = ldrs.esp32_dispositivo_id  
INNER JOIN ldr_dados ldrd on ldrs.id = ldrd.ldr_sensor_id           
GROUP BY esp.nome, esp.status, ldrs.id;