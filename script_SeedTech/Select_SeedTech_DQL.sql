-- select seed tech 
USE seed_tech;

-- 1.Qual é a quantidade total de dispositivos esp32 cadastrados no sistema?
SELECT COUNT(esp.id) "Dispositivo"
FROM esp32_dispositivos esp;
-- -------------------------------------------------------------------------------------------------------
-- 2.Quantos dispositivos ESP32 existem por armazém? (6)
SELECT arm.nome "Armazen",
arm.localizacao "Localização",
CONCAT(arm.capacidade_kg, ' kg') "Capacidade",
COUNT(esp.nome) "Dispositivo"
FROM armazens arm
INNER JOIN esp32_dispositivos esp on arm.id = esp.armazem_id
GROUP BY arm.nome, arm.localizacao, arm.capacidade_kg, esp.nome
ORDER BY esp.nome DESC;
-- -------------------------------------------------------------------------------------------------------

/*Liste todos os armazéns com seus dispositivos ESP32 e o sensor DHTT22, 
incluindo armazéns que não possuem dispositivos ou sensores.*/
-- 3.
SELECT arm.nome "Armazem",
arm.localizacao "Localização",
esp.nome "Dispositivo",
UPPER(esp.status) "Status do Dispositivo",
dhts.id "DHTT22"
FROM armazens arm
LEFT JOIN esp32_dispositivos esp on arm.id = esp.armazem_id
LEFT JOIN dht22_sensores dhts on esp.id = dhts.esp32_dispositivo_id
GROUP BY arm.nome, arm.localizacao, esp.nome, esp.status, dhts.id;

-- -------------------------------------------------------------------------------------------------------
/*Verificar se tem algum dispositivo que não esta conectado a nenhum sensor.*/
-- 4.
SELECT esp.nome "Dispositivo",
UPPER(esp.status) "Status do Dispositivo",
dhts.id "DHTT22",
concat('LDR ', ldrs.id) "LDR",
ult.id "Ultrassonico"
FROM esp32_dispositivos esp
LEFT JOIN dht22_sensores dhts on esp.id = dhts.esp32_dispositivo_id
LEFT JOIN ldr_sensores ldrs on esp.id = ldrs.esp32_dispositivo_id
LEFT JOIN ultrassonico_sensores ult on esp.id = ult.esp32_dispositivo_id
WHERE dhts.id and ldrs.id and ult.id IS NULL
GROUP BY esp.nome, UPPER(esp.status), dhts.id, ldrs.id, ult.id;

-- -------------------------------------------------------------------------------------------------------
/* Liste todos os dispositivos cadastrados, mostrando também a última leitura registrada para cada sensor. 
3. LDR
4. DHT22
5. Ultrassonico
*/
-- 5.
SELECT esp.nome "Dispositivo",
UPPER(esp.status) "Status do Dispositivo",
CONCAT('LDR ', MAX(ldrs.id)) "Sensor LDR",
CONCAT(MAX(ldrd.luminosidade), ' lx') "Luminosidade",
MAX(ldrd.timestamp) "Momento do Registro LDR"
FROM esp32_dispositivos esp 
INNER JOIN ldr_dados ldrd on esp.id = ldrd.ldr_sensor_id
INNER JOIN ldr_sensores ldrs on ldrd.id = ldrs.esp32_dispositivo_id
GROUP BY esp.nome, esp.status, ldrs.id
ORDER BY esp.nome;
-- -------------------------------------------------------------------------------------------------------
-- 6.
SELECT esp.nome "Dispositivo",
UPPER(esp.status) "Status do Dispositivo",
CONCAT('DHT ', dhts.id) "DHT22",
CONCAT( MAX(dhtd.temperatura), ' °C') "Temperatura",
MAX(dhtd.umidade) "Umidade",
MAX(dhtd.timestamp) "Momento do Registro DHT"
FROM esp32_dispositivos esp 
INNER JOIN dht22_sensores dhts on esp.id = dhts.esp32_dispositivo_id
INNER JOIN dht22_dados dhtd on dhts.id - dhtd.dht22_sensor_id
GROUP BY esp.nome, esp.status, dhts.id
ORDER BY esp.nome;
-- -------------------------------------------------------------------------------------------------------
-- 7.
SELECT esp.nome "Dispositivo",
esp.status "Status do Dispositivo",
CONCAT('ultrassonico ', MAX(ults.id)) "Ultrassonico",
CONCAT( MAX(ultd.distancia), ' M') "Distancia",
MAX(ultd.timestamp) "Momento do Registro Ultrassonico"
FROM esp32_dispositivos esp 
INNER JOIN ultrassonico_sensores ults on esp.id = ults.esp32_dispositivo_id
INNER JOIN ultrassonico_dados ultd on ults.id = ultd.ultrassonico_sensor_id
GROUP BY esp.nome, esp.status, ults.id
ORDER BY esp.nome;
-- -------------------------------------------------------------------------------------------------------
/*
-- ATENÇÃO
-- Qual foi a temperatura e umidade registradas pelos sensores DHT22 nos últimos 7 dias? 
SELECT CONCAT('DHT22 ', dhts.id) "DHT22", 
dhts.localizacao_detalhada "Localização", 
dhtd.temperatura "Temperatura", 
dhtd.umidade "Umidade",
dhtd.timestamp "Momento do Registro do Sensor"
FROM dht22_sensores dhts
INNER JOIN dht22_dados dhtd ON dhts.id = dhtd.dht22_sensor_id
ORDER BY dhtd.timestamp DESC;
*/
-- -------------------------------------------------------------------------------------------------------
-- 8. Qual foi o menor indice de luminosidade registrada em cada armazém? 
SELECT arm.nome "Armazém", 
arm.localizacao "Localização do Armazém",
CONCAT('LDR ', ldrs.id) "Sensor LDR", 
ldrs.localizacao_detalhada "Localização LDR", 
MIN(ldrd.luminosidade) "Menor Indice",
ldrd.timestamp "Momento do Registro"
FROM armazens arm 
INNER JOIN esp32_dispositivos esp ON arm.id = esp.armazem_id
INNER JOIN ldr_sensores ldrs ON esp.id = ldrs.esp32_dispositivo_id
INNER JOIN ldr_dados ldrd ON ldrs.id = ldrd.ldr_sensor_id
GROUP BY arm.nome, arm.localizacao, ldrs.id, ldrs.localizacao_detalhada, ldrd.timestamp
ORDER BY MIN(ldrd.luminosidade) DESC ;
-- -------------------------------------------------------------------------------------------------------
-- 9.Qual é a méia de temperatura em cada armazém?
SELECT arm.nome "Armazén",
arm.localizacao "Localização do Armazém", 
CONCAT('DHT22 ', dhts.id)"DHT22", 
dhts.localizacao_detalhada "Localização DHT22",
ROUND(AVG(dhtd.temperatura), 2) "Temperatura", 
dhtd.timestamp "Momento do Registro do Sensor"
FROM armazens arm 
INNER JOIN dht22_sensores dhts ON arm.id = dhts.esp32_dispositivo_id 
INNER JOIN dht22_dados dhtd ON dhts.id = dhtd.dht22_sensor_id
GROUP BY arm.nome, arm.localizacao, dhts.id, dhtd.timestamp
ORDER BY AVG(dhtd.temperatura) DESC;
-- -------------------------------------------------------------------------------------------------------
-- 10.Qual é a média de umidade em cada armazém?
SELECT arm.nome "Armazén",
arm.localizacao "Localização do Armazém",
CONCAT('DHT22 ', dhts.id) "DHT22", 
dhts.localizacao_detalhada "Localização DHT22",
ROUND(AVG(dhtd.temperatura), 2) "Temperatura",
dhtd.timestamp "Momento do Registro do Sensor"
FROM armazens arm
INNER JOIN dht22_sensores dhts ON arm.id = dhts.esp32_dispositivo_id 
INNER JOIN dht22_dados dhtd ON dhts.id = dhtd.dht22_sensor_id
GROUP BY arm.nome, arm.localizacao, dhts.id, dhtd.timestamp
ORDER BY AVG(dhtd.temperatura) DESC;
-- -------------------------------------------------------------------------------------------------------
-- 11.Qual é a distância média registrada pelos sensores ultrassônicos por armazém?
SELECT arm.nome "Armazén",
arm.localizacao "Localização do Armazém",
CONCAT('ultrassonico ', ults.id) "Sensor Ultrassonico",
ults.localizacao_detalhada "Localização Ultrassonico",
CONCAT(ROUND(AVG(ultd.distancia), 2), ' M') "Distancia",
ultd.timestamp "Momento de Registro do Sensor" 
FROM armazens arm
INNER JOIN ultrassonico_sensores ults ON arm.id = ults.esp32_dispositivo_id
INNER JOIN ultrassonico_dados ultd ON ults.id = ultd.ultrassonico_sensor_id
GROUP BY arm.nome, arm.localizacao, ults.id, ults.localizacao_detalhada, ultd.timestamp
ORDER BY AVG(ultd.distancia) DESC;
-- ------------------------------------------------------------------------------------------------------- 
-- 12.Quais armazéns possuem capacidade acima de 400,000.00 kg e quantos dispositivos estão instalados neles?

-- 13.Qual é a variação de temperatura e umidade ao longo do tempo em um armazém específico?
-- 14.Quais sensores DHT22 registraram umidade abaixo de 40% nos últimos 10 dias?
-- 15.Quais dispositivos ESP32 possuem status diferente de 'ativo'?  
-- 16.Qual é a variação de luminosidade (máxima e mínima) registrada por cada sensor LDR?




