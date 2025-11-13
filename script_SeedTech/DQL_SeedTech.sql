-- select seed tech 

/*Liste todos os armazéns com seus dispositivos ESP32 e o sensor DHTT22, 
incluindo armazéns que não possuem dispositivos ou sensores.*/
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
Caso algum dispositivo ainda não tenha leituras, ele deve aparecer mesmo assim (com valores nulos). */
SELECT esp.nome "Dispositivo",
esp.status "Status do Dispositivo",
concat('LDR ', ldrs.id) "Sensor LDR",
ldrd.luminosidade "Luminosidade",
ldrd.timestamp "Momento"
;

delimiter $$
create funcion 
delimiter ;



