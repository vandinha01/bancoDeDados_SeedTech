-- SELECT seed tech 

-- 1.Qual é a quantidade total de dispositivos esp32 cadastrados no sistema?
SELECT COUNT(esp.id) "Dispositivo"
FROM esp32_dispositivos esp;
-- -------------------------------------------------------------------------------------------------------
-- 2.Quantos dispositivos ESP32 existem por armazém? 
SELECT arm.nome "Armazen",
arm.localizacao "Localização",
CONCAT(arm.capacidade_kg, ' kg') "Capacidade",
COUNT(esp.id) "Dispositivo"
FROM armazens arm
INNER JOIN esp32_dispositivos esp on arm.id = esp.armazem_id
GROUP BY arm.nome, arm.localizacao, arm.capacidade_kg
ORDER BY COUNT(esp.id) DESC;
-- -------------------------------------------------------------------------------------------------------
-- 3.Qual é a quantidade de dispositivos ESP32 em cada armazém e qual é a média geral de dispositivos por armazém?
SELECT arm.nome "Armazém",
COUNT(esp.id) "Dispositivos",
(SELECT ROUND(AVG(qtd), 2)FROM (SELECT COUNT(e.id) qtd FROM esp32_dispositivos e 
GROUP BY e.armazem_id) sub) "Média Geral"
FROM armazens arm
LEFT JOIN esp32_dispositivos esp ON arm.id = esp.armazem_id
GROUP BY arm.nome;
-- -------------------------------------------------------------------------------------------------------
-- 4.Liste todos os armazéns com seus dispositivos ESP32 e o sensor DHTT22, incluindo armazéns que não possuem dispositivos ou sensores.
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
-- 5. Verificar se tem algum dispositivo que não esta conectado a nenhum sensor.
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
-- Liste todos os dispositivos cadastrados, mostrando também a última leitura registrada para cada sensor. 
-- 6. LDR
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
-- 7. DHT22
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
-- 8. ESP32
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
-- 8. Liste os sensores DHT22 que registraram temperatura acima da média geral de temperatura.
SELECT CONCAT('DHT22 ', dht.id) "Sensor",
       MAX(dhtd.temperatura) "Temperatura Máxima"
FROM dht22_sensores dht
INNER JOIN dht22_dados dhtd ON dht.id = dhtd.dht22_sensor_id
WHERE dhtd.temperatura > (SELECT AVG(temperatura) FROM dht22_dados)
GROUP BY dht.id
ORDER BY MAX(dhtd.temperatura) DESC; 
-- -------------------------------------------------------------------------------------------------------
-- 9. Qual foi o menor indice de luminosidade registrada em cada armazém? 
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
-- 10.Qual é a méia de temperatura em cada armazém?
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
-- 11.Qual é a média de umidade em cada armazém?
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
-- 12.Qual é a distância média registrada pelos sensores ultrassônicos por armazém?
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
-- 13.Quais armazéns possuem capacidade acima de 400,000.00 kg e quantos dispositivos estão instalados neles?
SELECT arm.nome "Armazém",
arm.localizacao "Localização do Armazém",
concat(arm.capacidade_kg, 'Kg') "Capacidade em kg",
COUNT(esp.id) "Quantidade de Dispositivos" 
FROM armazens arm 
INNER JOIN esp32_dispositivos esp ON arm.id = esp.armazem_id
WHERE arm.capacidade_kg > 400000
GROUP BY arm.id
ORDER BY COUNT(esp.id) DESC;
-- -------------------------------------------------------------------------------------------------------
-- 14.Quais armazéns possuem capacidade maior que a capacidade média de todos os armazéns? 
SELECT arm.nome "Armazém",
arm.capacidade_kg "Capacidade"
FROM armazens arm
WHERE arm.capacidade_kg > (SELECT AVG(arm.capacidade_kg)FROM armazens)
ORDER BY arm.capacidade_kg;
-- -------------------------------------------------------------------------------------------------------
-- 15.Qual é a variação de temperatura e umidade ao longo do tempo, no Armazém de Quarentena E?
SELECT arm.nome "Armazén", 
arm.localizacao "Localização do Armazém",
esp.nome "Nome do Dispositivo",
CONCAT('DHT22 ', dhts.id) "DHT22",
dhtd.temperatura "Temperatura", 
dhtd.umidade "Umidade",
dhtd.timestamp "Momento do Registro"
FROM armazens arm
INNER JOIN esp32_dispositivos esp ON arm.id = esp.armazem_id
INNER JOIN dht22_sensores dhts ON esp.id = dhts.esp32_dispositivo_id
INNER JOIN dht22_dados dhtd ON dhts.id = dhtd.dht22_sensor_id
WHERE arm.nome = 'Armazém de Quarentena E'
GROUP BY arm.nome, arm.localizacao, esp.nome, dhtd.temperatura, dhtd.umidade, dhtd.timestamp, dhts.id
;
-- ------------------------------------------------------------------------------------------------------- 
-- 16.Quais sensores DHT22 registraram umidade abaixo de 50.00 e acima 29 graus?
SELECT  arm.nome "Armazén", 
arm.localizacao "Localização do Armazém",
esp.nome "Nome do Dispositivo",
CONCAT('DHT22 ', dhts.id) "DHT22",
dhtd.temperatura "Temperatura", 
dhtd.umidade "Umidade",
dhtd.timestamp "Momento do Registro"
FROM armazens arm
INNER JOIN esp32_dispositivos esp ON arm.id = esp.armazem_id
INNER JOIN dht22_sensores dhts ON esp.id = dhts.esp32_dispositivo_id
INNER JOIN dht22_dados dhtd ON dhts.id = dhtd.dht22_sensor_id
WHERE dhtd.umidade < 50 and dhtd.temperatura > 29
GROUP BY arm.nome, arm.localizacao, esp.nome, dhtd.temperatura, dhtd.umidade, dhtd.timestamp, dhts.id
ORDER BY dhtd.umidade, dhtd.temperatura DESC;
-- ------------------------------------------------------------------------------------------------------- 
-- 17.Quais dispositivos ESP32 possuem status diferente de 'ativo', e em quais armazenns ele se encontra?  
SELECT arm.nome "Armazén",
arm.localizacao "Localização do Armazém",
esp.nome "Nome do Dispositivo",
UPPER(esp.status) "Status do Dispositivo"
FROM armazens arm
INNER JOIN esp32_dispositivos esp ON arm.id = esp.armazem_id
WHERE esp.status != 'ativo'
GROUP BY arm.nome, arm.localizacao, esp.nome, esp.status;
-- ------------------------------------------------------------------------------------------------------- 
-- 18.Liste os dispositivos ESP32 que estão em armazéns com capacidade acima da média.
SELECT esp.nome "Dispositivo",
UPPER(esp.status) "Status",
arm.nome "Armazém",
arm.capacidade_kg "Capacidade"
FROM esp32_dispositivos esp
INNER JOIN armazens arm ON esp.armazem_id = arm.id
AND arm.capacidade_kg > (SELECT AVG(capacidade_kg) FROM armazens)
ORDER BY arm.capacidade_kg DESC;
-- ------------------------------------------------------------------------------------------------------- 
-- 19.Qual é a média de temperatura registrada por sensores DHT22 em cada armazém, comparando com a média geral?
SELECT arm.nome AS "Armazém",
ROUND(AVG(dhtd.temperatura), 2) "Média Temperatura Armazém", 
(SELECT ROUND(AVG(temperatura), 2) FROM dht22_dados) "Média Geral"
FROM armazens arm
INNER JOIN esp32_dispositivos esp ON arm.id = esp.armazem_id
INNER JOIN dht22_sensores dht ON esp.id = dht.esp32_dispositivo_id
INNER JOIN dht22_dados dhtd ON dht.id = dhtd.dht22_sensor_id
GROUP BY arm.nome;
-- ------------------------------------------------------------------------------------------------------- 
-- 20.Liste os armazéns com a maior temperatura registrada, comparando com a temperatura máxima geral.
SELECT arm.nome "Armazém",
MAX(dhtd.temperatura) "Maior Temperatura Armazém",
(SELECT MAX(temperatura) FROM dht22_dados) "Maior Temperatura Geral"
FROM armazens arm
INNER JOIN esp32_dispositivos esp ON arm.id = esp.armazem_id
INNER JOIN dht22_sensores dht ON esp.id = dht.esp32_dispositivo_id
INNER JOIN dht22_dados dhtd ON dht.id = dhtd.dht22_sensor_id
GROUP BY arm.nome
ORDER BY MAX(dhtd.temperatura) DESC;

