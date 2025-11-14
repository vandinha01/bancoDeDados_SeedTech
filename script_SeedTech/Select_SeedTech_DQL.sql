-- select seed tech 
USE seed_tech;
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
Caso algum dispositivo ainda não tenha leituras, ele deve aparecer mesmo assim (com valores nulos). 
1. LDR
2. DHT22
3. Ultrassonico
*/
-- 3.
SELECT esp.nome "Dispositivo",
UPPER(esp.status) "Status do Dispositivo",
CONCAT('LDR ', ldrs.id) "Sensor LDR",
CONCAT(ldrd.luminosidade, ' lx') "Luminosidade",
ldrd.timestamp "Momento do Registro LDR"
FROM esp32_dispositivos esp 
INNER JOIN ldr_dados ldrd on esp.id = ldrd.ldr_sensor_id
INNER JOIN ldr_sensores ldrs on ldrd.id = ldrs.esp32_dispositivo_id
GROUP BY esp.nome, esp.status, CONCAT('LDR ', ldrs.id), ldrd.luminosidade, ldrd.timestamp
ORDER BY esp.nome;

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

-- 5.
SELECT esp.nome "Dispositivo",
esp.status "Status do Dispositivo",
CONCAT(ults.id, 'M') "Ultrassonico",
ultd.distancia ,
ultd.impacto ,
ultd.timestamp "Momento do Registro Ultrassonico"
;
