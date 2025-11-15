-- select seed tech 
USE seed_tech;


-- Qual é a quantidade total de dispositivos esp32 cadastrados no sistema?
SELECT COUNT(esp.id) "Dispositivo"
FROM esp32_dispositivos esp;
-- -------------------------------------------------------------------------------------------------------
-- Quantos dispositivos ESP32 existem por armazém? (6)
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
-- 1.
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
-- 2.
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
-- 3.
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
-- 4.
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
-- 5.
SELECT esp.nome "Dispositivo",
esp.status "Status do Dispositivo",
MAX(ults.id) "Ultrassonico",
CONCAT( MAX(ultd.distancia), ' M') "Distancia",
MAX(ultd.timestamp) "Momento do Registro Ultrassonico"
FROM esp32_dispositivos esp 
INNER JOIN ultrassonico_sensores ults on esp.id = ults.esp32_dispositivo_id
INNER JOIN ultrassonico_dados ultd on ults.id = ultd.ultrassonico_sensor_id
GROUP BY esp.nome, esp.status, ults.id
ORDER BY esp.nome;
-- -------------------------------------------------------------------------------------------------------
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

-- Qual foi a maior e menor luminosidade registrada nos últimos 30 dias? 

-- -------------------------------------------------------------------------------------------------------
-- Qual é a tendência de temperatura (média) em cada armazém?
SELECT arm.nome "Armazen",
CONCAT('DHT ', dhts.id)"DHT22", 
AVG(dhtd.temperatura) "Temperatura", 
dhtd.timestamp "Momento do Registro do Sensor"
FROM armazens arm 
INNER JOIN dht22_sensores dhts ON arm.id = dhts.esp32_dispositivo_id 
INNER JOIN dht22_dados dhtd ON dhts.id = dhtd.dht22_sensor_id
GROUP BY arm.nome, dhts.id, dhtd.temperatura, dhtd.timestamp
ORDER BY AVG(dhtd.temperatura) DESC;
-- -------------------------------------------------------------------------------------------------------
-- Qual é a tendência de umidade (média) em cada armazém?
-- Qual é a distância média registrada pelos sensores ultrassônicos por armazém?
-- Quais armazéns possuem capacidade acima de 400,000.00 kg e quantos dispositivos estão instalados neles?
-- Qual é a variação de temperatura e umidade ao longo do tempo em um armazém específico?
-- Quais sensores DHT22 registraram umidade abaixo de 40% nos últimos 10 dias?
-- Quais dispositivos ESP32 possuem status diferente de 'ativo'?  
-- Qual é a variação de luminosidade (máxima e mínima) registrada por cada sensor LDR?




